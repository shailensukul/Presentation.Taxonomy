# AddSiteColumnsToContentTypes.ps1
# 
# Description: 
#
# This script adds Site Columns to the appropriate Content 
# Types as listed in the AddSiteColumnsToContentTypes.csv. 
# The .CSV needs to be saved to "C:\PowerShell\" directory. 
# If this directory does not exist, you will need to create it.
#
# Running this script requires running PowerShell with elevated 
# privileges so right click the SharePoint 2010 Management Shell 
# and select "Run as administrator" then use change directory commands 
# and tabs to run the PS1 from its directory.
 
 
# Reference the CSV holding the Content Type values and begin the loop
$create = Import-Csv -path C:\Code\Presentation.Taxonomy\Presentation.Taxonomy.Demo\PS\Config\SiteColumnsContentTypes.csv
$create | ForEach-Object {
 
# Get the Site where the Site Columns will be added to Content Types
$site = Get-SPSite -Identity $($_.'SiteCollectionURL')
$web = $site.RootWeb
 
# Add Site Columns to Content Types
$ct=$web.ContentTypes["$($_.'ContentType')"]; 
$fieldAdd=$web.Fields["$($_.'SiteColumn')"]
$fieldLink=New-Object Microsoft.SharePoint.SPFieldLink($fieldAdd)
$ct.FieldLinks.Add($fieldLink);
$ct.Update()
 
# Dispose of the Web and Site objects and close the loop
$web.Dispose()
$site.Dispose()
}