Import-Module Microsoft.Online.SharePoint.PowerShell 
# enter details here
$userName = ""
$password = ""
$siteCollectionUrl = ""

#Put the Account Name of the O365 groups. To get the Account name, click on the group name present in Site Permissions
$O365Groups = "<add account name here>","<add account name here>" #this is an array, value e.g. c:0t.c|tenant|de61a10c-908b-4601-b1fc-de71865f9c2a

#error logging location file. Please make sure file exists in mentioned location
$filelocation = "F:\Test\logfile.txt"
#connect to sharepoint site
$securePassword = ConvertTo-SecureString $password –AsPlainText -Force
Add-Type –Path "c:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type –Path "c:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

#create context
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteCollectionUrl)
$ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userName, $securePassword)


Function RecursiveChangePermission($ctx,$web){
    try{
             $ctx.Load($web)
             $ctx.ExecuteQuery()
             foreach($O365Group in $O365Groups){
         try{

             $usr =$web.SiteUsers.GetByLoginName($O365Group)
             $ctx.Load($usr)
             $ctx.ExecuteQuery()
             $permissions = $web.GetUserEffectivePermissions($usr.LoginName)
             $ctx.ExecuteQuery();
             $roleassign = $web.RoleAssignments.GetByPrincipal($usr)
             foreach($RoleAssignment in $roleassign)
                {
            $RoleDefinitionBindings = $RoleAssignment.RoleDefinitionBindings
            $RoleAssignmentMember = $RoleAssignment.Member

            $ctx.Load($RoleDefinitionBindings)
            $ctx.Load($RoleAssignmentMember)
            $ctx.ExecuteQuery()


            foreach ($RoleDefinition in  $RoleDefinitionBindings)
             { 
                if($RoleDefinition.Name -eq "Contribute"){
                $readAccess = $web.RoleDefinitions.GetByName("Read")
                $readRole = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($ctx)  
                $readRole.Add($readAccess)
                $readPermission = $web.RoleAssignments.Add($usr, $readRole)  
                $ctx.Load($readPermission)          
                $ctx.ExecuteQuery();
                $ra = $web.RoleAssignments.GetByPrincipal($usr)
                $cont = $web.RoleDefinitions.GetByName("Contribute")
                $ra.RoleDefinitionBindings.Remove($cont)
                $ra.Update()          
                $ctx.ExecuteQuery();
                #Write-Host $RoleAssignmentMember.LoginName
                #Write-Host ([Microsoft.SharePoint.Client.Principal]$RoleAssignmentMember).PrincipalType
                #Write-Host $RoleDefinition.Name
                Write-Host "Permission Updated for:" $usr.LoginName "on Site:"$web.Url
                Write "Permission Updated for:" $usr.LoginName "on Site:"$web.Url "`r`n" >>$filelocation
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
         $listcoll = $web.Lists;
         $ctx.Load($listcoll)
         $ctx.ExecuteQuery()
         if($listcoll.Count -gt 0){
             foreach($list in $listcoll){
                 if($list.Title -eq "Pages" -or $list.Title -eq "Site Pages"  ){
                    $listitemcoll = $list.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery())
                    $ctx.load($listitemcoll)      
                    $ctx.executeQuery()
                    foreach($listitem in $listitemcoll){
                    $roleassignlist = $listitem.RoleAssignments.GetByPrincipal($usr)
                    foreach($RoleAssignment in $roleassignlist)
                            {
                        $RoleDefinitionBindings = $RoleAssignment.RoleDefinitionBindings
                        $RoleAssignmentMember = $RoleAssignment.Member

                        $ctx.Load($RoleDefinitionBindings)
                        $ctx.Load($RoleAssignmentMember)
                        $ctx.ExecuteQuery()


                        foreach ($RoleDefinition in  $RoleDefinitionBindings)
                         { 
                            if($RoleDefinition.Name -eq "Contribute"){
                            $readAccess = $web.RoleDefinitions.GetByName("Read")
                            $readRole = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($ctx)  
                            $readRole.Add($readAccess)
                            $readPermission = $listitem.RoleAssignments.Add($usr, $readRole)  
                            $ctx.Load($readPermission)          
                            $ctx.ExecuteQuery();
                            $ra = $listitem.RoleAssignments.GetByPrincipal($usr)
                            $cont = $web.RoleDefinitions.GetByName("Contribute")
                            $ra.RoleDefinitionBindings.Remove($cont)
                            $ra.Update()          
                            $ctx.ExecuteQuery();
                            #Write-Host $RoleAssignmentMember.LoginName
                            #Write-Host ([Microsoft.SharePoint.Client.Principal]$RoleAssignmentMember).PrincipalType
                            #Write-Host $RoleDefinition.Name
                            Write-Host "Permission Updated for:" $usr.LoginName "at Site:"$web.Url "on List:"$list.Title "at Page:"$listitem["FileLeafRef"].ToString()
                            Write "Permission Updated for:" $usr.LoginName "on List:"$list.Title "at Page:"$listitem["FileLeafRef"].ToString() "`r`n" >>$filelocation
                         }
                          
                        }
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
         }
         $subsites = $web.Webs
         $ctx.Load($subsites)
         $ctx.ExecuteQuery()
         if($subsites.Count -gt 0){
            foreach($subsite in $subsites)
            {
                RecursiveChangePermission $ctx $subsite
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
RecursiveChangePermission $ctx $web