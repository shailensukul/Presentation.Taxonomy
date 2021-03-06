$fieldName =  "PottyType"
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
$spSite = new-object Microsoft.SharePoint.SPSite("http://intranet")
$spWeb = $spSite.OpenWeb()
$xmlFilePath = "C:\Temp\Script-SiteColumns.xml"
$sourceID = ""

#Create Export Files
New-Item $xmlFilePath -type file -force
#Export Site Columns to XML file
Add-Content $xmlFilePath "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
Add-Content $xmlFilePath "`n<Fields>"

$spWeb.Fields | ForEach-Object {
	#Write-Host $_.Title
	# if ($_.Title -eq $fieldName) {
	if ($_.Group -eq "Sukul.Demo") {
			$fieldNameStatic = $_.StaticName + "0"
			$sourceID = $_.TextField
			Write-Host $fieldNameStatic

			Write-Host $_.TextField
			Add-Content $xmlFilePath $_.SchemaXml

			# Make a second pass to get the Note field
			if ($sourceID -ne "") {
				$spWeb.Fields | ForEach-Object {
					if ($_.Id -eq $sourceID) {
								Add-Content $xmlFilePath $_.SchemaXml
					}
				}
			}
	}
}
Add-Content $xmlFilePath "</Fields>"
$spWeb.Dispose()