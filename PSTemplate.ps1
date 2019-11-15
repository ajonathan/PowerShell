function PSTemplate {

<#
    .DESCRIPTION    
        Description

    .NOTES
        Notes
        AUTHOR: Jonathan

    .PARAMETER parameter1
        First parameter

    .SYNOPSIS
        Synopsis

    .EXAMPLE
        Example
#>

    [CmdletBinding (DefaultParametersetName="first")]
    param (
        # First parameter
        [Parameter (ParameterSetName="first", Mandatory=$true)]
        [string]
        $FirstParameter,

        # Second parameter
        [Parameter (ParameterSetName="second", Mandatory=$true)]
        [ValidateSet("one", "two")]
        [string]
        $SecondParameter
    )
    begin {}
    process {
        Write-Host "$FirstParameter $SecondParameter"
    }
    end {}
}

PSTemplate -FirstParameter "text"