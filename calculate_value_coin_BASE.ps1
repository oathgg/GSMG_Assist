cls

$curPath = $PSScriptRoot
if (-not $curPath) {
    $curPath = $psise.CurrentFile.FullPath
}

. "$curPath\parameters.ps1"
. "$curPath\Functions\binance_api.ps1"
. "$curPath\Functions\Converters.ps1"
. "$curPath\Functions\Tools.ps1"

#Write-Host "Querying exchange information..."
#$exchangeInfo = Query-ExchangeInfo

Write-Host "Querying Account information..."
$accountInformation = Get-AccountInformation
$balances = $accountInformation.balances | Where-Object { [float]$_.Free -gt 0 -or [float]$_.Locked -gt 0 } | Sort-Object asset

function Get-Balance($BaseMarket, $Balances) {
    $pairs = @{}

    if ($balances) {
        Write-Host "Parsing balances for $BaseMarket..."
        foreach($balance in $balances) {
            if ($balance.asset -eq "USDT"`
            -or $balance.asset -eq "BNB"`
            -or $balance.asset -eq "BUSD") {
                continue;
            }

            $market = "$($balance.asset)$BaseMarket"

            Write-Host "`t- $market"

            if (-not $pairs.Contains("$market")) {
                $pairs["$market"] = @{}
            }

            $timeago = (Get-Date).AddYears(-1)
            $Trades = Get-MyTrades -Symbol $market -From $timeago
            #$Trades | Select-Object Symbol, Price, Qty, QuoteQty, isBuyer | Format-Table -AutoSize
            $totalSoldCoins = 0
            $totalSoldMoney = 0
            $totalBoughtCoins = 0
            $totalBoughtMoney = 0
            $activeQty = 0 
            $boughtCoins = 0
            $i = 0

            foreach ($trade in $Trades) {
                if ($trade.isBuyer) {
                    $totalBoughtMoney += [float] $trade.quoteQty
                    $totalBoughtCoins += [float] $trade.qty
                    $boughtCoins += [float] $trade.qty
                } else {
                    $totalSoldMoney += [float] $trade.quoteQty
                    $totalSoldCoins += [float] $trade.qty
                    $boughtCoins -= [float] $trade.qty
                }

                if ($totalBoughtMoney - $totalSoldMoney -le 1 -or $totalBoughtCoins - $totalSoldCoins -le 1) {
                    $activeQty = 0
                } 
                elseif (-not $trade.isBuyer) {
                    $activeQty = $boughtCoins
                    if ($totalBoughtMoney - $totalSoldMoney -le 1) {
                        $pairs["$market"]["Total"]
                        $totalBoughtMoney = 0
                        $totalSoldMoney = 0
                    }
                }
                else {
                    $activeQty += [float] $trade.qty
                }
            }

            $pairs["$market"]["Total"] = $totalBoughtMoney - $totalSoldMoney
            [int]$pairs["$market"]["ActiveAmount"] = $activeQty

            if ($pairs["$market"]["Total"] -le 0) {
                $pairs["$market"]["Total"] = 0
                $pairs["$market"]["ActiveAmount"] = 0
            }

            if ($boughtCoins - $pairs["$market"]["Amount"] -gt 1) {
                $pairs["$market"]["TotalAmount"] = $boughtCoins
            } else {
                $pairs["$market"]["TotalAmount"] = $pairs["$market"]["ActiveAmount"]
            }

            if ($pairs["$market"]["Total"] -gt 0) {
                #Write-Host "Spent a total of $($pairs["$market"]["Total"]) dollar, on $($pairs["$market"]["ActiveAmount"]) coins."
            }
        }
    }

    return $pairs
}

#$balances = $balances | ? { $_.asset -eq "STMX" }
#$balances = $balances | ? { $_.asset -eq "XEM" }
#$balances = $balances | ? { $_.asset -eq "VET" }
$pairs = Get-Balance -BaseMarket "USDT" -Balances $balances
#$pairs += Get-Balance -BaseMarket "BUSD" -Balances $balances

Get-BinanceTable -Pairs $pairs
