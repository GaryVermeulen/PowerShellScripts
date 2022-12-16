$IP = "159.97.100.28"


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
		$OS_Name = $Result | Select-Object -ExpandProperty Caption
		$OS_Ver = $Result | Select-Object -ExpandProperty Version
		$OS_CSDVer = $Result | Select-Object -ExpandProperty CSDVersion
		$OS_Ver += " $OS_CSDVer"
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


Write-Output $Result
