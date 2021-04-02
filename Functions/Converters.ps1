Function Convert-ExcelToCsv ($File) {
    $myDir = Split-Path -Path $File
    $Excel = New-Object -ComObject Excel.Application
    $wb = $Excel.Workbooks.Open($File)
	
    $csvName = "$myDir\" + [io.path]::GetFileNameWithoutExtension($File) + ".csv"
    Remove-Item $csvName -ErrorAction Ignore -Force
    foreach ($ws in $wb.Worksheets) {
        $ws.SaveAs($csvName, 6)
    }
    $Excel.Quit()

    return $csvName
}