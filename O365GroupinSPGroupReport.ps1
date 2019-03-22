Import-Module Microsoft.Online.SharePoint.PowerShell 
# enter details here
$userName = ""
$password = ""
$siteCollectionUrl = ""

#Put the Account Name of the O365 groups. To get the Account name, click on the group name present in Site Permissions
$O365GroupOld = "c:0t.c|tenant|jh61a10c-908b-4601-b1fg-de71865f9c2r" #Old O365 Group
#error logging location file. Please make sure file exists in mentioned location
$filelocation = "F:\Test\logfile.txt"

#connect to sharepoint site
$securePassword = ConvertTo-SecureString $password –AsPlainText -Force
Add-Type –Path "c:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type –Path "c:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

#create context
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteCollectionUrl)
$ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userName, $securePassword)

$web = $ctx.Web
$ctx.Load($web)
$ctx.ExecuteQuery()
$usrold =$web.EnsureUser($O365GroupOld)
$ctx.Load($usrold)
$ctx.ExecuteQuery()
$spGroups =$web.SiteGroups
$ctx.Load($spGroups)
$ctx.ExecuteQuery()
$Output = foreach($group in $spGroups)
{
$ctx.Load($group)
$ctx.ExecuteQuery()
try{
$users = $group.Users;
$ctx.Load($users)
$ctx.ExecuteQuery()
foreach($user in $users){
if($user.LoginName -eq $O365GroupOld){
New-Object -TypeName PSObject -Property @{
    GroupName = $group.Title
    Replace = "" 
    ReplaceWith = ""
  } | Select-Object GroupName,Replace,ReplaceWith
}
}
}
catch{
$ErrorMessage = $_.Exception.Message;
Write "Error: $ErrorMessage `r`n" $filelocation
Write-Host $ErrorMessage
}
}
$Output | Export-Csv C:\GPoutput.csv