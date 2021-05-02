function New-ConfigurationObject($BemPct, $AggressivenessPct, $ShouldAllocate, $BaseCurrency, $MarketName, $MinProfitPct) {
    $Settings = New-Object PSObject -Property @{ 
        MarketName=$MarketName;
        BemPCT=$BemPct; 
        AggressivenessPct=$AggressivenessPct; 
        ShouldAllocate=$ShouldAllocate; 
        BaseCurrency=$BaseCurrency; 
        MinProfitPct=$MinProfitPct
    }
    return $Settings
}
