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

$strategyPath = "$curPath\Strategies\$global:GSMGStrategy.ps1"
if (-not (Test-Path $strategyPath)) {
    throw "Could not find strategy for filename '$strategyPath'."
}

while ($true) {
    cls

    . $strategyPath

    Write-Host "Sleeping for 60 seconds before running strategy again..."
    Sleep -Seconds 60
}
