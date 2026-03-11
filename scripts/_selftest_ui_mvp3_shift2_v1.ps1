param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function MustExist([string]$p){
  if(-not (Test-Path -LiteralPath $p -PathType Leaf)){
    throw ("MISSING: " + $p)
  }
}

$panel = Join-Path $RepoRoot "app\src\acompute\ui\DemoShift2Panel.tsx"
$main  = Join-Path $RepoRoot "app\src\main.tsx"
$pkg   = Join-Path $RepoRoot "app\package.json"

MustExist $panel
MustExist $main
MustExist $pkg

$pkgTxt = [System.IO.File]::ReadAllText($pkg)
if($pkgTxt -notmatch '"dev"\s*:\s*"vite"'){
  throw "SELFTEST_FAIL: package.json missing dev script"
}

Write-Host "SELFTEST_UI_MVP3_OK: scaffold + panel + dev script present" -ForegroundColor Green
