Function Find-NetDevices
{
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
		OS_Name    : Microsoft Windows Server 2008 R2 Enterprise
		OS_Ver     : 6.1.7601 Service Pack 1
		WMI        : True
		WinRM      : True
		
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
        -Added more scanning checks for non-Windows devices in an attempt to identify
        -Added output to log file
        -Simplified return value (sorting bug)
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

	[CmdletBinding(
		SupportsShouldProcess=$True,
		ConfirmImpact="Low" 
	)]	
	param(
		[parameter(Mandatory=$true)]
		[System.Net.IPAddress]$StartScanIP,
		[System.Net.IPAddress]$EndScanIP,
		[Int]$MaxJobs = 20,
		[Int[]]$Ports,
		[Switch]$ShowAll,
		[Switch]$ShowInstantly,
		[Int]$SleepTime = 5,
		[Int]$TimeOut = 90
	)

	Begin{
        $ErrorActionPreference = "Stop"
        $myLogFile = 'c:\tmp\Find-NetDevicesLog.txt'
        $myOUIFile = 'c:\tmp\vendor.txt'

        # Set-Content -Path $myLogFile -Value ("Scan-Net log file " + (Get-Date))

        [IPAddress] $ipStart = $StartScanIP
        [IPAddress] $ipEnd   = $EndScanIP

        $outOfRange = $true

        try{
            $myIPs = Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred    
        }
        catch {
            Write-Host "Error caught while checking Host IP address..."
        }    

        Write-Host "Host IP's found: $myIPs"


        $myIPs.IPAddress | ForEach-Object -Process {if (($_ -ge $ipStart) -AND ($_ -le $ipEnd)) {$outOfRange = $false; $goodIP = $_} }

        if ($outOfRange) {
            Write-Host "Warning: One or more Host IP(s) $myIPs are out of range: $ipStart to $ipEnd"
        }
        else {
            Write-Host "Host IP(s) $goodIP are within range: $ipStart to $ipEnd"
        }

    }

	Process
	{
		if ($pscmdlet.ShouldProcess("$StartScanIP $EndScanIP" ,"Scan IP range for active machines"))
		{
			if(Get-Job -name *.*.*.*)
			{
				Write-Verbose "Removing old jobs."
				Get-Job -name *.*.*.* | Remove-Job -Force
			}
			
			$ScanIPRange = @()
			if($EndScanIP -ne $null)
			{
				Write-Verbose "Generating IP range list."
				# Many thanks to Dr. Tobias Weltner, MVP PowerShell and Grant Ward for IP range generator
				$StartIP = $StartScanIP -split '\.'
	  			[Array]::Reverse($StartIP)  
	  			$StartIP = ([System.Net.IPAddress]($StartIP -join '.')).Address 
				
				$EndIP = $EndScanIP -split '\.'
	  			[Array]::Reverse($EndIP)  
	  			$EndIP = ([System.Net.IPAddress]($EndIP -join '.')).Address 
				
				For ($x=$StartIP; $x -le $EndIP; $x++) {    
					$IP = [System.Net.IPAddress]$x -split '\.'
					[Array]::Reverse($IP)   
					$ScanIPRange += $IP -join '.' 
				}
			}
			else
			{
				$ScanIPRange = $StartScanIP
			}

			Write-Verbose "Creating own list class."
			$Class = @"
			public class SubNetItem {
				public bool Active;
				public string Host;
				public System.Net.IPAddress IP;
				public string MAC;
				public System.Object Ports;
				public string WMI_OS_Name;
   				public string WMI_OS_Ver;
                public string WMI_TAG;
                public string WMI_BIOS_Ver;
				public bool WMI;
                public string WinRM_OS_Name;
                public string WinRM_OS_Ver;
				public bool WinRM;
			}
"@		

			Write-Verbose "Start scaning..."	
			$ScanResult = @()
			$ScanCount = 0
			Write-Progress -Activity "Scan IP Range $StartScanIP $EndScanIP" -Status "Scaning:" -Percentcomplete (0)
			Foreach($IP in $ScanIPRange)
			{
	 			Write-Verbose "Starting job ($((Get-Job -name *.*.*.* | Measure-Object).Count+1)/$MaxJobs) for $IP."

				Start-Job -Name $IP -ArgumentList $IP,$Ports,$Class -ScriptBlock{ 
				
					param
					(
                    ##$myOUIFile = $myOUIFile,  # Something strange since it hangs while passing file name...~? 
					[System.Net.IPAddress]$IP = $IP,
					[Int[]]$Ports = $Ports,
					$Class = $Class 
					)
					
					Add-Type -TypeDefinition $Class

					
					if(Test-Connection -ComputerName $IP -Quiet)
					{
						#Get Hostname
						Try
						{
							$HostName = [System.Net.Dns]::GetHostbyAddress($IP).HostName
						}
						Catch
						{
							$HostName = $null
			                Write-Verbose "GetHostbyAddress($IP) failed to return HostName"	
						}
						
						#Get WMI Access, OS Name and version via WMI
						Try
						{
							#I don't use Get-WMIObject because it havent TimeOut options. 
							$WMIObj = [WMISearcher]''  
							$WMIObj.options.timeout = '0:0:10' 
							$WMIObj.scope.path = "\\$IP\root\cimv2"  
							$WMIObj.query = "SELECT * FROM Win32_OperatingSystem"  
                            
							$Result = $WMIObj.get()  

							if($Result -ne $null)
							{
								$WMI_OS_Name = $Result | Select-Object -ExpandProperty Caption
								$WMI_OS_Ver = $Result | Select-Object -ExpandProperty Version
								$WMI_OS_CSDVer = $Result | Select-Object -ExpandProperty CSDVersion
								$WMI_OS_Ver += "> $WMI_OS_CSDVer"			
								$WMIAccess = $true					
							}
							else
							{
								$WMIAccess = $false	
							}
						}	
						catch
						{
							$WMIAccess = $false					
						}

                        # Get serial number
                        if ($WMIAccess -eq $true)
                        {
                            try
                            {
                                #Same code as aboved but looking for serial number. 
							    $WMIObj = [WMISearcher]''  
							    $WMIObj.options.timeout = '0:0:10' 
							    $WMIObj.scope.path = "\\$IP\root\cimv2"  
							    $WMIObj.query = "SELECT * FROM Win32_Bios"  
                            
							    $Result = $WMIObj.get()  

							    if($Result -ne $null)
							    {
								    $WMI_TAG = $Result | Select-Object -ExpandProperty SerialNumber
								    $WMI_BIOS_Ver = $Result | Select-Object -ExpandProperty SMBIOSBIOSVersion
								    $WMIAccess = $true					
							    }
							    else
							    {
								    $WMIAccess = $false	
							    }
                            }
                            catch
                            {
                                # This shouldn't happen
                                $WMIAccess = $false
                            }
                        }
						
						#Get WinRM Access, OS Name and version via WinRM
						if($HostName)
						{
							$Result = Invoke-Command -ComputerName $HostName -ScriptBlock {systeminfo} -ErrorAction SilentlyContinue 
						}
						else
						{
							$Result = Invoke-Command -ComputerName $IP -ScriptBlock {systeminfo} -ErrorAction SilentlyContinue 
						}

                        if($Result -ne $null) 
                        {
                            $WinRM_OS_Name = ($Result[2..3] -split ":\s+")[1]
                            $WinRM_OS_Ver = ($Result[2..3] -split ":\s+")[3]
                            $WinRMAccess = $true
                        }
                        else
                        {
                            $WinRMAccess = $false
                        }
                        						
						
						#Get MAC Address using NBTSTAT or ARP 
						Try
						{
							$result = nbtstat -A $IP | select-string "MAC"
                            $result = [string]([Regex]::Matches($result, "([0-9A-F][0-9A-F]-){5}([0-9A-F][0-9A-F])"))
                            if (($result -eq $null) -or ($result -eq '')) {
                                
                                $MAC = $null
                            }
                            else {
							    $MAC = "N: $result"
                            } 
						}
						Catch
						{
							$MAC = $null
						}
                        
                        if($MAC -eq $null)
                        {
                            # Is there an entry in ARP?
                            Try
						    {
							    $result = arp -A $IP
                                $result = [string]([Regex]::Matches($result, "([0-9a-f][0-9a-f]-){5}([0-9a-f][0-9a-f])"))
                                if (($result -eq $null) -or ($result -eq ''))
                                {
                                    $MAC = $null
                                } 
                                else 
                                {
                                    $MAC = "A: $result"
                                }  
						    }
						    Catch
						    {
							    $MAC = $null
						    }
						}

                        # Match MAC to vendor
                        if($MAC -ne $null) 
                        {    
                            Try
			                {
				               ## $output = Select-String -Path $myOUIFile -pattern $result.Substring(0,8)
                                $output = Select-String -Path 'c:\tmp\vendor.txt' -pattern $result.Substring(0,8) # Workaround until resolution of passing $myOUIFile issue
				                $output = $output -replace ".*(hex)"
				                $output = $output.Substring(3)
                                $MAC = "$MAC $output"
			                }
			                Catch
			                {
				                Write-Host "MAC address was not found"				   
			                }
                        }
                        else {
                            $MAC = "No MAC found"
                        }


						#Get ports status
						$PortsStatus = @()
						ForEach($Port in $Ports)
						{
							Try
							{							
								$TCPClient = new-object Net.Sockets.TcpClient
								$TCPClient.Connect($IP, $Port)
								$TCPClient.Close()
								
								$PortStatus = New-Object PSObject -Property @{            
		        					Port		= $Port
									Status      = $true
								}
								$PortsStatus += $PortStatus
							}	
							Catch
							{
								$PortStatus = New-Object PSObject -Property @{            
		        					Port		= $Port
									Status      = $false
								}	
								$PortsStatus += $PortStatus
							}
						}

						
						$HostObj = New-Object SubNetItem -Property @{            
		        					Active		  = $true
									Host          = $HostName
									IP            = $IP 
									MAC           = $MAC
									Ports         = $PortsStatus
		        					WMI_OS_Name   = $WMI_OS_Name
									WMI_OS_Ver    = $WMI_OS_Ver               
                                    WMI_TAG       = $WMI_TAG
                                    WMI_BIOS_Ver  = $WMI_BIOS_Ver
		        					WMI           = $WMIAccess
                                    WinRM_OS_Name = $WinRM_OS_Name
									WinRM_OS_Ver  = $WinRM_OS_Ver               
		        					WinRM         = $WinRMAccess
		        		}
						$HostObj
					}
					else
					{
						$HostObj = New-Object SubNetItem -Property @{            
		        					Active		  = $false
									Host          = $null
									IP            = $IP  
									MAC           = $null
									Ports         = $null
		        					WMI_OS_Name   = $null
									WMI_OS_Ver    = $null               
                                    WMI_TAG       = $null
                                    WMI_BIOS_Ver  = $null
		        					WMI           = $null      
                                    WinRM_OS_Name = $null
                                    WinRM_OS_Ver  = $null
		        					WinRM         = $null
		        		}
						$HostObj
					}
				} | Out-Null
				$ScanCount++
				Write-Progress -Activity "Scan IP Range $StartScanIP $EndScanIP" -Status "Scaning:" -Percentcomplete ([int](($ScanCount+$ScanResult.Count)/(($ScanIPRange | Measure-Object).Count) * 50))
				
				do
				{
					Write-Verbose "Trying get part of data."
					Get-Job -State Completed | Foreach {
						Write-Verbose "Geting job $($_.Name) result."
						$JobResult = Receive-Job -Id ($_.Id)

						if($ShowAll)
						{
							if($ShowInstantly)
							{
								if($JobResult.Active -eq $true)
								{
									Write-Host "$($JobResult.IP) is active." -ForegroundColor Green
								}
								else
								{
									Write-Host "$($JobResult.IP) is inactive." -ForegroundColor Red
								}
							}
							
							$ScanResult += $JobResult	
						}
						else
						{
							if($JobResult.Active -eq $true)
							{
								if($ShowInstantly)
								{
									Write-Host "$($JobResult.IP) is active." -ForegroundColor Green
								}
								$ScanResult += $JobResult
							}
						}
						Write-Verbose "Removing job $($_.Name)."
						Remove-Job -Id ($_.Id)
						Write-Progress -Activity "Scan IP Range $StartScanIP $EndScanIP" -Status "Scaning:" -Percentcomplete ([int](($ScanCount+$ScanResult.Count)/(($ScanIPRange | Measure-Object).Count) * 50))
					}
					
					if((Get-Job -name *.*.*.*).Count -eq $MaxJobs)
					{
						Write-Verbose "Jobs are not completed ($((Get-Job -name *.*.*.* | Measure-Object).Count)/$MaxJobs), please wait..."
						Sleep $SleepTime
					}
				}
				while((Get-Job -name *.*.*.*).Count -eq $MaxJobs)
			}
			
			$timeOutCounter = 0
			do
			{
				Write-Verbose "Trying get last part of data."
				Get-Job -State Completed | Foreach {
					Write-Verbose "Geting job $($_.Name) result."
					$JobResult = Receive-Job -Id ($_.Id)

					if($ShowAll)
					{
						if($ShowInstantly)
						{
							if($JobResult.Active -eq $true)
							{
								Write-Host "$($JobResult.IP) is active." -ForegroundColor Green
							}
							else
							{
								Write-Host "$($JobResult.IP) is inactive." -ForegroundColor Red
							}
						}
						
						$ScanResult += $JobResult	
					}
					else
					{
						if($JobResult.Active -eq $true)
						{
							if($ShowInstantly)
							{
								Write-Host "$($JobResult.IP) is active." -ForegroundColor Green
							}
							$ScanResult += $JobResult
						}
					}
					Write-Verbose "Removing job $($_.Name)."
					Remove-Job -Id ($_.Id)
					Write-Progress -Activity "Scan IP Range $StartScanIP $EndScanIP" -Status "Scaning:" -Percentcomplete ([int](($ScanCount+$ScanResult.Count)/(($ScanIPRange | Measure-Object).Count) * 50))
				}
				
				if(Get-Job -name *.*.*.*)
				{
					Write-Verbose "All jobs are not completed ($((Get-Job -name *.*.*.* | Measure-Object).Count)/$MaxJobs), please wait... ($timeOutCounter)"
					Sleep $SleepTime
					$timeOutCounter += $SleepTime				

					if($timeOutCounter -ge $TimeOut)
					{
						Write-Verbose "Time out... $TimeOut. Can't finish some jobs  ($((Get-Job -name *.*.*.* | Measure-Object).Count)/$MaxJobs) try remove it manualy."
						Break
					}
				}
			}
			while(Get-Job -name *.*.*.*)
			
			Write-Verbose "Scan finished."

          #  Add-Content -Path $myLogFile -Value ("$myString $myNumber " + (Get-Date))

            $sortedObj = $ScanResult | Sort-Object -Property @{Expression = {$_.IP}} | Format-Table IP, Active, MAC, WMI, WinRM, Host, WMI_OS_Name, WMI_OS_Ver, WMI_TAG, WMI_BIOS_Ver, WinRM_OS_Name, WinRM_OS_Ver, Ports -AutoSize

            $strObj = Out-String -InputObject $sortedObj 

            # Add-Content -Path $myLogFile -Value $strObj

            Set-Content -Path $myLogFile -Value $strObj
 
            Return $ScanResult | Sort-Object -Property @{Expression = {$_.IP}} 
		}
	}
	
	End{
        Add-Content -Path $myLogFile -Value "*End*"
    }
}
