
function Show-ArrayStringCompare {
    <#
        .DESCRIPTION
            Compares two string array's
        
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
            Show-ArrayStringCompare -ArrayOne $a -ArrayTwo $b
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
            [PSCustomObject] $ResultObj
            [System.Collections.ArrayList] $list = @()
            
            foreach ($info in $result) {
                if ("==" -eq $info.SideIndicator) {
                    $ResultObj = [PSCustomObject]@{
                        BothList  = $info.InputObject
                        FirstList  = $null
                        SecondList = $null
                    }
                    $list.Add($ResultObj) | Out-Null
                }
                if ("<=" -eq $info.SideIndicator) {
                    $ResultObj = [PSCustomObject]@{
                        BothList  = $null
                        FirstList  = $info.InputObject
                        SecondList = $null
                    }
                    $list.Add($ResultObj) | Out-Null
                }
                if ("=>" -eq $info.SideIndicator) {
                    $ResultObj = [PSCustomObject]@{
                        BothList  = $null
                        FirstList  = $null
                        SecondList = $info.InputObject
                    }
                    $list.Add($ResultObj) | Out-Null
                }
            }
            Get-OutputList -List $list
        }
    }
}

function Get-OutputList {
    <#
        .DESCRIPTION
            Output of an array with objects withour $null and "" fields

        .NOTES
            AUTHOR: jonathan

        .PARAMETER List
            Array with object with BothList, FirstList and SecondList

        .EXAMPLE
            Get-OutputList -List $list
    #>

    [CmdletBinding ()]
    param (
        [Parameter()]
        [Array]
        $List
    )
    Process {
        [int] $HighNr
        [System.Collections.ArrayList] $OutputList = @()

        # Create Array and remove $null and ""
        [string[]] $BothList = ($List.BothList |  Where-Object { $_ })
        [string[]] $FirstList = ($List.FirstList |  Where-Object { $_ })
        [string[]] $SecondList = ($List.SecondList |  Where-Object { $_ })

        [int] $BothListNr = 0
        [int] $FirstListNr = 0
        [int] $SecondListNr = 0

        # Get the highest number
        $HighNr = ($BothList.count, $FirstList.count, $SecondList.count | Measure-Object -Maximum).Maximum -as [int]

        # Add all values to a new Array with Objects
        for ([int] $i = 0; $i -lt $HighNr; ++$i) {
            # Create Object
            $ResultObj = [PSCustomObject]@{
                BothList  = $null
                FirstList  = $null
                SecondList = $null
            }
            $OutputList.Add($ResultObj) | Out-Null

            # Add BothListNr value to object in Array
            if ($null -ne $BothList[$i]) {
                $OutputList[$BothListNr].BothList = $BothList[$i]
                $BothListNr++
            }
            # Add FirstList value to object in Array
            if ($null -ne $FirstList[$i]) {
                $OutputList[$FirstListNr].FirstList = $FirstList[$i]
                $FirstListNr++
            }
            # Add SecondList value to object in Array
            if ($null -ne $SecondList[$i]) {
                $OutputList[$SecondListNr].SecondList = $SecondList[$i]
                $SecondListNr++
            }
        }
        Write-output $OutputList
    }
}