Clear-Host

$curPath = $PSScriptRoot
if (-not $curPath) {
    $curPath = $psise.CurrentFile.FullPath
}

. "$curPath\parameters.ps1"
. "$curPath\Functions\binance_api.ps1"
. "$curPath\Functions\Converters.ps1"
. "$curPath\Functions\Tools.ps1"

#Write-Host "Querying exchange information..."
#$exchangeInfo = Get-ExchangeInfo

Write-Host "Querying Account information..."
$accountInformation = Get-AccountInformation
$balances = $accountInformation.balances | Where-Object { [float]$_.Free -gt 0 -or [float]$_.Locked -gt 0 } | Sort-Object asset
$pairs = @{}

function Get-Pairs($Balances) {
    $pairs = @{}

    foreach($balance in $balances) {
        Write-Host "Parsing balances $($balance.asset)"

        $asset = $balance.asset
        if (-not $pairs.Contains("$asset")) {
            $pairs["$asset"] = @{}
        }

        if ($asset -eq "BUSD" -or $asset -eq "USDT") {
            Write-Host "`t- Base currency, adding free + locked in balance"

            $baseCurrencyValue = [float] $balance.free + [float] $balance.locked
            $pairs["$asset"]["Total"] = $baseCurrencyValue
            $pairs["$asset"]["Amount"] = $baseCurrencyValue
        } else {
            foreach ($symbol in @("USDT","BUSD")) {
                $market = $asset + $symbol
                $timeago = (Get-Date).AddYears(-1)
                $Trades = Get-MyTrades -Symbol $market -From $timeago

                foreach ($trade in $Trades) {
                    if ($trade.isBuyer) {
                        $pairs["$asset"]["Total"] += [float] $trade.quoteQty
                        $pairs["$asset"]["Amount"] += [float] $trade.qty - [float] $trade.commision
                    } else {
                        $pairs["$asset"]["Total"] -= [float] $trade.quoteQty
                        $pairs["$asset"]["Amount"] -= [float] $trade.qty - [float] $trade.commision

                        # If the total is 0 it means we have probably taken out all our profits
                        # Might be a moon bag, however, if the amount is less than 1 it means we left the coin completely
                        if ($pairs["$asset"]["Total"] -le 0 -and $pairs["$asset"]["Amount"] -lt 1) {
                            $pairs["$asset"] = @{}
                        }
                    }
                }
            }
        }
    }

    return $pairs
}

$pairs += Get-Pairs -Balances $balances

Get-BinanceTable -Pairs $Pairs

