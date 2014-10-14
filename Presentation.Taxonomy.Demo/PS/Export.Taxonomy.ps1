#
# This script allows the Term store to be exported to an XML file along with Term IDs
# Author: Shailen Sukul
# http://shailensukul.com
# This script works off an input file called Input.xml
# INPUT FILE: Input.xml

# these aren't required for the script to run, but help to develop
Add-Type -Path "Microsoft.SharePoint.Client.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "Microsoft.SharePoint.Client.Taxonomy.dll"

Function Get-Terms ($term, $ctx, [string]$tabLevel) 
 {
	Write-Host "<Term Id='$($term.Id)' Name='$($term.Name)' Lcid='$lcid'/>" -ForegroundColor Cyan
	Add-Content $xmlFilePath "$tabLevel<Term Id='$($term.Id)' Name='$($term.Name)' Lcid='$lcid'>"

	$ctx.Load($term.Terms)
	$ctx.ExecuteQuery()

	if ($term.Terms -ne $null) 
	{
		foreach($childTerm in $term.Terms)
		{
			Get-Terms ($childTerm) ($ctx) ($tabLevel + "`t")
		}
	}
	Add-Content $xmlFilePath "$tabLevel</Term>"
}

[xml]$inputFile = Get-Content Input.xml 
$executingScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
[string] $xmlFilePath = "$($executingScriptDirectory)\Taxonomy.xml"

$Url = $inputFile.SharePointSettings.Url;
$User = $inputFile.SharePointSettings.UserID;
$Pwd = $inputFile.SharePointSettings.Password
$SecurePwd = ConvertTo-SecureString $Pwd -AsPlainText -Force

# connect/authenticate to SharePoint Online and get ClientContext object.. 
[Microsoft.SharePoint.Client.ClientContext] $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($Url)
$Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($User, $SecurePwd)
$Ctx.Credentials = $Credentials

# What Term Group do you want to synchronize?
$TermGroupName = $inputFile.SharePointSettings.TermStoreGroup 

## Change locale here
$lcid = "1033"

if (!$Ctx.ServerObjectIsNull.Value) 
{ 
	cls
    Write-Host "Connected to the SOURCE SharePoint Online site: " $Ctx.Url "" -ForegroundColor Green
    
    $sTaxonomySession = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($Ctx)
    $sTaxonomySession.UpdateCache()
    $Ctx.Load($sTaxonomySession)
    $Ctx.ExecuteQuery()

    if (!$sTaxonomySession.ServerObjectIsNull)
    {
        Write-Host "Source Taxonomy session initiated: " $sTaxonomySession.Path.Identity "" -ForegroundColor Green

        $TermStore = $sTaxonomySession.GetDefaultSiteCollectionTermStore()
        $Ctx.Load($TermStore)
        $Ctx.ExecuteQuery()

        if ($TermStore.IsOnline) 
        {
			# Term store id is the SSPID
            Write-Host "...Default Term Store connected:" $TermStore.Id "" -ForegroundColor Green
            
            $Ctx.Load($TermStore.Groups)
            $Ctx.ExecuteQuery()

            foreach ($TermGroup in $TermStore.Groups)
            {
                if ($TermGroup.Name -eq $TermGroupName)
                {
                    Write-Host "Term Group loaded: " $TermGroup.Name "-" $TermGroup.Id "" -ForegroundColor Cyan
                    $Ctx.Load($TermGroup.TermSets)
                    $Ctx.ExecuteQuery()

					#Create Export Files
					New-Item $xmlFilePath -type file -force
					Add-Content $xmlFilePath "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
					Add-Content $xmlFilePath "<!--Generated on $(Get-Date -Format o)-->"
					Add-Content $xmlFilePath "<!--Generated from $($Url)-->"
					Add-Content $xmlFilePath "<TermStore Id='$($TermStore.Id)' Name='$($TermStore.Name)'>"
					Add-Content $xmlFilePath "`t<Group Id='$($TermGroup.Id)' Name='$($TermGroup.Name)'>"

                    foreach($TermSet in $TermGroup.TermSets)
                    {
                        Write-Host ".......Term Set found: " $TermSet.Name "-" $TermSet.Id "" -ForegroundColor Cyan
                        $Ctx.Load($TermSet.Terms)
                        $Ctx.ExecuteQuery()

						Add-Content $xmlFilePath "`t`t<TermSet Id='$($TermSet.Id)' Name='$($TermSet.Name)' Lcid='$lcid'>"

                        foreach($term in $TermSet.Terms)
                        {
							Get-Terms ($term) ($Ctx) ("`t`t`t")
                        }
						Add-Content $xmlFilePath "`t`t</TermSet>"
					}
					Add-Content $xmlFilePath "`t</Group>"
					Add-Content $xmlFilePath "</TermStore>"

                }
            }
        }
    }
}