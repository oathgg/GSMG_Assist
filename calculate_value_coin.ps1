. "C:\Users\svdho\Desktop\Trading\Functions\binance_api.ps1"
. "C:\Users\svdho\Desktop\Trading\Functions\Converters.ps1"

# Go to Spot Orders -> Trade History -> Set the market to ALL/USDT
$excel = "C:\Users\svdho\Desktop\Trading\Exports\Export Recent Trade History.xlsx"
$f = gc (Convert-ExcelToCsv -File $excel)
$tradeType = "UNKNOWN"
$pairs = @{}

# First row is the header, skip.
for ($i = 1; $i -lt $f.Length; $i++) {
    $row = $f[$i].Split(",")
    
    $tradeType = $row[2]
    $market = $row[1]
    $amount = $row[4]
    $total = $row[5]

    if (-not $pairs.Contains($market)) {
        $pairs["$market"] = @{}
    }

    switch ($tradeType) {
        "BUY" { 
            if ($market -eq "TCTUSDT") {
                Write-Verbose "Bp"
            } 
            $pairs["$market"]["Total"] += [float] $total
            $pairs["$market"]["Amount"] += [float] $amount
        }
        "SELL" { 
            $pairs["$market"]["Total"] -= [float] $total
            $pairs["$market"]["Amount"] -= [float] $amount
        }
    }
}

$clipboard = ""
$objList = @()
foreach ($market in $pairs.Keys | Sort-Object) {
    $pair = $pairs[$market]
    if ($pair.amount -gt 0) {
        $currentMarketPrice = (Query-MarketValue($Market)).price
        $total = $pair.Total
        if ($total -lt 0) {
            $total = 0
        }
        $profit = [float] $currentMarketPrice * [float] $pair.Amount - [float] $total
        $text = "$market`t$($pair.Amount)`t$($total)`t$($currentMarketPrice)"
        $clipboard += $text + "`r`n"

        $obj = New-Object psobject -Property @{ 
            Market=$market; 
            Amount=$pair.Amount; 
            Total=$total; 
            CurrentMarketPrice=$currentMarketPrice; 
            Profit= [Math]::Round($profit, 2)
        }
        $objList += $obj | Select-Object Market,Amount,Total,CurrentMarketPrice,Profit
    }
}

$objList | Format-Table
Set-Clipboard -Value $clipboard

