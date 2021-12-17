# PRTG-DataCore.PS1

<!-- ABOUT THE PROJECT -->
### About The Project
Project Owner: Jannos-443

PRTG Powershell Script to monitor Datacore Status

Free and open source: [MIT License](https://github.com/Jannos-443/PRTG-DataCore/blob/main/LICENSE)


<!-- GETTING STARTED -->
## Getting Started
1. Log into DataCore Server
   
   - add new local computer user (for example: prtg-datacore)
   
   - start DataCore Console and Register User (use the same User name) 

   - User neeeds at least "View" permission
   

2. Install `DataCorePowershellSupport-XXXXX.exe` on the Probe(s) 

3. Make sure the DataCore Powershell Module exists on the Probe under the following Path
   - `C:\Program Files\DataCore\Powershell Support\DataCore.Executive.Cmdlets.dll`

4. Place the Scripts under `C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML`

5. Place the lookup Files under `C:\Program Files (x86)\PRTG Network Monitor\lookups\custom`
   - `prtg.datacore.presencestatus.ovl`
   - `prtg.datacore.poolstatus.ovl`
   - `prtg.datacore.state.ovl`
   - `prtg.datacore.cachestate.ovl`
   - `prtg.datacore.powerstate.ovl`
   - `prtg.datacore.logstatus.ovl`

6. Run PRTG Lookup File Reload
   - PRTG > Setup > System Administration > Load Lookups and File Lists 

7. Create new Sensor

   | Settings | Value |
   | --- | --- |
   | EXE/Script Advanced | PRTG-DataCore.ps1 |
   | Parameters | -DcsServer 'YourDataCoreServer'|
   | Scanning Interval | 15 minutes |


## Authentication

    Windows Auth (Better): PRTG-DataCore.ps1 -DcsServer 'YourDataCoreServer' (Windows Auth)
    Username and Password: PRTG-DataCore.ps1 -DcsServer 'YourDataCoreServer' -User 'YourUsername' -Password 'YourPassword' 
    
You should try to use Windows Auth (Use Windows credentials of parent device)

if required use the -User and -Password parameter.

## Usage

Datacore Status
```powershell
PRTG-DataCore.ps1 -DcsServer 'YourDataCoreServer' -DcsStatus
```
![PRTG-DataCore-Status](media/Status.png)


Datacore Alerts
```powershell
PRTG-DataCore.ps1 -DcsServer 'YourDataCoreServer' -DcsAlerts
```
![PRTG-DataCore-Alerts](media/Alerts.png)


Datacore Pools
```powershell
PRTG-DataCore.ps1 -DcsServer 'YourDataCoreServer' -DcsPools
```
![PRTG-DataCore-Pools](media/Pools.png)


Datacore Ports
```powershell
PRTG-DataCore.ps1 -DcsServer 'YourDataCoreServer' -DcsPorts
```
![PRTG-DataCore-Ports](media/Ports.png)


Datacore VirtualDisks
```powershell
PRTG-DataCore.ps1 -DcsServer 'YourDataCoreServer' -DcsVirtualDisks
```
![PRTG-DataCore-VirtualDisks](media/VirtualDisks.png)
