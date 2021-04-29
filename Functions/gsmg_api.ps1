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

function Get-GSMGHeader() {
    $header = @{ 'Authorization' = "Bearer $($script:Token)" }
    return $header
}

function Invoke-GSMGRequest($Uri, $Method, $Body, [Switch] $RequiresToken) {
    if ($RequiresToken) {
        if ([string]::IsNullOrEmpty($script:Token)) {
            $gsmgMfaCode = Read-Host "Please enter the GSMG MFA code"
            New-GSMGAuthentication -Email $global:GSMGEmail -Password $global:GSMGPassword -Code $gsmgMfaCode
        } else {
            New-GSMGToken
        }
        $header = Get-GSMGHeader
    }

    $res = Invoke-WebRequest -Uri $Uri -Method $Method -Body:$body -ContentType "application/json;charset=UTF-8" -Headers:$header -DisableKeepAlive -ErrorAction Ignore

    #https://app.swaggerhub.com/apis-docs/bloctite/simple/1.0.0#/
    # - 500: Internal Server Error, here something goes wrong on GSMG end. In this case a unique reference is given and you are encouraged to contact support with it.
    if ($res.StatusCode -eq 500) {
        $res
        $res.content
        Read-Host "Response 500 encountered, press any key to continue..."
    }

    $res = $res | ConvertFrom-Json

    return $res
}

function New-GSMGToken() {
    $now = Get-Date
    if ($now -gt $script:TokenExpiresAt) {
        $header = Get-GSMGHeader
        $uri = "$script:baseUri/api/v1/refresh"
        $res = Invoke-WebRequest -Uri $Uri -Method Post -ContentType "application/json;charset=UTF-8" -Headers:$header -DisableKeepAlive -ErrorAction Ignore | ConvertFrom-Json

        $script:TokenExpiresAt = (Get-Date).AddSeconds($res.expires_in - 200)
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

    if ($null -ne $BemPct) {
        $hashSet += @{"bem_pct"=$BemPct}
    }
    if ($null -ne $AggressivenessPct) {
        $hashSet += @{"aggressiveness_pct"=$AggressivenessPct}
    }
    if ($null -ne $MinTradeProfitPct) {
        $hashSet += @{"min_trade_profit_pct"=$MinTradeProfitPct}
    }

    $body = ConvertTo-GSMGMessage -Hashset $hashSet
    Invoke-GSMGRequest -Uri $Uri -Method Patch -Body $body -RequiresToken | Out-Null
    Write-Host "[$Market] -> $body"
}

#GET /api/v1/markets/allocations HTTP/1.1
function Get-GSMGMarkets() {
    $uri = "$script:baseUri/api/v1/markets/allocations"
    $res = Invoke-GSMGRequest -Uri $Uri -Method Get -RequiresToken

    return $res.merged
}

function Set-GMSGMarketAllocation($Market, $AllocationPct) {
    $uri = "$script:baseUri/api/v1/markets/Binance:$Market/percent/$AllocationPct"
    $res = Invoke-GSMGRequest -Uri $Uri -Method Put -RequiresToken
    Write-Host "[$Market] -> Allocation: $AllocationPct"
}