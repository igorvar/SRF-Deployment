# SRF-Deployment
For get info from srf file used project OpenMcdf https://sourceforge.net/projects/openmcdf/ 

The project includes 2 scripts:
1. CompileAndDeploy2.ps1
1. DevTestDeployment2.ps1

#To run these scripts:
+ First way: Right click on ps1 file -> Run with PowerShell
+ Second way: powershell.exe -NoLogo -NoExit -ExecutionPolicy Unrestricted -File {PathToFile}.PS1

CompileAndDeploy.ps1 performs the following operations:
- Launches Siebel Tools and performs a full compilation into the siebel_sia.srf.New.<LANG> file for each language in folder in it executed script. If the compilation fails, 2 more attempts will be made for each of the languages.
- Move file to folder on server with name siebel_sia.srf.New.
- Compiles browser scripts for each language. At this point, you need the gbs.cfg file in the same folder as the script file.
- Shutdown the siebel service. Copy siebel_sia.srf.new to siebel_sia.srf.last.
- The current siebel_sia.srf is renamed to siebel_sia.srf.<COMPILATION_DAY_WEEK>, to save the previous srf.
- If a folder with browser scripts for the previous file is found, it will be deleted.  
- Renames siebel_sia.srf.New to siebel_sia.srf and runing the service.


DevTestDeployment.ps1 execute next steps:
1. Copy siebel_sia.srf for each language from dev environment to all servers in test environment
2. Copy from dev env or, if not found, compile browser scripts in local folder (BS) and copy it to all server in test. At this point, you need the gbsTest.cfg in the same folder as the main file
3. Shutdown siebel service in test
4. Rename current srf in test with name <time_stamp_of_compilation>.siebel_sia.srf for full compile or <time_stamp_of_compilation-COMPILATION_MASHINE>.siebel_sia.srf for partial compile.
5. Rename copied in step 1 file to siebel_sia.srf
6. Start siebel service

Installation
1. Compile SrFCompileInfo solution.
2. Create folder on disk. 
3. Copy files to this folder:
    - CompileAndDeploy2.ps1
    - DevTestDeployment2.ps1
    - gbs.cfg
    - gbsTest.cfg
    - SrfCompileInfoCmdLet.dll (result of compile from step 1)
    - OpenMcdf.dll (result of compile from step 1)
 4. Edit files CompileAndDeploy2.ps1, DevTestDeployment2.ps1, gbs.cfg, gbsTest.cfg
 5. Create Task Scheduler and/or create shortcuts (powershell.exe -NoLogo -NoExit -ExecutionPolicy Unrestricted -File {PathToFile}.PS1)
