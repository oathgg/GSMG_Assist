﻿function Run-Strategy() {
    $Settings = @();
    $addDefault = $true

    foreach ($marketName in ($global:MarketsToScan | Sort-Object)) {
        [float] $pctChangeFromATH = Get-AthChangePct -Market $marketName -Interval "1h" -CandleLimit 720 -IncludeCurrentCandle
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

        if ($addDefault) {
            $Settings += New-ConfigurationObject -BemPct $bemPct -AggressivenessPct $aggressivenessPct -ShouldAllocate $shouldAllocate -BaseCurrency "" -MarketName "DEFAULT" -MinProfitPct $minProfitPct
            $addDefault = $false
        }

        # Market is reversing after a downtrend
        # We do not want to spend money when the market has been going up too fast
        if ($pctChange24h -gt -5 -and $pctChange24h -lt 10)
        {
            if ($pctChangeFromATH -le -40) {
                if ($bagPct -lt 60) {
                    $bemPct = 2
                } else {
                    $bemPct = 0
                }
                $minProfitPct = 15
                $shouldAllocate = $true
            }
            elseif ($pctChangeFromATH -le -30) {
                $bemPct = 0
                $minProfitPct = 15
                $shouldAllocate = $true
            }
            elseif ($pctChangeFromATH -le -20) {
                if ($bagPct -gt 20) {
                    $bemPct = -4
                } else {
                    $bemPct = 0
                }
                $minProfitPct = 15
                $shouldAllocate = $true
            }
            # -15 might be too aggressive
            elseif ($pctChangeFromATH -le -15) {
                if ($bagPct -lt 10) {
                    $bemPct = -5
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