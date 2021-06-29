<#   
    .SYNOPSIS
    Monitors DataCore Pools

    .DESCRIPTION
    Using DataCore Powershell commands this Script checks DataCore Pools

    .PARAMETER DcsServer
    The Hostname of the DataCore Server

    .PARAMETER User
    Provide the DataCore Username

    .PARAMETER Password
    Provide the DataCore Password
    
    .EXAMPLE
    Sample call from PRTG EXE/Script Advanced
    PRTG-DataCore-Pools.ps1 -DcsServer 'YourDataCoreServer' (Windows Auth) <- better 
    PRTG-DataCore-Pools.ps1 -DcsServer 'YourDataCoreServer' -User 'YourUsername' -Password 'YourPassword' (Username and Password)

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
        $null = Disconnect-DcsServer -Connection $con -Confirm:$false -ErrorAction SilentlyContinue
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
$DcsPools = Get-DcsPool -Connection $con

$xmlOutput = '<prtg>'

# For Each Pool
foreach ($Pool in $DcsPools) 
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
    $xmlOutput = $xmlOutput + "<result>
        <channel>$($Pool.Caption) PoolStatus</channel>
        <value>$dcPoolStatus</value>
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
    $xmlOutput = $xmlOutput + "<result>
        <channel>$($Pool.Caption) PresenceStatus</channel>
        <value>$dcPresenceStatus</value>
        <ValueLookup>prtg.datacore.presencestatus</ValueLookup>
        </result>"

    $perf = Get-DcsPerformanceCounter -Object $Pool -Connection $con
    $SpaceFree = [math]::Round($perf.PercentAvailable,0)
    $xmlOutput = $xmlOutput + "<result>
        <channel>$($Pool.Caption) SpaceFree</channel>
        <value>$($SpaceFree)</value>
        <unit>Percent</unit>
        <limitmode>1</limitmode>
        <LimitMinError>10</LimitMinError>
        <LimitMinWarning>20</LimitMinWarning>
        </result>"
    }

# Disconnect DataCore
Disconnect-DcsServer -Connection $con

$xmlOutput = $xmlOutput + "</prtg>"

$xmlOutput