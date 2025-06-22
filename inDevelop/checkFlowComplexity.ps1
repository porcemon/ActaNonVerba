$invalid = @()
$maxDepth = 3

Get-ChildItem -Recurse -Include *.TcPOU | ForEach-Object {
    $file = $_.FullName
    Write-Host "Checking: $file"

    try {
        [xml]$xml = Get-Content $file -Raw -ErrorAction Stop
        $stBlocks = $xml.SelectNodes("//Implementation/ST")

        foreach ($block in $stBlocks) {
            $lines = $block.InnerText -split "`n"
            $depth = 0
            $maxReached = 0
            $lineNum = 0

            foreach ($line in $lines) {
                $lineNum++
                $code = $line.Trim().ToUpper()

                # Increase depth
                if ($code -match '^(IF|CASE|FOR|WHILE|REPEAT)\b') {
                    $depth++
                    if ($depth -gt $maxDepth) {
                        $invalid += "Too deep ($depth) in $file at line ${lineNum}: $line"
                    }
                    $maxReached = [math]::Max($depth, $maxReached)
                }

                # Decrease depth
                if ($code -match '^(END_IF|END_CASE|END_FOR|END_WHILE|UNTIL)\b') {
                    $depth = [math]::Max(0, $depth - 1)
                }
            }

            if ($maxReached -le $maxDepth) {
                Write-Host "Max depth in ${file}: $maxReached ✅"
            }
        }
    }
    catch {
        Write-Warning "Failed to parse ${file}: $_"
    }
}

if ($invalid.Count -gt 0) {
    Write-Host "`n❌ Excessive nesting detected:"
    $invalid | ForEach-Object { Write-Host " - $_" }
    exit 1
}
else {
    Write-Host "✅ All ST code blocks are within allowed nesting depth."
}
