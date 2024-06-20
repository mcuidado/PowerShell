
Start-Transcript -Path "$($env:SystemDrive)\temp\TeamsClassicRemediate.log"
$teamsClassicPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\Teams"
$shortcutPath = Join-Path -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -ChildPath "Microsoft Teams classic (work or school).lnk"
$args = ("-s", "--uninstall")

$proc = Start-Process -FilePath "$teamsClassicPath\Update.exe" -ArgumentList $args -PassThru -Wait

$proc.WaitForExit()

if(($proc.HasExited) -and ($proc.ExitCode -eq 0)){

    if(-not (Test-Path -Path "$teamsClassicPath\current")){

        if(Test-Path $shortcutPath){
            Remove-Item -Path "Microsoft Teams classic (work or school).lnk" -Force | Out-Null
            Write-Output "$env:COMPUTERNAME - SUCCESS - Teams classic icon removed successfully."
        }
        Write-Output "$env:COMPUTERNAME - SUCCESS - Teams classic uninstalled successfully."
    }else{
        Write-Output "$env:COMPUTERNAME - FAIL - Teams classic failed to uninstall."
    }
}else{
    Write-Output "$env:COMPUTERNAME - FAIL - Teams classic failed to uninstall. Process did not finish"
}

Stop-Transcript



