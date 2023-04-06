Write-Host "INTERNAL SCRIPT- Not for distribution - V.0.1.23 Infovista" -ForegroundColor blue
Write-Host {'
  /$$$$$$                                                /$$                       /$$                              
 /$$__  $$                                              | $$                      | $$                              
| $$  \__/  /$$$$$$   /$$$$$$   /$$$$$$  /$$   /$$      | $$$$$$$  /$$   /$$  /$$$$$$$  /$$$$$$$  /$$$$$$  /$$$$$$$ 
| $$       /$$__  $$ /$$__  $$ /$$__  $$| $$  | $$      | $$__  $$| $$  | $$ /$$__  $$ /$$_____/ /$$__  $$| $$__  $$
| $$      | $$  \ $$| $$  \__/| $$$$$$$$| $$  | $$      | $$  \ $$| $$  | $$| $$  | $$|  $$$$$$ | $$  \ $$| $$  \ $$
| $$    $$| $$  | $$| $$      | $$_____/| $$  | $$      | $$  | $$| $$  | $$| $$  | $$ \____  $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$      | $$  | $$|  $$$$$$/|  $$$$$$$ /$$$$$$$/|  $$$$$$/| $$  | $$
 \______/  \______/ |__/       \_______/ \____  $$      |__/  |__/ \______/  \_______/|_______/  \______/ |__/  |__/
                                         /$$  | $$                                                                  
                                        |  $$$$$$/                                                                  
                                         \______/                                                                   
'                      
}-ForegroundColor red

# Add KL, Dubai, Operator Connect
#
#
#
#


#install modules
##Function Uninstall-ModuleWrapper {
    param(
      [string]$moduleName
    )
    try {
      Uninstall-Module -Name $moduleName -ErrorAction Stop
      Write-Verbose "Module $moduleName uninstalled successfully."
    } catch {
    
    }
#  }
Write-Host "Connecting to Tenant" -ForegroundColor Green
Connect-MicrosoftTeams

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Line Details'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Please select a Calling Plan:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,40)
$listBox.Size = New-Object System.Drawing.Size(260,20)
$listBox.Height = 80

[void] $listBox.Items.Add('O_VP_AMER')
[void] $listBox.Items.Add('O_VP_EMEA')
[void] $listBox.Items.Add('O_VP_APAC')

$form.Controls.Add($listBox)

$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $x = $listBox.SelectedItem
    $x
}
#capture name and number
$Name = Read-Host -Prompt "Enter email address of target user" 
$Num = Read-Host -Prompt "Enter Phone number with country code | Refer to 'https://ivta.sharepoint.com/:x:/s/ITServicesTeam/EWYZR4YKGilApP8IlCOE7x8BC_G4_V-JH498MkayzWohoQ'"
Write-Verbose "Configuring $Name with number $num" -ForegroundColor Yellow
Write-Host "Adding Number and permissions"
#add vars
try {
    Set-CsPhoneNumberAssignment -Identity $Name -PhoneNumber $Num -PhoneNumberType DirectRouting
}
catch {
    Uninstall-ModuleWrapper -moduleName "MicrosoftTeams"

}

#Pull var from listbox and action on each
$Name | ForEach-Object {
    Grant-CsOnlineVoiceRoutingPolicy -Identity $_ -PolicyName $x
    Grant-CsTeamsCallingPolicy -Identity $_ -PolicyName AllowCalling
    Grant-CsCallingLineIdentity -Identity $_ -PolicyName $null
    Grant-CsTeamsUpgradePolicy -PolicyName UpgradeToTeams -Identity $_
} | Clear-Host

get-csonlineuser -identity $Name | Select-Object UserPrincipalName, EnterpriseVoiceEnabled, OnPremLineURI, HostedVoiceMail, OnlineVoiceRoutingPolicy, TeamsCallingPolicy, TenantDialPlan, TeamsUpgradeEffectiveMode, TeamsUpgradePolicy
Write-Host "User has been added, if all data is filled in above, then operation was successful" -ForegroundColor Green