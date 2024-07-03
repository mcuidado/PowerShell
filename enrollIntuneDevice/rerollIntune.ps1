# https://www.maximerastello.com/manually-re-enroll-a-co-managed-or-hybrid-azure-ad-join-windows-10-pc-to-microsoft-intune-without-loosing-current-configuration/

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

$cert = Get-ChildItem Cert:\LocalMachine\My | ?{$_.Issuer -eq "CN=Microsoft Intune MDM Device CA"}
$enrollerPath = "$env:windir\system32\deviceenroller.exe"
$intuneScheduledTasks = Get-ScheduledTask -TaskPath "\Microsoft\Windows\EnterpriseMgmt\*" | ? {$_.TaskPath -match '([0-9A-Fa-f]){8}-(([0-9A-Fa-f]){4}-){3}([0-9A-Fa-f]){11}'}

$enrollmentId = ($intuneScheduledTasks[0].TaskPath).TrimEnd("\").split("\")[-1]
Write-Output "$($Env:COMPUTERNAME) - The Intune Enrollment ID is $enrollmentId"

# delete the registry keys with the enrollment ID and all sub keys
foreach($path in $regArr){

    $targetPath = Join-Path $path $enrollmentId
    if(test-path -Path $targetPath){
        Write-Output("Removing {0} and all sub-keys/items" -f $targetPath)
        # Remove-Item -Path $targetPath -Recurse -Force 1>$null
    }
}

Write-Output("Removing {0} cert" -f $cert.Issuer)
# $cert | remove-item -Force 1>$null

if(test-path $enrollerPath){
    $p = Start-Process -FilePath $enrollerPath -ArgumentList @("/c", "/AutoEnrollMDM") -PassThru
    if($p.HasExited){
        Write-Output("{0} - Intune Re-enrollment successfully initiated")
    }
}


# cmd.exe /c psexec.exe /s cmd /c "$env:windir\system32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -file $enrollerPath

psexec.exe /s cmd /c $enrollerPath  