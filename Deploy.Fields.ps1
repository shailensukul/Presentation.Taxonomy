$file = resolve-path("Exported.Site.Columns.xml")
[xml]$inputFile = Get-Content $file
$file = resolve-path("Input.xml")
[xml]$credFile = Get-Content $file

# 1) Source Site
$sUrl = $credFile.SharePointSettings.SiteCollectionUrl;
$sAdmin = $credFile.SharePointSettings.UserID;
$sPwd = $credFile.SharePointSettings.Password
$sSecurePwd = ConvertTo-SecureString $sPwd -AsPlainText -Force

cls
# these aren't required for the script to run, but help to develop
Add-Type -Path "Microsoft.SharePoint.Client.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Runtime.dll"

# connect/authenticate to SharePoint Online and get ClientContext object.. 
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($sUrl)
if ($credFile.SharePointSettings.IsSiteSharePointOnline -eq $true) {
	$sCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($sAdmin, $sSecurePwd)
} else {
	$sCredentials = New-Object System.Net.NetworkCredential($sAdmin, $sSecurePwd)
}
$ctx.Credentials = $sCredentials

if (!$ctx.ServerObjectIsNull.Value) 
{ 
    Write-Host "Connected to the SOURCE SharePoint Online site: " $sCtx.Url "" -ForegroundColor Green
    
	try {
	#$web = $ctx.Web    
	$web = $ctx.Site.RootWeb;
    $fields = $web.Fields;         
    $ctx.Load($web);   
    $ctx.Load($fields);
    $ctx.ExecuteQuery();

	Write-Host Loaded fields -ForegroundColor Green

	$fieldOption = [Microsoft.SharePoint.Client.AddFieldOptions]::DefaultValue

	$nodelist = $inputFile.selectnodes("/Fields/Field") # XPath is case sensitive
	foreach ($childNode in $nodelist) {	

		Write-Host Deploying field [ $childNode.DisplayName ] -ForegroundColor Green

		#Check whether field already exists
		$skip = $false
		foreach ($field in $fields)
		{
				if ($field.InternalName -eq $childNode.Name) {
					Write-Host Field [ $childNode.DisplayName ] already exists. Skippping... -ForegroundColor Green;
					$skip = $true;
					break;
				} 
		}
		if ($skip -eq $false) {		
			$fieldAsXML = $childNode.get_OuterXml();
			$fld = $fields.AddFieldAsXml($fieldAsXML, $true, $fieldOption);
			#Write-Host $childNode.get_OuterXml()
		
			$ctx.Load($fields);
			$ctx.Load($fld);
			$ctx.ExecuteQuery();
			Write-Host Deployed field [ $childNode.DisplayName ] -ForegroundColor Green
		}
	}
	}
	catch {
		Write-Host Error occurred: $error[0].ToString() + $error[0].InvocationInfo.PositionMessage -ForegroundColor Red
	}
}