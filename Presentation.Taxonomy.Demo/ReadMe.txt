
2. The SSPID identifies your term store instance. To get the SSPID ID, type: 
./Presentation.Taxonomy.Console.exe SSPID https://sukulsharepoint-admin.sharepoint.com

3. In the "Presentation.Taxonomy.Demo" project, open BaseColumns\Elements.xml and search for SSPID
Replace the <value> node value with the SSPID from 2 above.
This will point the Managed Metadata columns to the correct termset

4. In DeploySolution.ps1, edit the $siteCollectionUrl, $login and $password and execute it from the PowerShell command prompt
./DeploySolution.ps1
This will deploy and activate the solution in your site collection


4.1 In the generated XML for columns, for Field elements of type "TaxonomyFieldType", search for List={some-guid} and replace with List="Lists/TaxonomyHiddenList" 

4.2 In the generated XML for columns, search for WebID={some-guid} and replace with WebId="~sitecollection"
4.2 In the generated XML for columns, search for SourceID={some-guid} and replace with SourceID="~sitecollection"

4.3. Search for Type="Lookup" and replace List=GUID with with List="Lists/LookupListName" 
4.4 Remove the Version attribute from the Field schema. See http://johnliu.net/blog/2012/8/22/sharepoint-the-object-has-been-updated-by-another-user-since.html