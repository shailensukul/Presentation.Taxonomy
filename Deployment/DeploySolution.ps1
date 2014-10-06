#
# Before running this, install the PowerShell module for SharePoint Online here 
# http://www.microsoft.com/en-us/download/details.aspx?id=35588
#

$secureSiteCollectionUrl = "https://sharepointclouddesign.sharepoint.com"
$site = "https://sharepointclouddesign.sharepoint.com"
$login = "shailensukul@SharePointCloudDesign.com"
$password = ""
$securePassword = convertto-securestring $password -asplaintext -force
 
#powershell -sta
cls
$executingScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

$consoleApp = Resolve-PAth "Presentation.Taxonomy.Console.exe"

Write-Host "Creating the taxonomy"
& $consoleApp METADATA $site $login $password

#Loads the client object model and the SharePointOnline.Helper library
[Reflection.Assembly]::LoadFile("$executingScriptDirectory\Microsoft.SharePoint.Client.dll")
[Reflection.Assembly]::LoadFile("$executingScriptDirectory\Microsoft.SharePoint.Client.Runtime.dll")
[Reflection.Assembly]::LoadFile("$executingScriptDirectory\SharePointOnline.Helper.dll")

#Tests the authentication for client object model
$ctx = [SharePointOnline.Helper.Authenticator]::GetClientContext($secureSiteCollectionUrl, $login, $password);
$web = $ctx.Web
$ctx.Load($web)
$ctx.ExecuteQuery()
Write-Host Title of the web : $web.Title

Write-Host Authenticate for web usage
$cookies = [SharePointOnline.Helper.Authenticator]::GetAuthenticatedCookies($secureSiteCollectionUrl, $login, $password);

Write-Host "Deactivating existing solution"
try {
[SharePointOnline.Helper.SandboxSolutions]::DeactivateSolution($secureSiteCollectionUrl, $cookies, "Presentation.Taxonomy.Demo.wsp");
}
catch {}

Read-Host

Write-Host "Uploading solution"
[SharePointOnline.Helper.SandboxSolutions]::UploadSolution($secureSiteCollectionUrl, $cookies, "$executingScriptDirectory\Presentation.Taxonomy.Demo.wsp");
# Write-Host "Activating solution"
 [SharePointOnline.Helper.SandboxSolutions]::ActivateSolution($secureSiteCollectionUrl, $cookies, "Presentation.Taxonomy.Demo.wsp");

# Deactivating features
Write-Host "Decativating features"
 .\manage-feature.ps1 -siteurl $secureSiteCollectionUrl -username $login -password $securePassword -featureID "5c49d98e-1a96-4085-ac83-202f874a0d8a" -enable $false
 .\manage-feature.ps1 -siteurl $secureSiteCollectionUrl -username $login -password $securePassword -featureID "8b9440dc-038e-42f2-92f7-3f68032083b4" -enable $false
 .\manage-feature.ps1 -siteurl $secureSiteCollectionUrl -username $login -password $securePassword -featureID "10155f60-5fa8-4611-b458-db94dad62ab6" -enable $false
 .\manage-feature.ps1 -siteurl $secureSiteCollectionUrl -username $login -password $securePassword -featureID "ab61a66a-8854-4bd0-9881-74d6f0050f4f" -enable $false
 .\manage-feature.ps1 -siteurl $secureSiteCollectionUrl -username $login -password $securePassword -featureID "48e3956f-9e64-4e4a-84bb-5ee6f0b1dcff" -enable $false
 .\manage-feature.ps1 -siteurl $secureSiteCollectionUrl -username $login -password $securePassword -featureID "23469372-44e1-466e-be57-0ce439d08504" -enable $false

Write-Host "Activating features in order with Lookup Lists"
 .\manage-feature.ps1 -siteurl $secureSiteCollectionUrl -username $login -password $securePassword -featureID "5c49d98e-1a96-4085-ac83-202f874a0d8a" -enable $true
 .\manage-feature.ps1 -siteurl $secureSiteCollectionUrl -username $login -password $securePassword -featureID "ab61a66a-8854-4bd0-9881-74d6f0050f4f" -enable $true
 & $consoleApp LISTS $site $login $password 1

 .\manage-feature.ps1 -siteurl $secureSiteCollectionUrl -username $login -password $securePassword -featureID "8b9440dc-038e-42f2-92f7-3f68032083b4" -enable $true
 .\manage-feature.ps1 -siteurl $secureSiteCollectionUrl -username $login -password $securePassword -featureID "48e3956f-9e64-4e4a-84bb-5ee6f0b1dcff" -enable $true
 & $consoleApp LISTS $site $login $password 2

 .\manage-feature.ps1 -siteurl $secureSiteCollectionUrl -username $login -password $securePassword -featureID "10155f60-5fa8-4611-b458-db94dad62ab6" -enable $true
 .\manage-feature.ps1 -siteurl $secureSiteCollectionUrl -username $login -password $securePassword -featureID "23469372-44e1-466e-be57-0ce439d08504" -enable $true
 & $consoleApp LISTS $site $login $password 3
