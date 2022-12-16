# Simple script to find a user
#

$searchUser = Read-Host "User name?"

If ($searchUser -eq "") {
    Write-Host "Nothing to do" -ForegroundColor Red
    exit
}

$searchUser = "*$searchUser*"

Get-ADUser -Filter 'Name -like $searchUser' | Format-Table Name, SamAccountName, DistinguishedName -AutoSize
