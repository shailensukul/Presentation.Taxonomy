using Microsoft.SharePoint.Client;
using Microsoft.SharePoint.Client.Publishing;
using Microsoft.SharePoint.Client.Taxonomy;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Linq.Expressions;
using System.Text;
using System.Threading.Tasks;

namespace Presentation.Taxonomy.Console
{
    static class FrameWork
    {
        public static Guid publishingHiddenWebFeatureId = new Guid("{22a9ef51-737b-4ff2-9346-694633fe4416}");
        public static TermGroup AddOrFindTermGroup(TermStore termStore, string groupname, Guid groupId, bool updateIfExists = false)
        {
            Trace.TraceInformation("checking term store group {0} with id{1}", groupname, groupId);
            ClientRuntimeContext ctx = termStore.Context;

            TermGroup resultGroup = null;

            resultGroup = termStore.GetGroup(groupId);
            ctx.Load(resultGroup, x => x.Name, x => x.Id, x => x.TermSets);

            ctx.ExecuteQuery();
            if (resultGroup.IsNullOrServerObjectIsNull())
            {
                Trace.Indent(); Trace.TraceInformation("creating new"); Trace.Unindent();
                resultGroup = termStore.CreateGroup(groupname, groupId);
                ctx.Load(resultGroup, x => x.Name, x => x.Id, x => x.TermSets);
            }
            else
            {
                if (updateIfExists)
                {
                    Trace.Indent(); Trace.TraceInformation("updating"); Trace.Unindent();
                    resultGroup.Name = groupname;
                }
            }
            ctx.ExecuteQuery();
            return resultGroup;
        }





        public static TermSet AddOrFindTermSet(TermGroup group, string name, Guid termSetId, bool isOpenTermset, bool updateIfExists, int lcid = 1033)
        {
            Trace.TraceInformation("checking term set group {0} with id{1}", name, termSetId);
            ClientRuntimeContext ctx = @group.Context;

            TermSet resultSet = null;

            resultSet = @group.TermSets.GetById(termSetId);
            ctx.Load(resultSet, x => x.Name, x => x.Id, x => x.Terms);

            try
            {
                ctx.ExecuteQuery();
            }
            catch (Exception ex)
            {
                if (ex.Message.Contains("out of the range"))
                {
                    resultSet = null;
                }
                else
                {
                    throw;
                }
            }
            if (resultSet == null)
            {
                Trace.Indent(); Trace.TraceInformation("creating new"); Trace.Unindent();
                resultSet = @group.CreateTermSet(name, termSetId, lcid);
                resultSet.IsOpenForTermCreation = isOpenTermset;
                ctx.Load(resultSet, x => x.Name, x => x.Id, x => x.Terms);
            }
            else
            {
                if (updateIfExists)
                {
                    Trace.Indent(); Trace.TraceInformation("updating"); Trace.Unindent();
                    resultSet.Name = name;
                }
            }
            ctx.ExecuteQuery();
            return resultSet;
        }
        public static Term AddOrFindTerm(TermSet termSet, string name, Guid termId, bool updateIfExists = false, int lcid = 1033)
        {
            Trace.TraceInformation("checking term   {0} with id{1}", name, termId);
            ClientRuntimeContext ctx = termSet.Context;

            Term term = null;

            term = termSet.GetTerm(termId);
            ctx.Load(term, x => x.Name, x => x.Id, x => x.Terms);

            ctx.ExecuteQuery();
            if (term.IsNullOrServerObjectIsNull())
            {
                Trace.Indent(); Trace.TraceInformation("creating new"); Trace.Unindent();
                term = termSet.CreateTerm(name, lcid, termId);
                termSet.TermStore.CommitAll();
                ctx.Load(term, x => x.Name, x => x.Id, x => x.Terms);
                ctx.ExecuteQuery();
            }
            else
            {
                if (updateIfExists)
                {
                    Trace.Indent(); Trace.TraceInformation("updating"); Trace.Unindent();
                    term.Name = name;
                }
            }
            return term;
        }
        public static bool IsNullOrServerObjectIsNull<T>(this T obj) where T : ClientObject
        {
            return ((obj == null) || (obj.ServerObjectIsNull.GetValueOrDefault(false)));
        }

        public static void AddNewEnterpriseKeyword(ClientContext ctx, string term, Guid termGuid)
        {
            //Reference: http://roy-sharepoint.blogspot.com.au/2013/02/sharepoint-add-terms-to-metadata-store.html

            //Get the Taxonomy session
            TaxonomySession taxonomySession = TaxonomySession.GetTaxonomySession(ctx);
            ctx.Load(taxonomySession,
                ts => ts.TermStores.Include(
                store => store.Name,
                store => store.Groups.Include(
                group => @group.Name))
            );
            ctx.ExecuteQuery();

            //Attach to the MMS service
            TermStore termStore = taxonomySession.GetDefaultKeywordsTermStore();
            ctx.Load(termStore);
            ctx.ExecuteQuery();

            //Get the system Group reference
            TermGroup termGroup = termStore.Groups.GetByName("System");
            ctx.Load(termGroup);
            ctx.ExecuteQuery();

            //Get the Keywords termset
            TermSet termSet = termGroup.TermSets.GetByName("Keywords");
            ctx.Load(termSet);
            ctx.ExecuteQuery();

            //Check if the given term exists
            Term checkTerm = termSet.GetTerm(termGuid);
            ctx.Load(checkTerm);
            ctx.ExecuteQuery();

            //check if the Term already exists
            if (checkTerm.IsNullOrServerObjectIsNull())
            {
                //Create the term
                Term keyWordTerm = termSet.CreateTerm(term, CultureInfo.CurrentCulture.LCID, termGuid);
                termStore.CommitAll();
                ctx.ExecuteQuery();
            }

        }

        public static string ConcatUrls(params string[] urls)
        {
            return urls.Aggregate((x, y) => ConcatUrlsInner(x, y));
        }
        static string ConcatUrlsInner(string url1, string url2)
        {
            if (String.IsNullOrEmpty(url2))
                return url1;
            if (String.IsNullOrEmpty(url1))
                return url2;
            return url1.TrimEnd('/') + "/" + url2.TrimStart('/');
        }

        public static Web GetSubWebByUrl(ClientContext ctx, Web web, string subWebUrl)
        {
            web.EnsureProperties("ServerRelativeUrl");
            var targetUrl = ConcatUrls(web.ServerRelativeUrl, subWebUrl);
            var webs = ctx.LoadQuery(web.Webs.Include(x => x.ServerRelativeUrl).Where(x => x.ServerRelativeUrl == targetUrl));
            ctx.ExecuteQuery();
            var newsWeb = webs.FirstOrDefault();
            return newsWeb;
        }

        //http://www.andymcm.com/blog/2009/09/building-lambda-expressions-at-runtime.html
        //[Obsolete("not working yet for value types, only for object tyoes",true)]
        /// <summary>
        /// cheks if a specific object is loaded
        /// only works with object properties, primitive are not supported yet
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="obj"></param>
        /// <param name="propertyNames"></param>
        public static void EnsureProperties<T>(this T obj, params string[] propertyNames) where T : ClientObject
        {
            if (propertyNames.Any(x => !obj.IsPropertyAvailable(x)))
            {
                List<Expression<Func<T, object>>> funcsList = new List<Expression<Func<T, object>>>();
                foreach (var propertyName in propertyNames)
                {
                    ParameterExpression p = Expression.Parameter(typeof(T), "p");
                    Expression body = Expression.Property(p, propertyName);
                    var expr = Expression.Lambda<Func<T, object>>(body, p);
                    funcsList.Add(expr);
                }
                obj.Context.Load(obj, funcsList.ToArray());
                obj.Context.ExecuteQuery();
            }
        }

        public static ContentType FindContentType(ClientContext ctx, ContentTypeCollection contentTypes, string contentTypeName, string group = null)
        {
            ctx.Load(contentTypes, types => types.Include
                (type => type.Id, type => type.Name,
                    type => type.Parent));

            IEnumerable<ContentType> query = null;
            if (String.IsNullOrEmpty(@group))
            {
                query = ctx.LoadQuery(contentTypes.Where
                    (c => c.Name == contentTypeName));
            }
            else
            {
                query = ctx.LoadQuery(contentTypes.Where
                    (c => (c.Name == contentTypeName) && (c.Group == @group)));
            }

            ctx.ExecuteQuery();

            ContentType result = query.FirstOrDefault();
            return result;
        }

        public static List GetListByUrl(ClientContext ctx, Web web, string webRelativeUrl)
        {
            var fullUrl = ConcatUrls(web.ServerRelativeUrl, webRelativeUrl);
            //if (!fullUrl.StartsWith("/"))
            //    fullUrl = "/" + webRelativeUrl;

            var alllists = ctx.LoadQuery(web.Lists);
            var existingLists = ctx.LoadQuery(
                    web.Lists.Where(l => l.RootFolder.ServerRelativeUrl == fullUrl)
                    );
            ctx.ExecuteQuery();

            var existingList = existingLists.FirstOrDefault();

            return existingList;

        }

        public static View SafeAddListView(ClientContext ctx, List list, ViewCreationInformation viewCreationInfo, string viewData = null)
        {

            //note there is no easy way to change calendar type to view via CSOM code
            //http://gauravkainth.com/2011/12/14/change-the-view-of-a-calendar-web-part-programmatically/
            //http://www.manvir.net/change-the-default-scope-of-sharepoint-calendar-view-to-week/

            string title = viewCreationInfo.Title;
            var view = GetListViewByTitle(ctx, list, title);


            if (view == null)
            {
                view = list.Views.Add(viewCreationInfo);
                ctx.Load(view);
            }
            else
            {
                view.Title = viewCreationInfo.Title;
                view.ViewQuery = viewCreationInfo.Query;
                view.Paged = viewCreationInfo.Paged;
                view.RowLimit = viewCreationInfo.RowLimit;
                SetViewFields(view, viewCreationInfo.ViewFields);
                view.Update();
            }
            if (!String.IsNullOrEmpty(viewData))
            {
                view.ViewData = viewData;
                view.Update();
            }

            ctx.ExecuteQuery();

            return view;
        }

        public static void SafeDeleteListView(ClientContext context, List list, string viewName)
        {
            var view = GetListViewByTitle(context, list, viewName);

            if (view != null)
            {
                view.DeleteObject();
                list.Update();

                context.ExecuteQuery();
            }
        }

        public static Field AddField(
            FieldCollection fields,
            Guid fieldId,
            FieldType type,
            string fieldTitle,
            string internalName = null,
            string customFieldXML = null,
            bool addToDefaultView = true, AddFieldOptions addFieldOptions = AddFieldOptions.AddToDefaultContentType,
            string group = ""
            )
        {
            var field =
                AddField(
                    fields,
                    fieldId,
                    type.ToString(),
                    fieldTitle,
                    internalName,
                    customFieldXML,
                    addToDefaultView,
                    addFieldOptions,
                    @group
                    );

            if (!field.IsPropertyAvailable("FieldTypeKind"))
            {
                field.Context.Load(field, x => x.FieldTypeKind);
                field.Context.ExecuteQuery();
            }

            if (field.FieldTypeKind != type)
            {
                field.FieldTypeKind = type;
                field.UpdateAndPushChanges(true);
                fields.Context.ExecuteQuery();
            }
            return field;
        }

        public static Field AddField(FieldCollection fields,
            Guid fieldId,
            string type,
            string fieldTitle,
            string internalName = null,
            string customFieldXML = null,
            bool addToDefaultView = true, AddFieldOptions addFieldOptions = AddFieldOptions.AddToDefaultContentType,
            string group = ""
            )
        {
            if (String.IsNullOrEmpty(internalName))
            {
                internalName = fieldTitle;
            }

            //Current web context
            var ctx = fields.Context;

            //get the fields for the given list
            FieldCollection fieldCollection = fields;

            string groupString = String.IsNullOrEmpty(@group) ? "" : String.Format(" Group='{0}'", @group);

            if (String.IsNullOrEmpty(customFieldXML))
            {
                customFieldXML = String.Format("<Field Id='{3:B}'{4} Type='{0}' DisplayName='{1}' Name='{2}' />", type, internalName, internalName, fieldId, groupString);
                //customFieldXML = String.Format("<Field Id='{3:B}' Type='{0}' DisplayName='{1}' Name='{2}' />", type, internalName, internalName, fieldId);
            }
            //TODO:ke this changeable and not only on creation
            if (type == "Note")
            {
                customFieldXML = Utils.SetAttribute(customFieldXML, "RichTextMode",
                    "FullHtml");
                customFieldXML = Utils.SetAttribute(customFieldXML, "RichText",
                    "TRUE");
            }
            if (type == "HTML")
            {
                customFieldXML = Utils.SetAttribute(customFieldXML, "RichTextMode",
                    "ThemeHtml");
                customFieldXML = Utils.SetAttribute(customFieldXML, "RichText",
                    "TRUE");
            }

            // it is not a misprint! we are supplying internal name as displayname. there is a well known sharepoint bug 

            // check if field is already there, first by internalname, then by guid
            var existingFieldQuery1 = ctx.LoadQuery(fields.Where(x => x.InternalName == internalName));
            var existingFieldQuery2 = ctx.LoadQuery(fields.Where(x => x.Id == fieldId));
            ctx.ExecuteQuery();

            //check if field exists
            var existingField = existingFieldQuery1.FirstOrDefault();
            if (existingField.IsNullOrServerObjectIsNull())
            {
                existingField = existingFieldQuery2.FirstOrDefault();
            }
            if (existingField.IsNullOrServerObjectIsNull())
            {
                //Add the XML to the field collection
                existingField = fieldCollection.AddFieldAsXml(customFieldXML, addToDefaultView, addFieldOptions);

                ctx.Load(existingField, x => x.Title, x => x.InternalName);
                ctx.ExecuteQuery();
            }

            existingField.Title = fieldTitle;
            if (!String.IsNullOrEmpty(@group))
            {
                existingField.Group = @group;
            }
            existingField.Update();
            ctx.ExecuteQuery();

            return existingField;
        }
        //TODO: rename string group to string contentTypeGroup
        [Obsolete("ideally this methd should not be used and the fileds shoud be added to content type")]
        public static void AddTaxonomyFieldToContentType(Web web, ContentType contentType, Guid fieldId, string group,
            string internalName, string title, Guid termStoreId, Guid termSetId)
        {
            var ctx = web.Context;
            //debug
            var allfields = ctx.LoadQuery(web.Fields);
            var allafields = ctx.LoadQuery(web.AvailableFields);
            ctx.ExecuteQuery();

            // check if field is already there
            var existingFieldQuery = ctx.LoadQuery(web.Fields.Where(x => x.Id == fieldId));
            ctx.ExecuteQuery();
            var existingField = existingFieldQuery.FirstOrDefault();
            if (existingField == null)
            {

                var def1 =
                    "<Field Type=\"TaxonomyFieldType\" Group=\"{2}\" DisplayName=\"{1}\" ShowField=\"Term1033\" Required=\"FALSE\" EnforceUniqueValues=\"FALSE\" ID=\"{0:B}\" StaticName=\"{1}\" Name=\"{1}\"></Field>";
                var definition = String.Format(def1, fieldId, internalName, @group);
                existingField = web.Fields.AddFieldAsXml(definition, true, AddFieldOptions.AddToAllContentTypes);
                ctx.Load(existingField, x => x.Id);
                ctx.ExecuteQuery();
                //existingFieldQuery = ctx.LoadQuery(web.Fields.Where(x => x.Id == fieldId));
                //existingField = existingFieldQuery.FirstOrDefault();
                //ctx.ExecuteQuery();

            }


            var taxField = ctx.CastTo<TaxonomyField>(existingField);
            taxField.Title = title;
            taxField.SspId = termStoreId;
            taxField.TermSetId = termSetId;
            taxField.Update();
            ctx.ExecuteQuery();

            var alllinks = ctx.LoadQuery(contentType.FieldLinks.Include(x => x.Id, x => x.Name));
            AddFieldLinkToContentType(contentType, taxField);
        }

        public static void SafeAddContentTypeToList(ClientContext ctx, List list, ContentType contentType)
        {
            list.EnsureProperties("ContentTypes");
            if (!list.ContentTypes.Any(x => x.StringId.StartsWith(contentType.StringId)))
            {
                // disabled  for a while - removing standard content types
                //var allContentTypes = list.ContentTypes.ToArray();
                //foreach (var ct in allContentTypes)
                //{
                //    if (!ct.StringId.StartsWith(FrameWork.FolderContentTypeId))
                //        ct.DeleteObject();
                //}

                list.ContentTypes.AddExistingContentType(contentType);
                list.Update();
                ctx.ExecuteQuery();
            }
        }

        public static void SafeRemoveListContentType(ClientContext context, List list, string contentTypeName)
        {
            list.EnsureProperties("ContentTypes");
            var contentType = list.ContentTypes.FirstOrDefault(ct => ct.Name == contentTypeName);
            if (contentType != null)
            {
                contentType.DeleteObject();
            }

            list.Update();
            context.ExecuteQuery();
        }

        public static void AddFieldLinkToContentType(ContentType contentType, Field field)
        {
            var ctx = contentType.Context;
            var existingFieldLinks =
                ctx.LoadQuery(contentType.FieldLinks.Include(x => x.Id, x => x.Name).Where(x => x.Id == field.Id));
            ctx.ExecuteQuery();
            var existingFieldLink = existingFieldLinks.FirstOrDefault();
            if (existingFieldLink == null)
            {
                FieldLinkCreationInformation f = new FieldLinkCreationInformation();
                f.Field = field;
                contentType.FieldLinks.Add(f);
                try
                {
                    contentType.Update(true);
                    ctx.ExecuteQuery();
                }
                catch (Exception ex)
                {
                    if (ex.Message == "The content type has no children.")
                    {
                        //TODO: configure separate trace source for information
                        //Trace.TraceWarning("content type {0} has no children", contentType.Name);
                        // try again 
                        contentType.FieldLinks.Add(f);
                        contentType.Update(false);
                        ctx.ExecuteQuery();
                    }
                    else
                    {
                        throw;
                    }
                }
            }
        }

        public static List SafeAddList(ClientContext ctx, Web web, ListCreationInformation listCreationInfo)
        {
            web.EnsureProperties("ServerRelativeUrl");
            Trace.TraceInformation("SafeAddList web:{0}  title:{1} webRelativeUrl:{2} listtemplate:{3}", web.ServerRelativeUrl, listCreationInfo.Title, listCreationInfo.Url, listCreationInfo.TemplateType);

            var existingList = GetListByUrl(ctx, web, listCreationInfo.Url);
            if (existingList == null)
            {
                existingList = web.Lists.Add(listCreationInfo);
                ctx.Load(existingList);
                ctx.Load(existingList.RootFolder);
            }
            else
            {
                existingList.Title = listCreationInfo.Title;
                if (listCreationInfo.Description != null)
                {
                    existingList.Description = listCreationInfo.Description;
                }
                existingList.OnQuickLaunch = listCreationInfo.QuickLaunchOption == QuickLaunchOptions.On;
                existingList.Update();
            }
            ctx.ExecuteQuery();

            return existingList;
        }
        public static void SetViewFields(View view, String[] fields)
        {
            view.ViewFields.RemoveAll();
            foreach (var viewfield1 in fields)
            {
                view.ViewFields.Add(viewfield1);
            }
        }
        public static View GetListViewByTitle(ClientContext ctx, List list, string title)
        {
            var existingViews = ctx.LoadQuery(
                list.Views.Where(v => v.Title == title)
                );
            ctx.ExecuteQuery();
            var view = existingViews.FirstOrDefault();
            return view;
        }

        public static void AddOrUpdatePublishingPage(ClientContext ctx, Web web,
            string pageFileName, string title, string layoutFileName, string pagesTitle = "Pages")
        {
            Trace.TraceInformation("AddOrUpdatePublishingPage web:{0}  title:{1} pageFileName:{2} ", web.ServerRelativeUrl,
                title, pageFileName);

            PublishingWeb publishingWeb = PublishingWeb.GetPublishingWeb(ctx, web);
            var rootWeb = ctx.Site.RootWeb;
            rootWeb.EnsureProperties("ServerRelativeUrl", "Url");
            //ctx.Load(rootWeb, x => x.Url, x => x.ServerRelativeUrl);
            //ctx.ExecuteQuery();
            var file =
                rootWeb.GetFileByServerRelativeUrl(ConcatUrls(rootWeb.ServerRelativeUrl,
                    "/_catalogs/masterpage/", layoutFileName));
            var layout = file.ListItemAllFields;

            ctx.Load(layout);

            ctx.ExecuteQuery();

            ExceptionHandlingScope scope = new ExceptionHandlingScope(ctx);

            File publishingPageFile = null;

            web.EnsureProperties("ServerRelativeUrl");
            //ctx.Load(web,w=>w.ServerRelativeUrl);
            //ctx.ExecuteQuery();

            publishingPageFile =
                web.GetFileByServerRelativeUrl(ConcatUrls(web.ServerRelativeUrl, "Pages", pageFileName));
            ctx.Load(publishingPageFile);
            try
            {
                ctx.ExecuteQuery();
            }
            catch (Exception e)
            {
                //TODO: configure separate trace source for information
                //Trace.TraceWarning("exception when  checking the file, might be file does not exist? Exception:{0}", e);
                publishingPageFile = null;
            }
            if ((publishingPageFile != null) && (!publishingPageFile.Exists))
                publishingPageFile = null;

            if (publishingPageFile == null)
            {
                // Create a publishing page

                var publishingPageInfo = new PublishingPageInformation
                {
                    Name = pageFileName,
                    PageLayoutListItem = layout
                };


                PublishingPage publishingPage = publishingWeb.AddPublishingPage(publishingPageInfo);

                publishingPageFile = publishingPage.ListItem.File;

                ctx.Load(publishingPage);
                ctx.Load(publishingPage, x => x.ListItem);

                ctx.Load(publishingPage.ListItem.File, obj => obj.ServerRelativeUrl);

            }
            ctx.Load(publishingPageFile, x => x.ListItemAllFields);
            ctx.Load(publishingPageFile, x => x.CheckOutType);
            ctx.ExecuteQuery();

            if (publishingPageFile.CheckOutType == CheckOutType.None)
                publishingPageFile.CheckOut();
            publishingPageFile.EnsureProperties("ListItemAllFields");

            ctx.Load(publishingPageFile.ListItemAllFields);
            ctx.ExecuteQuery();

            // update publishing page
            publishingPageFile.ListItemAllFields["Title"] = title;
            publishingPageFile.ListItemAllFields.Update();

            publishingPageFile.CheckIn(String.Empty, CheckinType.MajorCheckIn);

            publishingPageFile.Publish(String.Empty);

            //TODO: only add approval if it is enabled
            //publishingPage.ListItem.File.Approve(string.Empty);

            ctx.ExecuteQuery();

        }

        public static NavigationNode AddOrUpdateLink(Web web, NavigationNodeCollection navigationNodeCollection,
            string title, string fullUrl, bool isExternal = false)
        {
            var node = navigationNodeCollection.Where(x => x.Url == fullUrl).FirstOrDefault();
            if (node == null)
            {
                NavigationNodeCreationInformation info = new NavigationNodeCreationInformation()
                {
                    Title = title,
                    Url = fullUrl,
                    IsExternal = isExternal,
                    AsLastNode = true
                };
                node = navigationNodeCollection.Add(info);
            }
            else
            {
                node.Title = title;
                node.IsVisible = true;
                node.Update();
            }
            web.Update();
            web.Context.Load(navigationNodeCollection);
            return node;
        }


    }
}
