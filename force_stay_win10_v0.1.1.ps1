# Information and Variables
$script_name = "Script: IV_MIS_Force_to_stay_win10"
$script_creator = "Powershell script created by Danesh Lanza"
$script_version = "Version 0.1.1 - Last edit at: 2022-04-14 13:30 CET"
$logs_file = "$env:windir\..\ProgramData\IV_MIS\logs.txt"

# Log the start of the script
Add-Content -Path "$logs_file" -Value @"

===========================================================================================

$script_name
$script_creator
$script_version

$(Get-Date): Started running $script_name (ran via intune).
"@


# Add the following in the windows registry
# Windows build/revision version is set via Intune -> Configuration profiles -> [HUDSON] Windows 10 - Block Windows 11 Migration
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /f /v "ProductVersion" /t REG_SZ /d "Windows 10"
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /f /v "TargetReleaseVersion" /t REG_DWORD /d "1"

# Add logs
Add-Content -Path "$logs_file" -Value "$(Get-Date): Registry to force to stay in Windows 10 was configured."

# Clean error variable just to show in Intune that sucefully ran the task and show a green graph :)
$error.Clear()

exit