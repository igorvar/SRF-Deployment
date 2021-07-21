using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Management.Automation; //C:\WINDOWS\assembly\GAC_MSIL\System.Management.Automation\1.0.0.0__31bf3856ad364e35\System.Management.Automation.dll
                                    //using SrfCompileInfo;
using OpenMcdf;


//Based on https://www.red-gate.com/simple-talk/development/dotnet-development/using-c-to-create-powershell-cmdlets-the-basics/#first
/// <summary>
/// Name space comments
/// </summary>
namespace SrfCompileInfo
{

    /// <summary>
    /// <para type="synopsis">This is the cmdlet synopsis.</para>
    /// <para type="description">This is part of the longer cmdlet description.</para>
    /// <para type="description">Also part of the longer cmdlet description.</para>
    /// </summary>
    [Cmdlet(VerbsCommon.Get, "SrfData")]
    [OutputType(typeof(SrfCompileData))]
    public class GetSrfDataCmdlet : Cmdlet
    {
        [Parameter(ValueFromPipeline = true, Mandatory = true, Position = 0)]
        public string SrfFile { get; set; }
        protected override void BeginProcessing()
        {
            //WriteObject($"SrfName:{SrfFile}");
            base.BeginProcessing();
        }
        protected override void ProcessRecord()
        {
            //base.ProcessRecord();
            //WriteObject($"Process record. Srf{SrfFile}");
            CompoundFile cf = null;
            try
            {
                bool isFullCompile;
                CFItem compileDataStream;
                if (!System.IO.File.Exists(SrfFile))
                    throw new System.IO.FileNotFoundException("Not found file", SrfFile);
                cf = new CompoundFile(SrfFile);
                IList<OpenMcdf.CFItem> items = cf.GetAllNamedEntries("Last Incr. Compile");
                if (items.Count == 0)
                {
                    compileDataStream = cf.GetAllNamedEntries("Full Compile")[0];
                    isFullCompile = true;
                }
                else
                {
                    compileDataStream = items[0];
                    isFullCompile = false;
                }

                CFStream stream = compileDataStream as CFStream;

                SrfCompileData scd = ParseStream(stream);
                scd.IsFullCompile = isFullCompile;
                WriteObject(scd);
            }
            catch (Exception ex) 
            {
                throw (ex);
            }
            finally
            {
                cf.Close();
            }
        }

        private SrfCompileData ParseStream(CFStream stream)
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
            //new SrfCompileData()
            SrfCompileData scd = new SrfCompileData(
                userName: ascii.GetString(userNameBytes, 0, Array.IndexOf(userNameBytes, (byte)0)),
                languageCode: ascii.GetString(langBytes, 0, Array.IndexOf(langBytes, (byte)0)),
                pcName: ascii.GetString(pcNameBytes, 0, Array.IndexOf(pcNameBytes, (byte)0)),
                compilationAgeSeconds: BitConverter.ToUInt32(compileTimeStampBytes, 0)
                );

            return scd;
        }

        protected override void EndProcessing()
        {
            //WriteObject($"~~~EndProcessing: {SrfFile}");
            base.EndProcessing();
        }
        protected override void StopProcessing()
        {
            base.StopProcessing();
        }
    }




    public struct SrfCompileData
    {
        private static DateTime D70 = new DateTime(1970, 1, 1, 0, 0, 0);
        public SrfCompileData(string userName, string languageCode, string pcName, uint compilationAgeSeconds)
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
    }
}
