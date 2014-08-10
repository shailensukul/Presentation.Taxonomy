#######################
#
# Migrate Site Columns by Custom Group Name
#
# "Elise", a series of scripts to migrate O365 SharePoint Online Assets across O365 instances
#
# Copyright 2014, John Wefler, Rightpoint Consulting, LLC.
#
#######################

# Change the following to reflect your environments

# 1) Source Site
$sUrl = "https://wefnetOrig.sharepoint.com/"
$sAdmin = "wef@wefnetOrig.onmicrosoft.com"
$sPwd = "xxxxxxxxxxx"

# 2) Destination Site
$dUrl = "https://wefnetDest.sharepoint.com/"
$dAdmin = "wef@WEFNETDEST.onmicrosoft.com"
$dPwd = "xxxxxxxxxxx"

# 3) What Site Column Group do you want to synchronize?
$sGroupName = "Wef Custom"

## Stop here
$lcid = "1033"

$sSecurePwd = ConvertTo-SecureString $sPwd -AsPlainText -Force
$dSecurePwd = ConvertTo-SecureString $dPwd -AsPlainText -Force

# these aren't required for the script to run, but help to develop
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
# doh
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"

# connect/authenticate to SharePoint Online and get ClientContext object.. 
$sCtx = New-Object Microsoft.SharePoint.Client.ClientContext($sUrl)
$sCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($sAdmin, $sSecurePwd)
$sCtx.Credentials = $sCredentials

$dCtx = New-Object Microsoft.SharePoint.Client.ClientContext($dUrl)
$dCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($dAdmin, $dSecurePwd)
$dCtx.Credentials = $dCredentials

$continue = 0

if (!$dCtx.ServerObjectIsNull.Value)
{
    Write-Host "Connected to DESTINATION SharePoint Online site: " $dCtx.Url "" -ForegroundColor Green

    $continue = 1
}
 
if (!$sCtx.ServerObjectIsNull.Value -and $continue -eq 1) 
{ 
    Write-Host "Connected to the SOURCE SharePoint Online site: " $sCtx.Url "" -ForegroundColor Green
    $sSite = $sCtx.Web
    $sCols = $sSite.AvailableFields
    $sCtx.Load($sCols)
    $sCtx.ExecuteQuery()

    Write-Host "Found" $sCols.Count "Site Columns" -ForegroundColor Cyan

    foreach($sCol in $sCols)
    {
        if($sCol.Group -eq $sGroupName)
        {
            Write-Host ".........Column found:" $sCol.StaticName "" -ForegroundColor Cyan
            
            #convert to XML object for future manipulation of nodes
            [xml]$sColXML = $sCol.SchemaXml

            $newCol = $sColXML.OuterXml.ToString()

            $options = [Microsoft.SharePoint.Client.AddFieldOptions]::AddFieldToDefaultView

            $dField = $dCtx.Web.Fields.AddFieldAsXml($newCol, $true, $options)
            
            $dCtx.Load($dCtx.Web)
            $dCtx.ExecuteQuery()
        }
    }
}

$dCtx.Dispose()
$sCtx.Dispose()