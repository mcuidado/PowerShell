
function Remove-CachedBrowserPasswords {
    [CmdletBinding()]
    param (
        [string] $procName,
        [string] $directory,
        [string] $fileName,
        [int] $fileSize
    )

    if($null -ne (Get-Process -Name $procName -ErrorAction SilentlyContinue)){
        $p = Stop-Process -Name $procName -PassThru -Force
        $p.WaitForExit()
        Write-Output("{0} closed" -f $procName)
    }

    $passwordFile = Join-Path -Path $directory -ChildPath $fileName

    if( -not (test-path $passwordFile)){
        Write-Output "$passwordFile does not exist"
        return $true
    }

    $fileObj = get-item -Path $passwordFile | Select-Object -Property Name, @{n="sizeKB"; e={$_.Length/1KB}}

    if($fileObj.sizeKB -ge $fileSize){
        try{
            Write-Output("Removing file {0} with size {1} KB" -f $fileName, $fileObj.sizeKB)
            Remove-Item -Path $passwordFile -Force -Verbose 4>&1 | Out-String
        }catch{
            Write-Output $_.Exception.Message
        } 
    }else{
        Write-Output("{0} has no passwords saved. Size {1} KB" -f $fileName, $fileObj.sizeKB )
    }
}

$chromeDir = "$($env:LOCALAPPDATA)\Google\Chrome\User Data\Default"
$fName = "Login Data"

Remove-CachedBrowserPasswords -procName "chrome" `
    -directory $chromeDir `
    -fileName $fName `
    -fileSize 40 `


# $edge = "$($env:LOCALAPPDATA)\Microsoft\Edge\User Data\Default"
# $stopEdge = Stop-BrowserProcess -procName "msedge"