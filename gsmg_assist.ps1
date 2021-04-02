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
    Query-24hTicker($market.market_name.Replace("Binance:", ""))
}

#Set-GSMGSetting -Market "CAKEBUSD" -AggressivenessPct 15 -MinTradeProfitPct 5
