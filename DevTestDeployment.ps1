
#[System.Console]::ReadLine()
#return
Add-Type -AssemblyName PresentationCore,PresentationFramework
$a = (get-host).UI.RawUI
$b = $a.BufferSize
$b.Height = 2000
$b.Width = 108
$a.BufferSize = $b
$b=$a.WindowSize
$b.Width=108
$a.WindowSize=$b
(Get-Host).UI.RawUI.ForegroundColor = "Green"
(get-host).ui.rawui.windowtitle = "Srf dev to test deployment " + [System.DateTime]::Now.ToString("HH:mm:ss")

"
This process:
    1. Copy siebel_sia.srf for each language from dev environment to all servers in test environment
    2. Generate browser scripts in local folder (BS) and copy it to all server in test
    3. Shutdown siebel service in test
    4. Rename current srf in test with name <time_stamp>_siebel_sia.srf
    5. Rename copied in step 1 file to siebel_sia.srf
    6. Start siebel service
   
    
==========================================================================================================


"

[Array] $root = "\\siebelfronttst\d$\Siebel\15.0.0.0.0", "\\Siebelbacktst\d$\Siebel\15.0.0.0.0"
[Array] $WEB_SERVERS = "siebelfronttst",  "Siebelbacktst"
[Array] $SBL_SERVICES = "siebsrvr_enTST_FRONT01", "siebsrvr_enTST_BACK01"
[Array] $langList = "HEB", "ENU"


$OBJECTS_FOLDER = "ses\siebsrvr\OBJECTS"
$envDev = "\\siebelappdev02\D$\Siebel\15.0.0.0.0" + "\" + $OBJECTS_FOLDER + "\" 
$applicationCfg =  ($MyInvocation.MyCommand.Path | Split-Path -Parent) + "\gbsTest.cfg" 
$genbscript_exe = $root[0] + "\Client\BIN\genbscript.exe"




"Process started at " + [System.DateTime]::Now.ToString("HH:mm:ss")
"Copy srfs"



foreach($lang in $langList)
{
    $fileNameS = $envDev + "\" + $lang + "\siebel_sia.srf"
    foreach($envRoot in $root)
    {
        $fileNameDest = $envRoot + "\" + $OBJECTS_FOLDER + "\" + $lang + "\siebel_sia.srf.Last"
        "   from " + $fileNameS 
        "   to " + $fileNameDest
        Copy-Item -Path $fileNameS -Destination $fileNameDest -Force
        #"______________________________________________________________"
        ""
    }
}
""
""
$bscriptFolderTemp = ($MyInvocation.MyCommand.Path | Split-Path -Parent) + "\" + "BS" 
if (-not (Test-Path $bscriptFolderTemp)) 
{
    New-Item -Path $bscriptFolderTemp -Type "directory"
    #del $_.FullName
};


"Browser scripts generation in " + $bscriptFolderTemp 
foreach($lang in $langList)
{
""
    if (-not (Test-Path $bscriptFolderTemp\$lang)) 
    {
        New-Item -Path $bscriptFolderTemp\$lang  -Type "directory"
    }
    if (Test-Path $bscriptFolderTemp\$lang\srf*)
    {
        $isRemove = [System.Windows.MessageBox]::Show("Present folder with old browser scrips in $bscriptFolderTemp\$lang. Is remove it?" ,(get-host).ui.rawui.windowtitle,[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
        if($isRemove -eq "Yes")
        {
            Get-ChildItem $bscriptFolderTemp\$lang\srf* | Remove-Item  -Recurse #-WhatIf
        }
    }
    $process = Start-Process -Filepath $genbscript_exe -ArgumentList $applicationCfg, $bscriptFolderTemp\$lang, $lang -PassThru -NoNewWindow -Wait
}  

"applicationCfg: " + $applicationCfg


"




Deployment browser scripts"

foreach($envRoot in $root)
{
    "    Copy browser scripts in $envRoot"
    $bscriptFolder = $envRoot + "\eappweb\PUBLIC"
    foreach($lang in $langList)
    {
        $folder = Get-ChildItem $bscriptFolderTemp\$lang\srf*
        "        $lang (folder $folder)"
        Copy-Item -Path $folder.FullName -Destination $bscriptFolder\$lang -Recurse -Force #-PassThru 
    }
}


"Stop siebel service"
For($i = 0; $i -lt $SBL_SERVICES.Length; $i++)
{
    "    stoping " + $SBL_SERVICES[$i]
    $siebService = Get-Service -ComputerName $WEB_SERVERS[$i]  -Name $SBL_SERVICES[$i]
    "$siebService"
    Stop-Service -InputObject $siebService 
}

#rename old files
$prefixOldFile = [System.DateTime]::Now.ToString("yyyyMMdd-HHmm") + "_"
foreach($envRoot in $root)
{
    foreach($lang in $langList)
    {
        $fileNameS = $envRoot + "\" + $OBJECTS_FOLDER + "\" + $lang + "\siebel_sia.srf"
        $fileNameD = $envRoot + "\" + $OBJECTS_FOLDER + "\" + $lang + "\" + $prefixOldFile + "siebel_sia.srf"
        Rename-Item -Path $fileNameS -NewName $fileNameD  #-WhatIf
        $fileNameS = $envRoot + "\" + $OBJECTS_FOLDER + "\" + $lang + "\siebel_sia.srf.Last"
        $fileNameD = $envRoot + "\" + $OBJECTS_FOLDER + "\" + $lang + "\siebel_sia.srf"
        Rename-Item -Path $fileNameS -NewName $fileNameD  #-WhatIf
    }
}


#Start siebel service
"


Start siebel service"
For($i = 0; $i -lt $SBL_SERVICES.Length; $i++)
{
    "    starting " + $SBL_SERVICES[$i]
    $siebService = Get-Service -ComputerName $WEB_SERVERS[$i] -Name $SBL_SERVICES[$i]
    start-service -InputObject $siebService 
}




# removing deployed browser scripts
foreach($lang in $langList)
{
    Get-ChildItem $bscriptFolderTemp\$lang\srf* | Remove-Item -Recurse #-WhatIf
}

"


Deployment finished at " + [System.DateTime]::Now.ToString("HH:mm:ss")
"__________________________________________________________________________________________________________"
[System.Console]::ReadLine()
