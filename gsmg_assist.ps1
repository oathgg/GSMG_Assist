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

$strategyPath = "$curPath\Strategies\$global:GSMGStrategy.ps1"
if (-not (Test-Path $strategyPath)) {
    throw "Strategy with the name '$global:GSMGStrategy' not found"
}

. $strategyPath
