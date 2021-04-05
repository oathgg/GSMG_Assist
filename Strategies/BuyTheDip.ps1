<#

INFORMATION:
    Core thought of this script is to buy when the market is about to reverse.
    We do this once a market goes below the threshold we set, see $minThreshold.
    When the market is below the threshold we validate if the market is starting to reverse.
        If we're going up then that means we might reverse, if so then we adjust the BEM accordingly through a calculation and hopefully buy some stocks.
    When the market continues to go down the bot returns to its initial BEM value which should be passive until we pick up another reverse.

#>

#Default values, we want to be passive untill we get a good grip of the situation we are in.
[int] $minThreshold = -10 # I've chosen this number because its a nice decrease start value

if ($Global:BuyTheDip_ParametersInitialized -eq $null) {
    $Global:BuyTheDip_24hHistory = @{}
    $Global:BuyTheDip_ParametersInitialized = $true
}

$markets = Get-GSMGMarkets
foreach ($market in $markets) {
    [int] $bemPct = -2 # Default we need to be defensive

    $marketName = $market.market_name.Replace("$($market.exchange):", "")
    [int] $currentMarketValuePct = Query-7dAthChangePct($marketName)

    if (-not $Global:BuyTheDip_24hHistory.Contains($marketName)) {
        $Global:BuyTheDip_24hHistory[$marketName] = @{}
    }

    $Global:BuyTheDip_24hHistory[$marketName]["24hChangePct"] = $Global:BuyTheDip_24hHistory[$marketName]["24hChangePct"] | Select-Object -Last 10
    $24hChangePct = $Global:BuyTheDip_24hHistory[$marketName]["24hChangePct"]
    $24hHistoryLast1 = $24hChangePct | Select-Object -Last 1
    $24hHistoryLast2 = $24hChangePct | Select-Object -Last 2
    $24hHistoryLast10 = $24hChangePct | Select-Object -Last 10

    if ($currentMarketValuePct -le -5) {
        # If the market is lesser or equal to -5 we can set the bot on normal mode
        $bemPct = 0
    }

    if ($currentMarketValuePct -le $minThreshold) {
        # We need to have at least 10 values to somehwat estimate a good average
        if ($24hHistoryLast10.Count -eq 10) {
            # Round the last 2 values, because we might be hovering between -14 and -15 for example...
            # Hovering is a good sign, this might indicate that we have reached a support point.
            $valueToCompareWith = [Math]::Floor(($24hHistoryLast2 | Measure-Object -Sum).Sum / $24hHistoryLast2.Length)

            # If we're higher than our valueToCompareWith value it means the market is going up
            # The current market value needs to be less or equal to the 24h history avg, if we're lower then that means we have most likely missed our buying opportunity.
            if ($currentMarketValuePct -gt $valueToCompareWith) {
                # We're using the last 10 average to indicate when to stop our buy action
                # For example, @(-11, -12, -13, -14, -15, -16, -17, -18, -19, -20) will give an average of -15.5
                # In this case we will buy once the market goes to -19, until we reach the average count.
                # Do notice, that the average count will move up, as the market will also go up, this way we try to buy in a dip.
                $24hHistoryAvg = [Math]::Ceiling(($24hHistoryLast10 | Measure-Object -Sum).Sum / $24hHistoryLast10.Length)
                if ($currentMarketValuePct -le $24hHistoryAvg) {
                    $difference = $24hHistoryLast1 - $currentMarketValuePct
                    $bemPct = [Math]::Abs($24hHistoryAvg - $difference) # We should use the BEM assist tool for this...
                } 
            } 
        }
    }

    # If we dont a lastMarketValuePct then that means there is nothing in the list, hence we add it
    # If we do have a list then we compare the last known value with our current value, if its the same we dont add it
    $ceilingOfLastTwo = [Math]::Ceiling(($24hHistoryLast2 | Measure-Object -Sum).Sum / $24hHistoryLast2.Length)
    if ($24hHistoryLast1 -eq $null -or ($currentMarketValuePct -ne $ceilingOfLastTwo -and $currentMarketValuePct -ne $24hHistoryLast1)) {
        #Write-Host "`t- Adding $currentMarketValuePct to table."
        [int[]]$Global:BuyTheDip_24hHistory[$marketName]["24hChangePct"] += @($currentMarketValuePct)
    }

    Set-GSMGSetting -Market $marketName -BemPct $bemPct
}

