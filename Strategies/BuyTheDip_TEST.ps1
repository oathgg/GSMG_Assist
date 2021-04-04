﻿<#

INFORMATION:
    Core thought of this script is to buy when the market is about to reverse.
    We do this once a market goes below the threshold we set, see $minThreshold.
    When the market is below the threshold we validate if the market is starting to reverse.
        If we're going up then that means we might have hit support, we adjust the BEM accordingly through a calculation.
    When the market continues to go down the bot returns to its initial BEM value which should be passive until we pick up another reverse.

#>

#Default values, we want to be passive untill we get a good grip of the situation we are in.
[int] $minThreshold = -5 # I've chosen this number because its a nice decrease start value, most 24h candles are 30% when moving
[int] $bemPct = -2 # Defensive at first

$Global:BuyTheDip_24hHistory = @{}
#$Global:BuyTheDip_24hHistory["VETBUSD"] = @{"24hChangePct"=@(-5,-6,-5,-6,-5,-6,-5,-6,-5,-6,-5,-6,-5,-6,-5,-6,-5,-6,-5,-6)}
#$Global:BuyTheDip_24hHistory["VETBUSD"] = @{"24hChangePct"=@(-10,-11,-10,-11,-10,-11,-10,-11,-10,-11,-10,-11,-10,-11,-10,-11)}
$Global:BuyTheDip_24hHistory["VETBUSD"] = @{"24hChangePct"=@(12,10,8,6,4,2,0,-2,-4,-6,-8,-10,-12,-11,-14,-16,-18,-20,-21,-20,-19,-18)}

#$markets = Get-GSMGMarkets
#foreach ($market in $markets) {
    $marketName = "VETBUSD"
    Write-Host "$MarketName"
    $marketName = $market.market_name.Replace("$($market.exchange):", "")
    
    [int] $currentMarketValuePct = -16
    #[int] $currentMarketValuePct = (Query-24hTicker($marketName)).priceChangePercent

    if (-not $Global:BuyTheDip_24hHistory.Contains($marketName)) {
        $Global:BuyTheDip_24hHistory[$marketName] = @{}
    }

    if ($currentMarketValuePct -le $minThreshold) {
        # 24h movements for the market
        $24hChangePct = $Global:BuyTheDip_24hHistory[$marketName]["24hChangePct"]
        $24hHistoryLast1 = $24hChangePct | Select-Object -Last 1
        $24hHistoryLast2 = $24hChangePct | Select-Object -Last 2
        $24hHistoryLast10 = $24hChangePct | Select-Object -Last 10

        Write-Host "`t- We've got $($24hHistoryLast10.Count) values in our Memory"

        # We need to have at least 5 values to somehwat estimate a good average
        if ($24hHistoryLast10.Count -gt 5) {
            # Round the last 2 values, because we might be hovering between -14 and -15 for example...
            # Hovering is a good sign, this might indicate that we have reached a support point.
            $valueToCompareWith = [Math]::Floor(($24hHistoryLast2 | Measure-Object -Sum).Sum / $24hHistoryLast2.Length)

            # If we're higher than our valueToCompareWith value it means the market is going up
            # The current market value needs to be less or equal to the 24h history avg, if we're lower then that means we have most likely missed our buying opportunity.
            if ($currentMarketValuePct -gt $valueToCompareWith) {
                $24hHistoryAvg = [Math]::Ceiling(($24hHistoryLast10 | Measure-Object -Sum).Sum / $24hHistoryLast10.Length)

                # If we're less than (-20 -lt -15) we want to buy, otherwise we might buy while we're already going too far up
                if ($currentMarketValuePct -le $24hHistoryAvg) {
                    $difference = $24hHistoryLast1 - $currentMarketValuePct
                    Write-Host "`t- Advising to adjust BEM, difference between lastMarketValuePct and currentMarketValuePct is $difference. Substracting ($difference) from 24havg ($24hHistoryAvg) to calculate new BEM"
                    $bemPct = [Math]::Abs($24hHistoryAvg - $difference)
                } else {
                    $bemPct = 0 #Default GSMG setting
                }
            } 
        }

        # If we dont a lastMarketValuePct then that means there is nothing in the list, hence we add it
        # If we do have a list then we compare the last known value with our current value, if its the same we dont add it
        $ceilingOfLastTwo = [Math]::Ceiling(($24hHistoryLast2 | Measure-Object -Sum).Sum / $24hHistoryLast2.Length)
        if ($24hHistoryLast1 -eq $null -or $currentMarketValuePct -ne $ceilingOfLastTwo) {
            $Global:BuyTheDip_24hHistory[$marketName]["24hChangePct"] += @($currentMarketValuePct)
        }
    }

    Write-Host "`t- BEM $bemPct"
    #Set-GSMGSetting -Market $marketName -BemPct $bemPct
#}