using System;
using System.Diagnostics;

namespace Presentation.Taxonomy.Console
{
    public static class Log
    {
        public static void TraceInformation(string str, params object[] args)
        {
            TraceInformation(ConsoleColor.Yellow, str, args);
        }
        public static void TraceInformation(ConsoleColor color, string str, params object[] args)
        {
            var oldColor = System.Console.ForegroundColor;
            System.Console.ForegroundColor = color;
            Trace.TraceInformation(str, args);
            System.Console.ForegroundColor = oldColor;
        }

        public static void TraceError(string str, params object[] args)
        {
            var oldColor = System.Console.ForegroundColor;
            System.Console.ForegroundColor = ConsoleColor.Red;
            Trace.TraceError(str, args);
            System.Console.ForegroundColor = oldColor;
        }
    }

}
