# https://www.maximerastello.com/manually-re-enroll-a-co-managed-or-hybrid-azure-ad-join-windows-10-pc-to-microsoft-intune-without-loosing-current-configuration/
$ErrorActionPreference = "SilentlyContinue"


$regArr = @(
    "HKLM:\SOFTWARE\Microsoft\Enrollments\", 
    "HKLM:\SOFTWARE\Microsoft\Enrollments\Status\", 
    "HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked\", 
    "HKLM:\SOFTWARE\Microsoft\PolicyManager\AdmxInstalled\", 
    "HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers\", 
    "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\", 
    "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Logger\", 
    "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Sessions\"
)

$enrollerPath = "$env:windir\system32\deviceenroller.exe"
$cert = Get-ChildItem Cert:\LocalMachine\My | ?{$_.Issuer -eq "CN=Microsoft Intune MDM Device CA"}
$certOld = Get-ChildItem Cert:\LocalMachine\My\ | ? { $_.Issuer -Match "CN=SC_Online_Issuing" }

try{
    $enrollmentId = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Logger" -Name "CurrentEnrollmentId"
}catch{
    Write-Output "Inutune Enrollment Id not found. Exit 1"; exit 1
}

Write-Output "$($Env:COMPUTERNAME) - The Intune Enrollment ID is $enrollmentId"

# unregister all tasks within the enrollment folder
$intuneScheduledTasks = Get-ScheduledTask -TaskPath "\Microsoft\Windows\EnterpriseMgmt\$enrollmentId\" -ErrorAction SilentlyContinue

if($null -eq $intuneScheduledTasks){ 
    Write-Output("Task folder {0} does not exist. Exit 1" -f "\Microsoft\Windows\EnterpriseMgmt\$enrollmentId\"); exit 1
}

foreach($task in $intuneScheduledTasks){

    Write-Output("Unregistering scheduled task - {0}" -f $task.TaskName)
    Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Confirm:$false
}

# delete the enrollment task folder, 0 
$scheduleObj = New-Object -ComObject Schedule.Service
$scheduleObj.Connect()
$rootEnrollmentFolder = $scheduleObj.GetFolder("\Microsoft\Windows\EnterpriseMgmt")
$rootEnrollmentFolder.DeleteFolder($enrollmentId, 0)


# delete the registry keys with the enrollment ID and all sub keys
foreach($path in $regArr){

    $targetPath = Join-Path $path $enrollmentId
    if(test-path -Path $targetPath){
        Write-Output("Removing {0} and all sub-keys/items" -f $targetPath)
        Remove-Item -Path $targetPath -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

if($cert){ 
    Write-Output("{0}" -f $cert.Issuer)
    $cert | remove-item -Force -ErrorAction SilentlyContinue
}
if($certOld){
    Write-Output("{0}" -f $certOld.Issuer)
    $certOld | remove-item -Force -ErrorAction SilentlyContinue
}

if(test-path $enrollerPath){
    $p = Start-Process -FilePath $enrollerPath -ArgumentList @("/c", "/AutoEnrollMDM") -PassThru
    # if($p.HasExited){
    #     Write-Output("{0} - Intune Re-enrollment successfully initiated")
    # }
}


# cmd.exe /c psexec.exe /s cmd /c "$env:windir\system32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -file $enrollerPath

# psexec.exe /s cmd /c $enrollerPath 
