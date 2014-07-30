	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Taxonomy")
	$spSite = new-object Microsoft.SharePoint.SPSite("https://sukulsharepoint.sharepoint.com/sites/SPSat")
	$session = new-object Microsoft.SharePoint.Taxonomy.TaxonomySession($spSite)
	$termStore = $session.TermStores[0]; 
	Write-Host "SSPID: " $termStore.Id
