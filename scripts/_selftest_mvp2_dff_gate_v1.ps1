param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function MustExist([string]$p){ if(-not (Test-Path -LiteralPath $p -PathType Leaf)){ throw ("MISSING: " + $p) } }
function MustMatch([string]$name,[string]$txt,[string]$pattern){ if($txt -notmatch $pattern){ throw ("SELFTEST_FAIL: " + $name + " missing pattern: " + $pattern) } }

$Demo = Join-Path $RepoRoot "app\src\acompute\demos\demo_dff_rising.ts"
$Run  = Join-Path $RepoRoot "app\src\acompute\engine\run_demo_dff_rising.ts"
$Tr   = Join-Path $RepoRoot "app\src\acompute\core\transition.ts"
MustExist $Demo
MustExist $Run
MustExist $Tr

$demoTxt = [System.IO.File]::ReadAllText($Demo)
$runTxt  = [System.IO.File]::ReadAllText($Run)
$trTxt   = [System.IO.File]::ReadAllText($Tr)

MustMatch "demo has dff node" $demoTxt "kind:\s*""dff"""
MustMatch "demo has D input"  $demoTxt "id:\s*""D"".*kind:\s*""input"""
MustMatch "demo has Q dff"    $demoTxt "id:\s*""Q"".*kind:\s*""dff"""
MustMatch "demo edge D->Q"    $demoTxt "from:\s*""D"".*to:\s*""Q"".*inputIndex:\s*0"

# Transition rising-edge rule must be present
MustMatch "transition rising edge" $trTxt "const\s+rising\s*=\s*\(prev\.clk\s*===\s*0\)\s*&&\s*\(nextClk\s*===\s*1\)"
MustMatch "transition updates seq for dff" $trTxt "if\s*\(n\.kind\s*!==\s*""dff""\)\s*continue"
MustMatch "transition writes nextSeq" $trTxt "nextSeq\[n\.id\]\s*=\s*d"

# Demo runner should assert the semantic expectations (even if not executed here)
MustMatch "runner expects no capture when clk low" $runTxt "no rising edge"
MustMatch "runner expects capture on rising edge"   $runTxt "rising edge"

Write-Host "SELFTEST_MVP2_DFF_OK: rising-edge rule present + demo wired" -ForegroundColor Green

