function Get-BinanceTable($Pairs) {
    if ($Pairs) {
        $objList = @()
        $BinanceClipBoardText = ""

        Write-Host "Generating Binance table..."
        foreach ($market in $pairs.Keys | Sort-Object) {
            $pair = $pairs.$market
            if ($pair.Coins -gt 0 -or $pair.Amount -gt 0) {
                $marketName = $Market
                if ($marketName -notmatch "USDT" -and $marketName -notmatch "BUSD") {
                    $marketName += "USDT" # Set a default market
                }

                $coins = $pair.ActiveAmount
                $total = $pair.Spent
                $currentMarketPrice = (Get-MarketValue($marketName)).price

                $text = "$market`t$($activeAmount)`t$($Total)`t$($currentMarketPrice)"
                if (-not [string]::IsNullOrEmpty($BinanceClipBoardText)) {
                    $BinanceClipBoardText += "`r`n"
                }
                $BinanceClipBoardText += $text

                if ($activeAmount -gt 0) {
                    $profit = [float] $currentMarketPrice * [float] $ActiveAmount - [float] $total
                    $profitPercentage = $profit / ($total / 100)
                } else {
                    $profit = [float] $currentMarketPrice * [float] $totalAmount - [float] $total
                    $profitPercentage = $profit
                }

                $obj = New-Object psobject -Property @{ 
                    Market=$market; 
                    TotalAmount=$totalAmount; 
                    ActiveAmount=$activeAmount; 
                    Spent=$total; 
                    CurrentMarketPrice=$currentMarketPrice; 
                    Profit= [Math]::Round($profit, 2);
                    ProfitPercentage = $profitPercentage
                }
                $objList += $obj | Select-Object Market,TotalAmount,ActiveAmount,Spent,CurrentMarketPrice,Profit,ProfitPercentage
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