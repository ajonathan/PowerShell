<# 
	.DESCRIPTION 
		The script is used to send an email from within an Azure Site Recovery plan.
		The script is tested with the service SendGrid. To use SendGrid, create an 
		account in Azure and save the username and password.
		
		Import the script and create an an Azure Automation Credential with the 
		name SendEmailCred and add the username and password to be used when sending
		emails.

		Edit the variables:
		$EmailFrom
		$EmailTo
		
		For more information see systemcenterme.com
			
		Version 2018.03.18.0
 
	.NOTES 
		AUTHOR: Jonathan Andersson
#> 

param (
		[Object]$RecoveryPlanContext 
)

# Get information from the ASR plan
$RecoveryPlanName = $RecoveryPlanContext.RecoveryPlanName
$FailoverType = $RecoveryPlanContext.FailoverType
$GroupId = $RecoveryPlanContext.GroupId

# Get credential from the Azure Automation account
$cred = Get-AutomationPSCredential -Name 'SendEmailCred'

# Prepare the email
# Edit this section to fit your needs
$Username = $cred.Username
$Password = $cred.Password
$credential = New-Object System.Management.Automation.PSCredential $Username, $Password
$SMTPServer = "smtp.sendgrid.net"
$EmailFrom = "EmailFrom@mysite.com"
$EmailTo = "EmailTo@mysite.com"
$Subject = "Azure Site Recovery Failover Plan $RecoveryPlanName"
$Body = @"
ASR failover in progress

Recovery plan name: $RecoveryPlanName

Group Id: $GroupId

Failover type: $FailoverType

"@

# Send email
Send-MailMessage -smtpServer $SMTPServer -Credential $credential -Usessl -Port 587 -from $EmailFrom -to $EmailTo -subject $Subject -Body $Body
