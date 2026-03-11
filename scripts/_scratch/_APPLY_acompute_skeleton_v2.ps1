param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){ if([string]::IsNullOrWhiteSpace($p)){ throw "EnsureDir: empty path" } if(-not (Test-Path -LiteralPath $p -PathType Container)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBomLf([string]$Path,[string]$Text){
  if([string]::IsNullOrWhiteSpace($Path)){ throw "WriteUtf8NoBomLf: empty path" }
  $enc = New-Object System.Text.UTF8Encoding($false)
  $t = $Text -replace "`r`n","`n"
  $t = $t -replace "`r","`n"
  if(-not $t.EndsWith("`n")){ $t += "`n" }
  $dir = Split-Path -Parent $Path
  if([string]::IsNullOrWhiteSpace($dir)){ throw ("WriteUtf8NoBomLf: parent dir empty for path: " + $Path) }
  EnsureDir $dir
  [System.IO.File]::WriteAllText($Path,$t,$enc)
}

# --- dirs ---
EnsureDir $RepoRoot
EnsureDir (Join-Path $RepoRoot "SPEC")
EnsureDir (Join-Path $RepoRoot "WBS")
EnsureDir (Join-Path $RepoRoot "proofs\keys")
EnsureDir (Join-Path $RepoRoot "proofs\trust")
EnsureDir (Join-Path $RepoRoot "proofs\receipts")
EnsureDir (Join-Path $RepoRoot "scripts")
EnsureDir (Join-Path $RepoRoot "scripts\_scratch")
EnsureDir (Join-Path $RepoRoot "app")
EnsureDir (Join-Path $RepoRoot "app\src")
EnsureDir (Join-Path $RepoRoot "app\src\acompute\core")
EnsureDir (Join-Path $RepoRoot "app\src\acompute\graph")
EnsureDir (Join-Path $RepoRoot "app\src\acompute\engine")
EnsureDir (Join-Path $RepoRoot "app\src\acompute\demos")
EnsureDir (Join-Path $RepoRoot "app\src\ui\panels")
EnsureDir (Join-Path $RepoRoot "app\src\ui\render")

# --- README / SPEC / WBS ---
$readme=@()
$readme += "# ACompute"
$readme += ""
$readme += "ACompute is a deterministic computation visualization instrument: transistor -> gate -> state -> datapath -> control -> cache/memory -> instruction execution."
$readme += ""
$readme += "Canonical goal: make every transition explainable. No hidden time. No hidden state."
WriteUtf8NoBomLf (Join-Path $RepoRoot "README.md") ((@($readme) -join "`n") + "`n")

$spec=@()
$spec += "# ACompute Spec v1 (Foundation)"
$spec += ""
$spec += "ACompute teaches computation as deterministic state transitions across abstraction levels."
$spec += ""
$spec += "Core equation:"
$spec += ""
$spec += "State(t+1) = delta(State(t), Inputs(t), Control(t), Graph)"
WriteUtf8NoBomLf (Join-Path $RepoRoot "SPEC\ACompute_SPEC_v1.md") ((@($spec) -join "`n") + "`n")

$wbs=@()
$wbs += "# WBS v1"
$wbs += ""
$wbs += "- MVP1: gates + CMOS inverter + clock + DFF (demo)"
$wbs += "- MVP2: regfile + ALU + mux routing + micro-op stepping"
$wbs += "- MVP3: LSU + L1 tags + hit/miss + latency"
$wbs += "- MVP4: tiny ISA + fetch/decode/execute/mem/writeback"
WriteUtf8NoBomLf (Join-Path $RepoRoot "WBS\WBS_v1.md") ((@($wbs) -join "`n") + "`n")

$ledger=@()
$ledger += "# Progress Ledger v1"
$ledger += ""
$ledger += "- 2026-02-19: Canonical spec locked. Repo skeleton initialized (apply_skeleton_v2)."
WriteUtf8NoBomLf (Join-Path $RepoRoot "WBS\PROGRESS_LEDGER_v1.md") ((@($ledger) -join "`n") + "`n")

# --- NeverLost minimal placeholders (stub) ---
$tb = "{`n  ""version"": 1,`n  ""allowed_namespaces"": [""acompute""],`n  ""principals"": []`n}"
WriteUtf8NoBomLf (Join-Path $RepoRoot "proofs\trust\trust_bundle.json") $tb
WriteUtf8NoBomLf (Join-Path $RepoRoot "proofs\trust\allowed_signers") "# allowed_signers (stub)`n"
WriteUtf8NoBomLf (Join-Path $RepoRoot "proofs\receipts\neverlost.ndjson") ""
WriteUtf8NoBomLf (Join-Path $RepoRoot "scripts\_lib_neverlost_v1.ps1") "# STUB: replace with canonical NeverLost lib when ready.`n"

# --- app/package.json + main.tsx ---
WriteUtf8NoBomLf (Join-Path $RepoRoot "app\package.json") "{`n  ""name"": ""acompute-app"",`n  ""private"": true`n}`n"
WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\main.tsx") "console.log(""ACompute skeleton ready"");`n"

# --- TypeScript: core/types.ts (use single-quoted PS strings; TS keeps double quotes) ---
$types=@()
$types += 'export type Bit = 0 | 1;'
$types += 'export type NodeId = string;'
$types += 'export type EdgeId = string;'
$types += ''
$types += 'export type NodeKind = "input" | "gate" | "dff" | "probe";'
$types += 'export type GateOp = "NOT" | "AND" | "OR" | "XOR" | "NAND" | "NOR";'
WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\acompute\core\types.ts") ((@($types) -join "`n") + "`n")

# --- TypeScript: graph/graph.ts ---
$graph=@()
$graph += 'import type { NodeId, EdgeId, NodeKind, GateOp } from "../core/types";'
$graph += ''
$graph += 'export type Node = {'
$graph += '  id: NodeId;'
$graph += '  kind: NodeKind;'
$graph += '  label: string;'
$graph += '  op?: GateOp;'
$graph += '  x: number; y: number;'
$graph += '};'
$graph += ''
$graph += 'export type Edge = { id: EdgeId; from: NodeId; to: NodeId; inputIndex: number };'
$graph += 'export type Graph = { nodes: Node[]; edges: Edge[] };'
WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\acompute\graph\graph.ts") ((@($graph) -join "`n") + "`n")

# --- TypeScript: core/state.ts ---
$state=@()
$state += 'import type { Bit, NodeId } from "./types";'
$state += ''
$state += 'export type NodeState = { out: Bit };'
$state += 'export type SystemState = {'
$state += '  nodes: Record<NodeId, NodeState>;'
$state += '  seq: Record<NodeId, Bit>;'
$state += '  clk: Bit;'
$state += '  prevClk: Bit;'
$state += '};'
$state += ''
$state += 'export function initialState(): SystemState {'
$state += '  return { nodes: {}, seq: {}, clk: 0, prevClk: 0 };'
$state += '}'
WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\acompute\core\state.ts") ((@($state) -join "`n") + "`n")

# --- TypeScript: core/transition.ts ---
$tr=@()
$tr += 'import type { Bit, GateOp, NodeId } from "./types";'
$tr += 'import type { Graph } from "../graph/graph";'
$tr += 'import type { SystemState } from "./state";'
$tr += ''
$tr += 'export type Inputs = Record<string, Bit>;'
$tr += ''
$tr += 'function not(a: Bit): Bit { return a === 1 ? 0 : 1; }'
$tr += 'function and(a: Bit,b: Bit): Bit { return (a & b) as Bit; }'
$tr += 'function or(a: Bit,b: Bit): Bit { return (a | b) as Bit; }'
$tr += 'function xor(a: Bit,b: Bit): Bit { return ((a ^ b) & 1) as Bit; }'
$tr += ''
$tr += 'function evalGate(op: GateOp, ins: Bit[]): Bit {'
$tr += '  const a: Bit = (ins[0] ?? 0) as Bit;'
$tr += '  const b: Bit = (ins[1] ?? 0) as Bit;'
$tr += '  switch(op) {'
$tr += '    case "NOT":  return not(a);'
$tr += '    case "AND":  return and(a,b);'
$tr += '    case "OR":   return or(a,b);'
$tr += '    case "XOR":  return xor(a,b);'
$tr += '    case "NAND": return not(and(a,b));'
$tr += '    case "NOR":  return not(or(a,b));'
$tr += '    default:     return 0;'
$tr += '  }'
$tr += '}'
$tr += ''
$tr += 'function nodeInputs(nodeId: NodeId, g: Graph, outs: Record<NodeId, Bit>): Bit[] {'
$tr += '  const es = g.edges.filter(e => e.to === nodeId).sort((x,y)=>x.inputIndex-y.inputIndex);'
$tr += '  return es.map(e => (outs[e.from] ?? 0) as Bit);'
$tr += '}'
$tr += ''
$tr += 'export function transition(prev: SystemState, g: Graph, inputs: Inputs): SystemState {'
$tr += '  const outs: Record<NodeId, Bit> = {};'
$tr += '  const nodes = [...g.nodes].sort((a,b)=>a.id.localeCompare(b.id));'
$tr += '  for (const n of nodes) {'
$tr += '    if (n.kind === "input") {'
$tr += '      outs[n.id] = (inputs[n.id] ?? 0) as Bit;'
$tr += '    } else if (n.kind === "dff") {'
$tr += '      outs[n.id] = (prev.seq[n.id] ?? 0) as Bit;'
$tr += '    } else if (n.kind === "gate") {'
$tr += '      const ins = nodeInputs(n.id, g, outs);'
$tr += '      outs[n.id] = evalGate((n.op ?? "NOT") as GateOp, ins);'
$tr += '    } else {'
$tr += '      const ins = nodeInputs(n.id, g, outs);'
$tr += '      outs[n.id] = (ins[0] ?? 0) as Bit;'
$tr += '    }'
$tr += '  }'
$tr += ''
$tr += '  const rising = prev.prevClk === 0 && prev.clk === 1;'
$tr += '  const nextSeq: Record<NodeId, Bit> = { ...prev.seq };'
$tr += '  if (rising) {'
$tr += '    for (const n of nodes) {'
$tr += '      if (n.kind === "dff") {'
$tr += '        const ins = nodeInputs(n.id, g, outs);'
$tr += '        nextSeq[n.id] = (ins[0] ?? 0) as Bit;'
$tr += '      }'
$tr += '    }'
$tr += '  }'
$tr += ''
$tr += '  const nextNodes: Record<NodeId, { out: Bit }> = {};'
$tr += '  for (const k of Object.keys(outs).sort()) { nextNodes[k] = { out: outs[k] as Bit }; }'
$tr += '  return { nodes: nextNodes, seq: nextSeq, clk: prev.clk, prevClk: prev.clk };'
$tr += '}'
WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\acompute\core\transition.ts") ((@($tr) -join "`n") + "`n")

# --- TypeScript: demos/demo_not.ts ---
$dnot=@()
$dnot += 'import type { Graph } from "../graph/graph";'
$dnot += ''
$dnot += 'export const demoNot: Graph = {'
$dnot += '  nodes: ['
$dnot += '    { id: "A", kind: "input", label: "A", x: 40, y: 80 },'
$dnot += '    { id: "Y", kind: "gate", label: "NOT", op: "NOT", x: 220, y: 80 }'
$dnot += '  ],'
$dnot += '  edges: ['
$dnot += '    { id: "e1", from: "A", to: "Y", inputIndex: 0 }'
$dnot += '  ]'
$dnot += '};'
WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\acompute\demos\demo_not.ts") ((@($dnot) -join "`n") + "`n")

# --- selftest ---
$st=@()
$st += 'param([Parameter(Mandatory=$true)][string]$RepoRoot)'
$st += '$ErrorActionPreference="Stop"'
$st += 'Set-StrictMode -Version Latest'
$st += ''
$st += '$need = @(''README.md'',''SPEC\ACompute_SPEC_v1.md'',''WBS\WBS_v1.md'',''app\src\acompute\core\types.ts'',''app\src\acompute\core\transition.ts'')'
$st += 'foreach($r in $need){ $p = Join-Path $RepoRoot $r; if(-not (Test-Path -LiteralPath $p -PathType Leaf)){ throw ("SELFTEST_MISSING: " + $r) } }'
$st += 'Write-Host ("SELFTEST_OK: " + $RepoRoot) -ForegroundColor Green'
WriteUtf8NoBomLf (Join-Path $RepoRoot "scripts\_selftest_core_v1.ps1") ((@($st) -join "`n") + "`n")

Write-Host ("APPLY_OK: ACompute skeleton written") -ForegroundColor Green
