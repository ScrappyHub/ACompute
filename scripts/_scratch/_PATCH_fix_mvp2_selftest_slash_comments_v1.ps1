param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){ if([string]::IsNullOrWhiteSpace($p)){ throw "EnsureDir: empty path" } if(-not (Test-Path -LiteralPath $p -PathType Container)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBomLf([string]$Path,[string]$Text){ $enc=New-Object System.Text.UTF8Encoding($false); $t=$Text -replace "`r`n","`n"; $t=$t -replace "`r","`n"; if(-not $t.EndsWith("`n")){ $t += "`n" }; EnsureDir (Split-Path -Parent $Path); [System.IO.File]::WriteAllText($Path,$t,$enc) }

$Target = Join-Path $RepoRoot "scripts\_selftest_mvp2_dff_gate_v1.ps1"
if(-not (Test-Path -LiteralPath $Target -PathType Leaf)){ throw ("MISSING: " + $Target) }
$raw = [System.IO.File]::ReadAllText($Target)
$norm = ($raw -replace "`r`n","`n") -replace "`r","`n"
$lines = @(@($norm -split "`n",-1))
$out = New-Object System.Collections.Generic.List[string]
$changed = $false
for($i=0;$i -lt $lines.Count;$i++){
  $ln = $lines[$i]
  if($ln -match '^\s*//' ){
    $ln2 = ($ln -replace '^(\s*)//','$1#')
    if($ln2 -ne $ln){ $changed = $true; $ln = $ln2 }
  }
  [void]$out.Add($ln)
}
$final = ((@($out.ToArray()) -join "`n") + "`n")
WriteUtf8NoBomLf $Target $final
if($changed){ Write-Host ("PATCH_OK: replaced // with # in " + $Target) -ForegroundColor Green } else { Write-Host ("PATCH_OK: no // comments found in " + $Target) -ForegroundColor Green }
