function Get-ADDestinguishedPlacement {
    <#
        .DESCRIPTION
            Will return where user or computer object are placed in Active Directory

        .NOTES
            AUTHOR: Jonathan

        .PARAMETER Type
            Specify if user och computer should be searched for

        .EXAMPLE
            Get-ADDestinguishedPlacement -Type "User"
    #>

    [CmdletBinding()]
    [OutputType ([string[]])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("User", "Computer")]
        [string]
        $Type = $null
)
    Process {
        Import-Module ActiveDirectory
        [System.Collections.ArrayList] $Place = @()

        if ($Type -eq "Computer") {
            # Get all Computers from AD
            $ObjFromAD = Get-ADComputer -Filter *
        }
        else {
            # Get all Users from AD
            $ObjFromAD = Get-ADUser -Filter *
        }
    
        foreach ($Input in $ObjFromAD) {
            if (-not ($Place -contains ($Input.DistinguishedName).split(",",2)[1])) {
                $Place.Add(($Input.DistinguishedName).split(",",2)[1]) | Out-Null
            }
        }
        return $Place
    }
}

function Get-ADUserDestinguishedPlacementObjects {
    <#
        .DESCRIPTION
            List all users in a specific place in Active Directory

        .NOTES
            AUTHOR: Jonathan

        .PARAMETER SearchBaseString
            String with the destination to look for users

        .EXAMPLE
            Get-ADUserDestinguishedPlacementObjects -SearchBaseString "CN=Users,DC=contoso,DC=com"
            or
            $i = Get-ADDestinguishedPlacement
            Get-ADUserDestinguishedPlacementObjects -SearchBaseArray $i
    #>

    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $SearchBaseString = $null,

        [Parameter()]
        [string[]]
        $SearchBaseArray = $null
    )
    Process {
        Import-Module ActiveDirectory

        if (($null -eq $SearchBaseString) -and ($null -eq $SearchBaseArray)) {
            Write-Host "Don't use SearchBaseString and SearchBaseArray together"
        }
        if (($null -eq $SearchBaseString) -and ($null -eq $SearchBaseArray)) {
            Write-Host "Please provide SearchBaseString or SearchBaseArray as input"
        }
        If ($null -ne $SearchBaseString) {
            Get-ADUser -Filter * -SearchBase $SearchBaseString | Select-Object SamAccountName
        }
        If ($null -ne $SearchBaseArray) {
            foreach ($SearchBaseString in $SearchBaseArray) {
                Write-Output ""
                Write-Output "Placement: $SearchBaseString"
                Write-Output "--------------------------------------------"
                $users = Get-ADUser -Filter * -SearchBase $SearchBaseString.ToString().Trim()
                $users.SamAccountName
            }
         }
    }
}
