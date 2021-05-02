function Get-Latest($Path) {
    pushd
    cd $Path
    #git stash
    git pull
    popd
}

$curPath = $PSScriptRoot
if (-not $curPath) {
    $curPath = $psise.CurrentFile.FullPath
}

if (-not (Test-Path "$curPath\parameters.ps1")) {
    throw "Parameter file needs to be created before running the tool, see readme.md"
}

. "$curPath\Functions\binance_api.ps1"
. "$curPath\Functions\gsmg_api.ps1"
. "$curPath\Functions\Converters.ps1"
. "$curPath\Functions\Tools.ps1"

while ($true) {
    Get-Latest -Path $curPath
    . "$curPath\parameters.ps1"
    . "$curPath\CreateConfigurationObject.ps1"
    . "$curPath\ConfigureGSMG.ps1"

    $strategyPath = "$curPath\Strategies\$global:GSMGStrategy.ps1"
    if (-not (Test-Path $strategyPath)) {
        Write-Warning "Could not find strategy with filename '$strategyPath'."
    } else {
        . $strategyPath
    }

    $Global:GSMGmarkets = Get-GSMGMarkets
    $Global:GSMGAllocations = Get-GSMGMarketAllocations  

    Clear-Host

    $Settings = Run-Strategy
    Run-ConfigureGSMG -Settings $Settings

    Write-Host "Sleeping for 60 seconds before running strategy again..."
    Start-Sleep -Seconds 60
}
