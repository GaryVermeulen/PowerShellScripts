# *** Verify file location ***
$Records=Import-CSV C:\gdata\oui\Oui.csv
$myARP = arp -a
$myIPAddress = ''
$myDeviceList = @()

Write-Host $myARP.GetType()

Write-Host "================"
Write-Host $myARP
Write-Host "================"

ForEach ($entry in $myARP) {

    #Write-Host $entry

    # Parse localhost IP address
    if ($entry.Contains("Interface:")) {
         
        $tmpCnt = 0
        $tmpList = $entry.Split()

        ForEach ($tmpEntry in $tmpList) {
            
            if ($tmpCnt -eq 1) {
                $myIPAddress = $tmpEntry
                #Write-Host $myIPAddress

                $tmpSubNet = $myIPAddress.split(".")

                $mySubNet = $tmpSubNet[0] + "." + $tmpSubNet[1] + "." + $tmpSubNet[2]

                #Write-Host "SUB" $mySubNet
            }
            $tmpCnt += 1
        }
        #Write-Host "..........."
    }

    # Parse the rest of the arp entries and keep IP and MAC
    if ($entry.Contains($mySubNet)) {
        #Write-Host "x" $entry

        $tmpEntryList = $entry.split()
        $tmpCnt = 0
        ForEach ($tmpEntry in $tmpEntryList) {
            #Write-Host $tmpCnt $tmpEntry $mySubNet

            if ($tmpEntry.Contains($mySubNet)) {
                $tmpIP = $tmpEntry
                #Write-Host "GOT IP:" $tmpIP
              
            }

            if ($tmpEntry -like "*-*-*-*-*-*") {
                $tmpMAC = $tmpEntry
                #Write-Host "GOT MAC:" $tmpMAC
            }
            $tmpCnt += 1
        }
    }

    #Write-Host "PAIR" $tmpIp $tmpMAC

    if ($tmpMAC -ne "ff-ff-ff-ff-ff-ff") {
        if (-not ("$tmpIP,$tmpMAC" -in $myDeviceList)) {
            $myDeviceList += "$tmpIP,$tmpMAC"
        }
    }
    #Write-Host "----------"
    #Write-Host "LEN" $myDeviceList.Length
}

foreach ($tmpEntry in $myDeviceList) {
#    Write-Host $tmpEntry
#    Write-Host $tmpEntry.GetType()
    $tmpDevice = $tmpEntry.Split(",")
    $tmpIP = $tmpDevice[0]
    $tmpMAC = $tmpDevice[1]
#    Write-Host $tmpIP $tmpMAC
#    Write-Host "----------"

    Try
	{
	    $DNSName = [System.Net.Dns]::GetHostbyAddress($tmpIP).HostName
	}
	Catch
	{
		$DNSName = "UNK"
	}

    

    Write-Host "IP:" $tmpIP
    Write-Host "DNS Name:" $DNSName
    Write-Host "MAC:" $tmpMAC

    $tmpMACList = $tmpMAC.split("-")
    $tmpMACLookup = $tmpMACList[0] + $tmpMACList[1] + $tmpMACList[2]

#    Write-Host "LOOKUP" $tmpMACLookup

    ForEach ($Record in $Records){
        If ($Record.Assignment -eq $tmpMACLookup){
            Write-Host "Vendor:" $Record
        }
    }

    Write-Host "________________"

}
    

