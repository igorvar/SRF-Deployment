<#
$Host.UI.RawUI.BackgroundColor = ($bckgrnd = 'DarkBlue')
$Host.UI.RawUI.ForegroundColor = 'White'
$Host.PrivateData.ErrorForegroundColor = 'Red'
$Host.PrivateData.ErrorBackgroundColor = $bckgrnd
$Host.PrivateData.WarningForegroundColor = 'Magenta'
$Host.PrivateData.WarningBackgroundColor = $bckgrnd
$Host.PrivateData.DebugForegroundColor = 'Yellow'
$Host.PrivateData.DebugBackgroundColor = $bckgrnd
$Host.PrivateData.VerboseForegroundColor = 'Green'
$Host.PrivateData.VerboseBackgroundColor = $bckgrnd
$Host.PrivateData.ProgressForegroundColor = 'Cyan'
$Host.PrivateData.ProgressBackgroundColor = $bckgrnd
#>

Add-Type -AssemblyName PresentationCore,PresentationFramework
$a = (get-host).UI.RawUI
$b = $a.BufferSize
$b.Height = 999
$b.Width = 108
$a.BufferSize = $b
$b=$a.WindowSize
$b.Width=108
$a.WindowSize=$b
(Get-Host).UI.RawUI.ForegroundColor = "Green"
(Get-Host).UI.RawUI.BackgroundColor = "black"#$bckgrnd
#(Get-Host).UI.RawUI.ErrorBackgroundColor = "Yellow"
#(Get-Host).UI.RawUI.WarningBackgroundColor = "White"
(Get-Host).UI.RawUI.WindowTitle = "Srf dev to test deployment v2. $([System.DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss"))"
#[System.Console]::ReadLine()
#return
cls


Set-Variable ROOT -Option Constant -Value "\\siebelfronttst\d$\Siebel\15.0.0.0.0", "\\Siebelbacktst\d$\Siebel\15.0.0.0.0"     -Description "List of folders containing SES for each server"

Set-Variable APP_SERVERS -Option Constant -Value "siebelfronttst",  "Siebelbacktst"     -Description "List the names of the servers that are running the Siebel Services"

Set-Variable SBL_SERVICES -Option Constant -value "siebsrvr_enTST_FRONT01", "siebsrvr_enTST_BACK01"    -Description "List of names of services. Corresponded to APP_SERVERS"

Set-Variable LANG_LIST -Option Constant -Value "HEB", "ENU"     -Description "List of languages"

Set-Variable OBJECTS_FOLDER -Option Constant -Value "ses\siebsrvr\OBJECTS"     -Description "Folder present under ROOT. It contains folders to place SRF files for each language."

Set-Variable ENV_DEV -Option Constant -Value "\\siebelappdev02\D$\Siebel\15.0.0.0.0\$OBJECTS_FOLDER\"     -Description "Folder it contain original SRF"

Set-Variable ENV_DEV_BROWSER_SCRIPT_FOLDER -Option Constant -Value "\\siebelappdev02\D$\Siebel\15.0.0.0.0\eappweb\PUBLIC"     -Description "Folder it contain folder SRF... with browser scripts"

#Next 3 constants need for compilation BS in case of not found in ENV_DEV_BROWSER_SCRIPT_FOLDER
Set-Variable APPLICATION_CFG -Option Constant -Value "$($MyInvocation.MyCommand.Path | Split-Path -Parent)\gbsTest.cfg"     -Description "CFG for compilation BS"

Set-Variable GENBSCRIPT_EXE -Option Constant -Value "$($ROOT[0])\Client\BIN\genbscript.exe"     -Description "EXE for compilation BS"

#BS_SCRIPT_FOLDER_TEMP must be not real folder on server, with it work siebel: all subfolders srf* from this directory will be removed. 
Set-Variable BS_SCRIPT_FOLDER_TEMP -Option Constant "$($MyInvocation.MyCommand.Path | Split-Path -Parent)\BS"     -Description "Temporary folder for compilation BS. All subfolders SRF* from this folder will be removed"

#$bscriptFolderTemp = ($MyInvocation.MyCommand.Path | Split-Path -Parent) + "\" + "BS" 

"
This process:
    1. Copy siebel_sia.srf for each language from development environment to servers in test environment
    2. Search BS in development environment or generate browser scripts in local folder (BS) 
       and copy it to all server in test
    3. Shutdown siebel service in test
    4. Rename current srf in test with name <compile_time_stamp>.siebel_sia.srf (for full compile) or 
       <compile.time_stamp>-<PcName>.siebel_sia.srf for partial compile
    5. Rename copied in step 1 file to siebel_sia.srf
    6. Start siebel service
   
    
==========================================================================================================


"
#[System.Console]::ReadLine()
#return

Import-Module "$($MyInvocation.MyCommand.Path | Split-Path -Parent)\SrfCompileInfoCmdLet.dll" #-Force #11.07.21. Load dll from folder where present script

#"Process started at " + [System.DateTime]::Now.ToString("HH:mm:ss")
"Process started at $([System.DateTime]::Now.ToString("HH:mm:ss"))"
"Copy srfs"

foreach($lang in $LANG_LIST)
{
    $fileNameS = $ENV_DEV + "\" + $lang + "\siebel_sia.srf"
    foreach($envRoot in $ROOT)
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
#$bscriptFolderTemp = ($MyInvocation.MyCommand.Path | Split-Path -Parent) + "\" + "BS" 
<#if (-not (Test-Path $BS_SCRIPT_FOLDER_TEMP)) 
{
    New-Item -Path $BS_SCRIPT_FOLDER_TEMP -Type Directory
}#>

foreach($lang in $LANG_LIST)
{

    $originFolderBS = (Get-SrfData "$ENV_DEV\$lang\siebel_sia.srf").JsFolderName
    $originFolderBS = $ENV_DEV_BROWSER_SCRIPT_FOLDER + "\" + $lang + "\" + $originFolderBS 
    if(-not (Test-Path $originFolderBS))
    {
        "Not found folder $originFolderBS. Compilation BS"
        #$originFolderBS = ($MyInvocation.MyCommand.Path | Split-Path -Parent) + "\" + "BS" 
        $originFolderBS = $BS_SCRIPT_FOLDER_TEMP
        if (-not (Test-Path $originFolderBS)) 
            {New-Item -Path $originFolderBS -ItemType Directory }
        else 
            {Get-ChildItem $originFolderBS\srf* -Directory | Remove-Item -Recurse}
        "APPLICATION_CFG: " + $APPLICATION_CFG
        $process = Start-Process -Filepath $GENBSCRIPT_EXE -ArgumentList $APPLICATION_CFG, $originFolderBS, $lang -PassThru -NoNewWindow -Wait
        $originFolderBS = (Get-ChildItem $originFolderBS\srf*)[0].FullName
    }
    #for Windows7
        #Copy-Item -Path $folder.FullName -Destination $bscriptFolder\$lang -Recurse -Force #-PassThru 
    #for Windows 10
    "Deployment BS for $lang from $originFolderBS"
    foreach($envRoot in $ROOT)
    {
        "   to $envRoot"
        Copy-Item -Path $originFolderBS -Destination $envRoot\eappweb\PUBLIC\$lang -Recurse -Force #-PassThru 
    }
    Get-ChildItem $BS_SCRIPT_FOLDER_TEMP\srf* -Directory | Remove-Item -Recurse #-WhatIf
}

#[System.Console]::ReadLine()
#return

"Stop siebel service"
For($i = 0; $i -lt $SBL_SERVICES.Length; $i++)
{
    "    stoping " + $SBL_SERVICES[$i]
    $siebService = Get-Service -ComputerName $APP_SERVERS[$i]  -Name $SBL_SERVICES[$i]
    "$siebService"
    Stop-Service -InputObject $siebService 
}


foreach($envRoot in $ROOT)
{
    foreach($lang in $LANG_LIST)
    {
        "Replace srf in $envRoot for $lang"
        $fileNameS = $envRoot + "\" + $OBJECTS_FOLDER + "\" + $lang + "\siebel_sia.srf"
        $currentFileInfo = Get-SrfData $fileNameS
        if($currentFileInfo.IsFullCompile)
            {$prefixOldFile = $currentFileInfo.CompilationDate.ToString("yyyyMMdd-HHmm") + "."}
        else
            {$prefixOldFile = $currentFileInfo.CompilationDate.ToString("yyyyMMdd-HHmm") + "-" + $currentFileInfo.PcName + "."}
        $fileNameD = $envRoot + "\" + $OBJECTS_FOLDER + "\" + $lang + "\" + $prefixOldFile + "siebel_sia.srf"
        Rename-Item -Path $fileNameS -NewName $fileNameD  #-WhatIf

        $fileNameS = $envRoot + "\" + $OBJECTS_FOLDER + "\" + $lang + "\siebel_sia.srf.Last"
        $fileNameD = $envRoot + "\" + $OBJECTS_FOLDER + "\" + $lang + "\siebel_sia.srf"
        Rename-Item -Path $fileNameS -NewName $fileNameD  #-WhatIf

        $bsFolder = "$envRoot\eappweb\PUBLIC\$lang"
        #Get-Item $bsFolder\PreviousSrfJs | Remove-Item  -WhatIf
        If(
            $envRoot -ne $null -and $envRoot -ne "" -and 
            $lang -ne $null -and $lang -ne "" -and 
            $currentFileInfo.JsFolderName -ne $null -and $currentFileInfo.JsFolderName -ne ""
          )
        {
            Remove-Item $bsFolder\PreviousSrfJs -Recurse -ErrorAction Ignore -WhatIf 
            Rename-Item "$bsFolder\$($currentFileInfo.JsFolderName)" -NewName "$bsFolder\PreviousSrfJs" -WhatIf 
        }
    }
}


#Start siebel service
"


Start siebel service"
For($i = 0; $i -lt $SBL_SERVICES.Length; $i++)
{
    "    starting " + $SBL_SERVICES[$i]
    $siebService = Get-Service -ComputerName $APP_SERVERS[$i] -Name $SBL_SERVICES[$i]
    start-service -InputObject $siebService 
}


"


Deployment finished at " + [System.DateTime]::Now.ToString("HH:mm:ss")
"__________________________________________________________________________________________________________"
[System.Console]::ReadLine()
