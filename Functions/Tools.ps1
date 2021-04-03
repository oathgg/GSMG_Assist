function Get-BinanceTable($Pairs) {
    if ($Pairs) {
        $objList = @()
        $BinanceClipBoardText = ""

        Write-Host "Generating Binance table..."
        foreach ($market in $pairs.Keys | Sort-Object) {
            $pair = $pairs[$market]
            if ($pair.amount -gt 0) {
                $marketName = $Market
                if ($marketName -notmatch "USDT"`
                -and $marketName -notmatch "BUSD") {
                    $marketName += "USDT" # Set a default market
                }
                $currentMarketPrice = (Query-MarketValue($marketName)).price
                if ($currentMarketPrice -eq $null) {
                    $currentMarketPrice = 1
                }
                $total = $pair.Total
                if ($total -lt 0) {
                    $total = 0
                }
                $text = "$market`t$($pair.Amount)`t$($total)`t$($currentMarketPrice)"
                if (-not [string]::IsNullOrEmpty($BinanceClipBoardText)) {
                    $BinanceClipBoardText += "`r`n"
                }
                $BinanceClipBoardText += $text
                
                $profit = [float] $currentMarketPrice * [float] $pair.Amount - [float] $total

                if ($total -gt 0) {
                    $profitPercentage = $profit / ($total / 100)
                } else {
                    $profitPercentage = $profit
                }

                $obj = New-Object psobject -Property @{ 
                    Market=$market; 
                    Amount=$pair.Amount; 
                    Total=$total; 
                    CurrentMarketPrice=$currentMarketPrice; 
                    Profit= [Math]::Round($profit, 2);
                    ProfitPercentage = $profitPercentage
                }
                $objList += $obj | Select-Object Market,Amount,Total,CurrentMarketPrice,Profit,ProfitPercentage
            }
        }

        $objList | Format-Table
        Set-BinanceClipboard -Text $BinanceClipBoardText
    } else {
        Write-Warning "Pairs value is not valid"
    }
}

function Set-BinanceClipboard($Text) {
    if ($Text) {
        Write-Host "Updating clipboard..."
        $Text | clip
    }
}