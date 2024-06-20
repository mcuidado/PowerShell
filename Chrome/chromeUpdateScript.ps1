$DestinationDir = "C:\Temp"
$LogFile = Join-Path $DestinationDir "\GoogleChromeDeploymentLog.log"
$TmpOb = New-Object System.Net.WebClient
$ERRORVal = $false
$currentVer=$null
$detection = $false

function Write-ParsedOutStream{
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string] $logLevel,

        [string] $message 
    )
    $parsedDate = (get-date).toString('yyyy-MM-dd HH:mm:ss')
    Write-Output("{0} - {1} - {2}" -f $parsedDate, $logLevel, $message) | Tee-Object -FilePath $LogFile -Append
}

$latestVer = ((Invoke-WebRequest -Uri "https://chromiumdash.appspot.com/fetch_releases?channel=Stable&platform=Windows&num=1" -UseBasicParsing).content | ConvertFrom-Json).version

(test-path $LogFile) -and (Remove-Item $LogFile -Force)

try{
    $Detection = ($null -ne (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" -ErrorAction Stop))
    $currentVer=((get-item -path (Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" -Name "(default)" -ErrorAction Stop)).VersionInfo).ProductVersion

    Write-ParsedOutStream -logLevel INFO -message "Detected existing installation with prodcut version:`"$currentVer`""
}catch [Exception]{

    Write-ParsedOutStream -logLevel INFO -message "An existing Google Chrome installation not identified on the System & proceeding to installation"
}

function Chrome{
    try{
        try{
            $oldMsi=(Get-Item (Join-Path $DestinationDir '\googlechromestandaloneenterprise64.msi') -ErrorAction Stop)
            if($oldMsi.Exists){
                (Get-Item (Join-Path $DestinationDir '\googlechromestandaloneenterprise64.msi')).Delete()
            }
        }catch [Exception]{
            Write-ParsedOutStream -logLevel INFO -message "An existing Google Chrome installation file not identified ontheSystem & proceeding to installation"
        }

        $TmpOb.DownloadFile("https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi",(Join-Path $DestinationDir '\googlechromestandaloneenterprise64.msi'))
        Write-ParsedOutStream -logLevel INFO -message "Download Successful"
            
    }catch [Exception]{
        $ERRORVal = $true
        Write-ParsedOutStream -logLevel ERROR -message "An error occured during Download"
        Write-ParsedOutStream -logLevel ERROR -message $_.Exception
    }

    if( ! $ERRORVal ){
        try{
            Write-ParsedOutStream -logLevel INFO -message "Initiating Update "
            $proc = (Start-Process msiexec.exe -ArgumentList "/i $DestinationDir\googlechromestandaloneenterprise64.msi ALLUSERS=1 NOGOOGLEUPDATEPING=1 /qn /liewa+ $LogFile" -Wait -Passthru).ExitCode
        }catch [exception]{
            Write-ParsedOutStream -logLevel ERROR -message "An error occured during Install"
        }
    }
}

if($detection){
    if($currentVer -ne $latestVer){
        Write-ParsedOutStream -logLevel INFO -message "Initiating Upgrade from $currentVer to $latestVer"
        Chrome("Upgrade")
    }else{
        Write-ParsedOutStream -logLevel INFO -message "$currentVer is the latest version of Google Chrome Enterprise"
    }
}
