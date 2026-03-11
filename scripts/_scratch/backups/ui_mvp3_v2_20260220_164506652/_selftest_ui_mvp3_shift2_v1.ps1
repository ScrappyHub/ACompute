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

$pTxt = [System.IO.File]::ReadAllText($panel)
if($pTxt -notmatch "export function DemoShift2Panel"){ throw "SELFTEST_FAIL: DemoShift2Panel export missing" }
if($pTxt -notmatch "Pulse \\(0-\\&gt;1-\\&gt;0\\)"){ throw "SELFTEST_FAIL: pulse text missing (expected 0->1->0)" }

$mTxt = [System.IO.File]::ReadAllText($main)
if($mTxt -notmatch "DemoShift2Panel"){ throw "SELFTEST_FAIL: main.tsx not mounting DemoShift2Panel" }

$pkgTxt = [System.IO.File]::ReadAllText($pkg)
if($pkgTxt -notmatch '"dev"\s*:\s*"vite"'){ throw "SELFTEST_FAIL: package.json missing dev script" }

Write-Host "SELFTEST_UI_MVP3_OK: panel + mount + dev script present" -ForegroundColor Green
