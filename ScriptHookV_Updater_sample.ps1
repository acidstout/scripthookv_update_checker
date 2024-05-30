# Optional. If TRUE, no output will be printed. Instead errors will be logged into a file.
$script:QuietMode = $true

# Optional. If TRUE, mail configuration below needs to be set up.
$script:UseMail = $false
$script:MailRecipient = "recipient@example.com"
$script:MailUsername = "sender@example.com"
$script:MailPassword = "secret"
$script:MailServer = "mail.example.com"
$script:MailPort = "587"

# Optional. Set the URL of your ntfy.sh instance.
$script:NotifyURL = $false
