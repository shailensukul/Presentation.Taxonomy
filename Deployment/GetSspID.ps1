$executingScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
[xml]$inputFile = Get-Content $executingScriptDirectory\Input.xml 

# these aren't required for the script to run, but help to develop
Add-Type -Path "Microsoft.SharePoint.Client.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Taxonomy.dll"

$Url = $inputFile.SharePointSettings.SiteCollectionUrl;
$User = $inputFile.SharePointSettings.UserID;
$Pwd = $inputFile.SharePointSettings.Password
$SecurePwd = ConvertTo-SecureString $Pwd -AsPlainText -Force

# connect/authenticate to SharePoint Online and get ClientContext object.. 
[Microsoft.SharePoint.Client.ClientContext] $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($Url)
$Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($User, $SecurePwd)
$Ctx.Credentials = $Credentials

if (!$Ctx.ServerObjectIsNull.Value) 
{
	$sTaxonomySession = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($Ctx)
    $sTaxonomySession.UpdateCache()
    $Ctx.Load($sTaxonomySession)
    $Ctx.ExecuteQuery()


	if (!$sTaxonomySession.ServerObjectIsNull)
    {
		$TermStore = $sTaxonomySession.GetDefaultSiteCollectionTermStore()
        $Ctx.Load($TermStore)
        $Ctx.ExecuteQuery()

		if ($TermStore.IsOnline) 
        {
			# Term store id is the SSPID
			Write-Host "SSPID for $($Url) is: $($TermStore.Id)" -ForegroundColor Green
		}
	}
}

