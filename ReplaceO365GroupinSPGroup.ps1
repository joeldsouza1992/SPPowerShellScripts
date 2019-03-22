Import-Module Microsoft.Online.SharePoint.PowerShell 
# enter details here
$userName = ""
$password = ""
$siteCollectionUrl = ""

#Put the Account Name of the O365 groups. To get the Account name, click on the group name present in Site Permissions
$O365GroupOld = "c:0t.c|tenant|de61a10c-908c-4601-b1fc-de71865f9b2a" #Old O365 Group
$O365GroupNew = "c:0t.c|tenant|c0gh8906-c214-4b47-b86f-ac64578a3df5" #new O365 Group
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
foreach($group in $spGroups)
{
$ctx.Load($group)
$ctx.ExecuteQuery()
try{
$group.Users.Remove($usrold);
$group.Update()
$ctx.ExecuteQuery()
$usernew=$web.EnsureUser($O365GroupNew)
$ctx.Load($usernew)
$spUserToAdd= $group.Users.AddUser($usernew);
$ctx.Load($spUserToAdd)
$ctx.ExecuteQuery()
}
catch{
$ErrorMessage = $_.Exception.Message;
if($ErrorMessage -notmatch "Can not find the user")
{
Write "Error: $ErrorMessage `r`n" $filelocation
Write-Host $ErrorMessage
}
}
}