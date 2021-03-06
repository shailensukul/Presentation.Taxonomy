﻿# This script allows Site Columns belonging to a particular Group to be exported
# Author: Shailen Sukul
# http://shailensukul.com
# INPUT FILE: Input.xml

[xml]$inputFile = Get-Content Input.xml 

# 1) Source Site
$sUrl = $inputFile.SharePointSettings.Url;
$sAdmin = $inputFile.SharePointSettings.UserID;
$sPwd = $inputFile.SharePointSettings.Password

Write-Host $sUrl
# Which Site Column Group do you want to synchronize?
$sGroupName = $inputFile.SharePointSettings.SiteColumnGroup

## Set locale here
$lcid = "1033"

$sSecurePwd = ConvertTo-SecureString $sPwd -AsPlainText -Force

# these aren't required for the script to run, but help to develop
Add-Type -Path "Microsoft.SharePoint.Client.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Taxonomy.dll"

$xmlFilePath = "$($inputFile.SharePointSettings.ScriptExportFolder)\Exported.Site.Columns.xml"
#Create Export Files
New-Item $xmlFilePath -type file -force
#Export Site Columns to XML file
Add-Content $xmlFilePath "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
Add-Content $xmlFilePath "`n<Fields>"

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
    $sCols = $sSite.AvailableFields
    $sCtx.Load($sCols)
    $sCtx.ExecuteQuery()

    Write-Host "Found" $sCols.Count "Site Columns" -ForegroundColor Cyan

    foreach($sCol in $sCols)
    {
        if($sCol.Group -eq $sGroupName)
        {
            Write-Host ".........Column found:" $sCol.StaticName "" -ForegroundColor Cyan
            $sourceID = $sCol.TextField
            #convert to XML object for future manipulation of nodes
            [xml]$sColXML = $sCol.SchemaXml
			
			# Make a second pass to get the Note field
			if ($sourceID -ne "") {
				$sCols | ForEach-Object {
					if ($_.Id -eq $sourceID) {
								Write-Host "......... Note Column found:" $_.StaticName "" -ForegroundColor Cyan
								Add-Content $xmlFilePath $_.SchemaXml
					}
				}
			}
			Add-Content $xmlFilePath $sCol.SchemaXml

        }
    }
}
Add-Content $xmlFilePath "</Fields>"
$sCtx.Dispose()