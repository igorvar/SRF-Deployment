# SRF-Deployment
SRF Deployment

The project includes 2 scripts:
1. CompileAndDeploy.ps1
2. DevTestDeployment.ps1

To run these scripts:
+ First way: Right click on ps1 file -> Run with PowerShell
+ Second way: powershell.exe -NoLogo -NoExit -ExecutionPolicy Unrestricted -File {PathToFile}.PS1

CompileAndDeploy.ps1 performs the following operations:
- Launches Siebel Tools and performs a full compilation into the siebel_sia.srf.New.<LANG> file for each language in folder in it executed script.
- Move file to folder on server with name siebel_sia.srf.New.
- Compiles browser scripts for each language. At this point, you need the gbs.cfg file in the same folder as the script file.
- Shutdown the siebel service. Copy siebel_sia.srf.new to siebel_sia.srf.last.
- The current siebel_sia.srf is renamed to siebel_sia.srf. CURRENT_DAY_WEEK, to save the past srf.
- Renames siebel_sia.srf.new to siebel_sia.srf and raises the service.


DevTestDeployment.ps1 execute next steps:
1. Copy siebel_sia.srf for each language from dev environment to all servers in test environment
2. Generate browser scripts in local folder (BS) and copy it to all server in test. At this point, you need the gbsTest.cfg in the same folder as the main file
3. Shutdown siebel service in test
4. Rename current srf in test with name <time_stamp>_siebel_sia.srf
5. Rename copied in step 1 file to siebel_sia.srf
6. Start siebel service
