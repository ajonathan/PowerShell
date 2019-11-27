function Add-ADGroupMember
{
    <#
        .DESCRIPTION
            Adds users from a specific 

        .NOTES

        .PARAMETER GroupName
        
        .PARAMETER Attribute

        .PARAMETER AttributeValue

        .EXAMPLE

    #>
    Param (
        [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
        [string] $GroupName,
        [Parameter (Mandatory = $true)]
        [string] $Attribute,
        [Parameter (Mandatory = $true)]
        [string] $AttributeValue
    )
        Process {
        try
        {
            Import-Module ActiveDirectory
            $Group = Get-ADGroup $GroupName
            $Users = Get-ADUser -Filter {$Attribute -like $AttributeValue}
            
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