$site = Get-SPSite -Identity http://intranet
$web = $site.OpenWeb() 
$list = $web.Lists["Yahoo Weather"]
$list.SchemaXML | Out-File f:\code\schema.xml