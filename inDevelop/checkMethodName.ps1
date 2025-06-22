$invalid = @()

Get-ChildItem -Recurse -Include *.TcPOU | ForEach-Object {
    $file = $_.FullName
    Write-Host "Checking file: $file"

    try {
        [xml]$xml = Get-Content $file -Raw -ErrorAction Stop
        $methodNodes = $xml.SelectNodes("//Method")

        foreach ($method in $methodNodes) {
            $declNode = $method.SelectSingleNode("Declaration")
            $declText = $declNode.InnerText.Trim()

            # Match: METHOD [PRIVATE|PROTECTED] Name
            if ($declText -match '^METHOD\s+(?:(PRIVATE|PROTECTED)\s+)?([a-zA-Z_][a-zA-Z0-9_]*)') {
                $access = $matches[1]
                $declaredName = $matches[2]
                $methodXmlName = $method.Name

                if (-not $access) { $access = "PUBLIC" }  # Default case when unspecified

                switch ($access.ToUpper()) {
                    "PRIVATE" {
                        if ($methodXmlName -notmatch '^_M_') {
                            $invalid += "PRIVATE method '$methodXmlName' should start with '_M_' ($file)"
                        }
                    }
                    "PROTECTED" {
                        if ($methodXmlName -notmatch '^_M_') {
                            $invalid += "PROTECTED method '$methodXmlName' should start with '_M_' ($file)"
                        }
                    }
                    default {
                        # PUBLIC and everything else
                        if ($methodXmlName -notmatch '^M_') {
                            $invalid += "Method '$methodXmlName' should start with 'M_' ($file)"
                        }
                    }
                }
            }
            else {
                Write-Warning "Couldn't parse METHOD declaration in ${file}: $($declText -split '\n')[0]"
            }
        }
    }
    catch {
        Write-Warning "Failed to parse ${file}: $_"
    }
}

if ($invalid.Count -gt 0) {
    Write-Host "`n❌ Invalid method naming:"
    $invalid | ForEach-Object { Write-Host " - $_" }
    exit 1
}
else {
    Write-Host "✅ All methods follow naming conventions (_M_ / M_)"
}
