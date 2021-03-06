# This script allows Lists belonging to a particular Group to be exported
# Author: Shailen Sukul
# http://shailensukul.com
# INPUT FILE: Input.xml

[xml]$inputFile = Get-Content Input.xml 

$sUrl = $inputFile.SharePointSettings.Url;
$sAdmin = $inputFile.SharePointSettings.Credentials.UserID;
$sPwd = $inputFile.SharePointSettings.Credentials.Password
$sGroupName = $inputFile.SharePointSettings.Group

## Set locale here
$lcid = "1033"

$sSecurePwd = ConvertTo-SecureString $sPwd -AsPlainText -Force 

# these aren't required for the script to run, but help to develop
Add-Type -Path $(Resolve-Path("Microsoft.SharePoint.Client.dll"))
Add-Type -Path $(Resolve-Path("Microsoft.SharePoint.Client.Runtime.dll"))
Add-Type -Path $(Resolve-Path("Microsoft.SharePoint.Client.Taxonomy.dll")) 

$referencedAssemblies = (
    $(Resolve-Path("Microsoft.SharePoint.Client.dll")),
    $(Resolve-Path("Microsoft.SharePoint.Client.Runtime.dll")),
	"System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"
   # $(Resolve-Path("C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.5\System.Core.dll"))
	)
	
$sourceCode = @"
using Microsoft.SharePoint.Client;
using System.Collections.Generic;
using System.Linq;
 
public static class QueryHelper
{
    public static void LoadListWithLimtedFields(ClientContext ctx, List list)
    {
        ctx.Load(list, l => l.Title, l => l.OnQuickLaunch, l => l.RootFolder);
    }
}
"@

Add-Type -ReferencedAssemblies $referencedAssemblies -TypeDefinition $sourceCode -Language CSharp;

$xmlFilePath = "Exported.Lists.xml"
#Create Export Files
$fle = New-Item $xmlFilePath -type file -force
#Export Site Columns to XML file

$fileStr = ""
$fileStr = $fileStr + "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
$fileStr = $fileStr + "`r`n<Lists>"

#Add-Content $xmlFilePath "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
#Add-Content $xmlFilePath "`n<Fields>"

# connect/authenticate to SharePoint Online and get ClientContext object.. 
$Context = New-Object Microsoft.SharePoint.Client.ClientContext($sUrl)
if ($inputFile.SharePointSettings.IsSiteSharePointOnline -eq $true) {
	$sCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($sAdmin, $sSecurePwd)
} else {
	$sCredentials = New-Object System.Net.NetworkCredential($sAdmin, $sSecurePwd)
}
$Context.Credentials = $sCredentials

#Retrieve lists
$Lists = $Context.Web.Lists
$Context.Load($Lists)
$Context.ExecuteQuery()

foreach($list in $lists)
{
	if ($list.Description.Contains("Group:$GroupName")) {
		
		$Context.Load($list);
		[QueryHelper]::LoadListWithLimtedFields($Context, $list)
		$Context.Load($list.ContentTypes);			
		$Context.ExecuteQuery();
		
		$fileStr = $fileStr + "`r`n<!--$($list.Title)-->"
		$fileStr = $fileStr + "`r`n`t<List ID='$($list.Id)' Url='$($($($list.RootFolder)).ServerRelativeUrl.substring(1))' Title='$($list.Title)' BaseTemplate='$($list.BaseTemplate)' BaseType='$($list.BaseType)' ContentTypesEnabled='$($list.ContentTypesEnabled)' Description='$($list.Description)' EnableAttachments='$($list.EnableAttachments)' EnableVersioning='$($list.EnableVersioning)' OnQuickLaunch='$($list.OnQuickLaunch)'>"	 
		 
		$fileStr = $fileStr + "`r`n`t`t<ContentTypeRefs>"
		foreach ($contentType in $list.ContentTypes) {
		
			$parent = $contentType.Parent
			$Context.Load($parent)
			$Context.ExecuteQuery()
			#$trueCTId = $contentType.Id -replace $parent.Id, ""
			$trueCTId = $parent.Id
			$fileStr = $fileStr + "`r`n`t`t`t<ContentTypeRef Id='$($trueCTId)' Name='$($contentType.Name)' />" 
		}
		$fileStr = $fileStr + "`r`n`t`t</ContentTypeRefs>"
		$fileStr = $fileStr + "`r`n`t</List>"
		
	}
}

$fileStr = $fileStr + "`r`n</Lists>"
Add-Content $xmlFilePath $fileStr
$Context.Dispose()

