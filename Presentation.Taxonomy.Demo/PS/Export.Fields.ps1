#######################
#
# Migrate Site Columns by Custom Group Name
#
# "Elise", a series of scripts to migrate O365 SharePoint Online Assets across O365 instances
#
# Copyright 2014, John Wefler, Rightpoint Consulting, LLC.
#
#######################

# Change the following to reflect your environments
[xml]$inputFile = Get-Content Input.xml 


# 1) Source Site
$sUrl = $inputFile.SharePointCredentials.Url;
$sAdmin = $inputFile.SharePointCredentials.UserID;
$sPwd = $inputFile.SharePointCredentials.Password

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

$xmlFilePath = "F:\Code\Presentation.Taxonomy\Presentation.Taxonomy.Demo\PS\Script-SiteColumns.xml"
#Create Export Files
New-Item $xmlFilePath -type file -force
#Export Site Columns to XML file
Add-Content $xmlFilePath "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
Add-Content $xmlFilePath "`n<Fields>"

# connect/authenticate to SharePoint Online and get ClientContext object.. 
$sCtx = New-Object Microsoft.SharePoint.Client.ClientContext($sUrl)
$sCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($sAdmin, $sSecurePwd)
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

			Add-Content $xmlFilePath $sCol.SchemaXml

			# Make a second pass to get the Note field
			if ($sourceID -ne "") {
				$sCols | ForEach-Object {
					if ($_.Id -eq $sourceID) {
								Write-Host "......... Note Column found:" $_.StaticName "" -ForegroundColor Cyan
								Add-Content $xmlFilePath $_.SchemaXml
					}
				}
			}
        }
    }
}
Add-Content $xmlFilePath "</Fields>"
$sCtx.Dispose()