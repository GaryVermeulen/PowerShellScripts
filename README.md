Find-NetDevices.psm1
Modofied version of Michal Gajda's Get-NetItems (Thank you Michal!)
Attempting (work-in-process) to acquire as much information as possible from all devices found on a given subnet.

<# 
	.SYNOPSIS 
		Scan subnet machines
		
	.DESCRIPTION 
		Use Find-NetDevices to receive list of machines in specific IP range.
	.PARAMETER StartScanIP 
		Specify start of IP range.
	.PARAMETER EndScanIP
		Specify end of IP range.
	.PARAMETER Ports
		Specify ports numbers to scan if open or not.
		
	.PARAMETER MaxJobs
		Specify number of threads to scan.
		
	.PARAMETER ShowAll
		Show even adress is inactive.
	
	.PARAMETER ShowInstantly 
		Show active status of scaned IP address instanly. 
	
	.PARAMETER SleepTime  
		Wait time to check if threads are completed.
 
	.PARAMETER TimeOut 
		Time out when script will be break.
	.EXAMPLE 
		PS C:\>$Result = Find-NetDevices -StartScanIP 10.10.10.1 -EndScanIP 10.10.10.10 -ShowInstantly -ShowAll
		10.10.10.7 is active.
		10.10.10.10 is active.
		10.10.10.9 is active.
		10.10.10.1 is inactive.
		10.10.10.6 is active.
		10.10.10.4 is active.
		10.10.10.3 is inactive.
		10.10.10.2 is active.
		10.10.10.5 is active.
		10.10.10.8 is inactive.
		PS C:\> $Result | Format-Table IP, Active, WMI, WinRM, Host, OS_Name -AutoSize
		IP           Active   WMI WinRM Host              OS_Name
		--           ------   --- ----- ----              -------
		10.10.10.1    False False False
		10.10.10.2     True  True  True pc02.mydomain.com Microsoft Windows Server 2008 R2 Enterprise
		10.10.10.3    False False False
		10.10.10.4     True  True  True pc05.mydomain.com Microsoft Windows Server 2008 R2 Enterprise
		10.10.10.5     True  True  True pc06.mydomain.com Microsoft Windows Server 2008 R2 Enterprise
		10.10.10.6     True  True  True pc07.mydomain.com Microsoft(R) Windows(R) Server 2003, Standard Edition
		10.10.10.7     True False False
		10.10.10.8    False False False
		10.10.10.9     True  True False pc09.mydomain.com Microsoft Windows Server 2008 R2 Enterprise
		10.10.10.10    True  True False pc10.mydomain.com Microsoft Windows XP Professional
	.EXAMPLE 
		PS C:\> Find-NetDevices -StartScanIP 10.10.10.2 -Verbose
		VERBOSE: Creating own list class.
		VERBOSE: Start scaning...
		VERBOSE: Starting job (1/20) for 10.10.10.2.
		VERBOSE: Trying get part of data.
		VERBOSE: Trying get last part of data.
		VERBOSE: All jobs is not completed (1/20), please wait... (0)
		VERBOSE: Trying get last part of data.
		VERBOSE: All jobs is not completed (1/20), please wait... (5)
		VERBOSE: Trying get last part of data.
		VERBOSE: All jobs is not completed (1/20), please wait... (10)
		VERBOSE: Trying get last part of data.
		VERBOSE: Geting job 10.10.10.2 result.
		VERBOSE: Removing job 10.10.10.2.
		VERBOSE: Scan finished.
		RunspaceId : d2882105-df8c-4c0a-b92c-0d078bcde752
		Active     : True
		Host       : pc02.mydomain.com
		IP         : 10.10.10.2
		MAC        :
		OS_Name    : Microsoft Windows Server 2008 R2 Enterprise
		OS_Ver     : 6.1.7601 Service Pack 1
		WMI        : True
		WinRM      : True
		TAG        :
		BIOS_Ver   :
		
	.EXAMPLE 	
		PS C:\> $Result = Find-NetDevices -StartScanIP 10.10.10.1 -EndScanIP 10.10.10.25 -Ports 80,3389,5900	
		PS C:\> $Result | Select-Object IP, Host, MAC, @{l="Ports";e={[string]::join(", ",($_.Ports | Select-Object @{Label="Ports";Expression={"$($_.Port)-$($_.Status)"}} | Select-Object -ExpandProperty Ports))}} | Format-Table * -AutoSize
		
		IP          Host              MAC               Ports
		--          ----              ---               -----
		10.10.10.1                                      80-False, 3389-False, 5900-False
		10.10.10.2  pc02.mydomain.com 00-15-AD-0C-82-20 80-True, 3389-False, 5900-False
		10.10.10.5  pc05.mydomain.com 00-15-5D-1C-80-25 80-True, 3389-False, 5900-False
		10.10.10.7  pc07.mydomain.com 00-15-4D-0C-81-04 80-True, 3389-True, 5900-False
		10.10.10.9  pc09.mydomain.com 00-15-4A-0C-80-31 80-True, 3389-True, 5900-False
		10.10.10.10 pc10.mydomain.com 00-15-5D-02-1F-1C 80-False, 3389-True, 5900-False
	.NOTES 
	Original Get-SubNetItems Author: Michal Gajda
	Modifier: GV
		
	ChangeLog:
	----------
	v2.0; GV
		-Changed name
		-Added(adding) more scanning checks for non-Windows devices in an attempt to identify
		-Added output to log file
		-Simplified return value (fixed sorting bug)
		-Added host IP subnet check (is the host within the entered range?) 
		-Added MAC OUI, Many thanks to Tyler Wright's Get-MACVednor.psm1
	v1.4; GV
		-Check arp if nbtstat returns null
		-Scan for serial number
		
	v1.3
		-Scan items in subnet for MAC
		-Basic port scan on items in subnet
		-Fixed some small spelling bug
		
	v1.2
		-IP Range Ganerator upgrade
		
	v1.1
		-ProgressBar upgrade
		
	v1.0:
		-Scan subnet for items
		-Scan items in subnet for WMI Access
		-Scan items in subnet for WinRM Access
#>
