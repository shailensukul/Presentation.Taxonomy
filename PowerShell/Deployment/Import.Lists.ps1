# This script allows Lists belonging to a particular Group to be exported
# Author: Shailen Sukul
# http://shailensukul.com
# INPUT FILE: Input.xml

Function SafeAddContentTypeToList($ctx, $list, $contentType)
{
    #$list.EnsureProperties("ContentTypes");
	$contentTypes = $list.ContentTypes;
	$ctx.Load($contentTypes);
	$ctx.ExecuteQuery();
	
	$contentTypeExists = $false;
	#Make sure that the content type does not exist first
	foreach ($ct in $contentTypes) {
		$parent = $ct.Parent
		$Context.Load($parent)
		$Context.ExecuteQuery()
		if ($contentType.Id.StringValue -eq $parent.Id.StringValue) {
			$contentTypeExists = $true;
			break;
		}
	}
	if ($contentTypeExists -eq $false) {
	    $newContentType = $contentTypes.AddExistingContentType($contentType);
	    $list.Update();
	    $ctx.ExecuteQuery();
	} else {
		Write-Host Content type $contentType.Name already exists in list $list.Title
	}
}

Function SafeRemoveListContentType($context, $list, $contentTypeId)
{
	#Load the list's content types
	$contentTypes = $list.ContentTypes;
	$context.Load($contentTypes);
	$context.ExecuteQuery();
	#Make sure that the content type does not exist first
	foreach ($ct in $contentTypes) {
		#Get the parent content type
		$parent = $ct.Parent
		$context.Load($parent)
		$context.ExecuteQuery()
		
		if ($parent.Id.StringValue -eq $contentTypeId) {
			$ct.DeleteObject();
			$list.Update();
    		$context.ExecuteQuery();
			break;
		}
	}
}
		
Function Get-ContentType ($Context, $contentTypeId)
 {
	$rootWeb = $Context.Site.RootWeb;
	$Context.Load($rootWeb);
	$Ctypes = $rootWeb.ContentTypes;
	$Context.Load($Ctypes);
	$Context.ExecuteQuery();
	
	$retContentType = $null;
	foreach($Ctype in $Ctypes)
	{
		if ($Ctype.Id.StringValue -eq $contentTypeId.ToString()) {
			$retContentType = $Ctype;
			break;
		}
	}
 	return $retContentType;
 }

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

$nodelist = $inputFile.SelectNodes("//Lists/List") # XPath is case sensitive
foreach ($childNode in $nodelist) {	
	#Create list 
	$ListInfo = New-Object Microsoft.SharePoint.Client.ListCreationInformation
	$ListInfo.Title = $childNode.Title
	$ListInfo.TemplateType = $childNode.BaseTemplate
	$ListInfo.Url = $childNode.Url
		
	$List = $Context.Web.Lists.Add($ListInfo)
	$List.Description = $childNode.Description
	$List.ContentTypesEnabled = $true;
	$List.Update()
	$List.ContentTypesEnabled = $true;
	$Context.ExecuteQuery()
	#TODO: Add a check to see whether list already exists

	Foreach ($contentTypeNode in $childNode.ContentTypeRefs.ContentTypeRef)
	{
		$contentType = (Get-ContentType ($Context) ($contentTypeNode.Id))
		SafeAddContentTypeToList ($Context) ($List) ($contentType) 		
	} 
	SafeRemoveListContentType ($Context) ($List) ("0x01")
}
	
$Context.Dispose()


