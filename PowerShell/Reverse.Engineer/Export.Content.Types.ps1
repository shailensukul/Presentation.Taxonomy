# This script allows Site Content Types belonging to a particular Group to be exported
# Author: Shailen Sukul
# http://shailensukul.com
# INPUT FILE: Input.xml
# Reference: http://msdn.microsoft.com/en-us/library/office/aa543822(v=office.14).aspx (Content Type inheritance explained)
# TODO: Figure out how to set Inherited = TRUE for inherited content types

# Change the following to reflect your environments
[xml]$inputFile = Get-Content Input.xml 

# 1) Source Site
$sUrl = $inputFile.SharePointSettings.Url;
$sAdmin = $inputFile.SharePointSettings.Credentials.UserID;
$sPwd = $inputFile.SharePointSettings.Credentials.Password
$contentTypeGroup = $inputFile.SharePointSettings.Group

$sSecurePwd = ConvertTo-SecureString $sPwd -AsPlainText -Force
$fileStr = ""
# these aren't required for the script to run, but help to develop
Add-Type -Path "Microsoft.SharePoint.Client.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Taxonomy.dll"

$xmlFilePath = "Exported.Site.Content.Types.xml"
#Create Export Files
New-Item $xmlFilePath -type file -force
#Export Site Columns to XML file
$fileStr = $fileStr + "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
$fileStr = $fileStr + "`n<Elements xmlns=`"http://schemas.microsoft.com/sharepoint/`">"

#Add-Content $xmlFilePath "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
#Add-Content $xmlFilePath "<Elements xmlns=`"http://schemas.microsoft.com/sharepoint/`">"

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
			#Add-Content $xmlFilePath "<!--  $($sCtype.Name) -->"
			#Add-Content $xmlFilePath "<ContentType ID='$($sCtype.Id)' Name='$($sCtype.Name)' Group='$($sCtype.Group)' Description='$($sCtype.Description)' Overwrite='TRUE' Inherits='FALSE'>"
			#Add-Content $xmlFilePath "`t<FieldRefs>"

			$fileStr = $fileStr +  "`n<!--  $($sCtype.Name) -->"
			#$fileStr = $fileStr + "`n" + $sCtype.SchemaXml
			$fileStr = $fileStr +  "`n<ContentType ID='$($sCtype.Id)' Name='$($sCtype.Name)' Group='$($sCtype.Group)' Description='$($sCtype.Description)' Overwrite='TRUE' Inherits='FALSE'>"
			$fileStr = $fileStr +  "`n`t<FieldRefs>"

			$sFields = $sCtype.Fields
			$sCtx.Load($sFields)
			$sCtx.ExecuteQuery()
			ForEach ($field in $sFields)
			{
					$output = "`n`t`t<FieldRef ID='{$($field.Id)}' Name='$($field.InternalName)' Required='$($field.Required.ToString().ToUpper())' Hidden='$($field.Hidden.ToString().ToUpper())'"
					if ($field.ShowInNewForm -ne $null) {
						$output = $output + " ShowInNewForm='$($field.ShowInNewForm.ToString().ToUpper())'"
					 } 
					 if ($field.ShowInEditForm -ne $null) {
						$output = $output + " ShowInEditForm='$($field.ShowInEditForm.ToString().ToUpper())'"
					 } 
					 $output = $output + " />"
					#Add-Content $xmlFilePath  $output
					$fileStr = $fileStr + $output
				}

				$fileStr = $fileStr + "`n`t</FieldRefs>"
				$fileStr = $fileStr + "`n</ContentType>"

				#Add-Content $xmlFilePath "`t</FieldRefs>"
				#Add-Content $xmlFilePath "</ContentType>"
        }
    }
}
#Add-Content $xmlFilePath "</Elements>"
$fileStr = $fileStr + "`n</Elements>"
Add-Content $xmlFilePath $fileStr
$sCtx.Dispose()