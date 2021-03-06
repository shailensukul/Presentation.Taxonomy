#
# This script allows the Term store to be created from an XML file created via Export.Taxonomy.ps1
# Author: Shailen Sukul
# http://shailensukul.com
# INPUT FILE: Taxonomy.xml
# INPUT FILE: Input.xml

# these aren't required for the script to run, but help to develop
Add-Type -Path "Microsoft.SharePoint.Client.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Taxonomy.dll"

function SetTermsRecursive ($termsetitem, $parentnode)
{
	if ($parentnode.Term -ne $null) {
	 $parentnode.Term |
	 ForEach-Object {
	  ## create the term
	  Write-Host -ForegroundColor Cyan Creating term $_.Name
	  $newterm = $termsetitem.CreateTerm($_.Name, $_.Lcid, $_.Id);
	  Write-Host -ForegroundColor Cyan Added term $_.Name
	  SetTermsRecursive($termsetitem, $_)
 					}
	}
}
$executingScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
[string] $xmlFilePath = "$($executingScriptDirectory)\Taxonomy.xml"
## Change locale here
$lcid = "1033"

if (Test-Path $xmlFilePath) {
	Write-Host Found Taxonomy.xml..... processing -ForegroundColor Green
	
	[xml]$taxFile = Get-Content $xmlFilePath
	[xml]$inputFile = Get-Content Input.xml 

	$url = $inputFile.SharePointSettings.SiteCollectionUrl;
	$admin = $inputFile.SharePointSettings.UserID;
	$pwd = $inputFile.SharePointSettings.Password
	$securePwd = ConvertTo-SecureString $pwd -AsPlainText -Force

	#$Context = New-Object Microsoft.SharePoint.Client.ClientContext($url)
	#$Creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin,$securePwd)
	#$Context.Credentials = $Creds
	
	# connect/authenticate to SharePoint Online and get ClientContext object.. 
	$Context = New-Object Microsoft.SharePoint.Client.ClientContext($url)
	if ($inputFile.SharePointSettings.IsSiteSharePointOnline -eq $true) {
		$sCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $securePwd)
	} else {
		$sCredentials = New-Object System.Net.NetworkCredential($admin, $securePwd)
	}
	$Context.Credentials = $sCredentials

	if (!$sCtx.ServerObjectIsNull.Value) {
		#Bind to MMS	
		$MMS = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($Context)
		$Context.Load($MMS)
		$Context.ExecuteQuery()

		#Retrieve Term Stores
		$TermStores = $MMS.TermStores
		$Context.Load($TermStores)
		$Context.ExecuteQuery()

		#Bind to Term Store
		$TermStore = $TermStores[0]
		$Context.Load($TermStore)
		$Context.ExecuteQuery()

		Foreach ($Group in $taxFile.TermStore.Group)
		{
			#Create Groups
			Write-Host Creating group $Group.Name -ForegroundColor Green
			$NewGroup = $TermStore.CreateGroup($Group.Name, $Group.Id)
			$Context.Load($NewGroup)
			$Context.ExecuteQuery()
			Foreach ($TermSet in $Group.TermSet)
			{
				#Create Term Sets
				Write-Host Creating TermSet $Term.Name  -ForegroundColor Blue
				$NewTermSet = $NewGroup.CreateTermSet($TermSet.Name, $TermSet.Id, $TermSet.Lcid)
				$Context.Load($NewTermSet)
				$Context.ExecuteQuery()
				Foreach ($Term in $TermSet.Term)
				{
					#Create Terms
					Write-Host Creating Term $Term.Name  -ForegroundColor Blue
					$NewTerm = $NewTermSet.CreateTerm($Term.Name, $Term.Lcid, $Term.Id)
					$Context.Load($NewTerm)
					$Context.ExecuteQuery()
					Write-Host Created Term $Term.Name  -ForegroundColor Blue

					SetTermsRecursive $NewTerm $Term
				}
			}
		}
	} else {
		Write-Host Please provide an input file called Taxonomy.xml -ForegroundColor Red
	}
}