################
#Created by CH #
################
# Intune Distribution

# Set the execution policy to allow the script to run
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force

# Check if the script is running with administrator privileges
#$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# If the script is not running with administrator privileges, relaunch it with the "RunAs" verb
#if (-not $isAdmin) {
#Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -PassThru
#exit
#}

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{  
 $arguments = "& '" +$myinvocation.mycommand.definition + "'"
  Start-Process powershell -Verb runAs -ArgumentList $arguments
  Break
}

#start logging now after console is admin
$log = "C:\temp\FalconUnininstallLog.txt"
start-transcript -Path $log -force -Verbose

# Display all installed applications and their Uninstallstring
Write-Verbose "Getting list of installed applications..."
$installedApps = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$installedApps | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, UninstallString |
Format-Table -AutoSize
Write-Verbose "Finished getting list of installed applications."

#define uninstall strings, first looking in 32bit and then 64bit registry locales
$uninstall32 = Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" |
ForEach-Object { Get-ItemProperty $_.PSPath } |
Where-Object { $_.Publisher -like "Crowdstrike*" } |
Select-Object UninstallString 

$uninstall64 = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | 
ForEach-Object { Get-ItemProperty $_.PSPath } |
Where-Object { $_.Publisher -like "Crowdstrike*" } |
Select-Object UninstallString 

#Start on each one, storing in an array and action on each, waiting for each unininstall to finish
 
foreach ($uninstall in $uninstall64) {
    #for uninstall64 MSI exec is used, remove the defined flags so we can call a process and supply our own
        $guid = $uninstall.UninstallString -replace 'msiexec.exe', '' -replace '/I', '/X'
        #remove trailing spaces
        $guid = $guid.Trim()
        #tell us if it doesnt find anything
        if ([string]::IsNullOrWhiteSpace($guid)) {
            Write-Error "Error: Could not determine guid in: $guid"
        } else {
            Write-Host "Uninstalling 64bit"
            #Run quiet on the guid of app matching publisher
            Start-Process$ -FilePath "MsiExec.exe" -ArgumentList "/X" "$guid" -Wait -Verbose
            if ($process.ExitCode -ne 0) {
                #write error for intune to track
                Write-error "Error: a 64 bit Uninstall failed with exit code $($process.ExitCode)"
             }
        }
 }
       foreach ($uninstall in $uninstall32) {
        $uninstall32exe = $uninstall.UninstallString -replace '"', ''
        #define a working dir from whats defined in OS by modifying uninstall string and application (Remove app with your own)
        $uninstall32Path = $uninstall.UninstallString -replace '/uninstall$', '' -replace 'WindowsSensor.LionLanner.x64.exe', '' -replace '"', ''
        if ([string]::IsNullOrWhiteSpace($uninstall32Path)) {
            Write-Error "Error: Could not determine path for uninstall32 executable"
        } else {
            Write-Host "32bit uninstaller $uninstall32exe at path $uninstall32path"
          Start-Process $uninstall32exe -ArgumentList "/uninstall /passive" -WorkingDirectory $uninstall32Path -verbose -wait
            if ($process.ExitCode -ne 0) {
                #write error for intune to track
                Write-error "Error: 32bit Uninstall failed with exit code $($process.ExitCode)"
                }
        }
}

#Failover
    Write-Host "Hmm... Didn't find CrowdStrike in the registry, trying another method"
    $cim = Get-CimInstance -ClassName Win32_Product -Filter "Name Like 'Crowdstrike%'"
    foreach ($IdentifyingNumber in $cim.IdentifyingNumber) {
        Write-Verbose "Uninstalling CrowdStrike using CIM..."
        Start-Process "msiexec.exe" -ArgumentList "/X /Q /P $IdentifyingNumber /quiet" -Wait
        if ($process.ExitCode -ne 0) {
            Write-Error "Error: Uninstall failed with exit code $($process.ExitCode)"
            exit 1 
        }
    }


Stop-Transcript
