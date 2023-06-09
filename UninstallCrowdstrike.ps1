################
#Created by CH #
################
# Intune Distribution

### Standard deployment Template - IV Updated 4/2023 ###
# Set the execution policy to allow the script to run
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
#MakeAdmin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{  
 $arguments = "& '" +$myinvocation.mycommand.definition + "'"
  Start-Process powershell -Verb runAs -ArgumentList $arguments
  Break
}
#start logging now after console is admin
$log = "C:\temp\FalconUnininstallLog.txt"
start-transcript -Path $log -force -Verbose
### END TEMPLATE ###

$csAgentStatus = sc.exe query csagent
Write-Host $csAgentStatus

# Download the file and save it to the specified location
$downloadUrl = "https://ftp.empirix.com/?u=zTpvPz&p=mGAnan&path=/CsUninstallTool.exe"
$outputPath = "C:\temp\intune\CS\CsUninstallTool.exe"
New-Item -ItemType Directory -Path (Split-Path $outputPath) -Force | Out-Null
Write-Verbose "Downloading file from $downloadUrl to $outputPath"
Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath 

# Run the downloaded application silently with administrator privileges and /quiet flag
$csarguments = "/uninstall"
Write-Verbose "1/4 Running CsUninstallTool.exe with arguments: $csarguments"
Start-Process -FilePath $outputPath -ArgumentList $csarguments -Wait 

# Check if the application is removed from the default install path
$defaultInstallPath = "C:\ProgramData\Package Cache\"
$searchPattern = "WindowsSensor"
$installedAppPath = Get-ChildItem -Path $defaultInstallPath -Filter $searchPattern -Recurse -ErrorAction SilentlyContinue
if ($installedAppPath) {
    Write-Error "Error: WindowsSensor is still present in the default install path" 
} else {
        Write-Verbose "WindowsSensor successfully removed from the default install path"
}

#Begin backup removal method

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
                Write-Host "2/4 Uninstalling 64bit using MSIExec"
                #Run quiet on the guid of app matching publisher
                Start-Process -FilePath "MsiExec.exe" -ArgumentList "/uninstall $guid" -Wait -Verbose
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
                Write-Information "32 Bit not installed/detected"
            } else {
                Write-Host " 3/4 Uninstalling 32bit $uninstall32exe at path $uninstall32path"
              Start-Process $uninstall32exe -ArgumentList "/uninstall /passive" -WorkingDirectory $uninstall32Path -verbose -wait
                if ($process.ExitCode -ne 0) {
                    #write error for intune to track
                    Write-error "Error: 32bit Uninstall failed with exit code, might not be installed $($process.ExitCode)"
                    }
            }
    }

    #Failover
        Write-Host "Attempting Method CIM"
        $cim = Get-CimInstance -ClassName Win32_Product -Filter "Name Like 'Crowdstrike%'"
        foreach ($IdentifyingNumber in $cim.IdentifyingNumber) {
            Write-Verbose "4/4 Uninstalling CrowdStrike using CIM..."
            Start-Process "msiexec.exe" -ArgumentList "/x $IdentifyingNumber /quiet" -Wait
            if ($process.ExitCode -ne 0) {
                Write-Error "Error: Uninstall failed with exit code $($process.ExitCode)"
                exit 1 
            }
        }

Stop-Transcript
