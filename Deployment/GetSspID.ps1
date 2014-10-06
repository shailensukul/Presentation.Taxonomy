 $secureSiteCollectionUrl = "https://sharepointclouddesign.sharepoint.com"
 $login = "shailensukul@SharePointCloudDesign.com"
$password = "f1bon@cci"
$securePassword = convertto-securestring $password -asplaintext -force

$consoleApp = Resolve-Path "Presentation.Taxonomy.Console.exe"

cls
Write-Host "Getting SSPID"
& $consoleApp SSPID $secureSiteCollectionUrl $login $password 