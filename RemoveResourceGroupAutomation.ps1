<#
    .DESCRIPTION
        Removes Resource Groups that have a tag "RemoveResourceGroup" sat to "Yes"

    .NOTES
        Author: Jonathan Andersson
        Last Updated: 12/06/2019

    .EXAMPLE
        RemoveResourceGroupAutomation -TagResourceGroupName "RGName" -TagValue "Yes"
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $TagResourceGroupName = "RemoveResourceGroup",
    
    [Parameter()]
    [string]
    $TagValue = "Yes"
)
Process {
    try {
        [object] $Tag = @{}
        $Tag.Add($TagResourceGroupName, $TagValue)

        Write-Output "Using TagResourceGroupName: $TagResourceGroupName and TagValue: $TagValue"

        $ResourceGroups = Get-AzResourceGroup -tag $tag
        
        foreach ($ResourceGroup in $ResourceGroups) {
            Remove-AzResourceGroup -Name $ResourceGroup.ResourceGroupName -Force
            Write-Output "Removed Resource Group: $ResourceGroup.ResourceGroupName"
        }
    }
    catch {
        Write-Output "Trouble"
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
