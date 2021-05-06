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
        $minProfitPct = 5;
        $bemPct = "-15"
        $aggressivenessPct = "15"
        $shouldAllocate = $false
        $TrailingBuy = $true

        # Market is reversing after a downtrend
        # We do not want to spend money when the market has been going up too fast
        if ($pctChange24h -gt -10 -and $pctChange24h -lt 15)
        {
            if ($pctChangeFromATH -le -35) {
                if ($bagPct -le 60) {
                    $bemPct = 2
                    $TrailingBuy = $false
                } else {
                    $bemPct = 0
                }
                $minProfitPct = 15
                $shouldAllocate = $true
            }
            elseif ($pctChangeFromATH -le -25) {
                if ($bagPct -le 30) {
                    $bemPct = 1
                    $TrailingBuy = $false
                } else {
                    $bemPct = 0
                }
                $minProfitPct = 10
                $shouldAllocate = $true
            }
            elseif ($pctChangeFromATH -le -15) {
                if ($bagPct -le 20) {
                    $bemPct = 0
                    $TrailingBuy = $false
                } else {
                    $bemPct = -2
                }
                $minProfitPct = 5
                $shouldAllocate = $true
            } else {
                # So we keep buying in an uptrend, bem is quite defensive, Trailing buy is on by default... How desperate..
                if ($bagPct -le 10) {
                    $bemPct = 0
                    $minProfitPct = 3
                    $shouldAllocate = $true
                }
            }
        }

        if ($shouldAllocate) {
            Write-Host "[$marketName] -> BEM: $bemPct, AGGR: $aggressivenessPct, MPROFIT: $minProfitPct, TB: $TrailingBuy"
        }

        $Settings += New-ConfigurationObject -BemPct $bemPct -AggressivenessPct $aggressivenessPct -ShouldAllocate $shouldAllocate -BaseCurrency $market.base_currency -MarketName $marketName -MinProfitPct $minProfitPct -TrailingBuy $TrailingBuy
    }

    return $Settings
}