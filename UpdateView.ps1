Import-Module Microsoft.Online.SharePoint.PowerShell 
# enter details here
$userName = ""
$password = ""
$siteCollectionUrl = ""
$errorpath = "F:\Test\logfile.txt"
$fieldNames = @( "Title","Name","FileDescription","Created","Created By","Modified","Modified By");
#connect to sharepoint site
$securePassword = ConvertTo-SecureString $password –AsPlainText -Force
Add-Type –Path "c:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type –Path "c:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

#create context
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteCollectionUrl)
$ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userName, $securePassword)


Function RecursiveUpdateView($ctx,$web){
try{
$subsites = $web.Webs;
$list = $web.Lists.getByTitle("<List Name>");
$ctx.Load($web)
$ctx.Load($subsites)
$ctx.Load($list)
$ctx.ExecuteQuery()
$view = $list.DefaultView;
$viewfields = $view.ViewFields;
$ctx.Load($view)
$ctx.Load($viewfields)
$ctx.ExecuteQuery()
$viewFields.RemoveAll();
foreach ($fieldName in $fieldNames)
{
    $viewFields.Add($fieldName);
}
$view.ViewQuery = '<OrderBy><FieldRef Name="Modified" Ascending="FALSE"/></OrderBy>';
$view.Update();
$list.Update();
$ctx.ExecuteQuery()
Write-Host "View Updated Successfully at" $web.Url
Write "View Updated Successfully at" $web.Url "`r`n" >>$errorpath
if($subsites.Count -gt 0){
foreach($subsite in $subsites)
{
RecursiveUpdateView $ctx $subsite
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
RecursiveUpdateView $ctx $web