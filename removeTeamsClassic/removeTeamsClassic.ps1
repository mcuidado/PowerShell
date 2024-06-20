
Start-Transcript -Path "$($env:SystemDrive)\temp\TeamsClassicRemediate.log"

function Uninstall-TeamsClassic($TeamsPath) {
    try {
        $process = Start-Process -FilePath "$TeamsPath\Update.exe" -ArgumentList "--uninstall -s" -PassThru -Wait -ErrorAction STOP

        if ($process.ExitCode -ne 0) {
            Write-Error "Uninstallation failed with exit code $($process.ExitCode)."
        }
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

# Get all Users
$allUsers = Get-ChildItem -Path "$($ENV:SystemDrive)\Users"

# Process all Users
foreach ($user in $allUsers) {
    Write-Host "Processing user: $($user.Name)"

    # Locate installation folder
    $localAppData = "$($ENV:SystemDrive)\Users\$($user.Name)\AppData\Local\Microsoft\Teams"
    $programData = "$($env:ProgramData)\$($user.Name)\Microsoft\Teams"

    if (Test-Path "$localAppData\Current\Teams.exe") {
        Write-Host "  Uninstall Teams for user $($user.Name)"
        Uninstall-TeamsClassic -TeamsPath $localAppData
    }
    elseif (Test-Path "$programData\Current\Teams.exe") {
        Write-Host "  Uninstall Teams for user $($user.Name)"
        Uninstall-TeamsClassic -TeamsPath $programData
    }
    else {
        Write-Host "  Teams installation not found for user $($user.Name)"
    }
}

# Remove old Teams folders and icons
$oldTeamsFolder = "$($ENV:SystemDrive)\Users\*\AppData\Local\Microsoft\Teams"
$oldTeamsIcon = "$($ENV:SystemDrive)\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Teams*.lnk"

Get-Item $oldTeamsFolder | Remove-Item -Force -Recurse
Get-Item $oldTeamsIcon | Remove-Item -Force -Recurse

Stop-Transcript

