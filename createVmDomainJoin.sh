#!/bin/bash

# create a VM and join it to a domain
# version 1.1

rg="server-rg"
vmname="servername"
vnet="vnet"
subnet="subnet"
vnetrg="vnet-rg"
location="westeurope"
image="win2016datacenter"
vmsize="Standard_DS2_v2"
storagetype="StandardSSD_LRS"
localadminuser="username"
domainname="contoso.com"
domainuser="username"
read -p "Enter your local admin user password: " -s localadminpw
echo
read -p "Enter your domain joining user password: " -s domainjoinpw
echo

az group create -l $location -n "$rg"

# Get Subnet id
sub=$(az network vnet subnet show -g "$vnetrg" --vnet-name "$vnet" --name "$subnet" -o tsv --query id)

echo "Creating virtual network interface"
az network nic create --resource-group "$rg" --name $vmname-nic --subnet "$sub" --public-ip-address ""

echo "Creating VM"
az vm create --resource-group $rg --name $vmname --nics "$vmname-nic" --location $location --license-type None --image $image --size $vmsize --storage-sku $storagetype --admin-username $localadminuser --admin-password $localadminpw

echo "Adding VM to domain"
az vm extension set -n JsonADDomainExtension --publisher Microsoft.Compute --version 1.3.2 --vm-name $vmname -g $rg --settings '{"Name" : "'$domainname'", "User" : "'$domainname\\$domainuser'", "Restart" : "true", "Options" : 3}' --protected-settings '{"Password": "'$domainjoinpw'"}'
