using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace Presentation.Taxonomy.Console
{
    public class Utils
    {
        public static string SetAttribute(string xmlSource, string attribute, string value)
        {
            XElement x = XElement.Parse(xmlSource);
            x.SetAttributeValue(attribute, value);

            return x.ToString();
        }
    }
}
