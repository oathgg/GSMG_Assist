function Run-Strategy() {
    $Settings = @();
    $marketsToScan = $Global:GSMGmarkets | ? { $_.Enabled }
    foreach ($marketName in $marketsToScan.market_name) {
        [float] $pctChangeFromATH = Get-AthChangePct -Market $marketName -Interval "1d" -CandleLimit 30 -IncludeCurrentCandle
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
        $minProfitPct = 5
        $bemPct = 0
        $aggressivenessPct = 40
        $shouldAllocate = $true
        $TrailingBuy = $false
        $minProfitPct = 5

        # When we're in an uptrend we only take small profits so we don't get bags that are too high up
        if ($pctChangeFromATH -gt -10) {
            $TrailingBuy = $true
            $minProfitPct = 1
        }

        if ($pctChange24h -le -10) {
            $TrailingBuy = $true
        }

        # Start decreasing minprofit because we're getting bags!!
        if ($bagPct -gt 30) {
            $TrailingBuy = $true
            $minProfitPct = 3
        }

        # When the market has been going up too fast we want to distance ourselves a bit
        if ($pctChange24h -gt 15) {
            $bemPct = -3
            $TrailingBuy = $true
        }

        # If our bags are becoming too big we want to sell faster
        if ($bagPct -gt 40) {
            $TrailingBuy = $true
            $minProfitPct = 1
        }

        if ($shouldAllocate) {
            Write-Host "[$marketName] -> BEM: $bemPct, AGGR: $aggressivenessPct, MPROFIT: $minProfitPct, TB: $TrailingBuy"
        }

        $Settings += New-ConfigurationObject -BemPct $bemPct -AggressivenessPct $aggressivenessPct -ShouldAllocate $shouldAllocate -BaseCurrency $market.base_currency -MarketName $marketName -MinProfitPct $minProfitPct -TrailingBuy $TrailingBuy
    }

    return $Settings
}