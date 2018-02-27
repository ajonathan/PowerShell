# Makes a copy from VMs in one Azure Resource Group to a new Resource Group.
# The script uses snapshot and the VMs needs managed disks to be used.
#
# Edit varibles before running the script.
#
# Version 2018-02-26
#
# ----------------------------------------------------------------------------------

$resourceGroupName = '<ResourceGroup>' # ResourceGroup for VMs to Clone
$location = 'West Europe' # Location for the resources
$destinationResourceGroup = 'CloneVM-RG1' # ResourceGroup for new VM
$subnetName = 'SubNet01-Clone' # subnet for the new VM
$vnetName = 'VNET-Clone' # VNet for the new VM
$nsgName = 'NSG-Clone' # NSG for the new VM
$storageName = 'storageclone' # Storage account prefix name
$storage = $null # Varible to check if storage account exist


# Get ResourceGroup
$rg = Get-AzureRmResourceGroup `
    -Location $location `
    -Name $destinationResourceGroup `
    -ErrorAction SilentlyContinue

# If needed create a new resource group
IF ($rg) {
    Write-Output "ResourceGroup already exist"
} else {
    New-AzureRmResourceGroup `
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
if(!$VMs) {
    Write-Output "No VMs were found in the ResourceGroup"
} else {
        Foreach ($VM in $VMs) {
        # Set new varibles for the new VM
        $snapshotName = $VM.Name + '-Snapshot'
        $osDiskName = $VM.Name + '-OsDisk' # new OS disk name
        $ipName = $VM.Name + '-IP'# public IP for the VM
        $nicName = $VM.Name + '-NIC' # Nic for the new VM
        $newVmName = $VM.Name + "-Clone" # Name for the new VM

        #$VM = Get-AzureRmVM -Name $vm.Name -ResourceGroupName $resourceGroupName
        $diskType = $VM.StorageProfile.OsDisk.OsType

        # Get the OS disk name.
        $disk = Get-AzureRmDisk `
            -ResourceGroupName $resourceGroupName `
            -DiskName $VM.StorageProfile.OsDisk.Name

        # Create the snapshot configuration
        If ($diskType -eq "Windows")
        {
            $snapshotConfig =  New-AzureRmSnapshotConfig `
                -SourceUri $disk.Id `
                -OsType Windows `
                -CreateOption Copy `
                -Location $location 
        }
        If ($diskType -eq "Linux")
        {
            $snapshotConfig =  New-AzureRmSnapshotConfig `
                -SourceUri $disk.Id `
                -OsType Linux `
                -CreateOption Copy `
                -Location $location
        }

        # Take snapshot.
        $snapShot = New-AzureRmSnapshot `
           -Snapshot $snapshotConfig `
           -SnapshotName $snapshotName `
           -ResourceGroupName $destinationResourceGroup

        # Create the managed disk.
        $osDisk = New-AzureRmDisk -DiskName $osDiskName -Disk `
            (New-AzureRmDiskConfig  -Location $location -CreateOption Copy `
            -SourceResourceId $snapshot.Id) `
            -ResourceGroupName $destinationResourceGroup

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

        # Add OS disk if Windows
        If ($diskType -eq "Windows") {
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
        $vm = Set-AzureRmVMBootDiagnostics `
            -VM $vm `            -ResourceGroupName $destinationResourceGroup `
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

        Write-Output $newVM
    }
}

