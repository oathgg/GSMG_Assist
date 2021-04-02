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
$accountInformation = Query-Account
$balances = $accountInformation.balances | Where-Object { [float]$_.Free -gt 0 -or [float]$_.Locked -gt 0 } | Sort-Object asset
$pairs = @{}

function Calculate-Balance($BaseMarket, $Balances) {
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
            $Trades = Query-MyTrades -Symbol $market -From $timeago

            foreach ($trade in $Trades) {
                if ($trade.isBuyer) {
                    $pairs["$market"]["Total"] += [float] $trade.quoteQty
                    $pairs["$market"]["Amount"] += [float] $trade.qty - [float] $trade.commision
                } else {
                    $pairs["$market"]["Total"] -= [float] $trade.quoteQty
                    $pairs["$market"]["Amount"] -= [float] $trade.qty - [float] $trade.commision

                    # If the total is 0 it means we have probably taken out all our profits
                    # Might be a moon bag, however, if the amount is less than 1 it means we left the coin completely
                    if ($pairs["$market"]["Total"] -le 0 -and $pairs["$market"]["Amount"] -lt 1) {
                        $pairs["$market"] = @{}
                    }
                }
            }
        }
    }

    return $pairs
}

$pairs += Calculate-Balance -BaseMarket "USDT" -Balances $balances
#$pairs += Calculate-Balance -BaseMarket "BUSD" -Balances $balances

Get-BinanceTable -Pairs $Pairs

