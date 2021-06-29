<#   
    .SYNOPSIS
    Monitors DataCore Alerts

    .DESCRIPTION
    Using DataCore Powershell commands this Script checks DataCore Alerts

    .PARAMETER DcsServer
    The Hostname of the DataCore Server

    .PARAMETER User
    Provide the DataCore Username

    .PARAMETER Password
    Provide the DataCore Password
    
    .EXAMPLE
    Sample call from PRTG EXE/Script Advanced
    PRTG-DataCore-Alerts.ps1 -DcsServer 'YourDataCoreServer' (Windows Auth) <- better 
    PRTG-DataCore-Alerts.ps1 -DcsServer 'YourDataCoreServer' -User 'YourUsername' -Password 'YourPassword' (Username and Password)

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

# Get DataCore Server Alerts
$DCsAlerts = Get-DcsAlert -Connection $con

$ErrorCount = 0
$WarningCount = 0
$ErrorText = "Error: "
$WarningText = "Warning: "

foreach($alert in $DCsAlerts)
    {
    if($alert.Level -eq "Warning")
        {
        $WarningCount += 1
        $WarningText += "$($alert.MessageText) ###"
        }
    elseif($alert.Level -eq "Error")
        {
        $ErrorCount += 1
        $ErrorText += "$($alert.MessageText) ###"
        }
    }

$xmlOutput = '<prtg>'

$xmlOutput = $xmlOutput + "<result>
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

# Disconnect DataCore
Disconnect-DcsServer -Connection $con

# Output Text
$OutputText =""

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
    #The number sign (#) is not supported in sensor messages. If a message contains a number sign, the message is clipped at this point - https://www.paessler.com/manuals/prtg/custom_sensors
    
    $xmlOutput = $xmlOutput + "<text>$OutputText</text>"
    }

else
    {
    $xmlOutput = $xmlOutput + "<text>No Alerts found</text>"
    }

$xmlOutput = $xmlOutput + "</prtg>"

try
    {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::WriteLine($xmlOutput)
    #https://kb.paessler.com/en/topic/64817-how-can-i-show-special-characters-with-exe-script-sensors
    }

catch
    {
    $xmlOutput
    }
