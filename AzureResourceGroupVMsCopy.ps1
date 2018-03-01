# Makes a copy from VMs in one Azure Resource Group to a new Resource Group
# The script uses snapshot and the VMs needs managed disks to be used
#
# Edit varibles before running the script
# Login to Azure PowerShell before running script. Works in Azure Cloud Shell
# Tested with PowerShell version 4.3.0
# Only works with VMs that are in the same location as variable $location
#
# Version 2018-03-01
#
# ------------------------------------------------------------------------------------------

$resourceGroupName = '<ResourceGroup>' # ResourceGroup for VMs to Clone
$location = 'West Europe' # Location for resources
$destinationResourceGroup = $resourceGroupName + '-CloneVM-RG' # ResourceGroup for new VM
$subnetName = 'SubNet01-Clone' # subnet for the new VM
$vnetName = 'VNET-Clone' # VNet for the new VM
$nsgName = 'NSG-Clone' # NSG for the new VM
$storageName = 'storageclone' # Storage account prefix name


$storage = $null # Varible to check if storage account exist. Do not change

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
}

# Get all VMs in a RG
$VMs = Get-AzureRmVM -ResourceGroupName $resourceGroupName

# Snapshot and create VM
If(!$VMs) {
    Write-Output "No VMs were found in the ResourceGroup"
} else {
        Foreach ($VM in $VMs) {
        # Check that VM is in same location as defined in variable $location
        If ($vm.Location -ne $rg.Location) {
            $vmName = $vm.Name
            Write-Output "VM $vmName is not in defined Azure Region"
        } else {
            # Set new varibles for the new VM
            $snapshotSuffix = '-Snapshot'
            $osDiskName = $VM.Name + '-OsDisk' # new OS disk name
            $ipName = $VM.Name + '-IP'# public IP for the VM
            $nicName = $VM.Name + '-NIC' # Nic for the new VM
            $newVmName = $VM.Name + "-Clone" # Name for the new VM

            $diskType = $VM.StorageProfile.OsDisk.OsType

            # Get the OS disk name.
            $osDisk = Get-AzureRmDisk `
                -ResourceGroupName $resourceGroupName `
                -DiskName $VM.StorageProfile.OsDisk.Name

            # Create the snapshot configuration
            If ($diskType -eq "Windows") {
                $snapshotConfig =  New-AzureRmSnapshotConfig `
                    -SourceUri $osDisk.Id `
                    -OsType Windows `
                    -CreateOption Copy `
                    -Location $vm.Location
            }
            If ($diskType -eq "Linux") {
                $snapshotConfig =  New-AzureRmSnapshotConfig `
                    -SourceUri $osDisk.Id `
                    -OsType Linux `
                    -CreateOption Copy `
                    -Location $vm.Location
            }

            # Take snapshot of OS disk
            $snapshotName = $VM.Name + $snapshotSuffix
            $snapShot = New-AzureRmSnapshot `
               -Snapshot $snapshotConfig `
               -SnapshotName $snapshotName `
               -ResourceGroupName $destinationResourceGroup

            # Create the managed OS disk
            $osDisk = New-AzureRmDisk -DiskName $osDiskName -Disk `
                (New-AzureRmDiskConfig  -Location $location -CreateOption Copy `
                -SourceResourceId $snapshot.Id) `
                -ResourceGroupName $destinationResourceGroup

            # Get attached data disks
            $disks = $vm.StorageProfile.DataDisks
            
            # Snapshot data disks
            Foreach ($disk in $disks) {
                $diskobj = Get-AzureRmDisk -ResourceGroupName $resourceGroupName -DiskName $disk.Name

                # Create the snapshot configuration
                If ($diskType -eq "Windows") {
                    $snapshotConfig =  New-AzureRmSnapshotConfig `
                        -SourceUri $diskobj.Id `
                        -OsType Windows `
                        -CreateOption Copy `
                        -Location $vm.Location
                }
                If ($diskType -eq "Linux") {
                    $snapshotConfig =  New-AzureRmSnapshotConfig `
                        -SourceUri $diskobj.Id `
                        -OsType Linux `
                        -CreateOption Copy `
                        -Location $vm.Location
                }

                # Take snapshot
                $snapshotName = $VM.Name + $disk.lun + $snapshotSuffix
                $snapShot = New-AzureRmSnapshot `
                    -Snapshot $snapshotConfig `
                    -SnapshotName $snapshotName `
                    -ResourceGroupName $destinationResourceGroup

                # Create the managed disk
                $dataDiskName = $VM.Name + $disk.lun + '-Clone'
                New-AzureRmDisk -DiskName $dataDiskName -Disk `
                    (New-AzureRmDiskConfig  -Location $location -CreateOption Copy `
                    -SourceResourceId $snapshot.Id) `
                    -ResourceGroupName $destinationResourceGroup
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
                Break Script
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
                    }
            }

            # Add diagnostic to VM
            $newVM = Set-AzureRmVMBootDiagnostics `
                -VM $newVM `
                -ResourceGroupName $destinationResourceGroup `
                -StorageAccountName $storage.StorageAccountName `
                -Enable

            # Complete the VM
            New-AzureRmVM `
                -ResourceGroupName $destinationResourceGroup `
                -Location $location `
                -VM $newVM

            # Remove Snapshot
            Remove-AzureRmSnapshot `
                -ResourceGroupName $destinationResourceGroup `
                -SnapshotName $snapshotName -Force
        }
    }
}

