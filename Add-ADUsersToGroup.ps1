function Add-ADGroupMember {
    <#
        .DESCRIPTION
            Adds users from a specific 

        .NOTES
            AUTHOR: Jonathan

        .PARAMETER GroupName
            Name of the group that users should be added to

        .PARAMETER Properties
            Properties that decides if user should be added to group

        .PARAMETER PropertiesValue
            Priperties value that decides if user should be added to group

        .EXAMPLE
            Get-ADUser user01 | Set-ADUser -Department "IT"
            Add-ADGroupMember -GroupName mygroup -Properties Department -PropertiesValue IT
    #>
    Param (
        [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
        [string] $GroupName,
        [Parameter (Mandatory = $true)]
        [string] $Properties,
        [Parameter (Mandatory = $true)]
        [string] $PropertiesValue
    )
        Process {
        try
        {
            Import-Module ActiveDirectory
            $Group = Get-ADGroup $GroupName
            $Users = Get-ADUser -Filter {$Properties -like $PropertiesValue}
            
            Write-Output "Users added to group $GroupName :"
            foreach ($user in $users) 
            {
                Add-ADGroupMember -Identity $Group -Members $user
                Write-Output $user.sAMAccountName
            }
        }
        catch
        {
            Write-Output "Something went wrong"
        }
    }
}