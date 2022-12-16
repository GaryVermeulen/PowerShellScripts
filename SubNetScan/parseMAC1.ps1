
##$inStr = arp -a 159.97.100.97
##$inStr = "159.97.36.104"
$inStr = "159.97.37.5"

if (Test-Connection -ComputerName $inStr -Quiet) {

    Write-Output "Before call to ARP: $inStr"

    $outARP = arp -a $inStr

    $arpMAC = "After Regex outARP: " + [string]([Regex]::Matches($outARP, "([0-9a-f][0-9a-f]-){5}([0-9a-f][0-9a-f])"))
    Write-Output  $arpMAC

    Write-Output "Before call to NBTSTAT: $inStr"
    $outNBTSTAT = nbtstat -a $inStr

    $nbtstatMAC = "After NBTSTAT outNBTSTAT: " + [string]([Regex]::Matches($outNBTSTAT, "([0-9A-F][0-9A-F]-){5}([0-9A-F][0-9A-F])"))

    Write-Output $nbtstatMAC

    Write-Output "Before call to IPCONFIG /ALL: $inStr"

    $outIPCONFIG = ipconfig /all

    $ipconfigMAC = [string]([Regex]::Matches($outIPCONFIG, "([0-9A-F][0-9A-F]-){5}([0-9A-F][0-9A-F])"))

    Write-Output "After IPCONFIG outIPCONFIG: $ipconfigMAC"

    $ipconfigMAC.Split(' ') | ForEach-Object -Process {Write-Host ">$_<"}
 }
 else {
    Write-Output "Test-Connection $inStr failed."
}