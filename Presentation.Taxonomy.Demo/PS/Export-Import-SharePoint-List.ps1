function Export-List([string]$ListURL)
{
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") > $null
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Deployment") > $null

	$versions = [Microsoft.SharePoint.Deployment.SPIncludeVersions]::All

	$exportObject = New-Object Microsoft.SharePoint.Deployment.SPExportObject
	$exportObject.Type = [Microsoft.SharePoint.Deployment.SPDeploymentObjectType]::List 
	$exportObject.IncludeDescendants = [Microsoft.SharePoint.Deployment.SPIncludeDescendants]::All

	$settings = New-Object Microsoft.SharePoint.Deployment.SPExportSettings

	$settings.ExportMethod = [Microsoft.SharePoint.Deployment.SPExportMethodType]::ExportAll
	$settings.IncludeVersions = $versions
	$settings.IncludeSecurity = [Microsoft.SharePoint.Deployment.SPIncludeSecurity]::All
	$settings.OverwriteExistingDataFile = 1
	$settings.ExcludeDependencies = $true

	$site = new-object Microsoft.SharePoint.SPSite($ListURL)
	Write-Host "ListURL", $ListURL

	$web = $site.OpenWeb()
	$list = $web.GetList($ListURL)
	
	$settings.SiteUrl = $web.Url
	$exportObject.Id = $list.ID
	$settings.FileLocation = "C:\Temp\BackupRestoreTemp\"
	$settings.BaseFileName = "ExportList-"+ $list.ID.ToString() +".DAT"
	$settings.FileCompression = 1

	Write-Host "FileLocation", $settings.FileLocation

	$settings.ExportObjects.Add($exportObject)

	$export = New-Object Microsoft.SharePoint.Deployment.SPExport($settings)
	$export.Run()

	$web.Dispose()
	$site.Dispose()
}

function Import-List([string]$DestWebURL, [string]$FileName, [string]$LogFilePath)
{
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") > $null
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Deployment") > $null

	$settings = New-Object Microsoft.SharePoint.Deployment.SPImportSettings

	$settings.IncludeSecurity = [Microsoft.SharePoint.Deployment.SPIncludeSecurity]::All
	$settings.UpdateVersions = [Microsoft.SharePoint.Deployment.SPUpdateVersions]::Overwrite 
	$settings.UserInfoDateTime = [Microsoft.SharePoint.Deployment.SPImportUserInfoDateTimeOption]::ImportAll

	$site = new-object Microsoft.SharePoint.SPSite($DestWebURL)
	Write-Host "DestWebURL", $DestWebURL

	$web = $site.OpenWeb()

	Write-Host "SPWeb", $web.Url

	$settings.SiteUrl = $web.Url
	$settings.WebUrl = $web.Url
	$settings.FileLocation = "C:\Temp\BackupRestoreTemp\"
	$settings.BaseFileName = $FileName
	$settings.LogFilePath = $LogFilePath
	$settings.FileCompression = 1

	Write-Host "FileLocation", $settings.FileLocation

	$import = New-Object Microsoft.SharePoint.Deployment.SPImport($settings)
	$import.Run()

	$web.Dispose()
	$site.Dispose()
}


# For Export a specified SharePoint List
Export-List "http://mySharePointWebApplication/sites/MySiteCollection/MyListToExport/" 

# For Import the list you export in previous command
Import-List "http://mySharePointWebApplication/sites/OtherSiteCollection/" "ExportList-TheGUID.DAT" "C:\Temp\BackupRestoreTemp\ImportLog.txt" 
