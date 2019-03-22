﻿Import-Module Microsoft.Online.SharePoint.PowerShell
# enter details here
$userName = ""
$password = ""
$siteCollectionUrl = ""

#Put the Account Name of the O365 groups. To get the Account name, click on the group name present in Site Permissions
$O365GroupOld = "c:0t.c|tenant|de61a10c-908d-4601-b1ab-de71865f9d2c" #Old O365 Group
$O365GroupNew = "c:0t.c|tenant|c0fg8906-c214-4b47-a86c-ca64578a3gv5" #new O365 Group
#error logging location file. Please make sure file exists in mentioned location
$filelocation = "F:\Test\logfile.txt"
#connect to sharepoint site
$securePassword = ConvertTo-SecureString $password –AsPlainText -Force
Add-Type –Path "c:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type –Path "c:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

#create context
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteCollectionUrl)
$ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userName, $securePassword)


#Generic method to load the properties
Function Invoke-LoadMethod() {
    param(
    [Microsoft.SharePoint.Client.ClientObject]$Object = $(throw "Please provide a Client Object"),
    [string]$PropertyName
    )
    $ctx = $Object.Context
    $load = [Microsoft.SharePoint.Client.ClientContext].GetMethod("Load")
    $type = $Object.GetType()
    $clientLoad = $load.MakeGenericMethod($type)
    
    
    $Parameter = [System.Linq.Expressions.Expression]::Parameter(($type), $type.Name)
    $Expression = [System.Linq.Expressions.Expression]::Lambda(
    [System.Linq.Expressions.Expression]::Convert(
    [System.Linq.Expressions.Expression]::PropertyOrField($Parameter,$PropertyName),
    [System.Object]
    ),
    $($Parameter)
    )
    $ExpressionArray = [System.Array]::CreateInstance($Expression.GetType(), 1)
    $ExpressionArray.SetValue($Expression, 0)
    $clientLoad.Invoke($ctx,@($Object,$ExpressionArray))
}

Function RecursiveReplaceO365Group($ctx,$web){
    try{
        $ctx.Load($web)
        $ctx.ExecuteQuery()
            $usrold =$web.EnsureUser($O365GroupOld)
            $ctx.Load($usrold)
            $ctx.ExecuteQuery()
            $usernew=$web.EnsureUser($O365GroupNew)
            $ctx.Load($usernew)
            $ctx.ExecuteQuery()
        try{
            $listcoll = $web.Lists;
            $ctx.Load($listcoll)
            $ctx.ExecuteQuery()
            if($listcoll.Count -gt 0){
                foreach($list in $listcoll){
                    $ctx.Load($list)
                    $ctx.ExecuteQuery();
                    
                    if($list.Title -eq "Site Pages" -or $list.Title -eq "Pages"){
                        $listItems = $list.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery())
                        $ctx.Load($listItems)
                        $ctx.ExecuteQuery()
                        foreach($listItem in $listItems)
                        {
                            $ctx.Load($listItem)
                        $ctx.ExecuteQuery()
                            Invoke-LoadMethod -Object $listItem -PropertyName "HasUniqueRoleAssignments"
                            $ctx.ExecuteQuery()
                            if($listItem.HasUniqueRoleAssignments -eq $true){
                                try{
                                    $listItem.RoleAssignments.GetByPrincipal($usrold).DeleteObject()
                                    $ctx.ExecuteQuery()
                                    $roleDefinition = $ctx.Site.RootWeb.RoleDefinitions.GetByType([Microsoft.SharePoint.Client.RoleType]::Contributor)
                                    $roleBindings = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($ctx)
                                    $roleBindings.Add($roleDefinition)
                                    $ctx.Load($listItem.RoleAssignments.Add($usernew, $roleBindings))
                                    $ctx.ExecuteQuery()
                                    Write-Host "Success: 0365 group replaced at Item ID " $listItem["ID"].ToString() " in "$list.Title;
                                    Write "Success: 0365 group replaced at" $listItem["ID"].ToString() " in "$list.Title "`r`n" >>$filelocation
                                }
                                catch{
                                      $ErrorMessage = $_.Exception.Message;
                                      if($ErrorMessage -notmatch "Can not find the principal with id"){
                                      Write-Host $ErrorMessage;
                                      Write "Error: $ErrorMessage `r`n" >>$filelocation
                                      }
                                }
                                
                            }
                        }
                    }
                    
                    Invoke-LoadMethod -Object $list -PropertyName "HasUniqueRoleAssignments"
                    $ctx.ExecuteQuery()
                    if(($list.HasUniqueRoleAssignments -eq $true) -and ($list.Hidden -eq $false)){
                        try{
                            $list.RoleAssignments.GetByPrincipal($usrold).DeleteObject()
                            $ctx.ExecuteQuery()
                            $roleDefinition = $ctx.Site.RootWeb.RoleDefinitions.GetByType([Microsoft.SharePoint.Client.RoleType]::Contributor)
                            $roleBindings = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($ctx)
                            $roleBindings.Add($roleDefinition)
                            $ctx.Load($list.RoleAssignments.Add($usernew, $roleBindings))
                            $ctx.ExecuteQuery()
                            Write-Host "Success: 0365 group replaced at List" $list.Title;
                            Write "Success: 0365 group replaced at" $list.Title "`r`n" >>$filelocation
                        }
                        catch{
                              $ErrorMessage = $_.Exception.Message;
                              if($ErrorMessage -notmatch "Can not find the principal with id"){
                              Write-Host $ErrorMessage;
                              Write "Error: $ErrorMessage `r`n" >>$filelocation
                              }
                        }
                    }
                    
                }
            }
        }
        catch{
               $ErrorMessage = $_.Exception.Message;
               if($ErrorMessage -notmatch "Can not find the principal with id"){
                Write-Host $ErrorMessage;
                Write "Error: $ErrorMessage `r`n" >>$filelocation
                }
            
        }
        
        try{
            $web.RoleAssignments.GetByPrincipal($usrold).DeleteObject()
            $ctx.ExecuteQuery()
            $roleDefinition = $ctx.Site.RootWeb.RoleDefinitions.GetByType([Microsoft.SharePoint.Client.RoleType]::Contributor)
            $roleBindings = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($ctx)
            $roleBindings.Add($roleDefinition)
            $ctx.Load($web.RoleAssignments.Add($usernew, $roleBindings))
            $ctx.ExecuteQuery()
            Write-Host "Success: 0365 group replaced at Web" $web.Url;
            Write "Success: 0365 group replaced at" $web.Url "`r`n" >>$filelocation
        }
        
        catch{
                $ErrorMessage = $_.Exception.Message;
                if($ErrorMessage -notmatch "Can not find the principal with id"){
                Write-Host $ErrorMessage;
                Write "Error: $ErrorMessage `r`n" >>$filelocation
                }
        }
       $subsites = $web.Webs
        $ctx.Load($subsites)
        $ctx.ExecuteQuery()
        if($subsites.Count -gt 0){
            foreach($subsite in $subsites)
            {
                RecursiveReplaceO365Group $ctx $subsite
            }
            
        }
    }
    catch{
        $ErrorMessage = $_.Exception.Message;
        Write-Host $ErrorMessage;
        Write "Error: $ErrorMessage `r`n" >>$filelocation
    }
}

$web = $ctx.Web
RecursiveReplaceO365Group $ctx $web