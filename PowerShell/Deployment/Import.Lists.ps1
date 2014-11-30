# This script allows Lists belonging to a particular Group to be exported
# Author: Shailen Sukul
# http://shailensukul.com
# INPUT FILE: Input.xml

$file = resolve-path("Exported.Lists.xml")
[xml]$inputFile = Get-Content $file
$file = resolve-path("Input.xml")
[xml]$credFile = Get-Content $file

# 1) Source Site
$sUrl = $credFile.SharePointSettings.Url;
$sAdmin = $credFile.SharePointSettings.Credentials.UserID;
$sPwd = $credFile.SharePointSettings.Credentials.Password

## Set locale here
$lcid = "1033"

$sSecurePwd = ConvertTo-SecureString $sPwd -AsPlainText -Force

# these aren't required for the script to run, but help to develop
Add-Type -Path "Microsoft.SharePoint.Client.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Taxonomy.dll"


#Add-Content $xmlFilePath "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
#Add-Content $xmlFilePath "`n<Fields>"

# connect/authenticate to SharePoint Online and get ClientContext object.. 
$Context = New-Object Microsoft.SharePoint.Client.ClientContext($sUrl)
if ($credFile.SharePointSettings.IsSiteSharePointOnline -eq $true) {
	$sCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($sAdmin, $sSecurePwd)
} else {
	$sCredentials = New-Object System.Net.NetworkCredential($sAdmin, $sSecurePwd)
}
$Context.Credentials = $sCredentials


$nodelist = $inputFile.SelectNodes("//Lists/List", $ns) # XPath is case sensitive
foreach ($childNode in $nodelist) {	
	Write-Host	$childNode.Title $childNode.ID
	#Create list with "custom" list template
	$ListInfo = New-Object Microsoft.SharePoint.Client.ListCreationInformation
	$ListInfo.Title = $childNode.Title
	$ListInfo.TemplateType = $childNode.BaseTemplate
	$ListInfo.Url = $childNode.url
	$List = $Context.Web.Lists.Add($ListInfo)
	$List.Description = $childNode.Description
	$List.Update()
	$Context.ExecuteQuery()
}
$Context.Dispose()


