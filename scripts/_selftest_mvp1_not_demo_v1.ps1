param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function MustExist([string]$p){ if(-not (Test-Path -LiteralPath $p -PathType Leaf)){ throw ("MISSING: " + $p) } }
$E = Join-Path $RepoRoot "app\src\acompute\engine\eval.ts"
$R = Join-Path $RepoRoot "app\src\acompute\engine\run_demo_not.ts"
$D = Join-Path $RepoRoot "app\src\acompute\demos\demo_not.ts"
$T = Join-Path $RepoRoot "app\src\acompute\core\transition.ts"
MustExist $E
MustExist $R
MustExist $D
MustExist $T

$eTxt = [System.IO.File]::ReadAllText($E)
$rTxt = [System.IO.File]::ReadAllText($R)
if($eTxt -notmatch "export function evalGraph"){ throw "SELFTEST_FAIL: evalGraph export missing" }
if($rTxt -notmatch "runDemoNot"){ throw "SELFTEST_FAIL: runDemoNot missing" }
Write-Host ("SELFTEST_MVP1_OK: files present + exports detected") -ForegroundColor Green
