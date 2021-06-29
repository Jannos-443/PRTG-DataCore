<#   
    .SYNOPSIS
    Monitors DataCore Ports

    .DESCRIPTION
    Using DataCore Powershell commands this Script checks DataCore Ports

    .PARAMETER DcsServer
    The Hostname of the DataCore Server

    .PARAMETER User
    Provide the DataCore Username

    .PARAMETER Password
    Provide the DataCore Password
    
    .EXAMPLE
    Sample call from PRTG EXE/Script Advanced
    PRTG-DataCore-Ports.ps1 -DcsServer 'YourDataCoreServer' (Windows Auth) <- better 
    PRTG-DataCore-Ports.ps1 -DcsServer 'YourDataCoreServer' -User 'YourUsername' -Password 'YourPassword' (Username and Password)

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
$DcsPorts = Get-DcsPortConnection -Connection $con

$NotConnected = ""
$NotConnectedCount = 0
$NotPresent = ""
$NotPresentCount = 0
# For Each Pool
foreach ($Port in $DcsPorts) 
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

# Disconnect DataCore
Disconnect-DcsServer -Connection $con
$xmlOutput = '<prtg>'
$xmlOutput = $xmlOutput + "<result>
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
    
    $xmlOutput = $xmlOutput + "<text>$OutputText</text>"
    }

else
    {
    $xmlOutput = $xmlOutput + "<text>All Ports Connected</text>"
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