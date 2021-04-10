$Script:TimeDifference = $null

#API DOCS: #https://binance-docs.github.io/apidocs/

function Get-TimeDifference($TimeStamp) {
    if (-not $Script:TimeDifference) {
        $serverTime = Get-ServerTimestamp
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
    $TimeStamp -= (Get-TimeDifference -TimeStamp $TimeStamp)

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

function Invoke-BinanceRestMethod($Query, [Switch] $RequiresSignature) {
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

function Get-ExchangeInfo() {
    $res = Invoke-BinanceRestMethod -Query "/api/v3/exchangeInfo"
    return $res | ConvertFrom-Json -ErrorAction SilentlyContinue
}

function Get-ServerTimestamp() {
    $res = Invoke-BinanceRestMethod -Query "/api/v3/time"
    return $res | ConvertFrom-Json -ErrorAction SilentlyContinue
}

function Get-AccountInformation() {
    $timestamp = New-BinanceTimestamp
    $res = Invoke-BinanceRestMethod -Query "/api/v3/account?recvWindow=50000&timestamp=$timestamp" -RequiresSignature
    return $res | ConvertFrom-Json -ErrorAction SilentlyContinue
}

function Get-MyTrades($Symbol, $From) {
    $timestamp = New-BinanceTimestamp
    $startTime = New-BinanceTimestamp($From)
    $res = Invoke-BinanceRestMethod -Query "/api/v3/myTrades?timestamp=$timestamp&symbol=$Symbol&recvWindow=50000&startTime=$startTime" -RequiresSignature -RecVWindow 50000
    return $res | ConvertFrom-Json -ErrorAction SilentlyContinue
}

function Test-BinanceConnection() {
    $res = Invoke-BinanceRestMethod -Query "/api/v3/ping"
    return $res | ConvertFrom-Json -ErrorAction SilentlyContinue
}

function Get-MarketValue($Market) {
    $res = Invoke-BinanceRestMethod -Query "/api/v3/ticker/price?symbol=$Market"
    return $res | ConvertFrom-Json -ErrorAction SilentlyContinue
}

<#

    https://stackoverflow.com/questions/50321891/how-do-binance-api-calculate-pricechangepercent-in-24h
    1526171400000, // Open time
    "0.00154030", // Open
    "0.00154560", // High
    "0.00153600", // Low
    "0.00153780", // Close
    "5716.55000000", // Volume
    1526172299999, // Close time
    "8.79961911", // Quote asset volume
    729, // Number of trades
    "2149.12000000", // Taker buy base asset volume
    "3.30996242", // Taker buy quote asset volume
    "0" // Ignore

#>

function Get-ChangePct($FirstOpen, $LastClose) {
    $change = ($LastClose - $FirstOpen) * 100 / $FirstOpen;
    return $change
}

function Get-Ticker($Market, $Interval, $CandleLimit) {
    $res = Invoke-BinanceRestMethod -Query "/api/v3/klines?symbol=$Market&interval=$Interval&limit=$CandleLimit"
    $candles = $res | ConvertFrom-Json -ErrorAction SilentlyContinue

    return $candles
}

function Get-TickerChangePct($Market, $Interval, $CandleLimit) {
    $candles = Get-Ticker -Market $Market -Interval $Interval -CandleLimit $CandleLimit

    $first = $candles | Select-Object -First 1
    $last = $candles | Select-Object -Last 1
    $change = Get-ChangePct -FirstOpen $First[1] -LastClose $Last[4]

    return $change
}

function Get-15mTicker($Market) {
    return Get-TickerChangePct -Market $Market -Interval 1m -CandleLimit 15
}

function Get-1hTicker($Market) {
    return Get-TickerChangePct -Market $Market -Interval 1m -CandleLimit 60
}

function Get-4hTicker($Market) {
    return Get-TickerChangePct -Market $Market -Interval 1m -CandleLimit 240
}

function Get-6hTicker($Market) {
    return Get-TickerChangePct -Market $Market -Interval 1m -CandleLimit 360
}

function Get-24hTicker($Market) {
    $res = Invoke-BinanceRestMethod -Query "/api/v3/ticker/24hr?symbol=$Market"
    return $res | ConvertFrom-Json -ErrorAction SilentlyContinue
}

function Get-1wTicker($Market) {
    return Get-TickerChangePct -Market $Market -Interval 1h -CandleLimit 168
}

function Get-AthCandle($Candles) {
    $allTimeHighCandle = $candles | Select-Object -First 1
    foreach ($candle in $candles) {
        $close = $candle[4]
        if ($close -gt $allTimeHighCandle[4]) {
            $allTimeHighCandle = $candle
        }
    }

    return $allTimeHighCandle
}

function Get-AthChangePct($Market, $Interval, $CandleLimit) {
    $candles = Get-Ticker -Market $Market -Interval $Interval -CandleLimit $CandleLimit

    $allTimeHighCandle = Get-AthCandle -Candles $candles
    $current = $candles | Select-Object -Last 1

    $change = Get-ChangePct -FirstOpen $allTimeHighCandle[1] -LastClose $current[4]

    return $change
}

function Get-7dAthChangePct($Market) {
    $change = Get-AthChangePct -Market $Market -Interval 1h -CandleLimit 168
    return $change
}

function Get-14dAthChangePct($Market) {
    $change = Get-AthChangePct -Market $Market -Interval 1h -CandleLimit 336
    return $change
}

function Get-30dAthChangePct($Market, $Interval = "1h", $CandleLimit = "720") {
    $change = Get-AthChangePct -Market $Market -Interval $Interval -CandleLimit $CandleLimit
    return $change
}

function Get-PctChanges($Market, $Interval = "1h", $CandleLimit = "720") {
    $candles = Get-Ticker -Market $Market -Interval $Interval -CandleLimit $CandleLimit
    $allTimeHighCandleClose = (Get-AthCandle -Candles $candles)[1]

    $pctChanges = @()
    $previousChangePct = 0

    # We count our percentages back from the previous candle
    # We dont want to use the one we're currently at because that is still being formed
    for ($i = $candles.Count - 2; $i -gt 0; $i--) {
        $curCandle = $candles[$i]

        [int]$changePct = Get-ChangePct -FirstOpen $allTimeHighCandleClose -LastClose $curCandle[4]
        if ($changePct -ne $previousChangePct) {
            $pctChanges += $changePct
            $previousChangePct = $changePct
        }
    }

    [array]::Reverse($pctChanges)
    return $pctChanges
}

function Get-30dPctChanges($Market) {
    return Get-PctChanges -Market $Market -Interval 1h -CandleLimit 720
}