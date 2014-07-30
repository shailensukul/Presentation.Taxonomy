using Microsoft.SharePoint.Client;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Security;
using System.Text;
using System.Threading.Tasks;

namespace Presentation.Taxonomy.Console
{
    class Program
    {
        static string webUrl = string.Empty;
        static string userName = string.Empty;
        static SecureString password;
        static void Main(string[] args)
        {
            try
            {
                if (args.Length == 0)
                {
                    Usage();
                    return;
                }
                webUrl = args[1];
                GetUserCredentials();

                switch (args[0])
                {
                    case "SSPID":
                        var sspidSetup = new MetadataSetup(() => GetAuthenticatedContext(webUrl, userName, password));
                        sspidSetup.GetSSPID();
                        break;
                    case "METADATA":
                        var metadataSetup = new MetadataSetup(() => GetAuthenticatedContext(webUrl, userName, password));
                        metadataSetup.Execute();
                        break;
                    case "LISTS":
                        var listsSetup = new ListsSetup(() => GetAuthenticatedContext(webUrl, userName, password));
                        listsSetup.Execute(Int32.Parse(args[2]));
                        break;
                    default:
                        throw new ArgumentException("Not supported operation.");
                }
            }
            catch(Exception ex)
            {
                System.Console.Clear();
                System.Console.WriteLine(ex.Message);
                Usage();  
            }
        }



        private static SecureString GetPasswordFromConsoleInput()
        {
            ConsoleKeyInfo info;

            //Get the user's password as a SecureString
            SecureString securePassword = new SecureString();
            do
            {
                info = System.Console.ReadKey(true);
                if (info.Key != ConsoleKey.Enter)
                {
                    securePassword.AppendChar(info.KeyChar);
                }
            }
            while (info.Key != ConsoleKey.Enter);
            return securePassword;
        }
        private static void GetUserCredentials()
        {
            ConsoleColor defaultForeground = System.Console.ForegroundColor;
            System.Console.ForegroundColor = ConsoleColor.Green;
            System.Console.WriteLine("Enter your user name (ex: kirke@mytenant.microsoftonline.com) (Press ENTER for SharePoint OnPremises):");
            System.Console.ForegroundColor = defaultForeground;
            userName = System.Console.ReadLine();

            System.Console.ForegroundColor = ConsoleColor.Green;
            System.Console.WriteLine("Enter your password. (Press ENTER for SharePoint OnPremises)");
            System.Console.ForegroundColor = defaultForeground;
            password = GetPasswordFromConsoleInput();
        }

        private static void Usage()
        {
            System.Console.WriteLine("Please provide the operation option and the main intranet site collection url.");
            System.Console.WriteLine("Usage: Presentation.Taxonomy.Console.exe METADATA <site collection url>");
            System.Console.WriteLine("Usage: Presentation.Taxonomy.Console.exe LISTS <site collection url> [ListLevel]");
            System.Console.WriteLine("Where [ListLevel] = 1 for base lists, 2 for second level lists, 3 for third level lists and so on");
        }

        private static ClientContext GetAuthenticatedContext(string siteUrl, string userName, SecureString password)
        {
            ClientContext ctx;
            if (String.IsNullOrEmpty(userName))
            {
                // SharePoint OnPremises
                ctx = new ClientContext(siteUrl) { Credentials = System.Net.CredentialCache.DefaultCredentials };
            }
            else
            {
                // SharePoint Online
                ctx = new ClientContext(siteUrl) { Credentials = new SharePointOnlineCredentials(userName, password) };
            }
            return ctx;
        }
    }
}
