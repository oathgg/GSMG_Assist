$script:baseUri = "https://gsmg.io"
$script:Token = $null
$script:TokenExpiresAt = Get-Date

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
        } else {
            Refresh-GSMGToken
        }
        $header = @{ 'Authorization' = "Bearer $($script:Token)" }
    }

    $res = Invoke-WebRequest -Uri $Uri -Method $Method -Body:$body -ContentType "application/json;charset=UTF-8" -Headers:$header -DisableKeepAlive -ErrorAction Ignore
    $res = $res | ConvertFrom-Json

    return $res
}

function Refresh-GSMGToken() {
    $now = Get-Date
    if ($now -gt $script:TokenExpiresAt) {
        $uri = "$script:baseUri/api/v1/refresh"
        $res = Invoke-GSMGRequest -Uri $uri -Method Post -RequiresToken

        $script:TokenExpiresAt = (Get-Date).AddSeconds($res.expires_in)
        $script:Token = $res.token
    }
}

function New-GSMGAuthentication($Email, $Password, $Code) {
    $uri = "$script:baseUri/api/v1/login"
    $body = ConvertTo-GSMGMessage -Hashset @{
        "email"=$Email
        "password"=$Password
        "code"=$Code
    }

    $res = Invoke-GSMGRequest -Uri $Uri -Method Post -Body $body
    $script:TokenExpiresAt = (Get-Date).AddSeconds($res.expires_in)
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

    return $res.merged | Where-Object { $_.set_alloc_perc -gt 0 }
}