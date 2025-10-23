$path = "C:\Users\Gajda\OneDrive\Documents\cAlgo\Sources\Indicators\izzML\izzML\izzML.cs"
$content = Get-Content $path -Raw -Encoding Default
[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
Write-Host "File converted to UTF-8"
