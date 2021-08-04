<#   
    .SYNOPSIS
    Monitors DataCore Status

    .DESCRIPTION
    Using DataCore Powershell commands this Script checks DataCore Status

    .PARAMETER DcsServer
    The Hostname of the DataCore Server

    .PARAMETER User
    Provide the DataCore Username

    .PARAMETER Password
    Provide the DataCore Password
    
    .EXAMPLE
    Sample call from PRTG EXE/Script Advanced
    PRTG-DataCore-Status.ps1 -DcsServer 'YourDataCoreServer' (Windows Auth) <- better 
    PRTG-DataCore-Status.ps1 -DcsServer 'YourDataCoreServer' -User 'YourUsername' -Password 'YourPassword' (Username and Password)

    Author:  Jannos-443
    https://github.com/Jannos-443/PRTG-DataCore

#>
param(
    [string]$DcsServer = '',
    [string]$User = '',
    [string]$Password = ''
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
    Write-Output "<prtg>"
    Write-Output "<error>1</error>"
    Write-Output "<text>$Output</text>"
    Write-Output "</prtg>"
    Exit
}

#https://stackoverflow.com/questions/19055924/how-to-launch-64-bit-powershell-from-32-bit-cmd-exe
#############################################################################
#If Powershell is running the 32-bit version on a 64-bit machine, we 
#need to force powershell to run in 64-bit mode .
#############################################################################
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    #Write-warning  "Y'arg Matey, we're off to 64-bit land....."
    if ($myInvocation.Line) {
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    }else{
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
    }
exit $lastexitcode
}

#############################################################################
#End
#############################################################################    

# Error if there's anything going on
$ErrorActionPreference = "Stop"


# Import VMware PowerCLI module
try {
    Import-Module "C:\Program Files\DataCore\Powershell Support\DataCore.Executive.Cmdlets.dll" -ErrorAction Stop
} catch {
    Write-Output "<prtg>"
    Write-Output " <error>1</error>"
    Write-Output " <text>Error Loading DataCore Powershell Module ($($_.Exception.Message))</text>"
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
    Write-Output " <error>1</error>"
    Write-Output " <text>Could not connect to Datacore server $DcsServer. Error: $($_.Exception.Message)</text>"
    Write-Output "</prtg>"
    Exit
    }

# Get DataCore Server
$DCs = Get-DcsServer -Connection $con

#Online Server
$DCsOnline = ($DCs | where {$_.State -eq "Online"}).count

$xmlOutput = '<prtg>'

$xmlOutput = $xmlOutput + "<result>
        <channel>Server Online</channel>
        <value>$DCsOnline</value>
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
    $xmlOutput = $xmlOutput + "<result>
        <channel>$($DC.Caption) State</channel>
        <value>$dcstate</value>
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
    $xmlOutput = $xmlOutput + "<result>
        <channel>$($DC.Caption) LogStatus</channel>
        <value>$dclogstatus</value>
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
    $xmlOutput = $xmlOutput + "<result>
        <channel>$($DC.Caption) PowerState</channel>
        <value>$dcpowerstate</value>
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
    $xmlOutput = $xmlOutput + "<result>
        <channel>$($DC.Caption) CacheState</channel>
        <value>$dccachestate</value>
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
    $xmlOutput = $xmlOutput + "<result>
        <channel>$($DC.Caption) MemoryUsed</channel>
        <value>$UsedMem</value>
        <unit>Percent</unit>
        <limitmode>1</limitmode>
        <LimitMaxError>90</LimitMaxError>
        <LimitMaxWarning>80</LimitMaxWarning>
        </result>"
    }

#Storage Used (Byte?)
$StorageUsed = $DCs.StorageUsed | select -First 1 -ExpandProperty Value
$xmlOutput = $xmlOutput + "<result>
        <channel>Storage Used</channel>
        <value>$StorageUsed</value>
        <unit>BytesDisk</unit>
        </result>"



# Disconnect DataCore
Disconnect-DcsServer -Connection $con

if($DCsOnline -ge 1)
    {
    $xmlOutput = $xmlOutput + "<text>$($NodeOnlineTXT)</text>"
    }
else
    {
    $xmlOutput = $xmlOutput + "<text>No Online Nodes!</text>"
    }

$xmlOutput = $xmlOutput + "</prtg>"

$xmlOutput
