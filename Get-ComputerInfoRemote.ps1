function Get-ComputerInfoRemote {
    <#
        .DESCRIPTION
            Use this script to get ComputerInfo from remote machines
            Load the script with  . .\Get-ComputerInfoRemote.ps1

        .NOTE
            Author: Jonathan

        .PARAMETER UserName
            Username of the user for access to the computer (Optional). Needed if not a credential
            object is provided

        .PARAMETER Credential
            Credential object to be used if not a user name is provided (Optional). Created with
            "$credential = Get-Credential -Message "Login to Server" -UserName userName"

        .PARAMETER ComputerName
            Remote computer that script is going to be ran on

        .EXAMPLE
            . .\Get-ComputerInfoRemote.ps1
            Get-ComputerInfoRemote -Credential $credential -UserName username
            or:
            $credential = Get-Credential -Message "Login to Server" -UserName userName"
            "server01", 'server02' | Get-ComputerInfoRemote -Credential $credential
            
    #>

    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $false, HelpMessage = "User name of the user for access to the computer")]
        [string] $UserName,
        [Parameter (Mandatory = $false, HelpMessage = "Credential object to be used if not a user name is provided")]
        [System.Management.Automation.PSCredential] $Credential = $null,
        [Parameter (Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Remote computer that script is going to be ran on")]
        [string] $ComputerName
    )

    process {
        if ($null -eq $Credential) {
            $Credential = Get-Credential -Message "Login to Server" -UserName $UserName
            $session = New-PSSession -ComputerName $ComputerName -Credential $Credential
            Invoke-Command -Session $session -ScriptBlock {Get-ComputerInfo}
        }
        else {
            $session = New-PSSession -ComputerName $ComputerName -Credential $Credential
            Invoke-Command -Session $Session -ScriptBlock {Get-ComputerInfo}
        }
        
    }
}


function Get-ComputerOsLastBootUpTimeRemote {
    <#
        .DESCRIPTION
            Use this script to get OsLastBootUpTime from remote machines

        .NOTE
            Author: Jonathan

        .PARAMETER UserName
            Username of the user for access to the computer (Optional). Needed if not a credential
            object is provided

        .PARAMETER Credential
            Credential object to be used if not a user name is provided (Optional). Created with
            "$credential = Get-Credential -Message "Login to Server" -UserName userName"

        .PARAMETER ComputerName
            Remote computer that script is going to be ran on

        .EXAMPLE
            . .\Get-ComputerInfoRemote.ps1
            Get-ComputerOsLastBootUpTimeRemote -Credential $credential -UserName username
            or:
            $credential = Get-Credential -Message "Login to Server" -UserName userName"
            "server01", 'server02' | Get-ComputerOsLastBootUpTimeRemote -Credential $credential
            
    #>

    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $false, HelpMessage = "User name of the user for access to the computer")]
        [string] $UserName,
        [Parameter (Mandatory = $false, HelpMessage = "Credential object to be used if not a user name is provided")]
        [System.Management.Automation.PSCredential] $Credential = $null,
        [Parameter (Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Remote computer that script is going to be ran on")]
        [string] $ComputerName
    )

    Begin {
        # Property of the information that Get-ComputerInfo is going to display
        $Property = "OsLastBootUpTime"
    }
    process {
        if ($null -eq $Credential) {
            $Credential = Get-Credential -Message "Login to Server" -UserName $UserName
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
            $psoutput = Invoke-Command -Session $Session -ScriptBlock {
                [CmdletBinding()]
                Param (
                    [Parameter (Mandatory = $true)]
                    [string] $Property
                )
                Get-ComputerInfo -Property $Property
            } -ArgumentList $Property
            $psoutput | Select-Object -Property OsLastBootUpTime, PSComputerName
        }
        else {
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
            $psoutput = Invoke-Command -Session $Session -ScriptBlock {
                [CmdletBinding()]
                Param (
                    [Parameter (Mandatory = $true)]
                    [string] $Property
                )
                Get-ComputerInfo -Property $Property
            } -ArgumentList $Property
            $psoutput | Select-Object -Property OsLastBootUpTime, PSComputerName
        }
        
    }
}