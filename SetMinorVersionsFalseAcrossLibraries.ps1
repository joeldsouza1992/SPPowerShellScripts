Import-Module Microsoft.Online.SharePoint.PowerShell 
# enter details here
$userName = ""
$password = ""
$siteCollectionUrl = ""
$filelocation ="F:\Test\logfile.txt"
#connect to sharepoint site
$securePassword = ConvertTo-SecureString $password –AsPlainText -Force
Add-Type –Path "c:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type –Path "c:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

#create context
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteCollectionUrl)
$ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userName, $securePassword)


Function RecursiveChangeVersionSetting($ctx,$web){
try{
$subsites = $web.Webs;
$listcoll = $web.Lists;
$ctx.Load($subsites)
$ctx.Load($listcoll)
$ctx.ExecuteQuery()
if($listcoll.Count -gt 0){
foreach($list in $listcoll){
if($list.BaseType -eq "DocumentLibrary"){
if($list.EnableVersioning -eq $true -and $list.EnableMinorVersions -eq $true)
{
try{
$list.EnableMinorVersions = $false
$list.Update()
$ctx.ExecuteQuery()
Write-Host $list.Title "Library Version setting changed" $web.Url
Write $list.Title "Version setting changed" $web.Url "`r`n" >>$filelocation
}
catch{
$ErrorMessage = $_.Exception.Message;
Write-Host $ErrorMessage
Write "Error: $ErrorMessage `r`n" >>$filelocation
}
}
}
}
}
if($subsites.Count -gt 0){
foreach($subsite in $subsites)
{
RecursiveChangeVersionSetting $ctx $subsite
}
}
}
catch{
$ErrorMessage = $_.Exception.Message;
Write-Host $ErrorMessage
Write "Error: $ErrorMessage `r`n" >>$filelocation
}
}

$web = $ctx.Web
RecursiveChangeVersionSetting $ctx $web