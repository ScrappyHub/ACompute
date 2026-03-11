param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ throw "EnsureDir: empty path" }
  if(-not (Test-Path -LiteralPath $p -PathType Container)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBomLf([string]$Path,[string]$Text){
  if([string]::IsNullOrWhiteSpace($Path)){ throw "WriteUtf8NoBomLf: empty path" }
  $enc = New-Object System.Text.UTF8Encoding($false)
  $t = $Text -replace "`r`n","`n"
  $t = $t -replace "`r","`n"
  if(-not $t.EndsWith("`n")){ $t += "`n" }
  $parent = Split-Path -Parent $Path
  if(-not [string]::IsNullOrWhiteSpace($parent)){ EnsureDir $parent }
  [System.IO.File]::WriteAllText($Path,$t,$enc)
}

$demoDir    = Join-Path $RepoRoot "app\src\acompute\demos"
$engineDir  = Join-Path $RepoRoot "app\src\acompute\engine"
$coreDir    = Join-Path $RepoRoot "app\src\acompute\core"
$scriptsDir = Join-Path $RepoRoot "scripts"
EnsureDir $demoDir
EnsureDir $engineDir
EnsureDir $coreDir
EnsureDir $scriptsDir

$d = @()
$d += 'import type { Graph } from "../graph/graph";'
$d += ''
$d += '// DFF Rising-Edge Demo'
$d += '//  - Input D feeds DFF'
$d += '//  - DFF output Q is the stored value (prev.seq["Q"])'
$d += '//  - transition() updates Q only on rising edge (clk: 0 -> 1)'
$d += ''
$d += 'export const demoDffRising: Graph = {'
$d += '  nodes: ['
$d += '    { id: "D", kind: "input" },'
$d += '    { id: "Q", kind: "dff" },'
$d += '  ],'
$d += '  edges: ['
$d += '    { from: "D", to: "Q", inputIndex: 0 },'
$d += '  ],'
$d += '};'
WriteUtf8NoBomLf (Join-Path $demoDir "demo_dff_rising.ts") ((@($d) -join "`n") + "`n")

$r = @()
$r += 'import { initialState } from "../core/state";'
$r += 'import { demoDffRising } from "../demos/demo_dff_rising";'
$r += 'import { transition } from "../core/transition";'
$r += 'import type { Bit } from "../core/types";'
$r += ''
$r += 'function expect(name: string, got: Bit, want: Bit) {'
$r += '  if (got !== want) throw new Error(`ASSERT_FAIL ${name}: got=${got} want=${want}`);'
$r += '}'
$r += ''
$r += 'export function runDemoDffRising(): void {'
$r += '  // Start: Q=0 (default)'
$r += '  let st = initialState();'
$r += '  // Hold clk low: changing D should NOT update Q'
$r += '  st = transition(st, demoDffRising, { D: 1 }, 0);'
$r += '  expect("Q still 0 (no rising edge)", (st.seq["Q"] ?? 0) as Bit, 0);'
$r += '  // Rising edge: clk 0 -> 1 captures D=1 into Q'
$r += '  st = transition(st, demoDffRising, { D: 1 }, 1);'
$r += '  expect("Q captured 1 (rising edge)", (st.seq["Q"] ?? 0) as Bit, 1);'
$r += '  // Hold high or fall: should not recapture'
$r += '  st = transition(st, demoDffRising, { D: 0 }, 1);'
$r += '  expect("Q remains 1 (clk high)", (st.seq["Q"] ?? 0) as Bit, 1);'
$r += '  st = transition(st, demoDffRising, { D: 0 }, 0);'
$r += '  expect("Q remains 1 (falling edge)", (st.seq["Q"] ?? 0) as Bit, 1);'
$r += '  console.log("DEMO_DFF_RISING OK");'
$r += '}'
WriteUtf8NoBomLf (Join-Path $engineDir "run_demo_dff_rising.ts") ((@($r) -join "`n") + "`n")

$st = @()
$st += 'param([Parameter(Mandatory=$true)][string]$RepoRoot)'
$st += '$ErrorActionPreference="Stop"'
$st += 'Set-StrictMode -Version Latest'
$st += ''
$st += 'function MustExist([string]$p){ if(-not (Test-Path -LiteralPath $p -PathType Leaf)){ throw ("MISSING: " + $p) } }'
$st += 'function MustMatch([string]$name,[string]$txt,[string]$pattern){ if($txt -notmatch $pattern){ throw ("SELFTEST_FAIL: " + $name + " missing pattern: " + $pattern) } }'
$st += ''
$st += '$Demo = Join-Path $RepoRoot "app\src\acompute\demos\demo_dff_rising.ts"'
$st += '$Run  = Join-Path $RepoRoot "app\src\acompute\engine\run_demo_dff_rising.ts"'
$st += '$Tr   = Join-Path $RepoRoot "app\src\acompute\core\transition.ts"'
$st += 'MustExist $Demo'
$st += 'MustExist $Run'
$st += 'MustExist $Tr'
$st += ''
$st += '$demoTxt = [System.IO.File]::ReadAllText($Demo)'
$st += '$runTxt  = [System.IO.File]::ReadAllText($Run)'
$st += '$trTxt   = [System.IO.File]::ReadAllText($Tr)'
$st += ''
$st += 'MustMatch "demo has dff node" $demoTxt "kind:\s*""dff"""'
$st += 'MustMatch "demo has D input"  $demoTxt "id:\s*""D"".*kind:\s*""input"""'
$st += 'MustMatch "demo has Q dff"    $demoTxt "id:\s*""Q"".*kind:\s*""dff"""'
$st += 'MustMatch "demo edge D->Q"    $demoTxt "from:\s*""D"".*to:\s*""Q"".*inputIndex:\s*0"'
$st += ''
$st += '// Transition rising-edge rule must be present'
$st += 'MustMatch "transition rising edge" $trTxt "const\s+rising\s*=\s*\(prev\.clk\s*===\s*0\)\s*&&\s*\(nextClk\s*===\s*1\)"'
$st += 'MustMatch "transition updates seq for dff" $trTxt "if\s*\(n\.kind\s*!==\s*""dff""\)\s*continue"'
$st += 'MustMatch "transition writes nextSeq" $trTxt "nextSeq\[n\.id\]\s*=\s*d"'
$st += ''
$st += '// Demo runner should assert the semantic expectations (even if not executed here)'
$st += 'MustMatch "runner expects no capture when clk low" $runTxt "no rising edge"'
$st += 'MustMatch "runner expects capture on rising edge"   $runTxt "rising edge"'
$st += ''
$st += 'Write-Host "SELFTEST_MVP2_DFF_OK: rising-edge rule present + demo wired" -ForegroundColor Green'
WriteUtf8NoBomLf (Join-Path $scriptsDir "_selftest_mvp2_dff_gate_v1.ps1") ((@($st) -join "`n") + "`n")

$ledgerPath = Join-Path $RepoRoot "WBS\PROGRESS_LEDGER_v1.md"
if(-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)){
  EnsureDir (Split-Path -Parent $ledgerPath)
  WriteUtf8NoBomLf $ledgerPath ("# Progress Ledger v1`n`n")
}
$line = "- 2026-02-19: MVP2 gate added (DFF rising-edge demo + rule-presence selftest)."
$existing = [System.IO.File]::ReadAllText($ledgerPath)
if($existing -notmatch [regex]::Escape($line)){
  $out = ($existing -replace "`r`n","`n") -replace "`r","`n"
  if(-not $out.EndsWith("`n")){ $out += "`n" }
  $out += $line + "`n"
  WriteUtf8NoBomLf $ledgerPath $out
}

Write-Host "APPLY_OK: MVP2 DFF gate written" -ForegroundColor Green
