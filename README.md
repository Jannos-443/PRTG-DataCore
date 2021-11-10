# PRTG-DataCore
# About

## Project Owner:

Jannos-443

## Project Details

This Script can monitor DataCore.

## HOW TO
1. Log into DataCore Server
   
   - add new local computer user (for example: prtg-datacore)
   
   - start DataCore Console and Register User (use the same User name) 

   - User neeeds at least "View" permission
   

2. Install `DataCorePowershellSupport-XXXXX.exe` on the Probe(s) 

3. Make sure the DataCore Powershell Module exists on the Probe under the following Path
   - `C:\Program Files\DataCore\Powershell Support\DataCore.Executive.Cmdlets.dll`

4. Place the Scripts under `C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML`

5. Create new Sensor

   | Settings | Value |
   | --- | --- |
   | EXE/Script Advanced | PRTG-DataCore-XXX.ps1 |
   | Parameters | -DcsServer 'YourDataCoreServer'|
   | Scanning Interval | 15 minutes |


## Examples
### Example Call: 

    Windows Auth (Better): PRTG-DataCore-Alerts.ps1 -DcsServer 'YourDataCoreServer' (Windows Auth)
    Username and Password: PRTG-DataCore-Alerts.ps1 -DcsServer 'YourDataCoreServer' -User 'YourUsername' -Password 'YourPassword' 
    
You should try to use Windows Auth (Use Windows credentials of parent device)

if required use the -User and -Password parameter.

### Example Screenshots: 

PRTG-DataCore-Status
![PRTG-DataCore-Status](media/Status.png)

PRTG-DataCore-Alerts
![PRTG-DataCore-Alerts](media/Alerts.png)

PRTG-DataCore-Pools
![PRTG-DataCore-Pools](media/Pools.png)

PRTG-DataCore-Ports
![PRTG-DataCore-Ports](media/Ports.png)

PRTG-DataCore-VirtualDisks
![PRTG-DataCore-VirtualDisks](media/VirtualDisks.png)
