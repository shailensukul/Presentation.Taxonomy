#
# This script allows the Term store to be exported to an XML file along with Term IDs
# Author: Shailen Sukul
# http://shailensukul.com
# This script works off an input file called Input.xml

# these aren't required for the script to run, but help to develop
Add-Type -Path "Microsoft.SharePoint.Client.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Taxonomy.dll"

Function Get-Terms ($term, $ctx, [string]$tabLevel) 
 {
	Write-Host "`n<Term Id='$($term.Id)' Name='$($term.Name)' Lcid='$lcid'>" -ForegroundColor Cyan
	Add-Content $global:xmlFilePath "`n$tabLevel<Term Id='$($term.Id)' Name='$($term.Name)' Lcid='$lcid'>"

	$ctx.Load($term.Terms)
	$ctx.ExecuteQuery()

	if ($term.Terms -ne $null) 
	{
		foreach($childTerm in $term.Terms)
		{
			Get-Terms ($childTerm) ($ctx) ($tabLevel + "`t")
		}
	}
	Add-Content $global:xmlFilePath "$tabLevel</Term>"
}

[xml]$inputFile = Get-Content Input.xml 
[string] $global:xmlFilePath = "C:\Temp\Script-Taxonomy.xml"

# Source Site
$sUrl = $inputFile.SharePointCredentials.Url;
$sAdmin = $inputFile.SharePointCredentials.UserID;
$sPwd = $inputFile.SharePointCredentials.Password
$sSecurePwd = ConvertTo-SecureString $sPwd -AsPlainText -Force

# connect/authenticate to SharePoint Online and get ClientContext object.. 
[Microsoft.SharePoint.Client.ClientContext] $sCtx = New-Object Microsoft.SharePoint.Client.ClientContext($sUrl)
$sCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($sAdmin, $sSecurePwd)
$sCtx.Credentials = $sCredentials

# What Term Group do you want to synchronize?
$sTermGroupName = $inputFile.SharePointCredentials.TermStoreGroup 

## Change locale here
$lcid = "1033"

if (!$sCtx.ServerObjectIsNull.Value) 
{ 
	cls
    Write-Host "Connected to the SOURCE SharePoint Online site: " $sCtx.Url "" -ForegroundColor Green
    
    $sTaxonomySession = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($sCtx)
    $sTaxonomySession.UpdateCache()
    $sCtx.Load($sTaxonomySession)
    $sCtx.ExecuteQuery()

    if (!$sTaxonomySession.ServerObjectIsNull)
    {
        Write-Host "Source Taxonomy session initiated: " $sTaxonomySession.Path.Identity "" -ForegroundColor Green

        $sTermStore = $sTaxonomySession.GetDefaultSiteCollectionTermStore()
        $sCtx.Load($sTermStore)
        $sCtx.ExecuteQuery()

        if ($sTermStore.IsOnline) 
        {
            Write-Host "...Default Term Store connected:" $sTermStore.Id "" -ForegroundColor Green
            # $termStoreId will be the SspId in the taxonomy column configs
            
            $sCtx.Load($sTermStore.Groups)
            $sCtx.ExecuteQuery()

            foreach ($sTermGroup in $sTermStore.Groups)
            {
                if ($sTermGroup.Name -eq $sTermGroupName)
                {
                    Write-Host ".....Term Group loaded: " $sTermGroup.Name "-" $sTermGroup.Id "" -ForegroundColor Cyan
                    $sCtx.Load($sTermGroup.TermSets)
                    $sCtx.ExecuteQuery()

					#Create Export Files
					New-Item $global:xmlFilePath -type file -force
					Add-Content $global:xmlFilePath "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
					Add-Content $global:xmlFilePath "`n<Taxonomy Id='$($sTermStore.Id)' Name='$($sTermStore.Name)'>"
					Add-Content $global:xmlFilePath "`n`t<Group Id='$($sTermGroup.Id)' Name='$($sTermGroup.Name)'>"

                    foreach($sTermSet in $sTermGroup.TermSets)
                    {
                        Write-Host ".......Term Set found: " $sTermSet.Name "-" $sTermSet.Id "" -ForegroundColor Cyan
                        $sCtx.Load($sTermSet.Terms)
                        $sCtx.ExecuteQuery()

						Add-Content $global:xmlFilePath "`n`t`t<TermSet Id='$($sTermSet.Id)' Name='$($sTermSet.Name)' Lcid='$lcid'>"

                        foreach($term in $sTermSet.Terms)
                        {
							Get-Terms ($term) ($sCtx) ("`t`t`t")
                        }
						Add-Content $global:xmlFilePath "`n`t`t</TermSet>"
					}
					Add-Content $global:xmlFilePath "`n`t</Group>"
					Add-Content $global:xmlFilePath "`n</Taxonomy>"

                }
            }
        }
    }
}