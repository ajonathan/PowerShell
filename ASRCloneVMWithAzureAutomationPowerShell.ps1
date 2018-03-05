<# 
	.DESCRIPTION 
		The script is used to clone VMs in a Azure Site Recovery failover.
		It works with ASR Test Failover and can be used to clone an on-prem
		environmen without interupting, for example, the production workload.
		
		The script is using Azure snapshot and managed disks to make the clone
		of the VMs failed over.

		Edit varibles before running the script under the varibles section
		Only works with VMs that are in the same location as variable $location
		
		For more information see systemcenterme.com

		The following AzureRM Modules are required
		AzureRM.profile
		AzureRM.Resources
		AzureRM.Automation
		AzureRM.Network
		AzureRM.Compute
			
		Version 2018.03.05.0
 
	.NOTES 
		AUTHOR: Jonathan Andersson
#> 

param ( 
		[Object]$RecoveryPlanContext 
) 

# Valiables to change
$location = 'North Europe' # Location for resources after test failover
$destinationResourceGroupSuffix = '-CloneVM-RG' # ResourceGroup suffix
$subnetName = 'SubNet01-Clone' # subnet for the new VM
$vnetName = 'VNET-Clone' # VNet for the new VM
$nsgName = 'NSG-Clone' # NSG for the new VM
$storageName = 'storageclone' # Storage account prefix name

$storage = $null # Varible to check if storage account exist. Do not change

# Add extra logging by selecting $true
$LoggingVerbose = $false

If ($LoggingVerbose -eq $true) {
	Write-output $RecoveryPlanContext
}

# Connect to Azure with the RunAs COnnection
$connectionName = "AzureRunAsConnection"
try {
	# Get the connection "AzureRunAsConnection "
	$servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

	"Logging in to Azure..."
	Add-AzureRmAccount `
		-ServicePrincipal `
		-TenantId $servicePrincipalConnection.TenantId `
		-ApplicationId $servicePrincipalConnection.ApplicationId `
		-CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
} catch {
	if (!$servicePrincipalConnection)
	{
		$ErrorMessage = "Connection $connectionName not found."
		throw $ErrorMessage
	} else{
		Write-Error -Message $_.Exception
		throw $_.Exception
	}
}

Start-Sleep -s 60

# Get the VMs in the ASR plan group
$VMinfo = $RecoveryPlanContext.VmMap | Get-Member | Where-Object MemberType -EQ NoteProperty | select -ExpandProperty Name
$vmMap = $RecoveryPlanContext.VmMap

foreach($VMID in $VMinfo) {
	$asrVM = $vmMap.$VMID                
	if( !(($asrVM -eq $Null) -Or ($asrVM.ResourceGroupName -eq $Null) -Or ($asrVM.RoleName -eq $Null))) {
		#this check is to ensure that we skip when some data is not available else it will fail
		$resourceGroupName = $asrVM.ResourceGroupName

		If ($LoggingVerbose -eq $true) {
			Write-output "Resource Group name ", $asrVM.ResourceGroupName
			Write-output "Rolename " = $asrVM.RoleName
			Write-output "VM:  $asrVM"
		}

		# ResourceGroup for new VM
		$destinationResourceGroup = $resourceGroupName + $destinationResourceGroupSuffix
		
		# Get ResourceGroup
		$rg = Get-AzureRmResourceGroup `
			-Location $location `
			-Name $destinationResourceGroup `
			-ErrorAction SilentlyContinue

		# If needed create a new resource group
		IF ($rg) {
			Write-Output "ResourceGroup already exist"
		} else {
			$rg = New-AzureRmResourceGroup `
				-Location $location `
				-Name $destinationResourceGroup
			Write-output "Created Resource Group: $destinationResourceGroup"
		}

		# Get Vnet
		$vnet = Get-AzureRmVirtualNetwork `
			-ResourceGroupName $destinationResourceGroup `
			-Name $vnetName `
			-ErrorAction SilentlyContinue

		# If needed create Vnet and subNet with address prefix 10.0.0.0/24.
		IF ($vnet) {
			Write-Output "VNet already exist"
		} else {
			$singleSubnet = New-AzureRmVirtualNetworkSubnetConfig `
			   -Name $subnetName `
			   -AddressPrefix 10.0.0.0/24

			# Create the vNet and the address prefix for the virtual network to 10.0.0.0/16. 
			$vnet = New-AzureRmVirtualNetwork `
			   -Name $vnetName `
			   -ResourceGroupName $destinationResourceGroup `
			   -Location $location `
			   -AddressPrefix 10.0.0.0/16 `
			   -Subnet $singleSubnet
			Write-output "Created VNet: $vnetName"
		}

		# Snapshot and create VM
		If(!$asrVM) {
			Write-Output "No VM were found"
		} else {
			# Get the VM from Azure
			$VM = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $asrVM.RoleName
			
			If ($LoggingVerbose -eq $true) {
				Write-Output "Get VM for Snapshot: " $VM
			}
			$VMNameLog = $VM.Name
			Write-Output "Get VM Name: $VMNameLog"

			# Set new varibles for the new VM
			$snapshotSuffix = '-Snapshot'
			$osDiskName = $VM.Name + '-OsDisk' # new OS disk name
			$ipName = $VM.Name + '-IP'# public IP for the VM
			$nicName = $VM.Name + '-NIC' # Nic for the new VM
			$newVmName = $VM.Name + "-Clone" # Name for the new VM
				
			$diskType = $VM.StorageProfile.OsDisk.OsType

			# Create the snapshot configuration
			If ($diskType -eq "Windows") {
				$snapshotConfig =  New-AzureRmSnapshotConfig `
					-SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id `
					-OsType Windows `
					-CreateOption Copy `
					-Location $vm.Location
				Write-Output "Prepared Snapshot for Windows"
			}
			If ($diskType -eq "Linux") {
				$snapshotConfig =  New-AzureRmSnapshotConfig `
					-SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id `
					-OsType Linux `
					-CreateOption Copy `
					-Location $vm.Location
				Write-Output "Prepared Snapshot for Linux"
			}
				
			# Take snapshot of OS disk
			$snapshotName = $VM.Name + $snapshotSuffix
			$snapShot = New-AzureRmSnapshot `
			   -Snapshot $snapshotConfig `
			   -SnapshotName $snapshotName `
			   -ResourceGroupName $destinationResourceGroup
			Write-Output "Created Snapshot of OS disk: $snapshotName"

			# Create the managed OS disk
			$osDisk = New-AzureRmDisk -DiskName $osDiskName -Disk `
				(New-AzureRmDiskConfig  -Location $location -CreateOption Copy `
				-SourceResourceId $snapshot.Id) `
				-ResourceGroupName $destinationResourceGroup
			Write-Output "Created the managed OS disk: $osDisk"

			# Remove Snapshot
			Remove-AzureRmSnapshot `
				-ResourceGroupName $destinationResourceGroup `
				-SnapshotName $snapshotName -Force
			If ($LoggingVerbose -eq $true) {
				Write-Output "Removed OS Snapshot: $snapshotName"
			}

			# Get attached data disks
			$disks = $vm.StorageProfile.DataDisks
            
			# Snapshot data disks
			Foreach ($disk in $disks) {
				# Create the snapshot configuration
				If ($diskType -eq "Windows") {
					$snapshotConfig =  New-AzureRmSnapshotConfig `
						-SourceUri $disk.ManagedDisk.Id `
						-OsType Windows `
						-CreateOption Copy `
						-Location $vm.Location
					Write-Output "Created Snapshot Configuration for Windows data disk: " $disk.ManagedDisk.Id
				}
				If ($diskType -eq "Linux") {
					$snapshotConfig =  New-AzureRmSnapshotConfig `
						-SourceUri $disk.ManagedDisk.Id `
						-OsType Linux `
						-CreateOption Copy `
						-Location $vm.Location
					Write-Output "Created Snapshot Configuration for Linux data disk: " $disk.ManagedDisk.Id
				}

				# Take data disk snapshot
				#$snapshotName = $disk.Name + $snapshotSuffix
				$dataDiskName = $VM.Name + $disk.lun + '-Clone'
				$snapShot = New-AzureRmSnapshot `
					-Snapshot $snapshotConfig `
					-SnapshotName $snapshotName `
					-ResourceGroupName $destinationResourceGroup
				Write-Output "Created Snapshot data disk: $snapshotName"

				# Create the managed data disk
				#$dataDiskName = $disk.Name + '-Clone'
				$dataDiskName = $VM.Name + $disk.lun + '-Clone'
				New-AzureRmDisk -DiskName $dataDiskName -Disk `
					(New-AzureRmDiskConfig  -Location $location -CreateOption Copy `
						-SourceResourceId $snapshot.Id) `
						-ResourceGroupName $destinationResourceGroup
				Write-Output "Created managed data disk: $dataDiskName"

				# Remove Snapshot
				Remove-AzureRmSnapshot `
					-ResourceGroupName $destinationResourceGroup `
					-SnapshotName $snapshotName -Force
				If ($LoggingVerbose -eq $true) {
					Write-Output "Removed OS Snapshot: $snapshotName"
				}

			}

			# Create the public IP. In this example, the public IP address name is set to myIP.
			$pip = New-AzureRmPublicIpAddress `
			   -Name $ipName -ResourceGroupName $destinationResourceGroup `
			   -Location $location `
			   -AllocationMethod Dynamic

			# Create the NIC
			$nic = New-AzureRmNetworkInterface `
				-Name $nicName `
				-ResourceGroupName $destinationResourceGroup `
				-Location $location -SubnetId $vnet.Subnets[0].Id `
				-PublicIpAddressId $pip.Id `
				-NetworkSecurityGroupId $nsg.Id

			# Configure the VM with name and size
			$vmConfig = New-AzureRmVMConfig `
				-VMName $newVmName `
				-VMSize $vm.HardwareProfile.VmSize

			# Add NIC
			$newVM = Add-AzureRmVMNetworkInterface `
				-VM $vmConfig `
				-Id $nic.Id

			# Add OS disk
			If ($diskType -eq "Windows") {
				# Add OS disk if Windows
				$newVM = Set-AzureRmVMOSDisk `
					-VM $newVM `
					-ManagedDiskId $osDisk.Id `
					-StorageAccountType StandardLRS `
					-DiskSizeInGB 128 `
					-CreateOption Attach `
					-Windows
			} elseif ($diskType -eq "Linux") {
				# Add OS disk if Linux
				$newVM = Set-AzureRmVMOSDisk `
					-VM $newVM `
					-ManagedDiskId $osDisk.Id `
					-StorageAccountType StandardLRS `
					-DiskSizeInGB 128 `
					-CreateOption Attach `
					-Linux
			} else {
				Write-Output "No disk added. Didn't find supported OS version."
			}
            
			# Add data disks
			Foreach ($disk in $disks) {
				$dataDiskName = $VM.Name + $disk.lun + '-Clone'
				$diskobj = Get-AzureRmDisk -ResourceGroupName $destinationResourceGroup -DiskName $dataDiskName
               
				# Add data disk
				$newVM = Add-AzureRmVMDataDisk `
					-VM $newVM `
					-ManagedDiskId $diskobj.id `
					-StorageAccountType StandardLRS `
					-DiskSizeInGB $disk.DiskSizeGB `
					-Lun $disk.lun `
					-CreateOption Attach
				Write-Output "Added data disk $dataDiskName to VM $newVmName"
			}

			# Create storage account
			while ($storage -eq $null) {
				$number = Get-Random -Minimum 10000 -Maximum 99999
				$newStorageName = "$storageName$number"
       
				# Check if storage account already exist
				$checkStorateAccount = Get-AzureRmStorageAccount `
					-ResourceGroupName $destinationResourceGroup `
					-Name $newStorageName `
					-ErrorAction SilentlyContinue
            
				if ($checkStorateAccount -eq $null) {
					# Create storage account
					$storage = New-AzureRmStorageAccount `
						-ResourceGroupName $destinationResourceGroup `
						-Name $newStorageName `
						-Type Standard_LRS `
						-Location $location
					Write-Output "Created storage account: $newStorageName"
				}
			}
					
			# Add diagnostic to VM
			$newVM = Set-AzureRmVMBootDiagnostics `
				-VM $newVM `
				-ResourceGroupName $destinationResourceGroup `
				-StorageAccountName $storage.StorageAccountName `
				-Enable
			Write-Output "Set Boot Diagnostics on VM: $newVmName"

				# Complete the VM
				New-AzureRmVM `
					-ResourceGroupName $destinationResourceGroup `
					-Location $location `
					-VM $newVM
			Write-Output "Completed the VM: $newVmName"
		}
	}
}
