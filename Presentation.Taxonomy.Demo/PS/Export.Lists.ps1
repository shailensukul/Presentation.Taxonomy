# 
# Change the following to reflect your environments
[xml]$inputFile = Get-Content Input.xml 


# 1) Source Site
$sUrl = $inputFile.SharePointCredentials.Url;
$sAdmin = $inputFile.SharePointCredentials.UserID;
$sPwd = $inputFile.SharePointCredentials.Password
$contentTypeGroup = $inputFile.SharePointCredentials.ContentTypeGroup

Write-Host $sUrl
# 3) What Site Column Group do you want to synchronize?
$sGroupName = "Sukul.Demo"

## Stop here
$lcid = "1033"

$sSecurePwd = ConvertTo-SecureString $sPwd -AsPlainText -Force

# these aren't required for the script to run, but help to develop
Add-Type -Path "Microsoft.SharePoint.Client.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Taxonomy.dll"

$xmlFilePath = "F:\Code\Presentation.Taxonomy\Presentation.Taxonomy.Demo\PS\Script-Lists.xml"
#Create Export Files
New-Item $xmlFilePath -type file -force
#Export Site Columns to XML file
Add-Content $xmlFilePath "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
# connect/authenticate to SharePoint Online and get ClientContext object.. 
$sCtx = New-Object Microsoft.SharePoint.Client.ClientContext($sUrl)
$sCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($sAdmin, $sSecurePwd)
$sCtx.Credentials = $sCredentials

if (!$sCtx.ServerObjectIsNull.Value) 
{ 
    Write-Host "Connected to the SOURCE SharePoint Online site: " $sCtx.Url "" -ForegroundColor Green
    $sSite = $sCtx.Web
    $sLists = $sSite.Lists
    $sCtx.Load($sLists)
    $sCtx.ExecuteQuery()
	foreach($sList in $sLists)
    {
		if ($sList.Description -like "*$contentTypeGroup*" ) {
			Write-Host "Found list: " $sList.Title -ForegroundColor Green
	Write-Host $sList.SchemaXml
			Add-Content $xmlFilePath $sList.SchemaXml
		}
	}

}