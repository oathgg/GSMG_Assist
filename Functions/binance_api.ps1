$Script:TimeDifference = $null

function Calculate-TimeDifference($TimeStamp) {
    if (-not $Script:TimeDifference) {
        $serverTime = Query-ServerTimestamp
        $timeDifference = $TimeStamp - $serverTime.serverTime
        if ($timeDifference -gt 0) {
            Write-Warning "There is a time difference between us and the binance server time, correcting time difference by $timeDifference ms"
            $Script:TimeDifference = $timeDifference
        }
    }

    return $Script:TimeDifference
}

function New-BinanceTimestamp($Date) {
    if (-not $Date) {
        $Date = Get-Date
    }

    $TimeStamp = (Get-Date ($Date).ToUniversalTime() -UFormat %s).replace(',', '').replace('.', '').SubString(0,13)
    $TimeStamp -= (Calculate-TimeDifference -TimeStamp $TimeStamp)

    return $TimeStamp
}

function New-BinanceSignature($Query) {
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::ASCII.GetBytes($binanceSecret)

    $validQuery = $Query.Split("?")[1]

    $signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($validQuery))
    $signature = [System.BitConverter]::ToString($signature).Replace('-', '').ToLower()

    return $signature
}

function Query-Binance($Query, [Switch] $RequiresSignature) {
    $url = "https://api.binance.com" + $Query

    if ($RequiresSignature) {
        $url += "&signature=" + (New-BinanceSignature -Query $Query)
    }

    try {
        $res = Invoke-WebRequest -Uri $url -Headers @{ 'X-MBX-APIKEY' = "$binanceKey" } -Method GET -DisableKeepAlive
        if ($res.StatusCode -eq "429") {
            throw "Received status code 429 -> When a 429 is received, it's your obligation as an API to back off and not spam the API."
        }
        $res = $res.Content
    } catch {
        Write-Warning "Querying '$url' failed."
        Write-Warning "Response: $($_.ErrorDetails.Message)"
    }

    return $res
}

function Query-ExchangeInfo() {
    $res = Query-Binance -Query "/api/v3/exchangeInfo"
    return $res | ConvertFrom-Json -ErrorAction SilentlyContinue
}

function Query-ServerTimestamp() {
    $res = Query-Binance -Query "/api/v3/time"
    return $res | ConvertFrom-Json -ErrorAction SilentlyContinue
}

function Query-Account() {
    $timestamp = New-BinanceTimestamp
    $res = Query-Binance -Query "/api/v3/account?recvWindow=50000&timestamp=$timestamp" -RequiresSignature
    return $res | ConvertFrom-Json -ErrorAction SilentlyContinue
}

function Query-MyTrades($Symbol, $From) {
    $timestamp = New-BinanceTimestamp
    $startTime = New-BinanceTimestamp($From)
    $res = Query-Binance -Query "/api/v3/myTrades?timestamp=$timestamp&symbol=$Symbol&recvWindow=50000&startTime=$startTime" -RequiresSignature -RecVWindow 50000
    return $res | ConvertFrom-Json -ErrorAction SilentlyContinue
}

function Test-BinanceConnection() {
    $res = Query-Binance -Query "/api/v3/ping"
    return $res | ConvertFrom-Json -ErrorAction SilentlyContinue
}

function Query-MarketValue($Market) {
    $res = Query-Binance -Query "/api/v3/ticker/price?symbol=$Market"
    return $res | ConvertFrom-Json -ErrorAction SilentlyContinue
}

function Query-24hTicker($Market) {
    $res = Query-Binance -Query "/api/v3/ticker/24hr?symbol=$Market"
    return $res | ConvertFrom-Json -ErrorAction SilentlyContinue
}