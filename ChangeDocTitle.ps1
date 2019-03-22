Import-Module Microsoft.Online.SharePoint.PowerShell 
# enter details here
$userName = ""
$password = ""
$siteCollectionUrl = ""
$errorpath = "F:\Test\logfile.txt"
#connect to sharepoint site
$securePassword = ConvertTo-SecureString $password –AsPlainText -Force
Add-Type –Path "c:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type –Path "c:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

#create context
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteCollectionUrl)
$ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userName, $securePassword)


Function RecursiveChangeDocTitle($ctx,$web){
try{
$subsites = $web.Webs;
$list = $web.Lists.getByTitle("<Title 1>");
$ctx.Load($web)
$ctx.Load($subsites)
$ctx.Load($list)
$ctx.ExecuteQuery()
$list.Title = "<Title 2>";
$list.Update()
$ctx.ExecuteQuery()
Write-Host "List Renamed Successfully at" $web.Url
Write "List Renamed Successfully at" $web.Url "`r`n" >>$errorpath
if($subsites.Count -gt 0){
foreach($subsite in $subsites)
{
RecursiveChangeDocTitle $ctx $subsite
}
}
}
catch{
$ErrorMessage = $_.Exception.Message;
Write-Host "Error:" $ErrorMessage
Write "Error: $ErrorMessage `r`n" >>$errorpath
}
}

$web = $ctx.Web
RecursiveChangeDocTitle $ctx $web