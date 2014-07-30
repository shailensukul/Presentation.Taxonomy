# CreateContentTypes.ps1
# 
# Description: 
#
# This script creates Content Types in the appropriate Site 
# Collections as listed in the CreateContentTypes.csv. This 
# includes creating Document Sets.
# The .CSV needs to be saved to "C:\PowerShell\" directory.
# If this directory does not exist, you will need to create it.
#
# Running this script requires running PowerShell with elevated 
# privileges so right click the SharePoint 2010 Management Shell 
# and select "Run as administrator" then use change directory 
# commands and tabs to run the PS1 from its directory.
 
 
# Reference the CSV holding the Content Type values and begin the loop
$create = Import-Csv -path C:\Code\Presentation.Taxonomy\Presentation.Taxonomy.Demo\PS\Config\ContentTypes.csv
$create | ForEach-Object {
 
# Get the Site where the Content Type will be created
$site = Get-SPSite -Identity $($_.'SiteCollectionURL')
$web = $site.RootWeb
 
# Determine available Content Types Parents and add new Content Types
$Web.AvailableContentTypes | Select Name
$parent = $Web.AvailableContentTypes["$($_.'ParentContentType')"]
$contentType =  New-Object Microsoft.SharePoint.SPContentType -ArgumentList @($parent,$Web.ContentTypes,"$($_.'NewContentType')")
$contentType.Group = "$($_.'Group')"
$contentType.Description = "$($_.'Description')"
$Web.ContentTypes.Add($contentType)
$Web.Update()
 
# Dispose of the Web and Site objects and close the loop
$Web.Dispose()
$site.Dispose()
}