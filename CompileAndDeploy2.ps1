(get-host).UI.RawUI.WindowTitle = "Siebel SRF Full Compile 2.0"
(Get-Host).UI.RawUI.BackgroundColor = "Black"
(Get-Host).UI.RawUI.ForegroundColor = "Green"
cls;

Import-Module "$($MyInvocation.MyCommand.Path | Split-Path -Parent)\SrfCompileInfoCmdLet.dll" #-Force #11.07.21. Load dll from folder where present script

Set-Variable LANG_LIST -Option Constant -Value @("HEB", "ENU") -Description "List of languages for compilation"

#[int]$MAX_COMPILE_ATTEMPTS = 3
Set-Variable MAX_COMPILE_ATTEMPTS -Option Constant -Value 3

Set-Variable SBL_TOOLS_ROOT -Option Constant -Value "C:\Siebel\15.0.0.0.0"

Set-Variable PATH_TO_LOCAL_SRF_FOLDER      -Option Constant -Value (($MyInvocation.MyCommand.Path | Split-Path -Parent) <#+ "\"#>) #This folder for compilation SRF_NAME_NEW
Set-Variable PATH_TO_SERVER_SRF_FOLDER     -Option Constant -Value "\\siebelappdev02\d$\Siebel\15.0.0.0.0\ses\siebsrvr\OBJECTS" #In this folder present srf for each languege. SRF_NAME and SRF_NAME_LAST.
Set-Variable PATH_TO_BROWSER_SCRIPT_FOLDER -Option Constant -Value "\\siebelappdev02\D$\Siebel\15.0.0.0.0\eappweb\PUBLIC"

Set-Variable SRF_NAME      -Option Constant -Value "siebel_sia.srf"      -Description "File for siebel server executing"
Set-Variable SRF_NAME_NEW  -Option Constant -Value "siebel_sia.srf.New"  -Description "Temporary file for compile"
Set-Variable SRF_NAME_LAST -Option Constant -Value "siebel_sia.srf.LastFullCompile.srf" -Description "Back copy of SRF_NAME"

Set-Variable GBS_CFG -Option Constant -Value (($MyInvocation.MyCommand.Path | Split-Path -Parent) + "\gbs.cfg")
Set-Variable GBS_EXE -Option Constant -Value "C:\Siebel\15.0.0.0.0\Client\BIN\genbscript.exe"

Set-Variable SBL_TOOLS_LOGIN    -Option Constant -Value "SADMIN"
Set-Variable SBL_TOOLS_PASSWORD -Option Constant -Value "SADMIN"

Set-Variable SIEBEL_WEB_SERVER -Option Constant -Value "siebelappdev02"
Set-Variable SIEBEL_SERVICE    -Option Constant -Value "siebsrvr_enDEV_asDEV"

$recompilingList = @{}
[bool]$isStopCompile = $false
while($isStopCompile -ne $true)
{
    foreach($lang in $LANG_LIST)
    {
   
        #if (($recompilingList[$lang + "_IsCompiled"] -eq $true) -or ($recompilingList[$lang + "_Attempt"] -ge $MAX_COMPILE_ATTEMPTS)) 
        if (($recompilingList["$lang-IsCompiled"] -eq $true) -or ($recompilingList["$lang-Attempt"] -ge $MAX_COMPILE_ATTEMPTS)) 
        {
            $isStopCompile = $true
            continue
        }
        $isStopCompile = $false
        #$recompilingList[$lang + "_Attempt"] = 1 + $recompilingList[$lang + "_Attempt"]
        $recompilingList["$lang-Attempt"] = 1 + $recompilingList["$lang-Attempt"]
        
        #if ($recompilingList[$lang + "_Attempt"] -le 1)
        if ($recompilingList["$lang-Attempt"] -le 1)
            {"$([System.DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss")). Compiling language $lang"}
        else
        {
            #"$([System.DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss")). Compiling language $lang. Attempt # $($recompilingList[$lang + "_Attempt"])"
            "$([System.DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss")). Compiling language $lang. Attempt # $($recompilingList["$lang-Attempt"])"
        }
        #$newSRF = "$PATH_TO_LOCAL_SRF_FOLDER\$lang-$SRF_NAME_NEW"
        $newSRF = "$PATH_TO_LOCAL_SRF_FOLDER\$SRF_NAME_NEW.$lang"
        "New SRF:$newSRF"
        $process = Start-Process -FilePath $SBL_TOOLS_ROOT\Tools\bin\siebdev.exe -ArgumentList "/c", $SBL_TOOLS_ROOT\Tools\bin\enu\tools.cfg, "/d", "ServerDataSrc", "/u", $SBL_TOOLS_LOGIN, "/p", $SBL_TOOLS_PASSWORD, "/bc", '"Siebel Repository"', $newSRF, "/tl", $lang -PassThru <#-NoNewWindow#> -Wait 
        "Compiling of $newSRF finished at $($process.ExitTime) with code $($process.ExitCode)"

        if ($process.ExitCode -ne 0)
        {
            #$recompilingList[$lang + "_IsCompiled"] = $false
            $recompilingList["$lang-IsCompiled"] = $false
            continue
        }
        #$recompilingList[$lang + "_IsCompiled"] = $true
        $recompilingList["$lang-IsCompiled"] = $true
        
        $serverFileName = "$PATH_TO_SERVER_SRF_FOLDER\$lang\$SRF_NAME_NEW"
        Move-Item -Path $newSRF -Destination $serverFileName -Force #-WhatIf
        $lastFileName = "$PATH_TO_SERVER_SRF_FOLDER\$lang\$SRF_NAME_LAST"
        Remove-Item -Path $lastFileName  #-WhatIf
        Copy-Item -Path $serverFileName -Destination $lastFileName #-WhatIf

        "$([System.DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss")). GBS Started"
        $process = Start-Process -Filepath $GBS_EXE -ArgumentList $GBS_CFG, $PATH_TO_BROWSER_SCRIPT_FOLDER\$lang, $lang -PassThru -NoNewWindow -Wait 
        #Start-Process -Filepath C:\Siebel\15.0.0.0.0\Client\BIN\genbscript.exe -ArgumentList C:\Siebel\CompileAndDeployment\gbs.cfg, $\\siebelappdev02\D$\Siebel\15.0.0.0.0\eappweb\PUBLIC\ENU, "ENU" -PassThru -NoNewWindow -Wait 

        "GBS finished in $($process.ExitTime) with code $($process.ExitCode)"
        "--------------------------------------------------------------------------------------------"
        #$recompilingList
    }
} #end while loop

"Compiling finished"
"============================================================================================"
"Stop siebel service"
$siebService = get-service -ComputerName $SIEBEL_WEB_SERVER -Name $SIEBEL_SERVICE
Stop-Service -InputObject $siebService #-WhatIf 

foreach ($lang in $LANG_LIST)
{
    "$([System.DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss")). Replace srf $lang"
    $newFileName = "$PATH_TO_SERVER_SRF_FOLDER\$lang\$SRF_NAME_NEW"
    $serverFileName = "$PATH_TO_SERVER_SRF_FOLDER\$lang\$SRF_NAME"
    
    $compilationDate = (Get-SrfData $serverFileName).CompilationDate #11.07.21
    $arcFileName = $serverFileName  + "." + ($compilationDate.DayOfWeek) + ".SRF"  #11.07.21

    if(Test-Path $arcFileName) {$bsFolderToRemove = (Get-SrfData $arcFileName -ErrorAction Ignore).JsFolderName }
    else {$bsFolderToRemove = ""}
        
    #$bsFolderToRemove = (Get-Item -Path $PATH_TO_BROWSER_SCRIPT_FOLDER\$lang\$bsFolderToRemove -ErrorAction Ignore).FullName
    Move-Item -Path $serverFileName -Destination $arcFileName -Force #-WhatIf
    Move-Item -Path $newFileName -Destination $serverFileName #-WhatIf

    
    #"$([System.DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss")). Remove old BS folder - $bsFolderToRemove for $lang"
    <#if ($bsFolderToRemove -eq $null -or $bsFolderToRemove -eq "" -or -not (Test-Path -Path $PATH_TO_BROWSER_SCRIPT_FOLDER\$lang\$bsFolderToRemove))
    {
        "Not found folder with BS for $arcFileName"
        Remove-Item $PATH_TO_BROWSER_SCRIPT_FOLDER\$lang\$bsFolderToRemove -Recurse -WhatIf 
    }
    else
    {
        Remove-Item $PATH_TO_BROWSER_SCRIPT_FOLDER\$lang\$bsFolderToRemove -Recurse #-WhatIf 
    }#>

    if ($bsFolderToRemove -ne $null -and $bsFolderToRemove -ne "")
    {
        $bsFolderToRemove = $("$PATH_TO_BROWSER_SCRIPT_FOLDER\$lang\$bsFolderToRemove")
        if (Test-Path -Path $bsFolderToRemove) 
        {
            "$([System.DateTime]::Now.ToString("dd.MM.yyyy HH:mm:ss")). Removing $bsFolderToRemove"
            #Remove-Item $PATH_TO_BROWSER_SCRIPT_FOLDER\$lang\$bsFolderToRemove -Recurse
            Remove-Item $bsFolderToRemove -Recurse
        }
        else {"Not found folder $bsFolderToRemove"}
    }

}

#"Start siebel service"
Start-Service -InputObject $siebService #-WhatIf
$siebService 
[System.Console]::WriteLine("Deployment finished.")
#[System.Console]::ReadLine()
