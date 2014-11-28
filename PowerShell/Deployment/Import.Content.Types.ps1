Import-Module 'C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell'

$file = resolve-path("Exported.Site.Content.Types.xml")
[xml]$inputFile = Get-Content $file
$file = resolve-path("Input.xml")
[xml]$credFile = Get-Content $file

# 1) Source Site
$sUrl = $credFile.SharePointSettings.SiteCollectionUrl;
$sAdmin = $credFile.SharePointSettings.UserID;
$sPwd = $credFile.SharePointSettings.Password
$sSecurePwd = ConvertTo-SecureString $sPwd -AsPlainText -Force

# these aren't required for the script to run, but help to develop
Add-Type -Path "Microsoft.SharePoint.Client.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Runtime.dll"

# connect/authenticate to SharePoint Online and get ClientContext object.. 
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($sUrl)
if ($credFile.SharePointSettings.IsSiteSharePointOnline -eq $true) {
	$sCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($sAdmin, $sSecurePwd)
} else {
	$sCredentials = New-Object System.Net.NetworkCredential($sAdmin, $sSecurePwd)
}
$ctx.Credentials = $sCredentials

if (!$ctx.ServerObjectIsNull.Value) 
{ 
    Write-Host "Connected to the SOURCE SharePoint Online site: " $sCtx.Url "" -ForegroundColor Green
    
	try {
	$web = $ctx.Site.RootWeb;
    $contentTypes = $web.ContentTypes;         
	$fields = $web.Fields;         
    $ctx.Load($fields);
    $ctx.Load($web);   
    $ctx.Load($contentTypes);
    $ctx.ExecuteQuery();

	Write-Host Loaded content types -ForegroundColor Green

	$ns = new-object Xml.XmlNamespaceManager $inputFile.NameTable
	$ns.AddNamespace("msb", "http://schemas.microsoft.com/sharepoint/")

	$nodelist = $inputFile.SelectNodes("//msb:ContentType", $ns) # XPath is case sensitive
	foreach ($childNode in $nodelist) {	
		Write-Host Deploying content type [ $childNode.Name ] -ForegroundColor Green

		#Check whether the content type already exists
		$skip = $false
		foreach ($contentType in $contentTypes)
		{
				if ($contentType.Name -eq $childNode.Name) {
					Write-Host Content Type [ $childNode.Name ] already exists. Skippping... -ForegroundColor Green;
					$skip = $true;
					break;
				} 
		}
		if ($skip -eq $false) {		

			#Create a Content Type Information object
			$newContentType = New-Object Microsoft.SharePoint.Client.ContentTypeCreationInformation
			#Set the name for the content type
       
			$newContentType.Id = $childNode.ID; 
			$newContentType.Name =  $childNode.Name;       
			$newContentType.Group = $childNode.Group;   
			$newContentType.Description = $childNode.Description;   
			#$newContentType.Overwrite = $childNode.Overwrite;   
			#$newContentType = $contentTypes.Add($newContentType);
			if ($childNode.Inherits -eq "TRUE") {
				#$cType.ParentContentType = $docCT ; 
			}			
	
			#Create the content type
			$myContentType = $contentTypes.Add($newContentType);
			$refFields = $myContentType.FieldLinks;
			$fields = $web.Fields;

			#$ctx.Load($contentTypes);
			$ctx.Load($fields);
			$ctx.Load($myContentType);
			$ctx.Load($refFields);
			$ctx.ExecuteQuery();


			Write-Host Deployed content type [ $childNode.Name ] -ForegroundColor Green

			# Create the fieldrefs
			foreach ($fieldNode in $childNode.FieldRefs.FieldRef) {	
				if ($fieldNode.Hidden -eq "TRUE") { continue; }
				if ($fieldNode.Name -eq "ContentType") { continue; }
				if ($fieldNode.Name -eq "Title") { continue; }
				if ($fieldNode.Name -eq "FileLeafRef") { continue; }
				
				$skip = $true;
				foreach ($field in $fields)
				{					
					if ($field.Id -eq $fieldNode.ID) {
						$skip = $false;		
						$selectedField = $field

						Write-Host Creating field $fieldNode.Name
						$fldLink = New-Object Microsoft.SharePoint.Client.FieldLinkCreationInformation 
						$fldLink.Field = $field;
						$addedLink = $myContentType.FieldLinks.Add($fldLink);			
						$myContentType.Update($true);
						$ctx.ExecuteQuery();
						Write-Host Created field $fieldNode.Name

						break;
					} 
				}
				if ($skip -eq $true) {
					Write-Host Referenced field [ $fieldNode.ID - $fieldNode.Name ] does not exist. -ForegroundColor Yellow
					$skipContentType = $true
				} else {
					#$fldLink = New-Object Microsoft.SharePoint.Client.FieldLinkCreationInformation 
					#$fldLink.Field = $selectedField;
					#$link = $myContentType.FieldLinks.Add($fldLink);
	
					#$ctx.Load($myContentType);
					#$ctx.ExecuteQuery();			
				}
			}
			$ctx.Load($myContentType);
			$ctx.ExecuteQuery();			
		}
	}
	}
	catch {
		Write-Host Error occurred: $error[0].ToString() + $error[0].InvocationInfo.PositionMessage -ForegroundColor Red
	}
}