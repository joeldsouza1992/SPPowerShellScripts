Import-Module Microsoft.Online.SharePoint.PowerShell 
# enter details here
$userName = ""
$password = ""
$siteCollectionUrl = ""

#connect to sharepoint site
$securePassword = ConvertTo-SecureString $password –AsPlainText -Force
Add-Type –Path "c:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type –Path "c:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

#create context
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteCollectionUrl)
$ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userName, $securePassword)


Function RecursivePublishPage($ctx,$web){
try{
$subsites = $web.Webs;
$listcoll = $web.Lists;
$ctx.Load($subsites)
$ctx.Load($listcoll)
$ctx.ExecuteQuery()
if($listcoll.Count -gt 0){
foreach($list in $listcoll){
if($list.BaseType -eq "DocumentLibrary"){
$listitemcoll = $list.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery())
$ctx.load($listitemcoll)      
$ctx.executeQuery()
foreach($listitem in $listitemcoll){
 $ctx.Load($listItem)
 $ctx.ExecuteQuery()
 $fileurl = $listitem["FileRef"].toString();
 $title = $listItem["FileLeafRef"].toString();
 $file = $listItem.File  
$ctx.Load($file)  
$ctx.ExecuteQuery()  

#this is checked out
 if($file.CheckOutType -eq [Microsoft.SharePoint.Client.CheckOutType]:: Online){
 $listItem.File.CheckIn("", [Microsoft.SharePoint.Client.CheckinType]::MajorCheckIn)

 #if major minor versioning enabled
 if($file.Level -eq [Microsoft.SharePoint.Client.FileLevel]::Draft){
  $listItem.File.Publish("")
 }
 $ctx.Load($listItem)
 $ctx.ExecuteQuery()
 Write "CHECKEDIN_AND_PUBLISHED URL: $fileurl -- File : $title `r`n" >>F:\Test\logfile.txt
 Write-Host "CHECKEDIN_AND_PUBLISHED" $title
}

#this is checked in but not published
 if($file.Level -eq [Microsoft.SharePoint.Client.FileLevel]::Draft -and $file.CheckOutType -eq [Microsoft.SharePoint.Client.CheckOutType]:: None){
 $listItem.File.Publish("")
 $ctx.Load($listItem)
 $ctx.ExecuteQuery()
 Write "PUBLISHED URL: $fileurl -- File : $title `r`n" >>F:\Test\logfile.txt
 Write-Host "PUBLISHED" $title 
}
}
}
}
}
if($subsites.Count -gt 0){
foreach($subsite in $subsites)
{
RecursivePublishPage $ctx $subsite
}
}
}
catch{
$ErrorMessage = $_.Exception.Message;
Write "Error: $ErrorMessage `r`n" >>F:\Test\logfile.txt
}
}

$web = $ctx.Web
RecursivePublishPage $ctx $web