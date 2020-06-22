<#
    .DESCRIPTION    
        Will add a prefix on files and folders

    .NOTES
        CREATED WITH: Visual Studio Code
        AUTHOR: Jonathan
        LAST UPDATED: 06/21/2020
        FILENAME: Add-PrefixToFiles.ps1

    .PARAMETER Prefix
        Prefix that should be added to the file or folder

    .PARAMETER AlwaysPrefix
        Should the script always add the prefix or only on files that doesn't have the prefix already

    .PARAMETER File
        Only add prefix to files

    .PARAMETER Folder
        Only add prefix to folders

    .SYNOPSIS
        Synopsis

    .EXAMPLE
        Add-PrefixToFiles.ps1 -Prefix "My"
        Add-PrefixToFiles.ps1 -Prefix "g-" -AlwaysPrefix $false -Directory $true
#>
    
[CmdletBinding (DefaultParametersetName="first")]
param (
    # First parameter
    [Parameter (ParameterSetName="first", Mandatory=$true)]
    [string]
    $Prefix,

    # Second parameter
    [Parameter (Mandatory=$false)]
    [bool]
    $AlwaysPrefix,

    # Second parameter
    [Parameter (Mandatory=$false)]
    [bool]
    $File,

    # Second parameter
    [Parameter (Mandatory=$false)]
    [bool]
    $Directory
)
begin {
    if ($Directory -eq $true) {
        $items = Get-ChildItem -Directory *
    } elseif ($File -eq $true) {
        $items = Get-ChildItem -File *
    } else {
        $items = Get-ChildItem *
    }
}
process {
    try {
        foreach ($item in $items) {
            $fileName = $item.Name
            if ($fileName -ne "Add-PrefixToFiles.ps1") {
                if ($fileName.Substring(0, $Prefix.Length) -eq "$Prefix" -and $AlwaysPrefix -eq $false) {
                    Write-Host "Prefix already exist - " $Prefix ": " $fileName
                }
                    else {
                    Rename-Item $fileName "$prefix$fileName"
                    Write-Host $prefix$fileName
                }
            }
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        #$FailedItem = $_.Exception.ItemName
        "$Time - $ErrorMessage" | out-file c:\Logs\AddPrefixToFiles.log -append
    }
    
}
end {}
