Function Get-WinVerX {

    [CmdletBinding(
        SupportsShouldProcess=$True,
	    ConfirmImpact="Low"
    )]

    Param
   (
#        [Parameter(
#            Mandatory=$true
        #    Mandatory=$false,
        #    ValueFromPipelineByPropertyName=$true,
        #    ValueFromPipeline=$true
#        )]
        [string]$ouName,
        [string[]]$ComputerName = $env:COMPUTERNAME
    )


    Begin
    {

        Write-Host "In Begin..."

#        $Table = New-Object System.Data.DataTable
#        $Table.Columns.AddRange(@("ComputerName","Windows Edition","Version","OS Build"))
#
#
#        if ($ouName) {
#        # There may be a better way to do this, but for now, it works
#           try {
#                $ouName = Get-ADOrganizationalUnit -Filter 'Name -like $ouName' | Select-Object DistinguishedName -First 1
#            }
#            catch {
#                Write-Host "Unable to find $ouName in this Domain -- exiting."
#                exit(1)
#            }
#            $myStr = $ouName | foreach {"$_"}
#            $newStr = $myStr.Substring(20)
#            $ouName = $newStr.Substring(0,$newStr.Length-1)
#
#            Write-Host "Search ouName: >>$ouName<<"
#            try {
#                #$pcNames = Get-ADComputer -Filter * -SearchBase $ouName | Select -Expand Name
#                $pcNames = Get-ADComputer -Filter {(Enabled -eq $true)} -SearchBase $ouName | Select -Expand Name
#
#                $pcNamesCnt = $pcNames.Length
#
#                write-host "Found $pcNamesCnt devices to check."
#            }
#            catch {
#                Write-Host "Problem reading AD" -ForegroundColor Red
#                $ouName = $null
#            }
#        }
#        else {
#            Write-Host "No OU"
#        }
#
#        write-host "Exit for now"
#        exit(0)
    }
#
    Process
    {

        Write-Host "In Process..."

#        Foreach ($Computer in $ComputerName)
#        {
#            $Code = {
#                $ProductName = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' –Name ProductName).ProductName
#                Try
#                {
#                    $Version = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' –Name ReleaseID –ErrorAction Stop).ReleaseID
#                }
#                Catch
#                {
#                    $Version = "N/A"
#                }
#                $CurrentBuild = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' –Name CurrentBuild).CurrentBuild
#                $UBR = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' –Name UBR).UBR
#                $OSVersion = $CurrentBuild + "." + $UBR
#
#                $TempTable = New-Object System.Data.DataTable
#                $TempTable.Columns.AddRange(@("ComputerName","Windows Edition","Version","OS Build"))
#                [void]$TempTable.Rows.Add($env:COMPUTERNAME,$ProductName,$Version,$OSVersion)
#        
#                Return $TempTable
#            }
#
#            If ($Computer -eq $env:COMPUTERNAME)
#            {
#                $Result = Invoke-Command –ScriptBlock $Code
#                [void]$Table.Rows.Add($Result.Computername,$Result.'Windows Edition',$Result.Version,$Result.'OS Build')
#            }
#            Else
#            {
#                Try
#                {
#                    $Result = Invoke-Command –ComputerName $Computer –ScriptBlock $Code –ErrorAction Stop
#                    [void]$Table.Rows.Add($Result.Computername,$Result.'Windows Edition',$Result.Version,$Result.'OS Build')
#                }
#                Catch
#                {
#                    $_
#                }
#            }
#
#        }
#
    }

    End
    {

        Write-Host "In End."

#        Return $Table
    }
}

Get-WinVerX
