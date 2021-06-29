<#   
    .SYNOPSIS
    Monitors DataCore VirtualDisks

    .DESCRIPTION
    Using DataCore Powershell commands this Script checks DataCore VirtualDisks

    .PARAMETER DcsServer
    The Hostname of the DataCore Server

    .PARAMETER User
    Provide the DataCore Username

    .PARAMETER Password
    Provide the DataCore Password
    
    .EXAMPLE
    Sample call from PRTG EXE/Script Advanced
    PRTG-DataCore-VirtualDisks.ps1 -DcsServer 'YourDataCoreServer' (Windows Auth) <- better 
    PRTG-DataCore-VirtualDisks.ps1 -DcsServer 'YourDataCoreServer' -User 'YourUsername' -Password 'YourPassword' (Username and Password)

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


$xmlOutput = '<prtg>'
#Output Text
$Text = ""
if($DiskNotOnline.Count -gt 0)
    {
    $Text += $NotOnlineText
    }

if($NonMirrored.Count -gt 0)
    {
    $Text += $NonMirrorText
    }

if($RecoveryNeeded.Count -gt 0)
    {
    $Text += $RecoveryText
    }

if($Text -ne "")
    {
    $xmlOutput = $xmlOutput + "<text>$Text</text>"
    }

#Graphs
$xmlOutput = $xmlOutput + "<result>
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

# Disconnect DataCore
Disconnect-DcsServer -Connection $con

$xmlOutput = $xmlOutput + "</prtg>"

$xmlOutput