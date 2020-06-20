function PSTemplate {

    <#
        https://github.com/PoshCode/PowerShellPracticeAndStyle/blob/master/Style-Guide/Documentation-and-Comments.md#doc-01-write-comment-based-help
        .DESCRIPTION    
            Description
    
        .NOTES
            CREATED WITH: Visual Studio Code
            AUTHOR: Jonathan
            FILENAME: PSTemplate.ps1
    
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
        begin {
            $Time = Get-Date
        }
        process {
            try {
                if (-not (Get-Item -Path c:\Logs)) {
                    New-Item -Path c:\Logs -ItemType Directory
                }
                
                Write-Host "$FirstParameter $SecondParameter"
                $LastBootUpTime = (Get-CimInstance -ClassName win32_operatingsystem).LastBootUpTime
                Write-Host "LastBootUpTime: $LastBootUpTime"
                "$Time - LastBootUpTime $LastBootUpTime" | out-file c:\Logs\PSTemplate.log -append
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                #$FailedItem = $_.Exception.ItemName
                "$Time - $ErrorMessage" | out-file c:\Logs\PSTemplate.log -append
            }
            
        }
        end {}
    }
    
    PSTemplate -FirstParameter "parameter1"
    