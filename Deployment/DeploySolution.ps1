$siteCollectionUrl = "https://sukulsharepoint.sharepoint.com/sites/demo"
$login = "shailen@spdev.shailensukul.com"
$password = "Sh@rep0int"
 
#powershell -sta
cls
$executingScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

#Loads the client object model and the SharePointOnline.Helper library
[Reflection.Assembly]::LoadFile("$executingScriptDirectory\Microsoft.SharePoint.Client.dll")
[Reflection.Assembly]::LoadFile("$executingScriptDirectory\Microsoft.SharePoint.Client.Runtime.dll")
[Reflection.Assembly]::LoadFile("$executingScriptDirectory\SharePointOnline.Helper.dll")

#Tests the authentication for client object model
$ctx = [SharePointOnline.Helper.Authenticator]::GetClientContext($siteCollectionUrl, $login, $password);
$web = $ctx.Web
$ctx.Load($web)
$ctx.ExecuteQuery()
Write-Host Title of the web : $web.Title

Write-Host Authenticate for web usage
$cookies = [SharePointOnline.Helper.Authenticator]::GetAuthenticatedCookies($siteCollectionUrl, $login, $password);

Write-Host Test solution deactivation, upload, and activation
[SharePointOnline.Helper.SandboxSolutions]::DeactivateSolution($siteCollectionUrl, $cookies, "Presentation.Taxonomy.Demo.wsp");
[SharePointOnline.Helper.SandboxSolutions]::UploadSolution($siteCollectionUrl, $cookies, "$executingScriptDirectory\Presentation.Taxonomy.Demo.wsp");
[SharePointOnline.Helper.SandboxSolutions]::ActivateSolution($siteCollectionUrl, $cookies, "Presentation.Taxonomy.Demo.wsp");
