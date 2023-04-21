Connect-ExchangeOnline -UserPrincipalName chudson@empirix.com
<#
    List-DLMembers.ps1
    
    This script lists all members of a distribution list including all 
    child groups members recursively. It create a CSV file with all
    groups of the given distribution group.

    Parameter: Distribution group Alias or Name or Email Address

    Example:
    .\List-DLMembers.ps1 -DLName "NA-Sales"
#>
$DLname = prompt
$groupname = prompt

<#

Function    : Expand-Group
Parameter   : Distribution Group Name
Description : This function populates all the members of the
given distribution group to a global variable named $Global:Users 

#>
Function Expand-Group ($GroupName)
{
    $members = Get-DistributionGroupMember -Identity $GroupName

    foreach($member in $members)
    {
        $RecipientType = (Get-Recipient $member.Alias).RecipientType
        
        $member.Name + "`t`t`t" + $RecipientType
        if ($RecipientType -like "*DistributionGroup*")
        {
            # Found an child group - calling myself to expand the group
            Expand-Group -GroupName $member.Alias
        }

        # Create a PSCustomObject of the current member
        $MemberObject = [PSCustomObject] @{
            Name = "$($member.Name)" 
            Title = "$($member.Title)" 
            Department = "$($member.Department)" 
            Email = "$($member.PrimarySMTPAddress)" 
            Memberof = "$GroupName"
        }

        # Store the member object to Users array
        $global:users += $MemberObject
    }
}
<#
    End of the Function
#>




<#
 °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸ °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸

                THE SCRIPT STARTS HERE

 °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸ °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
#>


# Create a Global Array Variable to store all DL member objects
$global:users = @()

# Call the Expand-Group function to populate the all DL members
Expand-Group -GroupName $DLname

#Store the member objects to a CSV file
$filename = ".\$DLName-Members.csv"
$global:users | ConvertTo-Csv | Out-File -FilePath $filename

<#
 °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸ °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸

                END OF THE SCRIPT

 °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸ °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸

#>