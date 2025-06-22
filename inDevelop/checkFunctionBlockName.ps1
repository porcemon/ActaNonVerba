$invalid = @()

Get-ChildItem -Recurse -Include *.TcPOU | ForEach-Object {
    $file = $_.FullName
    Write-Host "Checking file: $file"

    try {
        [xml]$xml = Get-Content $file -Raw -ErrorAction Stop
        $pouNode = $xml.SelectSingleNode("//POU")

        if (-not $pouNode) {
            Write-Warning "No <POU> tag found in $file"
            return
        }

        $pouName = $pouNode.Name
        $declaration = $pouNode.Declaration.InnerText.Trim()

        if ($declaration -match '^FUNCTION_BLOCK\s+([a-zA-Z_][a-zA-Z0-9_]*)') {
            if ($pouName -notmatch '^FB_') {
                $invalid += "POU '$pouName' is a FUNCTION_BLOCK but doesn't start with 'FB_' ($file)"
            }
        }

    }
    catch {
        Write-Warning "Failed to parse ${file}: $_"
    }
}

if ($invalid.Count -gt 0) {
    Write-Host "`n❌ Invalid FUNCTION_BLOCK names:"
    $invalid | ForEach-Object { Write-Host " - $_" }
    exit 1
}
else {
    Write-Host "✅ All FUNCTION_BLOCKs are properly named with 'FB_' prefix."
}
