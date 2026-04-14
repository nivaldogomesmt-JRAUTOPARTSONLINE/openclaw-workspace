param(
  [Parameter(Mandatory=$true)]
  [string]$Root,

  [string]$OutDir = (Join-Path (Get-Location) 'reports'),

  [ValidateSet('SHA256','MD5')]
  [string]$Algorithm = 'SHA256'
)

$ErrorActionPreference = 'SilentlyContinue'

if(!(Test-Path $Root)){
  throw "Root not found: $Root"
}

if(!(Test-Path $OutDir)){
  New-Item -ItemType Directory -Path $OutDir | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outItems   = Join-Path $OutDir "dupes_exact_${timestamp}.csv"
$outSummary = Join-Path $OutDir "dupes_summary_${timestamp}.csv"

# Collect local files only to avoid triggering cloud downloads
$files = Get-ChildItem -LiteralPath $Root -File -Recurse -Force |
  Where-Object { (($_.Attributes -band [System.IO.FileAttributes]::Offline) -eq 0) }

# Group by size first (fast filter)
$sizeGroups = $files | Group-Object Length | Where-Object { $_.Count -gt 1 }

$dupeItems = New-Object System.Collections.Generic.List[object]

foreach($g in $sizeGroups){
  $hashRecords = foreach($f in $g.Group){
    try {
      $h = Get-FileHash -Algorithm $Algorithm -LiteralPath $f.FullName
      [pscustomobject]@{
        Length = [int64]$f.Length
        Hash = $h.Hash
        Path = $f.FullName
        LastWriteTimeUtc = $f.LastWriteTimeUtc
      }
    } catch {
      # ignore hash failures
    }
  }

  foreach($hg in ($hashRecords | Group-Object Hash | Where-Object { $_.Count -gt 1 })){
    $groupId = "${($g.Name)}_${($hg.Name)}"
    foreach($item in $hg.Group){
      $dupeItems.Add([pscustomobject]@{
        GroupId = $groupId
        Length = $item.Length
        Hash = $item.Hash
        Path = $item.Path
        LastWriteTimeUtc = $item.LastWriteTimeUtc
      })
    }
  }
}

$dupeItems | Export-Csv -Path $outItems -NoTypeInformation -Encoding UTF8

$summary = $dupeItems |
  Group-Object GroupId |
  ForEach-Object {
    $count = $_.Count
    $len = [int64]$_.Group[0].Length
    [pscustomobject]@{
      GroupId = $_.Name
      Count = $count
      SizeMB = [math]::Round($len/1MB, 2)
      WastedMB = [math]::Round((($count-1)*$len)/1MB, 2)
      ExamplePath = $_.Group[0].Path
    }
  } |
  Sort-Object WastedMB -Descending

$summary | Export-Csv -Path $outSummary -NoTypeInformation -Encoding UTF8

[pscustomobject]@{
  Root = $Root
  TotalFilesScanned = $files.Count
  SizeGroups = $sizeGroups.Count
  DuplicateGroups = $summary.Count
  ItemsInDuplicates = $dupeItems.Count
  OutputItems = $outItems
  OutputSummary = $outSummary
} | ConvertTo-Json -Depth 3
