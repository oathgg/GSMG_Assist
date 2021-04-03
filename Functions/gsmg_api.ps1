$script:baseUri = "https://gsmg.io"
$script:Token = $null

function ConvertTo-GSMGMessage($Hashset) {
    $body = "{"

    foreach ($key in $Hashset.Keys) {
        # If it's not the first item then we add a "," in front of it.
        if ($body -ne "{") {
            $body += ","
        }
        $body += '"' + $key + '":"' + $Hashset.Item($key) + '"' 
    }

    $body += "}"

    return $body
}

function Invoke-GSMGRequest($Uri, $Method, $Body, [Switch] $RequiresToken) {
    if ($RequiresToken) {
        if ([string]::IsNullOrEmpty($script:Token)) {
            $gsmgMfaCode = Read-Host "Please enter the GSMG MFA code"
            New-GSMGAuthentication -Email $global:GSMGEmail -Password $global:GSMGPassword -Code $gsmgMfaCode
        }
        $header = @{ 'Authorization' = "Bearer $($script:Token)" }
    }

    $res = Invoke-RestMethod -Uri $Uri -Method $Method -Body:$body -ContentType "application/json;charset=UTF-8" -Headers:$header

    <#
    if ($res.StatusCode -eq "500") {
        Write-Warning "Received status code 500 -> Refresh token."
        $script:Token = Refresh-GSMGToken
        $res = Invoke-GSMGRequest -Uri $Uri -Method $Method -Body $Body -RequiresToken:$RequiresToken
    }
    
    $res = $res | ConvertFrom-Json
    #>

    return $res
}

function Refresh-GSMGToken() {
    $url = "$script:baseUri/api/v1/refresh"
    $res = Invoke-GSMGRequest -Uri $Uri -Method Post

    if ($res.StatusCode -ne "200") {
        [System.Windows.MessageBox]::Show("Error", "Session has expired...", [System.Windows.MessageBoxButton]::OK)
        exit
    }

    return $res.token
}

function New-GSMGAuthentication($Email, $Password, $Code) {
    $uri = "$script:baseUri/api/v1/login"
    $body = ConvertTo-GSMGMessage -Hashset @{
        "email"=$Email
        "password"=$Password
        "code"=$Code
    }

    $res = Invoke-GSMGRequest -Uri $Uri -Method Post -Body $body
    $script:Token = $res.token
}

#PATCH /api/v1/markets/Binance:CAKEBUSD HTTP/1.1
function Set-GSMGSetting($Market, $AggressivenessPct, $MinTradeProfitPct, $BemPct) {
    $uri = "$script:baseUri/api/v1/markets/Binance:$Market"

    $hashSet = @{}

    if ($BemPct -ne $null) {
        $hashSet += @{"bem_pct"=$BemPct}
    }
    if ($AggressivenessPct -ne $null) {
        $hashSet += @{"aggressiveness_pct"=$AggressivenessPct}
    }
    if ($MinTradeProfitPct -ne $null) {
        $hashSet += @{"min_trade_profit_pct"=$MinTradeProfitPct}
    }

    $body = ConvertTo-GSMGMessage -Hashset $hashSet
    $res = Invoke-GSMGRequest -Uri $Uri -Method Patch -Body $body -RequiresToken
    Write-Host "Configured '$Market', with values '$body'"
}

#GET /api/v1/markets/allocations HTTP/1.1
function Get-GSMGMarkets() {
    $uri = "$script:baseUri/api/v1/markets/allocations"
    $res = Invoke-GSMGRequest -Uri $Uri -Method Get -RequiresToken

    return $res.merged
}