# This script allows Site Content Types belonging to a particular Group to be exported
# Author: Shailen Sukul
# http://shailensukul.com
# INPUT FILE: Input.xml

# Change the following to reflect your environments
[xml]$inputFile = Get-Content Input.xml 

# 1) Source Site
$sUrl = $inputFile.SharePointSettings.Url;
$sAdmin = $inputFile.SharePointSettings.UserID;
$sPwd = $inputFile.SharePointSettings.Password
$contentTypeGroup = $inputFile.SharePointSettings.ContentTypeGroup

$sSecurePwd = ConvertTo-SecureString $sPwd -AsPlainText -Force

# these aren't required for the script to run, but help to develop
Add-Type -Path "Microsoft.SharePoint.Client.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Taxonomy.dll"

$xmlFilePath = "$($inputFile.SharePointSettings.ScriptExportFolder)\Exported.Site.Coontent.Types.xml"
#Create Export Files
New-Item $xmlFilePath -type file -force
#Export Site Columns to XML file
Add-Content $xmlFilePath "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
Add-Content $xmlFilePath "<Elements xmlns=`"http://schemas.microsoft.com/sharepoint/`">"

# connect/authenticate to SharePoint Online and get ClientContext object.. 
$sCtx = New-Object Microsoft.SharePoint.Client.ClientContext($sUrl)
if ($inputFile.SharePointSettings.IsSiteSharePointOnline -eq $true) {
	$sCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($sAdmin, $sSecurePwd)
} else {
	$sCredentials = New-Object System.Net.NetworkCredential($sAdmin, $sSecurePwd)
}
$sCtx.Credentials = $sCredentials

if (!$sCtx.ServerObjectIsNull.Value) 
{ 
    Write-Host "Connected to the SOURCE SharePoint Online site: " $sCtx.Url "" -ForegroundColor Green
    $sSite = $sCtx.Web
    $sCtypes = $sSite.ContentTypes
    $sCtx.Load($sCtypes)
    $sCtx.ExecuteQuery()


    foreach($sCtype in $sCtypes)
    {
        if($sCtype.Group -eq $contentTypeGroup)
        {
			Write-Host "Found Content Type: " $sCtype.Name -ForegroundColor Green
			Add-Content $xmlFilePath "<!--  $($sCtype.Name) -->"
			Add-Content $xmlFilePath "<ContentType ID='$($sCtype.Id)' Name='$($sCtype.Name)' Group='$($sCtype.Group)' Description='$($sCtype.Description)' Overwrite='TRUE' Inherits='FALSE'>"
			Add-Content $xmlFilePath "`t<FieldRefs>"

			$sFields = $sCtype.Fields
			$sCtx.Load($sFields)
			$sCtx.ExecuteQuery()
			ForEach ($field in $sFields)
			{
					$output = "`t`t<FieldRef ID='{$($field.Id)}' Name='$($field.InternalName)' Required='$($field.Required.ToString().ToUpper())' Hidden='$($field.Hidden.ToString().ToUpper())'"
					if ($field.ShowInNewForm -ne $null) {
						$output = $output + " ShowInNewForm='$($field.ShowInNewForm.ToString().ToUpper())'"
					 } 
					 if ($field.ShowInEditForm -ne $null) {
						$output = $output + " ShowInEditForm='$($field.ShowInEditForm.ToString().ToUpper())'"
					 } 
					 $output = $output + " />"
					Add-Content $xmlFilePath  $output
				}

				Add-Content $xmlFilePath "`t</FieldRefs>"
				Add-Content $xmlFilePath "</ContentType>"
        }
    }
}
Add-Content $xmlFilePath "</Elements>"

$sCtx.Dispose()