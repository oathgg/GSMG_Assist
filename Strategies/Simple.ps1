function Run-Strategy() {
    $Settings = @();

    foreach ($market in $global:MarketsToScan) {
        $marketName = $market
        [float] $pctChangeFromATH = Get-AthChangePct -Market $marketName -Interval "1h" -CandleLimit 960 -IncludeCurrentCandle
        [float] $pctChange24h = (Get-24hTicker($marketName)).priceChangePercent
        $market = $GSMGmarkets | Where-Object { $_.market_name -eq $marketName }
        $allocation = $GSMGAllocations | Where-Object { $_.market_name -match $marketName }
        $bagPct = [float] $allocation.vol_sells_worth / ([float] $allocation.managed_value_usd / 100)

        if ([Double]::IsNaN($bagPct)) {
            $bagPct = 0
        }

        $minProfitPct = 1;
        $bemPct = "-15"
        $aggressivenessPct = "10"
        $shouldAllocate = $false

        # Market is reversing after a downtrend??
        if ($pctChange24h -gt -5)
        {
            if ($pctChangeFromATH -le -40 -and $bagPct -lt 60) {
                $bemPct = "2"
                $shouldAllocate = $true
                $minProfitPct = 10
            }
            elseif ($pctChangeFromATH -le -20) {
                $minProfitPct = 10
                $bemPct = "0"
                $shouldAllocate = $true
            }
            # -15 might be too aggressive
            elseif ($pctChangeFromATH -le -15) {
                $minProfitPct = 5
                $bemPct = "0"
                $shouldAllocate = $true
            } 
        }

        if ($shouldAllocate) {
            Write-Host "[$marketName] -> BEM: $bemPct, AGGR: $aggressivenessPct, MPROFIT: $minProfitPct"
        }

        $Settings += New-ConfigurationObject -BemPct $bemPct -AggressivenessPct $aggressivenessPct -ShouldAllocate $shouldAllocate -BaseCurrency $market.base_currency -MarketName $marketName -MinProfitPct $minProfitPct
    }

    return $Settings
}