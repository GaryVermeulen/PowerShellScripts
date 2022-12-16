#
# Simple script to retrieve Windows version and discern build number
# GV; v1.0; New; 6/1/2020
# GV: v1.1; Added search by OU or PC; 3/5/21
#

$searchOU = Read-Host "Search by OU <Y/N>?"

if (($searchOU -eq 'Y') -or ($searchOU -eq 'y')) {
    $searchOU = Read-Host "Enter OU:"
    $searchPC = ""
} elseif (($searchOU -eq 'N') -or ($searchOU -eq 'n')) {
    $searchPC = Read-Host "Enter PC search string:"
    $searchOU = ""
} else {
    Write-Host "I'm sorry Dave, I'm affraid I can't do that." -ForegroundColor Red
    exit
}

#

function ConvertTo-OperatingSystem {
    [CmdletBinding()]
    param(
        [string] $OperatingSystem,
        [string] $OperatingSystemVersion
    )
    if ($OperatingSystem -like 'Windows 10*') {
        $Systems = @{
            '10.0 (19042)' = "Windows 10 20H2"
            '10.0 (19041)' = "Windows 10 2004"
            '10.0 (18363)' = "Windows 10 1909"
            '10.0 (18362)' = "Windows 10 1903"
            '10.0 (17763)' = "Windows 10 1809"
            '10.0 (17134)' = "Windows 10 1803"
            '10.0 (16299)' = "Windows 10 1709"
            '10.0 (15063)' = "Windows 10 1703"
            '10.0 (14393)' = "Windows 10 1607"
            '10.0 (10586)' = "Windows 10 1511"
            '10.0 (10240)' = "Windows 10 1507"
            '10.0 (18898)' = 'Windows 10 Insider Preview'
        }
        $System = $Systems[$OperatingSystemVersion]
    } elseif ($OperatingSystem -notlike 'Windows 10*') {
        $System = $OperatingSystem
    }
    if ($System) {
        $System
    } else {
        'Unknown'
    }
}

#

$tmpPath = 'c:\tmp' 

if (Test-Path -Path $tmpPath) {
    $myLogFile = $tmpPath + '\WinBuildLog.csv'
} else {
    New-Item -Path "c:\" -Name 'tmp' -ItemType "directory"
    $myLogFile = $tmpPath + '\WinBuildLog.csv'
}


if ($searchOU -ne "") {
    $Computers = Get-ADComputer -Filter * -SearchBase "OU=Computers,OU=$searchOU,OU=North America,DC=gracead,DC=com" -Properties Name, OperatingSystem, OperatingSystemVersion, LastLogonDate, Description
} else {
    $Computers = Get-ADComputer -Filter 'name -like $searchPC'-properties Name, OperatingSystem, OperatingSystemVersion, LastLogonDate, Description
}

$ComputerList = foreach ($_ in $Computers) {
    [PSCustomObject] @{
        Name                   = $_.Name
        OperatingSystem        = $_.OperatingSystem
        OperatingSystemVersion = $_.OperatingSystemVersion
        System                 = ConvertTo-OperatingSystem -OperatingSystem $_.OperatingSystem -OperatingSystemVersion $_.OperatingSystemVersion
        LastLogonDate          = $_.LastLogonDate
        Description            = $_.Description
    }
}

$ComputerList | Group-Object -Property System | Format-Table -Property Name, Count

$ComputerList | Sort-Object -Property @{Expression = {$_.Name}} | Export-Csv -Path $myLogFile -NoTypeInformation

$ComputerList | Sort-Object -Property @{Expression = {$_.Name}} | Format-Table -AutoSize