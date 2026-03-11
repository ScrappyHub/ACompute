param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function MustExist([string]$p){ if(-not (Test-Path -LiteralPath $p -PathType Leaf)){ throw ("MISSING: " + $p) } }
function ReadAll([string]$p){ return [System.IO.File]::ReadAllText($p) }

$Eval = Join-Path $RepoRoot "app\src\acompute\engine\eval.ts"
$Tr   = Join-Path $RepoRoot "app\src\acompute\core\transition.ts"
$Demo = Join-Path $RepoRoot "app\src\acompute\demos\demo_shift2.ts"
$Run  = Join-Path $RepoRoot "app\src\acompute\engine\run_demo_shift2.ts"
MustExist $Eval
MustExist $Tr
MustExist $Demo
MustExist $Run

$e = ReadAll $Eval
$t = ReadAll $Tr
$d = ReadAll $Demo
$r = ReadAll $Run

# 1) Demo graph encodes D0->Q0 and Q0->Q1.
if($d -notmatch "from: `"D0`", to: `"Q0`""){ throw "SELFTEST_FAIL: demo missing D0->Q0" }
if($d -notmatch "from: `"Q0`", to: `"Q1`""){ throw "SELFTEST_FAIL: demo missing Q0->Q1" }

# 2) Eval must treat DFF outputs as stored state (prev.seq) so Q0 seen by Q1 is the *previous* Q0.
if($e -notmatch "kind\s*===\s*`"dff`""){ throw "SELFTEST_FAIL: eval missing dff branch" }
if($e -notmatch "prev\.seq|state\.seq"){ throw "SELFTEST_FAIL: eval does not reference prior seq state" }

# 3) Transition must compute combinational outs first, then compute nextSeq from outs snapshot (not from nextSeq).
$iOut = $t.IndexOf("const outs = evalGraph")
$iSeq = $t.IndexOf("const nextSeq")
if($iOut -lt 0){ throw "SELFTEST_FAIL: transition missing outs evalGraph line" }
if($iSeq -lt 0){ throw "SELFTEST_FAIL: transition missing nextSeq line" }
if($iSeq -lt $iOut){ throw "SELFTEST_FAIL: nextSeq appears before outs; would break shift semantics" }
if($t -notmatch "nextSeq\[n\.id\]\s*=\s*d"){ throw "SELFTEST_FAIL: transition missing nextSeq assignment" }
if($t -notmatch "outs\["){ throw "SELFTEST_FAIL: transition does not reference outs snapshot" }

# 4) Runner contains step expectations (optional but good sanity).
if($r -notmatch "step1 Q1"){ throw "SELFTEST_FAIL: runner missing step1 assertions" }
if($r -notmatch "step2 Q1"){ throw "SELFTEST_FAIL: runner missing step2 assertions" }

Write-Host "SELFTEST_MVP3_SHIFT2_OK: demo graph + two-step capture semantics encoded" -ForegroundColor Green
