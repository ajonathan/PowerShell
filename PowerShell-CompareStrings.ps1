
function Show-ArrayStringCompare {
    <#
        .DESCRIPTION
            Compares two String Array's
        
        .PARAMETER ArrayOne
            Add the first Array

        .PARAMETER ArrayTwo
            Add the second Array

        .PARAMETER ExistInBothList
            Add true or false if script should output all that exist or not exist in the lists

        .PARAMETER ExistOnlyInFirstList
            Add true of false if script should output all that only exist in one Array

        .EXAMPLE
            [string[]] $a = @("a","b","r","y","j","s","c")
            [string[]] $b = @("p","a","e","m","w","s","c")
            Show-ArrayStringCompare -ArrayOne $a -ArrayTwo $b -ExistInBothList $true
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string[]]
        $ArrayOne,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        $ArrayTwo,

        [Parameter(Mandatory=$false)]
        [Nullable[bool]]
        $ExistInBothList = $null,

        [Parameter(Mandatory=$false)]
        [Nullable[bool]]
        $ExistOnlyInFirstList = $null
    )
    Process {
        $result = Compare-Object -ReferenceObject $a -DifferenceObject $b -IncludeEqual

        if ($true -eq $ExistInBothList -and $null -eq $ExistOnlyInFirstList) {
            $result | Where-Object -Property SideIndicator -eq "==" | Select-Object -Property @{Name = 'Exist in both list'; Expression = {$_.InputObject}}
        }
        if ($false -eq $ExistInBothList -and $null -eq $ExistOnlyInFirstList) {
            $result | Where-Object -Property SideIndicator -ne "==" | Select-Object -Property @{Name = 'Exist in one list'; Expression = {$_.InputObject}}
        }
        if ($null -eq $ExistInBothList -and $true -eq $ExistOnlyInFirstList) {
            $result | Where-Object -Property SideIndicator -eq "<=" | Select-Object -Property @{Name = 'Exist in first list'; Expression = {$_.InputObject}}
        }
        if ($null -eq $ExistInBothList -and $false -eq $ExistOnlyInFirstList) {
            $result | Where-Object -Property SideIndicator -eq "=>" | Select-Object -Property @{Name = 'Exist in second list'; Expression = {$_.InputObject}}
        }
        if ($null -eq $ExistInBothList -and $null -eq $ExistOnlyInFirstList) {
            Write-Host "Please add -ExistInBothList or -ExistInFirstList parameter"
        }
    }
}