ABOUT
-----
This sample code is companion to the the presentation titled "SharePoint Taxonomy in Practice" presented at SharePoint Saturday 2014.
Follow the steps below to provision the taxonomy, columns, content types and lists in your own Office 365 SharePoint site collection.

1. Deploy the Term Store term stores and managed navigation terms
./Presentation.Taxonomy.Console.exe METADATA https://sukulsharepoint-admin.sharepoint.com

2. The SSPID identifies your term store instance. To get the SSPID ID, type: 
./Presentation.Taxonomy.Console.exe SSPID https://sukulsharepoint-admin.sharepoint.com

3. In the "Presentation.Taxonomy.Demo" project, open BaseColumns\Elements.xml and search for SSPID
Replace the <value> node value with the SSPID from 2 above.
This will point the Managed Metadata columns to the correct termset

4. In DeploySolution.ps1, edit the $siteCollectionUrl, $login and $password and execute it from the PowerShell command prompt
./DeploySolution.ps1
This will deploy and activate the solution in your site collection

5. Activating the solution also actives all the features. 
Initially, we do not require all the features activated.
Navigate to Site Collection Features and deactivate these features (in this order):

- Sukul.Demo.ContentTypes
- Sukul.Demo.Columns
- Sukul.Demo.2ndLevelContentTypes
- Sukul.Demo.2ndLevelColumns

6. Deploy the base lists based on the base content types:
./Presentation.Taxonomy.Console.exe LISTS https://sukulsharepoint-admin.sharepoint.com 1

7. Activate feature "Sukul.Demo.2ndLevelColumns"

8. Activate feature "Sukul.Demo.2ndLevelContentTypes"

9. Deploy the 2nd level lists based on the 2nd level content types
./Presentation.Taxonomy.Console.exe LISTS https://sukulsharepoint-admin.sharepoint.com 2

10. Finally, activate feature "Sukul.Demo.Columns"

11. Also activate feature "Sukul.Demo.ContentTypes"

12. Deploy the 3rd level lists
./Presentation.Taxonomy.Console.exe LISTS https://sukulsharepoint-admin.sharepoint.com 3

13. To connect to Managed Navigation:
    13.1 Go to Site Collection Features and ensure that the "SharePoint Server Publishing Infrastructure" feature is enabled
	13.2 Go to "Site Settings" -> "Navigation Settings"
	13.3 In the "Global Navigation" section, select "Managed Navigation"
	13.4 In the "Current Navigation" section, select "Managed Navigation"
	13.5 In the "Managed Navigation: Term Set" section, select "Site Collection - [Your Site Collection Url]\Sukul Navigation"
	13.6 Click OK
