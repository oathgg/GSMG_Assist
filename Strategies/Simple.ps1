function Run-Strategy() {
    $Settings = @();
    $marketsToScan = $Global:GSMGmarkets | ? { $_.Enabled }
    foreach ($marketName in $marketsToScan.market_name) {
        [float] $pctChangeFromATH = Get-AthChangePct -Market $marketName -Interval "1d" -CandleLimit 365 -IncludeCurrentCandle
        [float] $pctChange24h = (Get-24hTicker($marketName)).priceChangePercent

        $market = $Global:GSMGmarkets | Where-Object { $_.market_name -eq $marketName }
        $allocation = $Global:GSMGAllocations | Where-Object { $_.market_name -match $marketName }

        if ($allocation) {
            $bagPct = 0
            if ($allocation.set_alloc_perc -gt 0) {
                $bagPct = [float] [Math]::Round(($allocation.open_sells_alloc_perc / $allocation.set_alloc_perc) * 100, 1)
            } else {
                $bagPct = [float] [Math]::Round(($allocation.open_sells_alloc_perc / $allocation.current_alloc) * 100, 1)
                
                # When we have stepped out of the market it means all the money in that market is going to be a bag...
                # So we check the bag space by comparing it to our max allocation on this base currency.
                if ($bagPct -eq 100) {
                    $bagPct = [float] [Math]::Round(($allocation.open_sells_alloc_perc / $global:MaxAllocationPct[$market.base_currency]) * 100, 1)
                }
            }
        } else {
            $bagPct = 0
        }

        # Default settings
        $bemPct = 0
        $aggressivenessPct = 20
        $shouldAllocate = $true
        $TrailingBuy = $false
        $minProfitPct = 5
        $trailingSell = $false

        # When the market has been changing too fast
        if ($pctChange24h -le -15 -or $pctChange24h -gt 15) {
            # If we are close to our ATH then we want to sell quickly as well
            # If the market drops rather quickly then we want to sell asap whenever we buy.
            # We might want to manage trailing sell during this time as well.?
            if ($pctChangeFromATH -gt -10 -or $pctChange24h -le -15) {
                $minProfitPct = 1
            }
            
            # Try to get even more profit, LETSGO!
            $trailingSell = $true
            $TrailingBuy = $true

            # Keep a bit more distance from the market so we don't fomo buy.
            $bemPct = -2
        }
        else {
            if ($bagPct -ge 30) {
                $minProfitPct = 3
            }

            $sellOrders = Get-GSMGOpenOrders -Type "sellorders" -Market $marketName
            if ($sellOrders -and $sellOrders.Count -ge 3) {
                # Get the avg of the last 3 sell orders, if we meet our threshold then we can buy aggressively
                $avg = ($sellOrders | Sort-Object Price | Select-Object -First 3 | Measure-Object price -Average).Average
                $curPrice = Get-Ticker -Market $marketName -Interval "1m" -CandleLimit "1"
                $priceDiffPct = $avg / $curPrice.Close * 100 - 100

                if ($priceDiffPct -le $minProfitPct) {
                    $trailingBuy = $true
                }
                if ($priceDiffPct -ge 10) {
                    $bemPct = 1
                }
            }
            else {
                # If we don't have any sell orders then lets just turn off TB
                # In my experience if I have TB on with default settings its sometimes a bit slow with getting a first buy order in.
                $bemPct = 1
            }
        }

        if ($shouldAllocate) {
            Write-Host "[$marketName] -> BEM: $bemPct, AGGR: $aggressivenessPct, MPROFIT: $minProfitPct, TB: $TrailingBuy, TS: $trailingSell"
        }

        $Settings += New-ConfigurationObject -BemPct $bemPct -AggressivenessPct $aggressivenessPct -ShouldAllocate $shouldAllocate -BaseCurrency $market.base_currency -MarketName $marketName -MinProfitPct $minProfitPct -TrailingBuy $TrailingBuy -TrailingSell $trailingSell
    }

    return $Settings
}