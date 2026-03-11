param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ throw "EnsureDir: empty path" }
  if(-not (Test-Path -LiteralPath $p -PathType Container)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}

function WriteUtf8NoBomLf([string]$Path,[string]$Text){
  if([string]::IsNullOrWhiteSpace($Path)){ throw "WriteUtf8NoBomLf: empty path" }
  $enc = New-Object System.Text.UTF8Encoding($false)
  $t = $Text -replace "`r`n","`n"
  $t = $t -replace "`r","`n"
  if(-not $t.EndsWith("`n")){ $t += "`n" }
  EnsureDir (Split-Path -Parent $Path)
  [System.IO.File]::WriteAllText($Path,$t,$enc)
}

$panelPath = Join-Path $RepoRoot "app\src\acompute\ui\DemoShift2Panel.tsx"
if(-not (Test-Path -LiteralPath $panelPath -PathType Leaf)){
  throw ("MISSING_PANEL: " + $panelPath)
}

$txt = [System.IO.File]::ReadAllText($panelPath)

# Replace ASCII arrows in *display text* with Unicode arrows
$txt = $txt.Replace("D0 -> Q0, and Q0 -> D1 -> Q1. Pulse performs clk 0->1->0 (rising edge capture).", "D0 → Q0, and Q0 → D1 → Q1. Pulse performs clk 0→1→0 (rising edge capture).")
$txt = $txt.Replace("Pulse (0->1->0)", "Pulse (0→1→0)")

WriteUtf8NoBomLf $panelPath $txt

Write-Host ("PATCH_OK: fixed JSX arrow text in " + $panelPath) -ForegroundColor Green
Write-Host "NOTE: in the Vite terminal press r + Enter to reload" -ForegroundColor Yellow
