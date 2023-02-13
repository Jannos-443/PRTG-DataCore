<#   
    .SYNOPSIS
    Monitors DataCore Status/Alerts/Pools/Ports/VirtualDisks

    .DESCRIPTION
    Using DataCore Powershell Module this Script checks DataCore Status/Alerts/Pools/Ports/VirtualDisks

    .PARAMETER DcsServer
    The Hostname of the DataCore Server

    .PARAMETER User
    Provide the DataCore Username

    .PARAMETER Password
    Provide the DataCore Password
    
    .EXAMPLE
    Sample call from PRTG EXE/Script Advanced
    PRTG-DataCore-Alerts.ps1 -DcsServer 'YourDataCoreServer' -DcsStatus (Windows Auth) <- better 
    PRTG-DataCore-Alerts.ps1 -DcsServer 'YourDataCoreServer' -DcsStatus -User 'YourUsername' -Password 'YourPassword' (Username and Password)

    Author:  Jannos-443
    https://github.com/Jannos-443/PRTG-DataCore

#>
param(
    [string]$DcsServer = '',
    [string]$User = '',
    [string]$Password = '',
    [switch]$DcsAlerts,
    [switch]$DcsPools,
    [switch]$DcsPorts,
    [switch]$DcsVirtualDisks,
    [switch]$DcsStatus,
    [string]$Excludes = '',
    [string]$Includes = ''
)

#Catch all unhandled Errors
trap{
    if($con)
        {
        $null = Disconnect-DcsServer -Connection $con -ErrorAction SilentlyContinue
        }
    $Output = "line:$($_.InvocationInfo.ScriptLineNumber.ToString()) char:$($_.InvocationInfo.OffsetInLine.ToString()) --- message: $($_.Exception.Message.ToString()) --- line: $($_.InvocationInfo.Line.ToString()) "
    $Output = $Output.Replace("<","")
    $Output = $Output.Replace(">","")
    $Output = $Output.Replace("#","")
    Write-Output "<prtg>"
    Write-Output "<error>1</error>"
    Write-Output "<text>$($Output)</text>"
    Write-Output "</prtg>"
    Exit
}

#https://stackoverflow.com/questions/19055924/how-to-launch-64-bit-powershell-from-32-bit-cmd-exe
#############################################################################
#If Powershell is running the 32-bit version on a 64-bit machine, we 
#need to force powershell to run in 64-bit mode .
#############################################################################
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") 
    {
    if ($myInvocation.Line) 
        {
        [string]$output = &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
        }
    else
        {
        [string]$output = &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
        }

    #Remove any text after </prtg>
    try{
        $output = $output.Substring(0,$output.LastIndexOf("</prtg>")+7)
        }

    catch
        {
        }

    Write-Output $output
    exit
    }

#############################################################################
#End
#############################################################################    

# Select Mode
$ModeCount = 0
if($DcsStatus)
    {
    $ModeCount ++
    }
if($DcsAlerts)
    {
    $ModeCount ++
    }
if($DcsPools)
    {
    $ModeCount ++
    }
if($DcsPorts)
    {
    $ModeCount ++
    }
if($DcsVirtualDisks)
    {
    $ModeCount ++
    }
if($ModeCount -eq 0)
    {
    Write-Output "<prtg>"
    Write-Output "<error>1</error>"
    Write-Output "<text>Please select scripte mode. e.g. -DcsStatus</text>"
    Write-Output "</prtg>"
    Exit  
    }
if($ModeCount -gt 1)
    {
    Write-Output "<prtg>"
    Write-Output "<error>1</error>"
    Write-Output "<text>Please only select ONE scripte mode at once. e.g. -DcsStatus</text>"
    Write-Output "</prtg>"
    Exit   
    }


# Error if there's anything going on
$ErrorActionPreference = "Stop"


# Import VMware PowerCLI module
try {
    Import-Module "C:\Program Files\DataCore\Powershell Support\DataCore.Executive.Cmdlets.dll" -ErrorAction Stop
} catch {
    Write-Output "<prtg>"
    Write-Output "<error>1</error>"
    Write-Output "<text>Error Loading DataCore Powershell Module ($($_.Exception.Message))</text>"
    Write-Output "</prtg>"
    Exit
}
 


# Connect to Datacore Server
try {
    if(($User -ne "") -and ($Password -ne ""))
        {
        $con = Connect-DcsServer -Server $DcsServer -Username $User -Password $Password
        }
    else
        {
        $con = Connect-DcsServer -Server $DcsServer
        } 
    }
 
catch
    {
    Write-Output "<prtg>"
    Write-Output "<error>1</error>"
    Write-Output "<text>Could not connect to Datacore server $($DcsServer). Error: $($_.Exception.Message)</text>"
    Write-Output "</prtg>"
    Exit
    }

# Output Text
$OutputText = ""
$xmlOutput = '<prtg>'

# Start Region Datacore Alerts
if($DcsAlerts)
    {
    $Alerts = Get-DcsAlert -Connection $con

    $ErrorCount = 0
    $WarningCount = 0
    $ErrorText = "Error: "
    $WarningText = "Warning: "

    foreach($alert in $Alerts)
        {
        if($alert.Level -eq "Warning")
            {
            $WarningCount += 1
            $WarningText += "$($alert.MessageText) - "
            }
        elseif($alert.Level -eq "Error")
            {
            $ErrorCount += 1
            $ErrorText += "$($alert.MessageText) - "
            }
        }

    $xmlOutput += "<result>
            <channel>Error Count</channel>
            <value>$($ErrorCount)</value>
            <unit>Count</unit>
            <limitmode>1</limitmode>
            <LimitMaxError>0</LimitMaxError>
            </result>
            <result>
            <channel>Warning Count</channel>
            <value>$($WarningCount)</value>
            <unit>Count</unit>
            <limitmode>1</limitmode>
            <LimitMaxWarning>0</LimitMaxWarning>
            </result>"




    if($ErrorCount -gt 0)
        {
        $OutputText += "Error: $($ErrorText)"
        }

    if($WarningCount -gt 0)
        {
        $OutputText += "Warning: $($WarningText)"
        }


    if(($WarningCount -gt 0) -or ($ErrorCount -gt 0))
        {
        $OutputText = $OutputText.Replace("<","")
        $OutputText = $OutputText.Replace(">","")
        $OutputText = $OutputText.Replace("#","")
        $OutputText = $OutputText.Replace("[","")
        $OutputText = $OutputText.Replace("]","")
        #The number sign (#) is not supported in sensor messages. If a message contains a number sign, the message is clipped at this point - https://www.paessler.com/manuals/prtg/custom_sensors
        
        $xmlOutput += "<text>$($OutputText)</text>"
        }

    else
        {
        $xmlOutput += "<text>No Alerts found</text>"
        }
    }
# End Region Datacore Alerts


#Start Region Datacore Status
if($DcsStatus)
    {
    # Get DataCore Server
    $DCs = Get-DcsServer -Connection $con

    #Online Server
    $DCsOnline = ($DCs | Where-Object {$_.State -eq "Online"}).count

    $xmlOutput += "<result>
            <channel>Server Online</channel>
            <value>$($DCsOnline)</value>
            <unit>Count</unit>
            <limitmode>1</limitmode>
            <LimitMinError>1</LimitMinError>
            </result>"

    # For Each Server
    $NodeOnlineTXT = "Nodes Online: "
    foreach ($DC in $DCs) 
        {
        if($DC.State -eq "Online")
            {
            $NodeOnlineTXT += "$($DC.Caption), "
            }
        #State
        switch ($DC.State)
            {
            'NotPresent' { $dcstate = 1 }
            'Offline' { $dcstate = 2}
            'Online' { $dcstate = 3}
            'Failed' { $dcstate = 4}
            default { $dcstate = -1 }
            }
        $xmlOutput += "<result>
            <channel>$($DC.Caption) State</channel>
            <value>$($dcstate)</value>
            <ValueLookup>prtg.datacore.state</ValueLookup>
            </result>"

        #LogStatus
        switch ($DC.LogStatus)
            {
            'Operational' { $dclogstatus = 1 }
            'StoragePaused' { $dclogstatus = 2}
            'StorageFailed' { $dclogstatus = 3}
            'QueueFull' { $dclogstatus = 4}
            'Flooded' { $dclogstatus = 5}
            default { $dclogstatus = -1 }
            }
        $xmlOutput += "<result>
            <channel>$($DC.Caption) LogStatus</channel>
            <value>$($dclogstatus)</value>
            <ValueLookup>prtg.datacore.logstatus</ValueLookup>
            </result>"

        #PowerState
        switch ($DC.PowerState)
            {
            'Unknown' { $dcpowerstate = 1 }
            'ACOffline' { $dcpowerstate = 2}
            'ACOnline' { $dcpowerstate = 3}
            'BatteryLow' { $dcpowerstate = 4}
            default { $dcpowerstate = -1 }
            }
        $xmlOutput += "<result>
            <channel>$($DC.Caption) PowerState</channel>
            <value>$($dcpowerstate)</value>
            <ValueLookup>prtg.datacore.powerstate</ValueLookup>
            </result>"
        
        #CacheState
        switch ($DC.CacheState)
            {
            'Unknown' { $dccachestate = 1 }
            'WritethruGlobal' { $dccachestate = 2}
            'WritebackGlobal' { $dccachestate = 3}
            default { $dccachestate = -1 }
            }
        $xmlOutput += "<result>
            <channel>$($DC.Caption) CacheState</channel>
            <value>$($dccachestate)</value>
            <ValueLookup>prtg.datacore.cachestate</ValueLookup>
            </result>"

        #System Memory %
        #Total/Available
        try{
            $UsedMem = [math]::Round(($DC.AvailableSystemMemory.Value / $DC.TotalSystemMemory.Value *100),0)
            }
        catch
            {
            $UsedMem = 0
            }
        $xmlOutput += "<result>
            <channel>$($DC.Caption) MemoryUsed</channel>
            <value>$($UsedMem)</value>
            <unit>Percent</unit>
            <limitmode>1</limitmode>
            <LimitMaxError>90</LimitMaxError>
            <LimitMaxWarning>80</LimitMaxWarning>
            </result>"
        }

    #Storage Used (Byte?)
    $StorageUsed = $DCs.StorageUsed | Select-Object -First 1 -ExpandProperty Value
    $xmlOutput += "<result>
            <channel>Storage Used</channel>
            <value>$($StorageUsed)</value>
            <unit>BytesDisk</unit>
            </result>"

    if($DCsOnline -ge 1)
        {
        $xmlOutput += "<text>$($NodeOnlineTXT)</text>"
        }
    else
        {
        $xmlOutput += "<text>No Online Nodes!</text>"
        }
    }
# End Region Datacore Status


# Start Region Datacore VirtualDisks
if($DcsVirtualDisks)
    {
    #All Virtual Disks
    $disks = Get-DcsVirtualDisk -Connection $con

    #Online/Offline
    $NotOnlineText = "Disk not Online: "
    $DiskOnline = $disks | Where-Object {$_.diskstatus -eq  "online"}
    $DiskNotOnline = $disks | Where-Object {$_.diskstatus -ne  "online"}
    Foreach ($Disk in $DiskNotOnline )
        {
        $NotOnlineText += "$($Disk.Caption) - $($Disk.DiskStatus); "
        }


    #Not MultiPathMirrored
    $NonMirrorText = "Disk NonMirrored: "
    $NonMirrored = $diskonline | Where-Object {$_.Type -ne  "MultiPathMirrored"}
    Foreach ($Disk in $NonMirrored )
        {
        $NonMirrorText += "$($Disk.Caption); "
        }

    #RecoveryState
    $RecoveryText = "Disk Recovery: "
    $RecoveryNeeded = Get-DcsMirror -Connection $con | Where-Object {(($_.FirstRecovery -ne "NoRecoveryNeeded") -and ($_.FirstRecovery -ne  "Undefined")) -or (($_.SecondRecovery -ne "NoRecoveryNeeded") -and ($_.SecondRecovery -ne "Undefined"))}
    Foreach ($Disk in $RecoveryNeeded )
        {
        if(($Disk.FirstRecovery -ne "NoRecoveryNeeded") -and ($Disk.FirstRecovery -ne  "Undefined"))
            {
            $RecoveryText += "$($Disk.Caption) - $($Disk.FirstRecovery); "
            }
        else
            {
            $RecoveryText += "$($Disk.Caption) - $($Disk.SecondRecovery); "
            }
        
        }

    #Output Text
    if($DiskNotOnline.Count -gt 0)
        {
        $OutputText += $NotOnlineText
        }

    if($NonMirrored.Count -gt 0)
        {
        $OutputText += $NonMirrorText
        }

    if($RecoveryNeeded.Count -gt 0)
        {
        $OutputText += $RecoveryText
        }

    if($OutputText -ne "")
        {
        $xmlOutput += "<text>$($OutputText)</text>"
        }

    #Graphs
    $xmlOutput += "<result>
            <channel>VDisks Online</channel>
            <value>$($DiskOnline.Count)</value>
            <unit>Count</unit>
            </result>
            <result>
            <channel>VDisks Not Online</channel>
            <value>$($DiskNotOnline.Count)</value>
            <unit>Count</unit>
            <limitmode>1</limitmode>
            <LimitMaxError>0</LimitMaxError>
            </result>
            <result>
            <channel>VDisks NonMirrored</channel>
            <value>$($NonMirrored.Count)</value>
            <unit>Count</unit>
            <limitmode>1</limitmode>
            <LimitMaxWarning>0</LimitMaxWarning>
            </result>
            <result>
            <channel>VDisks Recovery needed</channel>
            <value>$($RecoveryNeeded.Count)</value>
            <unit>Count</unit>
            <limitmode>1</limitmode>
            <LimitMaxError>0</LimitMaxError>
            </result>"
    }
# End Region Datacore VirtualDisks


# Start Region Datacore Pools
if($DcsPools)
    {
    # Get DataCore Server
    $Pools = Get-DcsPool -Connection $con

    # For Each Pool
    foreach ($Pool in $Pools) 
        {
        #PoolStatus
        switch ($Pool.PoolStatus)
            {
            'Running' { $dcPoolStatus = 1 }
            'Initializing' { $dcPoolStatus = 2}
            'MissingDisks' { $dcPoolStatus = 3}
            'Foreign' { $dcPoolStatus = 4}
            'Offline' { $dcPoolStatus = 5}
            'Unknown' { $dcPoolStatus = 6}
            default { $dcPoolStatus = -1 }
            }
        $xmlOutput += "<result>
            <channel>$($Pool.Caption) PoolStatus</channel>
            <value>$($dcPoolStatus)</value>
            <ValueLookup>prtg.datacore.poolstatus</ValueLookup>
            </result>"

        #PresenceStatus
        switch ($Pool.PresenceStatus)
            {
            'Unknown' { $dcPresenceStatus = 1 }
            'Present' { $dcPresenceStatus = 2}
            'NotPresent' { $dcPresenceStatus = 3}
            default { $dcPresenceStatus = -1 }
            }
        $xmlOutput += "<result>
            <channel>$($Pool.Caption) PresenceStatus</channel>
            <value>$($dcPresenceStatus)</value>
            <ValueLookup>prtg.datacore.presencestatus</ValueLookup>
            </result>"

        $perf = Get-DcsPerformanceCounter -Object $Pool -Connection $con
        $SpaceFree = [math]::Round($perf.PercentAvailable,0)
        $xmlOutput += "<result>
            <channel>$($Pool.Caption) SpaceFree</channel>
            <value>$($SpaceFree)</value>
            <unit>Percent</unit>
            <limitmode>1</limitmode>
            <LimitMinError>10</LimitMinError>
            <LimitMinWarning>20</LimitMinWarning>
            </result>"
        }
    }
# End Region Datacore Pools

# Start Region Datacore Pools
if($DcsPorts)
    {
    $Ports = Get-DcsPortConnection -Connection $con

    $NotConnected = ""
    $NotConnectedCount = 0
    $NotPresent = ""
    $NotPresentCount = 0
    # For Each Pool
    foreach ($Port in $Ports) 
        {
        #Connected?
        if($Port.Connected -eq $false)
            {
            $NotConnectedCount += 1
            $NotConnected += "$($Port.ExtendedCaption) not connected; "

            }

        #Present?
        elseif(($Port.Connected -eq $true) -and ($Port.Present -eq $false))
            {
            $NotPresentCount += 1
            $NotPresent += "$($Port.ExtendedCaption) is connected but not Present; "
            }    
        }

    $xmlOutput += "<result>
            <channel>Ports not Connected</channel>
            <value>$($NotConnectedCount)</value>
            <unit>Count</unit>
            <limitmode>1</limitmode>
            <LimitMaxError>0</LimitMaxError>
            </result>
            <result>
            <channel>Ports not Presented</channel>
            <value>$($NotPresentCount)</value>
            <unit>Count</unit>
            <limitmode>1</limitmode>
            <LimitMaxWarning>0</LimitMaxWarning>
            </result>"

    $OutputText = ""

    if($NotConnectedCount -gt 0)
        {
        $OutputText += $NotConnected
        }

    if($NotPresentCount -gt 0)
        {
        $OutputText += $NotPresent
        }


    if(($NotConnectedCount -gt 0) -or ($NotPresentCount -gt 0))
        {
        $OutputText = $OutputText.Replace("<","")
        $OutputText = $OutputText.Replace(">","")
        $OutputText = $OutputText.Replace("#","")
        #The number sign (#) is not supported in sensor messages. If a message contains a number sign, the message is clipped at this point - https://www.paessler.com/manuals/prtg/custom_sensors
        
        $xmlOutput += "<text>$($OutputText)</text>"
        }

    else
        {
        $xmlOutput += "<text>All Ports Connected</text>"
        }
    }
# End Region Datacore Ports

# Disconnect DataCore
Disconnect-DcsServer -Connection $con

$xmlOutput += "</prtg>"

Write-Output $xmlOutput
