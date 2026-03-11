param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

$need = @('README.md','SPEC\ACompute_SPEC_v1.md','WBS\WBS_v1.md','app\src\acompute\core\types.ts','app\src\acompute\core\transition.ts')
foreach($r in $need){ $p = Join-Path $RepoRoot $r; if(-not (Test-Path -LiteralPath $p -PathType Leaf)){ throw ("SELFTEST_MISSING: " + $r) } }
Write-Host ("SELFTEST_OK: " + $RepoRoot) -ForegroundColor Green
