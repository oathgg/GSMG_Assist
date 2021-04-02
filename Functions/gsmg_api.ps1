$script:baseUri = "https://gsmg.io"
$script:Token = ""

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
            throw "No token has been configured, call 'New-GSMGAuthentication' first."
        }
        $header = @{ 'Authorization' = "Bearer $($script:Token)" }
    }

    $res = Invoke-WebRequest -Uri $Uri -Method $Method -Body:$body -DisableKeepAlive -ContentType "application/json;charset=UTF-8" -Headers:$header
    $res = $res.content | ConvertFrom-Json

    return $res
}

function New-GSMGAuthentication($Email, $Password, $Code) {
    Write-Host "Authenticating to GSMG..."

    $uri = "$script:baseUri/api/v1/login"
    $body = ConvertTo-GSMGMessage -Hashset @{
        "email"=$Email
        "password"=$Password
        "code"=$Code
    }

    $res = Invoke-GSMGRequest -Uri $Uri -Method Post -Body $body
    $script:Token = $res.token

    Write-Host "Authenticated, using token $($script:Token)"
}

#PATCH /api/v1/markets/Binance:CAKEBUSD HTTP/1.1
function Set-GSMGSetting($Market, $AggressivenessPct, $MinTradeProfitPct, $BemPct) {
    $uri = "$script:baseUri/api/v1/markets/Binance:$Market"

    $hashSet = @{}
    if ($BemPct) {
        $hashSet += @{"bem_pct"=$BemPct}
    }
    if ($AggressivenessPct) {
        $hashSet += @{"aggressiveness_pct"=$AggressivenessPct}
    }
    if ($MinTradeProfitPct) {
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