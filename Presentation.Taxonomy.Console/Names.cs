using Microsoft.SharePoint.Client;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Presentation.Taxonomy.Console
{
    class Names
    {
        internal class TermSet
        {
            public Guid Id = default(Guid);
            public string Name = string.Empty;
            public List<Term> Terms = new List<Term>();
        }
        internal class Term
        {
            public Guid Id = default(Guid);
            public string Name = string.Empty;
        }

        internal class NavigationTermSet
        {
            public Guid Id = default(Guid);
            public string Name = string.Empty;
            public string SimpleLinkUrl = string.Empty;
            public List<NavigationTerm> Terms = new List<NavigationTerm>();
        }

        internal class NavigationTerm
        {
            public Guid Id = default(Guid);
            public string Name = string.Empty;
            public string SimpleLinkUrl = string.Empty;
        }

        public class NavigationTaxonomy
        {
            public const string rootGroupName = "Sukul Navigation";
            public const string rootGroupId = "9365F384-4174-4E15-B491-72D5567052A5";
            public const string SimpleLinkUrl = "~site/Pages/Default.aspx";

            private static NavigationTaxonomy _instance = null;
            public static NavigationTaxonomy Instance
            {
                get
                {
                    if (_instance == null)
                    {
                        _instance = new NavigationTaxonomy();
                    }
                    return _instance;
                }
            }
            private NavigationTaxonomy()
            {
                TermSets = new List<NavigationTermSet>() { 
                new NavigationTermSet
                {
                    Id = new Guid("{ACA420FD-4CFF-4723-B9B1-BE15F86A27B5}"),
                    Name = "Rooms",
                    SimpleLinkUrl = "/Rooms",
                    Terms = new List<NavigationTerm>()
                                {
                                new NavigationTerm { Id = new Guid("{1C76D00A-A5E8-47E5-961B-421AD4DF16A2}"), Name = "Toddler 1", SimpleLinkUrl="/Rooms/Pages/Toddler1.aspx" },
                                new NavigationTerm { Id = new Guid("{4833BE43-D55F-408C-82A5-288B9FDB8736}"), Name = "Toddler 2", SimpleLinkUrl="/Rooms/Pages/Toddler3.aspx" },
                                new NavigationTerm { Id = new Guid("{4016AAD3-F364-4862-B39A-A8FBE9DD551F}"), Name = "Pre Kinder", SimpleLinkUrl="/Rooms/Pages/PreKinder.aspx" },
                                new NavigationTerm { Id = new Guid("{3B13EE65-189B-4A77-A95D-844A8AE0F4E6}"), Name = "Kindergarden", SimpleLinkUrl="/Rooms/Pages/Kindergarden.aspx" }
                                }
                    },
                    new NavigationTermSet
                    {
                        Id = new Guid("{6A12DD97-8139-4056-94F3-8019E84D6E44}"),
                        Name = "About Us",
                        SimpleLinkUrl = "/Pages/About.aspx"
                    },
                    new NavigationTermSet
                    {
                        Id = new Guid("{8996EA6B-67F0-4235-9439-3C33CBC1D0BE}"),
                        Name = "Our Mission",
                        SimpleLinkUrl = "/Pages/Mission.aspx"
                    },
                    new NavigationTermSet
                    {
                        Id = new Guid("{64502769-753D-4643-A381-1DA41A4E732D}"),
                        Name = "Our Carers",
                        SimpleLinkUrl = "/Pages/Carers.aspx"
                    },
                    new NavigationTermSet
                    {
                        Id = new Guid("{BB320A30-9AE6-4BDB-807F-6EBB0B9F44AF}"),
                        Name = "Contact Us",
                        SimpleLinkUrl = "/Pages/Contact.aspx"
                    }
                };
            }

            public List<NavigationTermSet> TermSets = new List<NavigationTermSet>();
        }
        public class Taxonomy
        {
            public const string rootGroupName = "Sukul Terms";
            public static Guid rootGroupId = new Guid("{1E6297EB-9782-4690-862E-9608B190DE8A}");
            public static List<TermSet> TermSets = new List<TermSet>() { new TermSet
                {
                    Id = new Guid("{F6D8E1B6-78C7-4F85-9773-3BA601AD0196}"),
                    Name = "Rooms",
                    Terms = new List<Term>()
                                {
                                new Term { Id = new Guid("{56CE1A58-74FA-4490-996B-BF94AF820553}"), Name = "Infant" }, 
                                new Term { Id = new Guid("{17ED26F0-B17B-4FEF-A374-7D8C80D4BBBC}"), Name = "Toddler 1" }, 
                                new Term { Id = new Guid("{6E48A9CC-42B3-4611-85C7-31CBBC737829}"), Name = "Toddler 2" }, 
                                new Term { Id = new Guid("{4E0EE5BE-4F00-4B55-8B0B-1388819AAF2B}"), Name = "Pre Kinder" }, 
                                new Term { Id = new Guid("{6EAAC0B0-AD09-41B8-8888-2977FBC6342A}"), Name = "Kindergarden" } 
                                }
                },
                new TermSet
                {
                    Id = new Guid("{939E25A2-CA80-4A4D-895C-FFA2790FD23D}"),
                    Name = "PottyType",
                    Terms = new List<Term>()
                    {
                        new Term { Id = new Guid("{32768B71-18B0-43D1-B1DA-4759E852A3F4}"), Name="Wee" },
                        new Term { Id = new Guid("{807313AC-788F-47C6-91E4-32AE95E4ED6D}"), Name="Poo" },
                        new Term { Id = new Guid("{33B94B00-23E0-4FA8-AEB0-B101D36E1800}"), Name="Both" },
                    }
                },
                new TermSet
                {
                    Id = new Guid("{BFE6D355-4566-491A-8C57-FDE0233E56A2}"),
                    Name = "GuardianType",
                    Terms = new List<Term>()
                    {
                        new Term { Id = new Guid("{3675028F-954E-4EDF-A0D5-2281E62683BA}"), Name="Father" },
                        new Term { Id = new Guid("{FAB1ED28-B80D-4F6B-9F00-B39B9DE25D4D}"), Name="Mother" },
                        new Term { Id = new Guid("{B33535B0-D1F1-421E-935B-01E714FE16DB}"), Name="Grandfather" },
                        new Term { Id = new Guid("{DC96DB7D-F914-43AF-AE6D-22873D31276E}"), Name="Grandmother" },
                        new Term { Id = new Guid("{31167E00-50ED-4327-B842-5C9FF222B7C6}"), Name="Uncle" },
                        new Term { Id = new Guid("{2012199E-C206-410D-8C3F-45259A8065DB}"), Name="Aunt" },
                        new Term { Id = new Guid("{87E10A10-EEE6-47B0-9EF6-500346295552}"), Name="Other" },
                    }
                }
            };
        }


        public class ListTaxonomy
        {
            public static List<List> Lists = new List<List>()
            {
                new List() { ListUrl="Lists/Staff", ListTitle="Staff", ListTemplate = ListTemplateType.GenericList, ContentTypeName = "Staff", ListLevel=1 },
                new List() { ListUrl="Lists/Guardians", ListTitle="Guardians", ListTemplate = ListTemplateType.GenericList, ContentTypeName = "Guardian", ListLevel=1 },
                new List() { ListUrl="Lists/Kids", ListTitle="Kids", ListTemplate = ListTemplateType.GenericList, ContentTypeName = "Child", ListLevel=2 },
                new List() { ListUrl="Lists/Potty", ListTitle="Potty", ListTemplate = ListTemplateType.GenericList, ContentTypeName = "Potty", ListLevel=3 },
                new List() { ListUrl="Lists/Attendance", ListTitle="Attendance", ListTemplate = ListTemplateType.GenericList, ContentTypeName = "Attendance", ListLevel=3 },
                new List() { ListUrl="Lists/Roster", ListTitle="Roster", ListTemplate = ListTemplateType.GenericList, ContentTypeName = "Roster", ListLevel=3 }
            };
        }

        public class List
        {
            public string WebUrl = string.Empty;
            public string ListUrl = string.Empty;
            public string ListTitle = string.Empty;
            public ListTemplateType ListTemplate;
            public string ContentTypeName = string.Empty;
            public int ListLevel = 3;

        }
    }
}
