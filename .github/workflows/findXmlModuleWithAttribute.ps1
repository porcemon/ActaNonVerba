<#
.SYNOPSIS
  Finds XML tags with a specific attribute (and optional value).

.PARAMETER File
  Path to the XML file to search.

.PARAMETER Tag
  XML tag name (element) to search for.

.PARAMETER Attribute
  Name of the attribute to look for.

.PARAMETER Value
  (Optional) Specific value of the attribute to match.
#>

param(
  [Parameter(Mandatory=$true)]
  [string]$File,

  [Parameter(Mandatory=$true)]
  [string]$Tag,

  [Parameter(Mandatory=$true)]
  [string]$Attribute,

  [string]$Value
)

if (-not (Test-Path $File)) {
  Write-Error "File not found: $File"
  exit 1
}

[xml]$xml = Get-Content $File

# Find all matching tags
$elements = $xml.SelectNodes("//$Tag")

if ($elements.Count -eq 0) {
  Write-Host "No <$Tag> elements found."
  exit 0
}

foreach ($el in $elements) {
  if ($el.HasAttribute($Attribute)) {
    if ($Value) {
      if ($el.$Attribute -eq $Value) {
        Write-Host "Found <$Tag $Attribute=`"$Value`">"
      }
    } else {
      Write-Host "Found <$Tag> with attribute '$Attribute' = '$($el.$Attribute)'"
    }
  }
}
