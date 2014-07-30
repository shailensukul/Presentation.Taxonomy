using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
//using CamlexNET;
using Microsoft.SharePoint.Client;
using Microsoft.SharePoint.Client.Taxonomy;
using Microsoft.SharePoint.Client.WebParts;
using System.Text;

namespace Presentation.Taxonomy.Console
{
    public class ListsSetup
    {
        private readonly Func<ClientContext> getContext;

        public ListsSetup(Func<ClientContext> getContext)
        {
            this.getContext = getContext;
        }

        public void Execute(int listLevel)
        {
            Log.TraceInformation(ConsoleColor.Magenta, "Creating lists and attaching Content types ");
            using (var ctx = getContext())
            {
                BuildLists(ctx, listLevel);
            }
        }

        private void BuildLists(ClientContext ctx, int listLevel)
        {
            foreach (var list in Presentation.Taxonomy.Console.Names.ListTaxonomy.Lists)
            {
                if (list.ListLevel != listLevel) { continue; }
                Log.TraceInformation(string.Format("Building list: {0}", list.ListTitle));
                var web = ctx.Site.RootWeb;
                // build notifications list 
                var listCreationInformation = new ListCreationInformation
                {
                    Url = list.ListUrl,
                    Title = list.ListTitle,
                    TemplateType = (int)list.ListTemplate,
                };

                var listNew = FrameWork.SafeAddList(ctx, ctx.Web, listCreationInformation);

                var listConfigurationContentType = FrameWork.FindContentType(ctx, web.ContentTypes, list.ContentTypeName);
                listNew.ContentTypesEnabled = true;
                listNew.Update();
                ctx.ExecuteQuery();

                FrameWork.SafeAddContentTypeToList(ctx, listNew, listConfigurationContentType);
                FrameWork.SafeRemoveListContentType(ctx, listNew, "Item");

                var defaultView = listNew.DefaultView;
                listConfigurationContentType = FrameWork.FindContentType(ctx, web.ContentTypes, list.ContentTypeName);
                ctx.Load(listConfigurationContentType, x => x.Fields);
                ctx.ExecuteQuery();
                FrameWork.SetViewFields(defaultView, GetFieldsAsStringArray(listConfigurationContentType.Fields));
                defaultView.Update();
                ctx.ExecuteQuery();
            }
        }

        private string[] GetFieldsAsStringArray(FieldCollection fields)
        {
            List<string> fieldsA = new List<string>();
            foreach (var field in fields)
            {
                if (!field.InternalName.ToLower().Equals("contenttype"))
                {
                    fieldsA.Add(field.InternalName);
                }
            }
            return fieldsA.ToArray();
        }
    }
}

