# This script goes through the exported XML for Site Columns 
# and fixes up the following:
# * Changes the taxonomy's hidden list name
# * Removes the Version attribute
# * Remotes the WebId attribute
# The only manual part remaining is to search for List="<Some Guid>" and replace with "Lists/List Name" for Lookup fields
#

$file = resolve-path("Exported.Site.Columns.xml")
[xml]$inputFile = Get-Content $file
$xmlFilePath = "Exported.Site.Columns.Fixed.xml"

# TODO: PUT THE VALUE OF THE NEW SSPID HERE
$sspId = 'c8e52792-e7c3-4281-9e35-7c6a6beb79d5'

#Create Export Files
New-Item $xmlFilePath -type file -force
Add-Content $xmlFilePath "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
Add-Content $xmlFilePath "`n<Fields>"

$nodelist = $inputFile.selectnodes("/Fields/Field") # XPath is case sensitive
foreach ($childNode in $nodelist) {	
	$childNode.RemoveAttribute("Version");
	$childNode.RemoveAttribute("WebId");
	if ($childNode.Type -eq "TaxonomyFieldType") {
		$childNode.List = "Lists/TaxonomyHiddenList";
		ForEach ($e in $childNode.selectnodes("//Customization/ArrayOfProperty/Property")) { 
			if ($e.Name -eq "SspId") {
				$e.Value.set_InnerXml($sspId);
				#break;
			}
		}
	}
	Add-Content $xmlFilePath $childNode.get_OuterXml();
}
Add-Content $xmlFilePath "</Fields>"