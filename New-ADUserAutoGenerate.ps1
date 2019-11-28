function New-ADUserAutoGenerate {
    <#
        .DESCRIPTION
            Script with easy user creation logic in AD

        .NOTES
            AUTHOR: Jonathan

        .PARAMETER GivenName
            Add a given name to the user

        .PARAMETER SurName
            Add a surname to the user

        .EXAMPLE
            New-ADUserAuto -GivenName givenname -SurName surname
    #>

    [CmdletBinding ()]
    Param (
        [Parameter (Mandatory = $true)]
        [string] $GivenName,
        [Parameter (Mandatory = $true)]
        [string] $SurName
    )
    Process {
        $UserCreated = $false

        if ($GivenName.Length -ge 3 -and $SurName.Length -ge 3) {
            $SamAccountName = $GivenName.Trim().Substring(0,3).ToLower() + $SurName.Trim().Substring(0,3).ToLower()
            if (-not (Get-ADUserSamAccountName -SamAccountName $SamAccountName)) {
                $UserCreated = New-ADUserCreate -GivenName $GivenName -SurName $SurName -SamAccountName $SamAccountName
            }
        }
        if ($false -eq $UserCreated) {
            if ($GivenName.Length -ge 2 -and $SurName.Length -ge 4) {
                $SamAccountName = $GivenName.Trim().Substring(0,2).ToLower() + $SurName.Trim().Substring(0,4).ToLower()
                if (-not (Get-ADUserSamAccountName -SamAccountName $SamAccountName)) {
                    $UserCreated = New-ADUserCreate -GivenName $GivenName -SurName $SurName -SamAccountName $SamAccountName
                }
            }
        }
        if ($false -eq $UserCreated) {
            if ($GivenName.Length -ge 4 -and $SurName.Length -ge 2) {
                $SamAccountName = $GivenName.Trim().Substring(0,4).ToLower() + $SurName.Trim().Substring(0,2).ToLower()
                if (-not (Get-ADUserSamAccountName -SamAccountName $SamAccountName)) {
                    $UserCreated = New-ADUserCreate -GivenName $GivenName -SurName $SurName -SamAccountName $SamAccountName
                }
            }
        }
        if ($false -eq $UserCreated) {
            if ($GivenName.Length -ge 1 -and $SurName.Length -ge 5) {
                $SamAccountName = $GivenName.Trim().Substring(0,1).ToLower() + $SurName.Trim().Substring(0,5).ToLower()
                if (-not (Get-ADUserSamAccountName -SamAccountName $SamAccountName)) {
                    $UserCreated = New-ADUserCreate -GivenName $GivenName -SurName $SurName -SamAccountName $SamAccountName
                }
            }
        }
        if ($false -eq $UserCreated) {
            if ($GivenName.Length -ge 5 -and $SurName.Length -ge 1) {
                $SamAccountName = $GivenName.Trim().Substring(0,5).ToLower() + $SurName.Trim().Substring(0,1).ToLower()
                if (-not (Get-ADUserSamAccountName -SamAccountName $SamAccountName)) {
                    $UserCreated = New-ADUserCreate -GivenName $GivenName -SurName $SurName -SamAccountName $SamAccountName
                }
            }
        }
        if ($false -eq $UserCreated) {
            Write-Output "User $GivenName $SurName was not created"
        }
    }
}

function New-ADUserCreate {
    <#
        .DESCRIPTION
            Create a new user in AD
            Returns a true if user was created and a false if not created

        .NOTES
            AUTHOR: Jonathan

        .PARAMETER GivenName
            The given name of the account

        .PARAMETER SurName
            The surname of the account

        .PARAMETER SamAccountName
            The SamAccountName of the account

        .EXAMPLE
            New-ADUserCreate -GivenName givenname -SurName surname -SamAccountName samaccountname
    #>

    [CmdletBinding ()]
    [OutputType ([bool])]
    Param (
        [Parameter (Mandatory = $true)]
        [string] $GivenName,
        [Parameter (Mandatory = $true)]
        [string] $SurName,
        [Parameter (Mandatory = $true)]
        [string] $SamAccountName
    )
    Process {
        try {
            New-ADUser -Name "$GivenName $SurName ($SamAccountName)" -DisplayName "$GivenName $SurName" -SamAccountName $SamAccountName -GivenName $GivenName -Surname $SurName -UserPrincipalName "$SamAccountName@contoso.com"
            Write-Output "User with samaccountname $SamAccountName have been created"
            return $true
        }
        catch {
            Write-Output "Failed to create user $GivenName $SurName with SamAccountName $SamAccountName"
            return $false
        }    
    }
}

function Get-ADUserSamAccountName {
    <#
        .DESCRIPTION
            Checks if the SamAccountName already exist in the AD

        .NOTES
            AUTHOR: Jonathan

        .PARAMETER SamAccountName
            The SamAccountName that should be checked if it exist
    #>
    
    [CmdletBinding ()]
    [OutputType ([bool])]
    Param (
        [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
        [string] $SamAccountName
    )
    Process {
        If (-not (Get-ADUser -Filter {SamAccountName -like $SamAccountName})) {
            return $false
        }
        else {
            return $true
        }
        
    }
}

function Get-ADUserName {
    <#
        .DESCRIPTION
            Checks if an account with the name already exist in AD

        .NOTES
            AUTHOR: Jonathan

        .PARAMETER Name
            The name of the AD account
    #>
    
    [CmdletBinding ()]
    [OutputType ([bool])]
    Param (
        [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Name
    )
    Process {
        If (-not (Get-ADUser -Filter {name -like $Name})) {
            return $false
        }
        else {
            return $true
        }
        
    }
}
