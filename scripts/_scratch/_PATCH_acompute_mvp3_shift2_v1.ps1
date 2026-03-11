param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){ if([string]::IsNullOrWhiteSpace($p)){ throw "EnsureDir: empty path" } if(-not (Test-Path -LiteralPath $p -PathType Container)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBomLf([string]$Path,[string]$Text){ if([string]::IsNullOrWhiteSpace($Path)){ throw "WriteUtf8NoBomLf: empty path" }; $enc=New-Object System.Text.UTF8Encoding($false); $t=$Text -replace "`r`n","`n"; $t=$t -replace "`r","`n"; if(-not $t.EndsWith("`n")){ $t += "`n" }; EnsureDir (Split-Path -Parent $Path); [System.IO.File]::WriteAllText($Path,$t,$enc) }

$demoDir   = Join-Path $RepoRoot "app\src\acompute\demos"
$engineDir = Join-Path $RepoRoot "app\src\acompute\engine"
$scriptsDir= Join-Path $RepoRoot "scripts"
EnsureDir $demoDir
EnsureDir $engineDir
EnsureDir $scriptsDir

$d=@()
$d += 'import type { Graph } from "../graph/graph";'
$d += ''
$d += '# Shift register: D0 -> Q0, Q0 -> Q1'
$d += 'export const demoShift2: Graph = {'
$d += '  nodes: ['
$d += '    { id: "D0", kind: "input", label: "D0", x: 40,  y: 80 },'
$d += '    { id: "Q0", kind: "dff",   label: "DFF0", x: 220, y: 80 },'
$d += '    { id: "Q1", kind: "dff",   label: "DFF1", x: 400, y: 80 }'
$d += '  ],'
$d += '  edges: ['
$d += '    { id: "e0", from: "D0", to: "Q0", inputIndex: 0 },'
$d += '    { id: "e1", from: "Q0", to: "Q1", inputIndex: 0 }'
$d += '  ]'
$d += '};'
WriteUtf8NoBomLf (Join-Path $demoDir "demo_shift2.ts") ((@($d) -join "`n") + "`n")

$r=@()
$r += 'import type { Bit } from "../core/types";'
$r += 'import { initialState } from "../core/state";'
$r += 'import { evalGraph } from "./eval";'
$r += 'import { transition } from "../core/transition";'
$r += 'import { demoShift2 } from "../demos/demo_shift2";'
$r += ''
$r += 'function expect(name: string, got: Bit, want: Bit){ if(got !== want){ throw new Error(`EXPECT_FAIL ${name}: got=${got} want=${want}`); } }'
$r += ''
$r += 'export function runDemoShift2(){'
$r += '  let s = initialState();'
$r += '  # Step 1 (rising): D0=1 => Q0 captures 1, Q1 captures old Q0(0)'
$r += '  s = transition(s, demoShift2, { D0: 1 }, 1 as Bit);'
$r += '  const o1 = evalGraph(s, demoShift2, { D0: 1 });'
$r += '  console.log("SHIFT2 step1 Q0=", o1["Q0"], "Q1=", o1["Q1"]);'
$r += '  expect("step1 Q0", (o1["Q0"] ?? 0) as Bit, 1);'
$r += '  expect("step1 Q1", (o1["Q1"] ?? 0) as Bit, 0);'
$r += ''
$r += '  # Step 2 (rising): D0=0 => Q0 captures 0, Q1 captures previous Q0(1)'
$r += '  s = transition(s, demoShift2, { D0: 0 }, 1 as Bit);'
$r += '  const o2 = evalGraph(s, demoShift2, { D0: 0 });'
$r += '  console.log("SHIFT2 step2 Q0=", o2["Q0"], "Q1=", o2["Q1"]);'
$r += '  expect("step2 Q0", (o2["Q0"] ?? 0) as Bit, 0);'
$r += '  expect("step2 Q1", (o2["Q1"] ?? 0) as Bit, 1);'
$r += '}'
WriteUtf8NoBomLf (Join-Path $engineDir "run_demo_shift2.ts") ((@($r) -join "`n") + "`n")

$st=@()
$st += 'param([Parameter(Mandatory=$true)][string]$RepoRoot)'
$st += '$ErrorActionPreference="Stop"'
$st += 'Set-StrictMode -Version Latest'
$st += ''
$st += 'function MustExist([string]$p){ if(-not (Test-Path -LiteralPath $p -PathType Leaf)){ throw ("MISSING: " + $p) } }'
$st += 'function ReadAll([string]$p){ return [System.IO.File]::ReadAllText($p) }'
$st += ''
$st += '$Eval = Join-Path $RepoRoot "app\src\acompute\engine\eval.ts"'
$st += '$Tr   = Join-Path $RepoRoot "app\src\acompute\core\transition.ts"'
$st += '$Demo = Join-Path $RepoRoot "app\src\acompute\demos\demo_shift2.ts"'
$st += '$Run  = Join-Path $RepoRoot "app\src\acompute\engine\run_demo_shift2.ts"'
$st += 'MustExist $Eval'
$st += 'MustExist $Tr'
$st += 'MustExist $Demo'
$st += 'MustExist $Run'
$st += ''
$st += '$e = ReadAll $Eval'
$st += '$t = ReadAll $Tr'
$st += '$d = ReadAll $Demo'
$st += '$r = ReadAll $Run'
$st += ''
$st += '# 1) Demo graph encodes D0->Q0 and Q0->Q1.'
$st += 'if($d -notmatch "from: `"D0`", to: `"Q0`""){ throw "SELFTEST_FAIL: demo missing D0->Q0" }'
$st += 'if($d -notmatch "from: `"Q0`", to: `"Q1`""){ throw "SELFTEST_FAIL: demo missing Q0->Q1" }'
$st += ''
$st += '# 2) Eval must treat DFF outputs as stored state (prev.seq) so Q0 seen by Q1 is the *previous* Q0.'
$st += 'if($e -notmatch "kind\s*===\s*`"dff`""){ throw "SELFTEST_FAIL: eval missing dff branch" }'
$st += 'if($e -notmatch "prev\.seq|state\.seq"){ throw "SELFTEST_FAIL: eval does not reference prior seq state" }'
$st += ''
$st += '# 3) Transition must compute combinational outs first, then compute nextSeq from outs snapshot (not from nextSeq).'
$st += '$iOut = $t.IndexOf("const outs = evalGraph")'
$st += '$iSeq = $t.IndexOf("const nextSeq")'
$st += 'if($iOut -lt 0){ throw "SELFTEST_FAIL: transition missing outs evalGraph line" }'
$st += 'if($iSeq -lt 0){ throw "SELFTEST_FAIL: transition missing nextSeq line" }'
$st += 'if($iSeq -lt $iOut){ throw "SELFTEST_FAIL: nextSeq appears before outs; would break shift semantics" }'
$st += 'if($t -notmatch "nextSeq\[n\.id\]\s*=\s*d"){ throw "SELFTEST_FAIL: transition missing nextSeq assignment" }'
$st += 'if($t -notmatch "outs\["){ throw "SELFTEST_FAIL: transition does not reference outs snapshot" }'
$st += ''
$st += '# 4) Runner contains step expectations (optional but good sanity).'
$st += 'if($r -notmatch "step1 Q1"){ throw "SELFTEST_FAIL: runner missing step1 assertions" }'
$st += 'if($r -notmatch "step2 Q1"){ throw "SELFTEST_FAIL: runner missing step2 assertions" }'
$st += ''
$st += 'Write-Host "SELFTEST_MVP3_SHIFT2_OK: demo graph + two-step capture semantics encoded" -ForegroundColor Green'
WriteUtf8NoBomLf (Join-Path $scriptsDir "_selftest_mvp3_shift2_v1.ps1") ((@($st) -join "`n") + "`n")

$ledgerPath = Join-Path $RepoRoot "WBS\PROGRESS_LEDGER_v1.md"
if(-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)){ EnsureDir (Split-Path -Parent $ledgerPath); WriteUtf8NoBomLf $ledgerPath ("# Progress Ledger v1`n`n") }
$line = "- 2026-02-20: MVP3 gate added (2-DFF shift register demo + selftest validates two-step capture semantics; no node required)."
$existing = [System.IO.File]::ReadAllText($ledgerPath)
if($existing -notmatch [regex]::Escape($line)){ $out = ($existing -replace "`r`n","`n") -replace "`r","`n"; if(-not $out.EndsWith("`n")){ $out += "`n" }; $out += $line + "`n"; WriteUtf8NoBomLf $ledgerPath $out }

Write-Host "APPLY_OK: MVP3 shift2 demo + selftest written" -ForegroundColor Green
