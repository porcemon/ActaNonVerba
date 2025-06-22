$invalid = @()
$maxLines = 50

Get-ChildItem -Recurse -Include *.TcPOU | ForEach-Object {
    $file = $_.FullName
    Write-Host "Checking methods in: $file"

    try {
        [xml]$xml = Get-Content $file -Raw -ErrorAction Stop
        $methods = $xml.SelectNodes("//Method")

        foreach ($method in $methods) {
            $methodName = $method.Name
            $implNode = $method.SelectSingleNode("Implementation/ST")

            if ($implNode -ne $null) {
                $lines = $implNode.InnerText -split "`n"
                $lineCount = ($lines | Where-Object { $_.Trim() -ne "" }).Count

                if ($lineCount -gt $maxLines) {
                    $invalid += "Method '$methodName' in $file has $lineCount lines (limit is $maxLines)"
                }
            }
            else {
                Write-Warning "No implementation found for method '$methodName' in $file"
            }
        }
    }
    catch {
        Write-Warning "Failed to parse ${file}: $_"
    }
}

if ($invalid.Count -gt 0) {
    Write-Host "`n❌ Methods that exceed $maxLines lines:"
    $invalid | ForEach-Object { Write-Host " - $_" }
    exit 1
}
else {
    Write-Host "✅ All methods are within the allowed length of $maxLines lines."
}
