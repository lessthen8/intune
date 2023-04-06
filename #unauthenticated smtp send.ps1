#unauthenticated smtp send

$from = "prtg@empirix.com"
$to = "corey.hudson@infovista.com"
$subject = "Test Email- Should be blocked"
$body = "This is a test email sent from PowerShell"
$smtpServer = "empirix-com.mail.protection.outlook.com"
$smtpPort = "25"

$message = New-Object System.Net.Mail.MailMessage($from, $to, $subject, $body)
$client = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
$client.Send($message)
