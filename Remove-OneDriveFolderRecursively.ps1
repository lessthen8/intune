##
## Script to recursively delete a OneDrive folder and its contents.
## 

## Install PnP.PowerShell module if it is missing
if(-not (Get-Module PnP.PowerShell -listavailable))
{
    install-module PnP.PowerShell -allowclobber -scope currentuser -force -ErrorAction Inquire
    Import-Module PnP.PowerShell
}

## Display a quick guide
Write-Host -foregroundcolor Cyan "`r`nTo delete a OneDrive folder and all its contents, confirm your login name by pressing 'Enter'.`r`nThen enter the folder name and press 'Enter'.`r`n"
Write-Host -foregroundcolor Cyan "You can also delete a subfolder by enter the path to it.`r`nExample: Delete subfolder named 'Monitor' under folder IT/Hardware, enter:`r`n`r`nIT/Hardware/Monitor`r`n"
Write-Host -foregroundcolor Cyan "Note1! Folder names are not case sensitive, so 'it/hardware/monitor' will work too.`r`nNote2! Large folders containing many Gigabytes of data may take several hours to delete`r`n"

# Setup configuration variables and user inputs.
$OneDriveHost = 'https://ivta-my.sharepoint.com'
$Login = whoami /upn
If (!($User=Read-Host "Your login name is: $Login . Press 'Enter' to confirm, or type 'q' and press 'Enter' to exit script")) { $User = $Login }

If ($User -ne $Login) {
    Write-Host "Script ended" 
    break }

$FolderToDel = Read-Host -Prompt 'Enter the OneDrive folder you want to delete'
$SitePath = '/personal/' + $User.Replace('.','_').Replace('@','_')
$TopFolder = $SitePath + '/Documents'
$FolderPath = $TopFolder + '/' + $FolderToDel.Replace('\','/')
$SiteURL = $OneDriveHost + $SitePath
$FolderSiteRelativeURL = $FolderPath 

# Function to recursively remove files and folders from the path given.
Function Clear-PnPFolder([Microsoft.SharePoint.Client.Folder]$Folder) {
    $InformationPreference = 'Continue'
    If ($Web.ServerRelativeURL -eq '/') {
        $FolderSiteRelativeURL = $Folder.ServerRelativeUrl
    } Else {       
        $FolderSiteRelativeURL = $Folder.ServerRelativeUrl.Replace($Web.ServerRelativeURL, [string]::Empty)
    }
    # First remove all files in the folder.
    $Files = Get-PnPFolderItem -FolderSiteRelativeUrl $FolderSiteRelativeURL -ItemType File
    ForEach ($File in $Files) {
        # Delete the file.
        Try {
        Remove-PnPFile -ServerRelativeUrl $File.ServerRelativeURL -Force -Recycle | Out-Null
        Write-Information ("Deleted File: '{0}' at '{1}'" -f $File.Name, $Folder.ServerRelativeURL)
        }
        Catch {
        Write-Information ("Unable to delete file: '{0}' at '{1}'" -f $File.Name,$Folder.ServerRelativeURL)
        }
    }
    # Second loop through sub folders and remove them - unless they are "special" or "hidden" folders.
    $SubFolders = Get-PnPFolderItem -FolderSiteRelativeUrl $FolderSiteRelativeURL -ItemType Folder
    Foreach ($SubFolder in $SubFolders) {
        If (($SubFolder.Name -ne 'Forms') -and (-Not($SubFolder.Name.StartsWith('_vti_')))) {
            # Recurse into children.
            Clear-PnPFolder -Folder $SubFolder
            # Finally delete the now empty folder.
            Try {
            Remove-PnPFolder -Name $SubFolder.Name -Folder $SitePath$FolderSiteRelativeURL -Force -Recycle | Out-Null
            Write-Information ("Deleted Folder: '{0}' at '{1}'" -f $SubFolder.Name, $Folder.ServerRelativeURL)
            }
            Catch {
            Write-Information ("Unable to delete folder: '{0}' at '{1}'" -f $File.Name,$Folder.ServerRelativeURL)
            Write-Host -f Yellow 'Folder not empty'
            }
        }
    }
    $InformationPreference = 'SilentlyContinue'
}     

# Connect to the site with the PnP.PowerShell module.

    try {
        Write-Host -f Yellow "Connecting to OneDrive..."
        Connect-PnPOnline -Url $SiteURL -Interactive
        Write-Host -f Green "Connected"
        # Check if OneDrive URL is correct and possible to connect to.
        $Web = Get-PnPWeb
        }
    catch {
        Write-Host -f Red 'Unable to connect to your OneDrive URL. Check spelling of your email address and try again'
        Disconnect-PnPOnline
        Write-Host -f Cyan 'Script ended' -ErrorAction stop
        break
    }

# Check if the folder to be deleted exists. End script if it doesn't.
Try {
    $Folder = Get-PnPFolder -Url $FolderSiteRelativeURL
    }
catch {
    Write-Host -f Red 'The folder you want to delete does not exist. Check spelling or folder path and try again.'
    Disconnect-PnPOnline
    Write-Host -f Cyan 'Script ended' -ErrorAction stop
    break
    }
    # Call the function to empty the folder if it exists.
    if ($null -ne $Folder) {
        Clear-PnPFolder -Folder $Folder
    } Else {
        Write-Error ("Folder '{0}' not found" -f $FolderSiteRelativeURL)
        Write-Host -f Cyan 'Script ended' -ErrorAction stop
        break
        }
#Finally remove the folder that now is empty.
Try {
    Remove-PnPFolder -Name $FolderToDel -Folder $TopFolder -Force -Recycle | Out-Null
    Write-Host -f Yellow 'Completed! The folder: ' -nonewline; Write-Host -f Green $FolderToDel.Replace('\','/') -nonewline; Write-Host -f Yellow ' is deleted and sent to the OneDrive Recycle Bin' 
    }
Catch {
    Write-Host -f Red 'Failed to delete the folder. It may contain files or folders that could not be deleted.'
    Write-Host -f Red 'Delete the remaining files/folders manually'
    } 
# Disconnect from PnP.PowerShell
Disconnect-PnPOnline
Write-Host -f Cyan 'Disconnected'
