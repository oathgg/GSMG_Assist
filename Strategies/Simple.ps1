function Run-Strategy() {
    $Settings = @();

    foreach ($marketName in ($global:MarketsToScan | Sort-Object)) {
        [float] $pctChangeFromATH = Get-AthChangePct -Market $marketName -Interval "1h" -CandleLimit 960 -IncludeCurrentCandle
        [float] $pctChange24h = (Get-24hTicker($marketName)).priceChangePercent
        $market = $Global:GSMGmarkets | Where-Object { $_.market_name -eq $marketName }
        $allocation = $Global:GSMGAllocations | Where-Object { $_.market_name -match $marketName }

        if ($allocation) {
            $bagPct = [float] [Math]::Round(($allocation.open_sells_alloc_perc / $allocation.current_alloc) * 100, 1)
            if ([Double]::IsNaN($bagPct)) {
                $bagPct = 0
            }
        } else {
            $bagPct = 0
        }

        # Default settings
        $minProfitPct = 5;
        $bemPct = "-15"
        $aggressivenessPct = "10"
        $shouldAllocate = $false

        # Market is reversing after a downtrend
        # We do not want to spend money when the market has been going up too fast
        if ($pctChange24h -gt -5 -and $pctChange24h -lt 10)
        {
            if ($pctChangeFromATH -le -40 -and $bagPct -lt 60) {
                $bemPct = 2
                $shouldAllocate = $true
                $minProfitPct = 15
            }
            elseif ($pctChangeFromATH -le -20) {
                $bemPct = 0
                $minProfitPct = 10
                $shouldAllocate = $true
            }
            # -15 might be too aggressive
            elseif ($pctChangeFromATH -le -15) {
                if ($bagPct -lt 20) {
                    $bemPct = 0
                    $minProfitPct = 5
                    $shouldAllocate = $true
                }
            } 
        }

        if ($shouldAllocate) {
            Write-Host "[$marketName] -> BEM: $bemPct, AGGR: $aggressivenessPct, MPROFIT: $minProfitPct"
        }

        $Settings += New-ConfigurationObject -BemPct $bemPct -AggressivenessPct $aggressivenessPct -ShouldAllocate $shouldAllocate -BaseCurrency $market.base_currency -MarketName $marketName -MinProfitPct $minProfitPct
    }

    return $Settings
}