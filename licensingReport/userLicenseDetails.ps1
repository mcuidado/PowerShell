param (
    [Parameter()]
    [ValidateSet("Philadelphia")] # other cities
    [string] $office
)

Import-Module Microsoft.Graph.Users

$licenseDataName = "$(Get-Location)\serviceNames.csv"

if(-not (test-path $licenseDataName) ){
    try{
        $url = "https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv"
        $webObj = New-Object System.Net.WebClient
        $webObj.DownloadFile($url, $licenseDataName)
    }catch{
        Write-Output $_.Exception.Message; exit 1
    }
}

$csvData = Import-Csv -Path $licenseDataName
$settings = Get-Content -Path .\settings.json | ConvertFrom-Json

$clientId = $settings.clientId
$tenantId = $settings.tenantId
$scope = $settings.graphUserScopes

# Connect-MgGraph -ClientId $clientId -TenantId $authTenant -Scopes $graphScopes -UseDeviceAuthentication -NoWelcome
try{
    Get-MgUser -Top 1 2>&1>$null
    Write-Host "Connected to graph" -ForegroundColor Green
}catch{
    Write-Host "Please connect to graph" -ForegroundColor Yellow
    Connect-MgGraph -ClientId $clientId -TenantId $tenantId -Scopes $scope -UseDeviceAuthentication
}

$officeUsers = Get-MgUser -Search "OfficeLocation:$office" -ConsistencyLevel eventual

foreach($user in $officeUsers) {

    Write-Host $user.UserPrincipalName -ForegroundColor Green
    
    $userAssignedSKUs = (Get-MgUserLicenseDetail -UserId $user.UserPrincipalName).SkuPartNumber

    $skuIndex = $userAssignedSKUs.Length - 1

    foreach($row in $csvData){

        $sku = $userAssignedSKUs[$skuIndex]
        $displayName = ($csvData | ?{ $_.String_Id -eq $sku })[0].Product_Display_Name 
        Write-Output ("{0} - {1}" -f $userAssignedSKUs[$skuIndex], $displayName)

        if($skuIndex -eq 0){ break }
        $skuIndex--
    }
}






    # foreach($sku in $userAssignedSKUs){

    #     foreach($row in $csvData){
    #         if($sku -eq $row.String_Id){
    #             Write-Output ("{0} - {1}" -f $sku, $row.Product_Display_Name)
    #             break
    #         }
    #     }
    # }
