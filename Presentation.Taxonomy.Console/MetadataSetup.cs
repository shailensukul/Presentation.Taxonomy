using System;
using System.Diagnostics;
using System.Threading;
using Microsoft.SharePoint.Client;
using Microsoft.SharePoint.Client.Publishing.Navigation;
using Microsoft.SharePoint.Client.Taxonomy;

namespace Presentation.Taxonomy.Console
{
    public class MetadataSetup
    {
        private readonly Func<ClientContext> getContext;

        public MetadataSetup(Func<ClientContext> getContext)
        {
            this.getContext = getContext;
        }

        public void Execute()
        {
            try
            {
                Log.TraceInformation(ConsoleColor.Magenta, "Building Taxonomy");

                using (var context = getContext())
                {
                    BuildTaxonomy(context);
                }
                using (var context = getContext())
                {
                    BuildManagedNavigation(context);
                }
            }
            catch (Exception ex)
            {
                System.Console.WriteLine(ex.Message);
                throw ex;
            }
        }

        public void GetSSPID()
        {
            using (var clientContext = getContext())
            {
                var taxonomySession = TaxonomySession.GetTaxonomySession(clientContext);
                taxonomySession.UpdateCache();

                clientContext.Load(taxonomySession, ts => ts.TermStores);
                clientContext.ExecuteQuery();

                if (taxonomySession.TermStores.Count == 0)
                    throw new InvalidOperationException("The Taxonomy Service is offline or missing");

                var termStore = taxonomySession.TermStores[0];
                clientContext.Load(termStore,
                ts => ts.Name,
                ts => ts.WorkingLanguage);

                System.Console.WriteLine("SSPID: " + termStore.Id);
            }
        }

        private void BuildManagedNavigation(ClientContext clientContext)
        {
            var taxonomySession = TaxonomySession.GetTaxonomySession(clientContext);
            taxonomySession.UpdateCache();

            clientContext.Load(taxonomySession, ts => ts.TermStores);
            clientContext.ExecuteQuery();

            if (taxonomySession.TermStores.Count == 0)
                throw new InvalidOperationException("The Taxonomy Service is offline or missing");

            var termStore = taxonomySession.TermStores[0];
            clientContext.Load(termStore,
            ts => ts.Name,
            ts => ts.WorkingLanguage);

            // Does the TermSet object already exist?
            TermSet existingTermSet;

            // Handles an error that occurs if the return value is null.
            var exceptionScope = new ExceptionHandlingScope(clientContext);
            using (exceptionScope.StartScope())
            {
                using (exceptionScope.StartTry())
                {
                    existingTermSet = termStore.GetTermSet(Guid.NewGuid());
                }
                using (exceptionScope.StartCatch())
                {
                }
            }
            clientContext.ExecuteQuery();

            if (!existingTermSet.ServerObjectIsNull.Value)
            {
                Log.TraceInformation("CreateNavigationTermSet(): Deleting old TermSet");
                existingTermSet.DeleteObject();
                termStore.CommitAll();
                clientContext.ExecuteQuery();
            }

            Log.TraceInformation("CreateNavigationTermSet(): Creating new TermSet");

            // Creates a new TermSet object.
            var siteCollectionGroup = termStore.GetSiteCollectionGroup(clientContext.Site,
                createIfMissing: true);
            var termSet = siteCollectionGroup.CreateTermSet(Names.NavigationTaxonomy.rootGroupName,
                Guid.NewGuid(), termStore.WorkingLanguage);

            termStore.CommitAll();
            clientContext.ExecuteQuery();

            var navTermSet = NavigationTermSet.GetAsResolvedByWeb(clientContext, termSet,
                clientContext.Web, "GlobalNavigationTaxonomyProvider");

            navTermSet.IsNavigationTermSet = true;
            navTermSet.TargetUrlForChildTerms.Value = Names.NavigationTaxonomy.SimpleLinkUrl;

            termStore.CommitAll();
            clientContext.ExecuteQuery();

            NavigationTerm term1 = null;
            NavigationTerm childTerm = null;
            // Menu
            foreach (var ts in Names.NavigationTaxonomy.Instance.TermSets)
            {
                term1 = navTermSet.CreateTerm(ts.Name, NavigationLinkType.SimpleLink, Guid.NewGuid());
                term1.SimpleLinkUrl = ts.SimpleLinkUrl;

                foreach (var t in ts.Terms)
                {
                    childTerm = term1.CreateTerm(t.Name, NavigationLinkType.SimpleLink, Guid.NewGuid());
                    childTerm.SimpleLinkUrl = t.SimpleLinkUrl;

                    childTerm.GetTaxonomyTerm().TermStore.CommitAll();
                }
            }

            clientContext.ExecuteQuery();
        }

        private static void BuildTaxonomy(ClientContext ctx)
        {
            var ts = TaxonomySession.GetTaxonomySession(ctx);
            ctx.Load(ts, x => x.TermStores);
            ctx.ExecuteQuery();
            ctx.Load(ts.TermStores[0], x => x.Groups);
            ctx.ExecuteQuery();

            bool update = false;
#if DEBUG
            update = true;
#endif
            var pwcsGroup = FrameWork.AddOrFindTermGroup(ts.TermStores[0], Names.Taxonomy.rootGroupName, Names.Taxonomy.rootGroupId, update);
            Trace.Indent();
            foreach (var termSet in Names.Taxonomy.TermSets)
            {
                var tset = FrameWork.AddOrFindTermSet(pwcsGroup, termSet.Name, termSet.Id, false, update);
                foreach (var term in termSet.Terms)
                {
                    FrameWork.AddOrFindTerm(tset, term.Name, term.Id, update);
                }
                Trace.Unindent();
            }
        }
    }
}
