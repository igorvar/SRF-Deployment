using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using OpenMcdf;

namespace SrfCompileInfo
{
    
    public struct CompileInfo
    {
        private static DateTime D70 = new DateTime(1970, 1, 1, 0, 0, 0);
        internal CompileInfo(string userName, string languageCode, string pcName, uint compilationAgeSeconds)
        {
            int folderSuffix = 0;
            UserName = userName;
            LanguageCode = languageCode;
            PcName = pcName;
            CompilationDate = D70.AddSeconds(compilationAgeSeconds).ToLocalTime();
            IsFullCompile = false;
            foreach (char c in userName.ToCharArray())
                folderSuffix += (byte)c;
            JsFolderName = $"srf{ compilationAgeSeconds.ToString()}_{folderSuffix.ToString()}";
    }
        /// <summary>
        /// Name of the user who executed compilation (SADMIN)
        /// </summary>
        public string UserName { get; }
        /// <summary>
        /// Language code (ENU)
        /// </summary>
        public string LanguageCode { get; }
        /// <summary>
        /// The name of the computer on which compiling (SIEBELAPPDEV)
        /// </summary>
        public string PcName { get; }
        /// <summary>
        /// LocalTime of compilation
        /// </summary>
        public DateTime CompilationDate { get; }
        public bool IsFullCompile { get; internal set; }
        /// <summary>
        /// Folder containing browser scripts (srf1625479050_444)
        /// </summary>
        public string JsFolderName { get; }
        public override string ToString()
        {
            return $"IsFullCompile: {IsFullCompile}\nLanguageCode: {LanguageCode}\nCompilationDate: {CompilationDate.ToString("yyyy-MM-dd HH:mm:ss")}\nUser: {UserName}\nPcName: {PcName}\nJsFolder: {JsFolderName}";
        }
    }
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Siebel SRF file compilation info");
            string s;
            s = System.IO.Path.GetFileName(System.Reflection.Assembly.GetEntryAssembly().Location);
            string fileSrf;
            CompoundFile cf = null;
            if (args.Length == 0)
            {
                Console.WriteLine("Execution in from command line:");
                Console.WriteLine($"{System.IO.Path.GetFileName(System.Reflection.Assembly.GetEntryAssembly().Location)} <SrfFile>");
                Console.Write("SrfFile: ");
                fileSrf = Console.ReadLine();
            }
            else
                fileSrf = args[0];

            if (!System.IO.File.Exists(fileSrf))
                throw new System.IO.FileNotFoundException("Not found file", fileSrf);
            //CompoundFile cf = new CompoundFile(@"c:\Siebel\15.0.0.0.0\Client\objects\HEB\siebel_sia.srf");
            try
            {
                cf = new CompoundFile(fileSrf);
            }
            catch (CFFileFormatException ex)
            {
                throw new System.IO.InvalidDataException($"Invalid SRF file {fileSrf}", ex);
            }
            CFItem compileDataStream;
            bool isFullCompile;
            IList<OpenMcdf.CFItem> items = cf.GetAllNamedEntries("Last Incr. Compile");//[0];

            if (items.Count == 0)
            {
                try
                {
                    compileDataStream = cf.GetAllNamedEntries("Full Compile")[0];
                }
                catch (ArgumentOutOfRangeException /*ex*/)
                {
                    throw new System.IO.InvalidDataException($"Invalid SRF File {fileSrf}. Not contain compilation info");
                }
                isFullCompile = true;
            }
            else
            {
                compileDataStream = items[0];
                isFullCompile = false;
            }
            CFStream stream = compileDataStream as CFStream;// = new CFStream();
            CompileInfo ci = ParseStream(stream);
            cf.Close();
            ci.IsFullCompile = isFullCompile;
            if (args.Length > 0) Console.WriteLine(fileSrf);
            Console.WriteLine(ci);
            if (args.Length > 0) Console.ReadLine();
            
        }
        static CompileInfo ParseStream(CFStream stream )
        {
            byte[] compileTimeStampBytes = new byte[4];
            byte[] userNameBytes = new byte[32];
            byte[] pcNameBytes = new byte[128];
            byte[] langBytes = new byte[4];
            ASCIIEncoding ascii = new ASCIIEncoding();
            stream.Read(compileTimeStampBytes, 4, compileTimeStampBytes.Length);
            stream.Read(pcNameBytes, 8, pcNameBytes.Length);
            stream.Read(langBytes, 0x88, langBytes.Length);
            stream.Read(userNameBytes, 0x8c, userNameBytes.Length);

            CompileInfo ci = new CompileInfo(
                ascii.GetString(userNameBytes, 0, Array.IndexOf(userNameBytes, (byte)0)),
                ascii.GetString(langBytes, 0, Array.IndexOf(langBytes, (byte)0)),
                ascii.GetString(pcNameBytes, 0, Array.IndexOf(pcNameBytes, (byte)0)),
                BitConverter.ToUInt32(compileTimeStampBytes, 0)
                );

            return ci;

        }
        //static void ReadBin()
        //{
        //    string file = @"\\siebelappdev02\d$\Siebel\15.0.0.0.0\ses\siebsrvr\OBJECTS\enu\Full Compile";
        //    byte[] compileTimeStampBytes = new byte[4];
        //    DateTime compileTimeStamp;
        //    byte[] userNameBytes = new byte[32];
        //    string userName;
        //    byte[] pcNameBytes = new byte[128];
        //    string pcName;
        //    byte[] langBytes = new byte[4];
        //    string lang;
        //    int folderSuffix = 0;
        //    string bsFolderName;
        //    using (System.IO.FileStream fs = new System.IO.FileStream(file, System.IO.FileMode.Open, System.IO.FileAccess.Read))
        //    {
        //        fs.Seek(4, System.IO.SeekOrigin.Begin);     fs.Read(compileTimeStampBytes, 0, compileTimeStampBytes.Length);
        //        fs.Seek(8, System.IO.SeekOrigin.Begin);     fs.Read(pcNameBytes, 0, pcNameBytes.Length);
        //        fs.Seek(0x88, System.IO.SeekOrigin.Begin);  fs.Read(langBytes, 0, langBytes.Length);
        //        fs.Seek(0x8c, System.IO.SeekOrigin.Begin);  fs.Read(userNameBytes, 0, userNameBytes.Length);
        //    }
        //    uint ageOfCompilation = BitConverter.ToUInt32(compileTimeStampBytes, 0);

        //    foreach (byte a in userNameBytes)
        //    {
        //        if (a == 0) break;
        //        folderSuffix += a;
        //    }
        //    bsFolderName = "srf" + ageOfCompilation.ToString() + "_" + folderSuffix;
        //    ASCIIEncoding ascii = new ASCIIEncoding();
        //    pcName = ascii.GetString(pcNameBytes, 0, Array.IndexOf(pcNameBytes, (byte)0));
        //    lang = ascii.GetString(langBytes, 0, Array.IndexOf(langBytes, (byte)0));
        //    userName = ascii.GetString(userNameBytes, 0, Array.IndexOf(userNameBytes, (byte)0));
        //    compileTimeStamp = UnixTimeToDate(ageOfCompilation).ToLocalTime();
        //}

        static DateTime UnixTimeToDate(long UnixTime)
        {
            DateTime d70 = new DateTime(1970, 1, 1, 0, 0, 0/*, DateTimeKind.Utc*/);
            return d70.AddSeconds(UnixTime);
        }
        
    }
}
