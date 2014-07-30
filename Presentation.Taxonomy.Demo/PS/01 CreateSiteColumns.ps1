# CreateSiteColumns.ps1
#
# Description: 
#
# This script creates Site Columns in the appropriate Site
# Collections as listed in the CreateSiteColumns.csv. 
# The .CSV needs to be saved to "C:\PowerShell\" directory.
# If this directory does not exist, you will need to create it.
#
# Running this script requires running PowerShell with elevated 
# privileges so right click the SharePoint 2010 Management Shell
# and select "Run as administrator" then use change directory 
# commands and tabs to run the PS1 from its directory.
#
# This script assumes that you are creating the Site Column in 
# the top-level site of a site collection.
# It can also be used to create a Site Column in the Content Type Hub.
# 
# Once a Site Column is created, you will need to configure any 
# options not covered in the script, as the varying options per 
# field type would create increased load and may not reduce time 
# entry versus selecting options in a Site Column within the 
# SharePoint Site Settings GUI.
#
# LIST OF FIELD TYPES
#
# OOTB Field Types
#
# AllDayEvent
# Attachments
# Boolean
# BusinessData
# Calculated
# Choice
# Computed
# ContentTypeId
# Counter
# CrossProjectLink
# Currency
# DateTime
# Decimal
# File
# GridChoice
# Guid
# Integer
# Lookup
# LookupMulti
# ModStat
# MultiChoice
# MultiColumn
# Note
# Number
# PageSeperator
# Recurrence
# Text
# ThreadIndex
# Threading
# Url
# User
# UserMulti
# WorkflowEventType
# WorkflowStatus
# 
# Hold Field Types
#
# HoldsField
# ExemptField
# 
# Publishing Field Types
#
# HTML
# Image
# Link
# SummaryLinks
# LayoutVariationsField
# ContentTypeIdFieldType
# PublishingScheduleStartDateFieldType
# PublishingScheduleEndDateFieldType
# MediaFieldType
# 
# SPRating Field Types
#
# AverageRating
# RatingCount
# 
# TargetTo Field Types
#
# TargetTo
# 
# Taxonomy Field Types
#
# TaxonomyFieldType
# TaxonomyFieldTypeMulti
 
 
# Reference the CSV holding the Site Column values and begin the loop
$create = Import-Csv -path C:\Code\Presentation.Taxonomy\Presentation.Taxonomy.Demo\PS\Config\SiteColumns.csv
ForEach($row in $create) {
 
# Get Site and Web object
$site = Get-SPSite -Identity $row.SiteCollectionURL
$web = $site.RootWeb
 
# Assign fieldXML variable with XML string for Site Column
$fieldXML = '<Field Type="'+$row.FieldType+'"
 Name="'+$row.Name+'"
 Description="'+$row.Description+'"
 DisplayName="'+$row.DisplayName+'"
 StaticName="'+$row.StaticName+'"
 Group="'+$row.Group+'"
 Hidden="'+$row.Hidden+'"
 Required="'+$row.Required+'"
 Sealed="'+$row.Sealed+'"
 ShowInDisplayForm="'+$row.ShowInDisplayForm+'"
 ShowInEditForm="'+$row.ShowInEditForm+'"
 ShowInListSettings="'+$row.ShowInListSettings+'"
 ShowInNewForm="'+$row.ShowInNewForm+'"></Field>' 
 
# Output XML to console
write-host $fieldXML
 
# Create Site Column from XML string
$web.Fields.AddFieldAsXml($fieldXML)
 
# Dispose of Web and Site objects and close the loop
$web.Dispose()
$site.Dispose()
}