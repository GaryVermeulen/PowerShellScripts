#Find logged in user of remote computer

$computer=read-host "Enter computer name:"
gwmi win32_computersystem -comp $computer | select USername,Caption,Manufacturer
