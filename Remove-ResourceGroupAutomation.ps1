<#
    .DESCRIPTION
        Removes Resource Groups that have a tag "RemoveResourceGroup" set to "Yes"
        
        Script can be used in both Azure Automation and direct from PowerShell prompt
        The script have been tested in Azure Automation with module AzureRM.Resources version 6.7.3

    .NOTES
        Author: Jonathan Andersson
        Last Updated: 12/09/2019

    .PARAMETER TagResourceGroupName
        Tag name

    .PARAMETER TagValue
        Tag value

    .PARAMETER AzureAutomation
        If script sould be run in Azure Automation

    .PARAMETER ConnectionName
        A<ure Automation RunAs Connection to Azure

    .EXAMPLE
        RemoveResourceGroupAutomation -TagResourceGroupName "RGName" -TagValue "Yes" -AzureAutomation $false
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $TagResourceGroupName = "RemoveResourceGroup",
    
    [Parameter()]
    [string]
    $TagValue = "Yes",      

    [Parameter()]
    [bool]
    $AzureAutomation = $true,

    [Parameter()]
    [string]
    $ConnectionName = "AzureRunAsConnection"
)

# Create a Tag object
[object] $Tag = @{}

try {
    if ($AzureAutomation) {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName         

        # Logging in to Azure
        Add-AzureRmAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint | Out-Null
    }
    $Tag.Add($TagResourceGroupName, $TagValue)
    Write-Output "Using TagResourceGroupName: $TagResourceGroupName and TagValue: $TagValue"

    $ResourceGroups = Get-AzureRmResourceGroup -Tag $Tag

    foreach ($ResourceGroup in $ResourceGroups) {
        Remove-AzureRmResourceGroup -Name $ResourceGroup.ResourceGroupName -Force | Out-Null
        Write-Output "Removed Resource Group: " $ResourceGroup.ResourceGroupName
    }
} 
catch {
	if (!$servicePrincipalConnection)
	{
		$ErrorMessage = "Connection $ConnectionName not found."
		throw $ErrorMessage
    } 
    else{
		Write-Error -Message $_.Exception
		throw $_.Exception
	}
}
