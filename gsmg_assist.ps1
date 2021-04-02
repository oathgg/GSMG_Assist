cls

$curPath = $PSScriptRoot
if (-not $curPath) {
    $curPath = $psise.CurrentFile.FullPath
}

if (-not (Test-Path "$curPath\parameters.ps1")) {
    throw "Parameter file needs to be created before running the tool, see readme.md"
}
. "$curPath\parameters.ps1"
. "$curPath\Functions\binance_api.ps1"
. "$curPath\Functions\gsmg_api.ps1"
. "$curPath\Functions\Converters.ps1"
. "$curPath\Functions\Tools.ps1"

$gsmgMfaCode = Read-Host "Please enter the GSMG MFA code"
New-GSMGAuthentication -Email $global:GSMGEmail -Password $global:GSMGPassword -Code $gsmgMfaCode
$markets = Get-GSMGMarkets

foreach ($market in $markets) {
    $marketName = $market.market_name.Replace("Binance:", "")
    $market24hInformation = Query-24hTicker($marketName)
    $24hPriceChange = [float] $market24hInformation.priceChange
    $bagPct = [float] $market.vol_sells_worth / ([float] $market.managed_value_usd / 100)

    if ($bagPct -le 40 -and $24hPriceChange -le 0) {
        Set-GSMGSetting -Market $marketName -BemPct 2
    } else {
        Set-GSMGSetting -Market $marketName -BemPct 0
    }
}
