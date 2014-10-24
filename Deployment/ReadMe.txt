ABOUT
-----

# Before running this, install the PowerShell module for SharePoint Online here 
# http://www.microsoft.com/en-us/download/details.aspx?id=35588
# Also, you MUST PowerShell as an Administrator
# Also need to set execution policy:
# Set-ExecutionPolicy Unrestricted

This sample code is companion to the the presentation titled "SharePoint Taxonomy in Practice" presented at SharePoint Saturday 2014 and in more depth at TechEd 2014.
Follow the steps below to provision the taxonomy, columns, content types and lists in your own Office 365 SharePoint site collection.

1. If you do not already have an Office 365 site, provision a trial one for free at http://office.microsoft.com

2. In the Deployment folder, edit the Input.xml document and provide the SiteCollection url (where schema will be deployed), Site url 
(where the lists will be deployed) and the Admin user id and password of your O365 tenant

3. Open PowerShell, and navigate to the Deployment folder

4. Run DeploySolution.ps1

5. Check for any errors and repeat if necessary
