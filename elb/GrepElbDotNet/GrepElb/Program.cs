using System;
using System.Collections.Generic;
using System.Configuration;
using System.Diagnostics;
using System.IO;
using System.Linq;

namespace GrepElb
{
    internal class Program
    {
        private static string _path = ConfigurationManager.AppSettings["Path"];
        private static string _searchPattern = ConfigurationManager.AppSettings["SearchPattern"];
        private static float _threshold = float.Parse(ConfigurationManager.AppSettings["Threshold"]);
        private static bool _compareElbInternalProcessingTime = bool.Parse(ConfigurationManager.AppSettings["CompareElbInternalProcessingTime"]);
        private static bool _compareElbBackendProcessingTime = bool.Parse(ConfigurationManager.AppSettings["CompareElbBackendProcessingTime"]);
        private static bool _compareElbResponseProcessingTime = bool.Parse(ConfigurationManager.AppSettings["CompareElbResponseProcessingTime"]);
        private static bool _outputVerbose = bool.Parse(ConfigurationManager.AppSettings["Verbose"]);

        private static void Main(string[] args)
        {
            // Override config by passing some parameters, if you fancy.
            ParseCommandLineArgs(args);

            var files = Directory.GetFiles(_path, _searchPattern);

            if (!files.Any())
            {
                Console.WriteLine("No files found at {0} with search pattern {1}", _path, _searchPattern);
                if (Debugger.IsAttached)
                {
                    Console.WriteLine("Press any key to exit");
                    Console.ReadKey();
                    Environment.Exit(-1);
                }
            }

            foreach (var filePath in files)
            {
                Console.WriteLine("---------- {0} ----------", filePath);
                Console.WriteLine(filePath);

                string line;

                StreamReader file = new StreamReader(filePath);

                while ((line = file.ReadLine()) != null)
                {
                    try
                    {
                        ParseLine(line);
                    }
                    catch (Exception)
                    {
                        Console.ForegroundColor = ConsoleColor.Red;
                        Console.WriteLine("Failed to parse line {0}", line);
                        Console.ResetColor();
                    }
                }
            }

            Console.WriteLine("---------- Completed ----------");

            if (Debugger.IsAttached)
            {
                Console.WriteLine("Press any key to exit");
                Console.ReadKey();
            }
        }

        private static void ParseLine(string line)
        {
            const string notSet = " - ";
            string
                elbInternalProcessingTime = notSet,
                elbBackendProcessingTime = notSet,
                elbResponseProcessingTime = notSet;

            var items = line.Split(' ');
            string
                date = items[0],
                elb = items[1],
                clientip = items[2],
                referrer = items[3],
                requestProcessingTime = items[4],
                backendProcessingTime = items[5],
                responseProcessingTime = items[6],
                elbstatus = items[7],
                backendstatus = items[8],
                rbytes = items[9],
                sbytes = items[10],
                verb = items[11],
                url = items[12];

            if (_compareElbInternalProcessingTime && (float.Parse(requestProcessingTime) > _threshold))
            {
                elbInternalProcessingTime = requestProcessingTime;
            }

            if (_compareElbBackendProcessingTime && (float.Parse(backendProcessingTime) > _threshold))
            {
                elbBackendProcessingTime = backendProcessingTime;
            }

            if (_compareElbResponseProcessingTime && (float.Parse(responseProcessingTime) > _threshold))
            {
                elbResponseProcessingTime = responseProcessingTime;
            }

            if (elbInternalProcessingTime != notSet || elbBackendProcessingTime != notSet || elbResponseProcessingTime != notSet)
            {
                if (_outputVerbose)
                {
                    Console.WriteLine(line);
                }
                else
                {
                    Console.WriteLine("{0} {1} {2} {3} {4} ({5})",
                        date,
                        elbInternalProcessingTime,
                        elbInternalProcessingTime,
                        elbResponseProcessingTime,
                        url,
                        backendstatus);
                }
            }
        }

        private static void ParseCommandLineArgs(string[] args)
        {
            var arguments = new Dictionary<string, string>();

            foreach (string argument in args)
            {
                string[] splitArgs = argument.Split('=');

                if (splitArgs.Length == 1)
                {
                    arguments[splitArgs[0]] = "";
                }
                else if (splitArgs.Length == 2)
                {
                    arguments[splitArgs[0]] = splitArgs[1];
                }
            }

            foreach (var item in arguments)
            {
                switch (item.Key)
                {
                    case "-1":
                        _compareElbInternalProcessingTime = true;
                        break;

                    case "-2":
                        _compareElbBackendProcessingTime = true;
                        break;

                    case "-3":
                        _compareElbResponseProcessingTime = true;
                        break;

                    case "-verbose":
                    case "--verbose":
                        _outputVerbose = true;
                        break;

                    case "-threshold":
                    case "--threshold":
                        _threshold = float.Parse(item.Value);
                        break;

                    case "-path":
                    case "--path":
                        _path = item.Value;
                        break;

                    case "-searchpattern":
                    case "--searchpattern":
                        _searchPattern = item.Value;
                        break;
                }
            }
        }
    }
}