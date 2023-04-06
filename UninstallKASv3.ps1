
#elevate me
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{  
 $arguments = "& '" +$myinvocation.mycommand.definition + "'"
  Start-Process powershell -Verb runAs -ArgumentList $arguments
  Break
}

#start logging
start-transcript -Path c:\temp\uninstallLog.txt -Append -force

################################################################
#Hacked together by Corey Hudson
#V4 - Rewritten for uninstalling all versions found in array 
# Removed reboot force
# Added addtl check for registry entries
# Added second password and foreach loop x2
# Added check for defender activity and remediation
################################################################


#display all installed applications and their Uninstallstring:
Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, UninstallString | Format-Table -AutoSize

#define uninstall strings
$uninstall32 = gci "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_ -contains "Crowdstrike%" } | select UninstallString
$uninstall64 = gci "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_ -contains "Crowdstrike%" } | select UninstallString
$Scan = {Defender\Start-MpScan}
#Try 2 pwds then none
$pw =  @('KLLOGIN=KLAdmin KLPASSWD=7YWyjEO^s4ZFa3Y&','KLLOGIN=KLAdmin KLPASSWD=EUi#b*6&RZ&U','KLLOGIN=KLAdmin KLPASSWD=','KLLOGIN=KLAdmin KLPASSWD=EUi#b*6',"")
$kasregloc = "HKLM:\SOFTWARE\WOW6432Node\KasperskyLab"
$KasReg = gci $kasregloc -ErrorAction SilentlyContinue
$defenderReg = Get-ItemPropertyValue -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\policy manager" -name "AllowRealtimeMonitoring"

if ($uninstall64) {
#The following line removes unnecessary components of the Uninstallstring string. We are just basically extracting the "Uninstallstring" string.
$uninstall64 = $uninstall64.UninstallString -Replace "msiexec.exe","" -Replace "/I","" -Replace "/X","" 
$uninstall64 = $uninstall64.Trim()
Write-host "Found one! Uninstalling 64bit..."
start-process "msiexec.exe" -arg "/X $uninstall64 /qn $pw" -Wait
exit 
}

if ($uninstall32) {
$uninstall32 = $uninstall32.UninstallString -Replace "msiexec.exe","" -Replace "/I","" -Replace "/X",""
$uninstall32 = $uninstall32.Trim()
Write-host "Found one! Uninstalling 32bit..."
start-process "msiexec.exe" -arg "/X $uninstall32 /qn $pw" -Wait
}

else {
#write-host "Hmm...Didnt find Kaspersky in the registry, trying another method"
$cim = Get-CimInstance -ClassName Win32_Product -Filter "Name Like 'Kaspersky%'" 
$cim | Select-Object Name | FL Name | Out-Host
#pull the Guid from the CIM
$Guid = $cim.IdentifyingNumber
#get the pacakge info
$name = $cim.name
#If more than one instance found, store in an array and action on each portion
    foreach ($prod in $guid)
    {
    ForEach ($pwd in $pw)
        { 
        Write-host "Uninstalling $name with password $pwd"
        cmd /c "msiexec.exe /x $prod /qn $pwd" 
        }

    }

}

#Final check"

$cim2 = Get-CimInstance -ClassName Win32_Product -Filter "Name Like 'Kaspersky%'" 
$cim2 | Select-Object Name | FL Name | Out-Host

#Checking for kaspersky registry entries, sending to log 
$kasreg | fl * >> c:\temp\Reglog.txt -erroraction silentlycontinue
#clean up the mess

write-host "Checking if Defender is online and working"
$defenderEnabled = Get-ItemPropertyValue -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\policy manager" -name "AllowRealtimeMonitoring"

if ($defenderenabled -eq 0) {
	write-warning -message "Defender not functioning properly, removing kaspersky remnants to attempt to remediate"
	Remove-Item -Path $kasregloc -Recurse -Errorvariable $nostart
	Write-Information "Attmpting to start defender post key removal"
	start-process -FilePath "C:\Program Files\Windows Defender\MpCmdRun.exe" -ArgumentList "-wdenable" -errorVariable $nostart -Wait -RedirectStandardOutput C:\temp\MPEnable.log
Get-Content  C:\temp\MPEnable.log | out-host
	start-process -FilePath "C:\Program Files\Windows Defender\MpCmdRun.exe" -ArgumentList "-SignatureUpdate" -errorVariable $nostart -Wait
	
	if ($nostart -eq 1) {
		write-warning "Defender failed to start, kaspersky failed removal"
		pause
	}
}

if ($defenderenabled -eq 1) {
Write-Information "Defender is online and functional"
}
pause 5
else { Write-warning "Error in script"
}

Write-host "Checking drivers and appending to log"
Get-Childitem –Path C:\windows\system32\drivers -Include *KL* -Recurse -ErrorAction SilentlyContinue | Select-Object Versioninfo | FL * >>.\Driverlog.txt -ErrorAction SilentlyContinue
Stop-Transcript
pause