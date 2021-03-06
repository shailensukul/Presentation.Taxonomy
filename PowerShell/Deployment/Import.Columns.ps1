$file = resolve-path("Exported.Site.Columns.xml")
[xml]$inputFile = Get-Content $file
$file = resolve-path("Input.xml")
[xml]$credFile = Get-Content $file

# 1) Source Site
$sUrl = $credFile.SharePointSettings.SiteCollectionUrl;
$sAdmin = $credFile.SharePointSettings.UserID;
$sPwd = $credFile.SharePointSettings.Password
$sSecurePwd = ConvertTo-SecureString $sPwd -AsPlainText -Force

cls
# these aren't required for the script to run, but help to develop
Add-Type -Path "Microsoft.SharePoint.Client.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Taxonomy.dll"

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

	# Get the SSPID
	$MMS = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($ctx)
	
	$ctx.Load($MMS)
	$ctx.ExecuteQuery()

	#Retrieve Term Stores
	$TermStores = $MMS.TermStores
	$ctx.Load($TermStores)
	$ctx.ExecuteQuery()

	#Bind to Term Store
	$termStore = $TermStores[0]
	$ctx.Load($TermStore)
	$ctx.ExecuteQuery()
	
	$sspid= $termStore.Id
	Write-Host Term Store Id: $sspid

    Write-Host "Connected to the SOURCE SharePoint Online site: " $sCtx.Url "" -ForegroundColor Green
    
	try {
	#$web = $ctx.Web    
	$web = $ctx.Site.RootWeb;
    $fields = $web.Fields;         
    $ctx.Load($web);   
    $ctx.Load($fields);
    $ctx.ExecuteQuery();

	Write-Host Loaded fields -ForegroundColor Green

	$fieldOption = [Microsoft.SharePoint.Client.AddFieldOptions]::DefaultValue

	$nodelist = $inputFile.selectnodes("/Fields/Field") # XPath is case sensitive
	foreach ($childNode in $nodelist) {	

		if ($childNode.Hidden -eq "TRUE") { continue; }
		Write-Host Deploying field [ $childNode.DisplayName ] -ForegroundColor Green
		#Check whether field already exists
		$skip = $false
		foreach ($field in $fields)
		{
				if ($field.InternalName -eq $childNode.Name) {
					Write-Host Field [ $childNode.DisplayName ] already exists. Skippping... -ForegroundColor Yellow;
					$skip = $true;
					break;
				} 
		}
		if ($skip -eq $false) {					
			if ($childNode.Type -eq "TaxonomyFieldType" -or $childNode.Type -eq "TaxonomyFieldTypeMulti") {
				$mult = $False;
				#$sspid = "";
				$termsetid = "";
				$isOpen = "";
				if ($childNode.Type -eq "TaxonomyFieldTypeMulti") {
					$mult = $childNode.Mult;
				}
				
				foreach ($prop in $childNode.Customization.ArrayOfProperty.Property) {
					#if ($prop.Name -eq "SspId") {
					#	$sspid = $prop.Value.InnerText;
					#}
					if ($prop.Name -eq "TermSetId") {
						$termsetid = $prop.Value.InnerText;
					}
					if ($prop.Name -eq "Open") {
						$isOpen = $prop.Value.InnerText;
					}
				}
				# Create as a regular field setting the desired type in XML
				$childNode.RemoveChild($childNode.FirstChild);
				$childNode.RemoveChild($childNode.FirstChild);
				$childNode.RemoveAttribute("List");
				$childNode.RemoveAttribute("SourceID");
				$childNode.RemoveAttribute("ShowField");
				$childNode.RemoveAttribute("Mult");
				$childNode.RemoveAttribute("Sortable");				
#<Field Type="TaxonomyFieldTypeMulti" DisplayName="Driver Facility" Required="FALSE" EnforceUniqueValues="FALSE" Group="QHealth" ID="{a5d360a6-a582-4765-b7c7-1625719a16b6}" StaticName="DriverFacility" Name="DriverFacility" Mult="TRUE" Sortable="FALSE">		
				#<Field DisplayName='Session Topics' Name='SessionTopics' ID='{bed14299-afe0-4c75-9e04-92e3d8b39a18}' Group='SharePoint Saturday 2014 Columns' Type='TaxonomyFieldTypeMulti'/>
				#<Field Type="TaxonomyFieldType" DisplayName="Risk Likelihood" Required="FALSE" EnforceUniqueValues="FALSE" Group="QHealth" ID="{73fa4106-1e1c-4675-8908-4eb3556d9319}" StaticName="RiskLikelihood" Name="RiskLikelihood"></Field>
# $childNode.get_OuterXml()
				$fieldAsXML = $childNode.get_OuterXml();
				$fld = $fields.AddFieldAsXml(
				$fieldAsXML, 
				$false, [Microsoft.SharePoint.Client.AddFieldOptions]::AddFieldInternalNameHint);
				$ctx.Load($fld);
				$ctx.ExecuteQuery();
				 				 
				# Retrieve as Taxonomy Field
				#$taxonomyField = $ctx.CastTo<Microsoft.SharePoint.Client.Taxonomy.TaxonomyField>($fld);
				$taxonomyField = [Microsoft.SharePoint.Client.ClientContext].GetMethod("CastTo").MakeGenericMethod([Microsoft.SharePoint.Client.Taxonomy.TaxonomyField]).Invoke($ctx, $fld)
				
				$taxonomyField.SspId = $sspid;
				$taxonomyField.TermSetId = $termsetid;
				$taxonomyField.TargetTemplate = [system.string]::empty;
				$taxonomyField.AnchorId = [system.guid]::empty;
				if ($mult -eq "TRUE") {
				 $taxonomyField.AllowMultipleValues = $true;
				}
				if ($isOpen -eq "true") {
            	 	$taxonomyField.Open = $true;
				}
				
				$taxonomyField.Update();

				$ctx.ExecuteQuery();				
			} else {

				if ($childNode.Type -eq "Lookup") { 
					# Do nothing
				} else {
					$fieldAsXML = $childNode.get_OuterXml();
					$fld = $fields.AddFieldAsXml($fieldAsXML, $true, $fieldOption);
					#Write-Host $childNode.get_OuterXml()
					#$field.UpdateAndPushChanges($True)
					$ctx.Load($fields);
					$ctx.Load($fld);
					$ctx.ExecuteQuery();
				}
			}
			Write-Host Deployed field [ $childNode.DisplayName ] -ForegroundColor Green
		}
	}
	}
	catch {
		Write-Host Error occurred: $error[0].ToString() + $error[0].InvocationInfo.PositionMessage -ForegroundColor Red
	}
}