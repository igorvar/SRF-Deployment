(get-host).ui.rawui.windowtitle = "Siebel SRF deployment"
#(Get-Host).UI.RawUI.BackgroundColor = "Gray"
(Get-Host).UI.RawUI.ForegroundColor = "Green"
#[System.Threading.Thread]::CurrentThread.CurrentCulture = 'he-IL'
#comm[System.Threading.Thread]::CurrentThread.CurrentUICulture = 'he-IL'

[Array]$langList = "HEB", "ENU"
$sblToolsRoot = "C:\Siebel\15.0.0.0.0"
$sblToolsLogin = "SADMIN"
$sblToolsPassword = "SADMIN"

New-PSDrive -Name SblServerRoot -PsProvider FileSystem -Root \\siebelappdev02\D$\Siebel\15.0.0.0.0 | Out-Null
$siebelService = "siebsrvr_enDEV_asDEV"
$WEB_SERVER = "siebelappdev02"

foreach($lang in $langList)
{
    "" + [System.DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss") + ". Compiling language " + $lang
    $NEW_SRF = (Get-PSDrive -name SblServerRoot).root + "\ses\siebsrvr\OBJECTS\" + $lang + "\siebel_sia.srf.new"
    "New SRF: " + $NEW_SRF
    $process = Start-Process -Filepath $sblToolsRoot'\Tools\bin\siebdev.exe' -ArgumentList "/c", $sblToolsRoot\Tools\bin\enu\tools.cfg, "/d", "ServerDataSrc", "/u", $sblToolsLogin, "/p", $sblToolsPassword, "/bc", '"Siebel Repository"', $NEW_SRF, "/tl", $lang -PassThru <#-NoNewWindow#> -Wait
    "Compiling of " + $NEW_SRF + " finished at " + $process.ExitTime + " with code " + $process.ExitCode
<#"HasExited " + $process.HasExited
"ExitTime " + $process.ExitTime
"ExitCode " + $process.ExitCode#>
# <# comment #>

#GBS
    "GBS Started"
    #$applicationCfg = "C:\gbs.cfg"
    $applicationCfg = ($MyInvocation.MyCommand.Path | Split-Path -Parent) + "\gbs.cfg"
    $bscriptFolder = (Get-PSDrive -name SblServerRoot).root + "\eappweb\PUBLIC\" + $lang 
    $process = Start-Process -Filepath $sblToolsRoot'\Client\BIN\genbscript.exe' -ArgumentList $applicationCfg, $bscriptFolder, $lang -PassThru -NoNewWindow -Wait 

    #"HasExited " + $process.HasExited
    "GBS finished in " + $process.ExitTime + " with code " + $process.ExitCode
    "------------------------------------------------------------------------------"
}
"Compiling finished"
"Stop siebel service"
"=============================================================================="
#Stop siebel service
$siebService = get-service -ComputerName $WEB_SERVER <#siebelappdev02#> -Name $siebelService
 Stop-Service -InputObject $siebService 
## $siebService 
foreach ($lang in $langList)
{
    "" + [System.DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss") + ". Replace srf " + $lang
    #$NEW_SRF = (Get-PSDrive -name SblServerRoot).root + "\ses\siebsrvr\OBJECTS\" + $lang + "\siebel_sia.srf.new"
    #Rename srfs
    $fileName = "SblServerRoot:\ses\siebsrvr\OBJECTS\" + $lang + "\siebel_sia.srf"
    $NEW_SRF = $fileName + ".new"
    $arcFileName = $fileName  + "." + [System.DateTime]::Now.DayOfWeek
    $fileNameToday = $fileName + ".Last"
    
    Move-Item -Path $fileName -Destination $arcFileName -Force
    Move-Item -Path $NEW_SRF  -Destination $fileName 
    Remove-Item -Path $fileNameToday 
    Copy-Item -Path $fileName -Destination $fileNameToday 
    
    
}

"Start siebel service"
"=============================================================================="
#Start siebel service
start-service -InputObject $siebService 
$siebService 
[System.Console]::WriteLine("Deployment finished.")
#[System.Console]::ReadLine()
<#
\Client\BIN\genbscript.exe
C:\Siebel\15.0.0.0.0\Client\BIN\genbscript.exe C:\finsGEN.cfg \\siebelappdev02\D$\Siebel\15.0.0.0.0\\eappweb\PUBLIC\heb heb

Could not open repository file '
\\siebelappdev02\D$\15.0.0.0.0\ses\siebsrvr\objects\enu\siebel_sia.srf'.
\\siebelappdev02\D$\Siebel\15.0.0.0.0\ses\siebsrvr\OBJECTS\heb\siebel_sia.srf
#>
