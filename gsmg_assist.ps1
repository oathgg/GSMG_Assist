param ($ParameterFileName = "parameters")

function Get-Latest($Path) {
    Push-Location
    Set-Location $Path
    git pull
    Pop-Location
}

$curPath = $PSScriptRoot
if (-not $curPath) {
    $curPath = $psise.CurrentFile.FullPath
}

if (-not (Test-Path "$curPath\$parameterFileName.ps1")) {
    throw "Parameter file needs to be created before running the tool, see readme.md"
}

. "$curPath\$parameterFileName.ps1"
. "$curPath\Functions\binance_api.ps1"
. "$curPath\Functions\gsmg_api.ps1"

while ($true) {
    if ($Global:DoGetLatest) {
        Get-Latest -Path $curPath
    }
    
    . "$curPath\$parameterFileName.ps1"
    . "$curPath\MarketHelper.ps1"

    $strategyPath = "$curPath\Strategies\$global:GSMGStrategy.ps1"
    if (-not (Test-Path $strategyPath)) {
        Write-Warning "Could not find strategy with filename '$strategyPath'."
    } else {
        . $strategyPath
    }

    $Global:GSMGmarkets = Get-GSMGMarkets | Where-Object { $_.market_name -notin $global:MarketsToIgnore }
    $Global:GSMGAllocations = Get-GSMGMarketAllocations | Where-Object { $_.market_name.Replace("Binance:", "") -notin $global:MarketsToIgnore }

    Clear-Host

    $Settings = Run-Strategy
    Run-ConfigureGSMG -Settings $Settings

    Write-Host "Sleeping for 60 seconds before running strategy again..."
    Start-Sleep -Seconds 60
}