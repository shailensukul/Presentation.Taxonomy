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

$global:output = ""

Function CleanseInput([string]$name)
{
	[string] $encoded = [System.Web.HttpUtility]::HtmlEncode($name);
	$encoded;
}

Function Get-Terms ($term, $ctx, [string]$tabLevel)
 {
	Write-Host "<Term Id='$($term.Id)' Name='$(CleanseInput($term.Name))' Lcid='$lcid'/>" -ForegroundColor Cyan
#	Add-Content $xmlFilePath "$tabLevel<Term Id='$($term.Id)' Name='$($term.Name)' Lcid='$lcid'>"
	$global:output = $global:output + "`n$tabLevel<Term Id='$($term.Id)' Name='$(CleanseInput($term.Name))' Lcid='$lcid'>"
	#Set-Variable -Name $output1 -Value ($output + "$tabLevel<Term Id='$($term.Id)' Name='$($term.Name)' Lcid='$lcid'>") -Scope Global

	$ctx.Load($term.Terms)
	$ctx.ExecuteQuery()

	if ($term.Terms -ne $null) 
	{
		foreach($childTerm in $term.Terms)
		{
			Get-Terms  ($childTerm) ($ctx) ($tabLevel + "`t") 
		}
	}
	#Add-Content $xmlFilePath "$tabLevel</Term>"
	$global:output= $global:output + "`n$tabLevel</Term>"
	#Set-Variable -Name $output -Value ($output + "$tabLevel</Term>") -Scope Global
}

[xml]$inputFile = Get-Content Input.xml 
$executingScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
[string] $xmlFilePath = "$($inputFile.SharePointSettings.ScriptExportFolder)\Taxonomy.xml"

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
					#Add-Content $xmlFilePath "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
					#Add-Content $xmlFilePath "<!--Generated on $(Get-Date -Format o)-->"
					#Add-Content $xmlFilePath "<!--Generated from $($Url)-->"
					#Add-Content $xmlFilePath "<TermStore Id='$($TermStore.Id)' Name='$($TermStore.Name)'>"
					#Add-Content $xmlFilePath "`t<Group Id='$($TermGroup.Id)' Name='$($TermGroup.Name)'>"

					$global:output  = "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
					$global:output  = $global:output + "`n<!--Generated on $(Get-Date -Format o)-->"
					$global:output  = $global:output + "`n<!--Generated from $($Url)-->"
					$global:output  = $global:output + "`n<TermStore Id='$($TermStore.Id)' Name='$($TermStore.Name)'>"
					$global:output  = $global:output + "`n`t<Group Id='$($TermGroup.Id)' Name='$($TermGroup.Name)'>"

					#Set-Variable -Name $output -Value ($output + "<?xml version=`"1.0`" encoding=`"utf-8`"?>") -Scope Global
					#Set-Variable -Name $output -Value ($output + "<!--Generated on $(Get-Date -Format o)-->") -Scope Global
					#Set-Variable -Name $output -Value ($output + "<!--Generated from $($Url)-->") -Scope Global
					#Set-Variable -Name $output -Value ($output + "<TermStore Id='$($TermStore.Id)' Name='$($TermStore.Name)'>") -Scope Global
					#Set-Variable -Name $output -Value ($output + "`t<Group Id='$($TermGroup.Id)' Name='$($TermGroup.Name)'>") -Scope Global

                    foreach($TermSet in $TermGroup.TermSets)
                    {
                        Write-Host ".......Term Set found: " $TermSet.Name "-" $TermSet.Id "" -ForegroundColor Cyan
                        $Ctx.Load($TermSet.Terms)
                        $Ctx.ExecuteQuery()

						#Add-Content $xmlFilePath "`t`t<TermSet Id='$($TermSet.Id)' Name='$($TermSet.Name)' Lcid='$lcid'>"
						$global:output = $global:output + "`n`t`t<TermSet Id='$($TermSet.Id)' Name='$($TermSet.Name)' Lcid='$lcid'>"
						#Set-Variable -Name $output -Value ($output + "`t`t<TermSet Id='$($TermSet.Id)' Name='$($TermSet.Name)' Lcid='$lcid'>") -Scope Global

                        foreach($term in $TermSet.Terms)
                        {
							Get-Terms ($term) ($Ctx) ("`t`t`t") 
                        }
						#Add-Content $xmlFilePath "`t`t</TermSet>"
						$global:output = $global:output + "`n`t`t</TermSet>"						
						#Set-Variable -Name $output -Value ($output + "`t`t</TermSet>") -Scope Global
					}
					#Add-Content $xmlFilePath "`t</Group>"
					#Add-Content $xmlFilePath "</TermStore>"

					$global:output = $global:output + "`n`t</Group>"
					$global:output = $global:output + "`n</TermStore>"

					#Set-Variable -Name $output -Value ($output + "`t</Group>") -Scope Global
					#Set-Variable -Name $output -Value ($output + "</TermStore>") -Scope Global


					Add-Content $xmlFilePath $global:output  

                }
            }
        }
    }
}