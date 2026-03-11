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

$engineDir = Join-Path $RepoRoot "app\src\acompute\engine"
$coreDir   = Join-Path $RepoRoot "app\src\acompute\core"
$demoDir   = Join-Path $RepoRoot "app\src\acompute\demos"
$scriptsDir= Join-Path $RepoRoot "scripts"
EnsureDir $engineDir
EnsureDir $coreDir
EnsureDir $demoDir
EnsureDir $scriptsDir

$eval = @()
$eval += 'import type { Bit, GateOp, NodeId } from "../core/types";'
$eval += 'import type { Graph } from "../graph/graph";'
$eval += 'import type { SystemState } from "../core/state";'
$eval += ''
$eval += 'export type Inputs = Record<string, Bit>;'
$eval += 'export type Outs = Record<NodeId, Bit>;'
$eval += ''
$eval += 'function not(a: Bit): Bit { return a === 1 ? 0 : 1; }'
$eval += 'function and(a: Bit,b: Bit): Bit { return (a & b) as Bit; }'
$eval += 'function or(a: Bit,b: Bit): Bit { return (a | b) as Bit; }'
$eval += 'function xor(a: Bit,b: Bit): Bit { return ((a ^ b) & 1) as Bit; }'
$eval += ''
$eval += 'function evalGate(op: GateOp, ins: Bit[]): Bit {'
$eval += '  const a: Bit = (ins[0] ?? 0) as Bit;'
$eval += '  const b: Bit = (ins[1] ?? 0) as Bit;'
$eval += '  switch(op) {'
$eval += '    case "NOT":  return not(a);'
$eval += '    case "AND":  return and(a,b);'
$eval += '    case "OR":   return or(a,b);'
$eval += '    case "XOR":  return xor(a,b);'
$eval += '    case "NAND": return not(and(a,b));'
$eval += '    case "NOR":  return not(or(a,b));'
$eval += '    default:     return 0;'
$eval += '  }'
$eval += '}'
$eval += ''
$eval += 'function nodeInputs(nodeId: NodeId, g: Graph, outs: Outs): Bit[] {'
$eval += '  const es = g.edges'
$eval += '    .filter(e => e.to === nodeId)'
$eval += '    .slice()'
$eval += '    .sort((x,y)=>x.inputIndex - y.inputIndex);'
$eval += '  return es.map(e => (outs[e.from] ?? 0) as Bit);'
$eval += '}'
$eval += ''
$eval += 'export function evalGraph(prev: SystemState, g: Graph, inputs: Inputs): Outs {'
$eval += '  // Deterministic: stable evaluation order by node id.'
$eval += '  const outs: Outs = {};'
$eval += '  const nodes = g.nodes.slice().sort((a,b)=>a.id.localeCompare(b.id));'
$eval += '  for (const n of nodes) {'
$eval += '    if (n.kind === "input") {'
$eval += '      outs[n.id] = (inputs[n.id] ?? 0) as Bit;'
$eval += '      continue;'
$eval += '    }'
$eval += '    if (n.kind === "dff") {'
$eval += '      // DFF output is stored Q from previous sequential state.'
$eval += '      outs[n.id] = (prev.seq[n.id] ?? 0) as Bit;'
$eval += '      continue;'
$eval += '    }'
$eval += '    const ins = nodeInputs(n.id, g, outs);'
$eval += '    if (n.kind === "gate") {'
$eval += '      outs[n.id] = evalGate((n.op ?? "NOT") as GateOp, ins);'
$eval += '      continue;'
$eval += '    }'
$eval += '    // probe or unknown: pass-through first input'
$eval += '    outs[n.id] = (ins[0] ?? 0) as Bit;'
$eval += '  }'
$eval += '  return outs;'
$eval += '}'
WriteUtf8NoBomLf (Join-Path $engineDir "eval.ts") ((@($eval) -join "`n") + "`n")

$run = @()
$run += 'import { initialState } from "../core/state";'
$run += 'import { demoNot } from "../demos/demo_not";'
$run += 'import { evalGraph } from "./eval";'
$run += 'import type { Bit } from "../core/types";'
$run += ''
$run += 'function expect(name: string, got: Bit, want: Bit) {'
$run += '  if (got !== want) {'
$run += '    throw new Error(`ASSERT_FAIL ${name}: got=${got} want=${want}`);'
$run += '  }'
$run += '}'
$run += ''
$run += 'export function runDemoNot(): void {'
$run += '  const prev = initialState();'
$run += '  const out0 = evalGraph(prev, demoNot, { A: 0 });'
$run += '  const out1 = evalGraph(prev, demoNot, { A: 1 });'
$run += '  console.log("DEMO_NOT A=0 => Y=", out0["Y"]);'
$run += '  console.log("DEMO_NOT A=1 => Y=", out1["Y"]);'
$run += '  expect("NOT(0)", (out0["Y"] ?? 0) as Bit, 1);'
$run += '  expect("NOT(1)", (out1["Y"] ?? 0) as Bit, 0);'
$run += '}'
$run += ''
$run += '// Allow direct execution in future bundlers; harmless if imported.'
$run += 'try {'
$run += '  // eslint-disable-next-line @typescript-eslint/no-explicit-any'
$run += '  const g: any = (globalThis as any);'
$run += '  if (g && g.__ACOMPUTE_AUTO_RUN__ === true) { runDemoNot(); }'
$run += '} catch { /* ignore */ }'
WriteUtf8NoBomLf (Join-Path $engineDir "run_demo_not.ts") ((@($run) -join "`n") + "`n")

$tr = @()
$tr += 'import type { Bit, NodeId } from "./types";'
$tr += 'import type { Graph } from "../graph/graph";'
$tr += 'import type { SystemState } from "./state";'
$tr += 'import type { Inputs } from "../engine/eval";'
$tr += 'import { evalGraph } from "../engine/eval";'
$tr += ''
$tr += 'export function transition(prev: SystemState, g: Graph, inputs: Inputs, nextClk: Bit): SystemState {'
$tr += '  // 1) Combinational evaluate from prev sequential state + current inputs.'
$tr += '  const outs = evalGraph(prev, g, inputs);'
$tr += ''
$tr += '  // 2) Sequential update on rising edge: DFF captures its first input.'
$tr += '  const rising = (prev.clk === 0) && (nextClk === 1);'
$tr += '  const nextSeq: Record<NodeId, Bit> = { ...prev.seq };'
$tr += '  if (rising) {'
$tr += '    const nodes = g.nodes.slice().sort((a,b)=>a.id.localeCompare(b.id));'
$tr += '    for (const n of nodes) {'
$tr += '      if (n.kind !== "dff") continue;'
$tr += '      const es = g.edges.filter(e => e.to === n.id).slice().sort((x,y)=>x.inputIndex-y.inputIndex);'
$tr += '      const d: Bit = (es.length > 0 ? (outs[es[0].from] ?? 0) : 0) as Bit;'
$tr += '      nextSeq[n.id] = d;'
$tr += '    }'
$tr += '  }'
$tr += ''
$tr += '  // 3) Normalize node outputs into deterministic map.'
$tr += '  const nextNodes: Record<NodeId, { out: Bit }> = {};'
$tr += '  for (const k of Object.keys(outs).sort()) { nextNodes[k] = { out: outs[k] as Bit }; }'
$tr += ''
$tr += '  return { nodes: nextNodes, seq: nextSeq, clk: nextClk, prevClk: prev.clk };'
$tr += '}'
WriteUtf8NoBomLf (Join-Path $coreDir "transition.ts") ((@($tr) -join "`n") + "`n")

$st = @()
$st += 'param([Parameter(Mandatory=$true)][string]$RepoRoot)'
$st += '$ErrorActionPreference="Stop"'
$st += 'Set-StrictMode -Version Latest'
$st += ''
$st += 'function MustExist([string]$p){ if(-not (Test-Path -LiteralPath $p -PathType Leaf)){ throw ("MISSING: " + $p) } }'
$st += '$E = Join-Path $RepoRoot "app\src\acompute\engine\eval.ts"'
$st += '$R = Join-Path $RepoRoot "app\src\acompute\engine\run_demo_not.ts"'
$st += '$D = Join-Path $RepoRoot "app\src\acompute\demos\demo_not.ts"'
$st += '$T = Join-Path $RepoRoot "app\src\acompute\core\transition.ts"'
$st += 'MustExist $E'
$st += 'MustExist $R'
$st += 'MustExist $D'
$st += 'MustExist $T'
$st += ''
$st += '$eTxt = [System.IO.File]::ReadAllText($E)'
$st += '$rTxt = [System.IO.File]::ReadAllText($R)'
$st += 'if($eTxt -notmatch "export function evalGraph"){ throw "SELFTEST_FAIL: evalGraph export missing" }'
$st += 'if($rTxt -notmatch "runDemoNot"){ throw "SELFTEST_FAIL: runDemoNot missing" }'
$st += 'Write-Host ("SELFTEST_MVP1_OK: files present + exports detected") -ForegroundColor Green'
WriteUtf8NoBomLf (Join-Path $scriptsDir "_selftest_mvp1_not_demo_v1.ps1") ((@($st) -join "`n") + "`n")

$ledgerPath = Join-Path $RepoRoot "WBS\PROGRESS_LEDGER_v1.md"
if(-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)){
  EnsureDir (Split-Path -Parent $ledgerPath)
  WriteUtf8NoBomLf $ledgerPath ("# Progress Ledger v1`n`n")
}
$line = "- 2026-02-19: MVP1 engine added (evalGraph + NOT demo runner + transition wiring)."
$existing = [System.IO.File]::ReadAllText($ledgerPath)
if($existing -notmatch [regex]::Escape($line)){
  $out = ($existing -replace "`r`n","`n") -replace "`r","`n"
  if(-not $out.EndsWith("`n")){ $out += "`n" }
  $out += $line + "`n"
  WriteUtf8NoBomLf $ledgerPath $out
}

Write-Host "APPLY_OK: MVP1 evaluator + demo runner + selftest written" -ForegroundColor Green
