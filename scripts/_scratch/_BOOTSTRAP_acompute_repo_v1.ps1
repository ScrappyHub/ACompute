param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){ if([string]::IsNullOrWhiteSpace($p)){ throw "EnsureDir: empty path" } if(-not (Test-Path -LiteralPath $p -PathType Container)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBomLf([string]$Path,[string]$Text){
  $enc = New-Object System.Text.UTF8Encoding($false)
  $t = $Text -replace "`r`n","`n"
  $t = $t -replace "`r","`n"
  if(-not $t.EndsWith("`n")){ $t += "`n" }
  EnsureDir (Split-Path -Parent $Path)
  [System.IO.File]::WriteAllText($Path,$t,$enc)
}

# --- Root dirs ---
EnsureDir $RepoRoot
EnsureDir (Join-Path $RepoRoot "SPEC")
EnsureDir (Join-Path $RepoRoot "WBS")
EnsureDir (Join-Path $RepoRoot "proofs\keys")
EnsureDir (Join-Path $RepoRoot "proofs\trust")
EnsureDir (Join-Path $RepoRoot "proofs\receipts")
EnsureDir (Join-Path $RepoRoot "scripts")
EnsureDir (Join-Path $RepoRoot "scripts\_scratch")
EnsureDir (Join-Path $RepoRoot "app\src\acompute\core")
EnsureDir (Join-Path $RepoRoot "app\src\acompute\graph")
EnsureDir (Join-Path $RepoRoot "app\src\acompute\engine")
EnsureDir (Join-Path $RepoRoot "app\src\acompute\demos")
EnsureDir (Join-Path $RepoRoot "app\src\ui\panels")
EnsureDir (Join-Path $RepoRoot "app\src\ui\render")

# --- README ---
$readme = @()
$readme += "# ACompute"
$readme += ""
$readme += "ACompute is a deterministic computation visualization instrument: transistor → gate → state → datapath → control → cache/memory → instruction execution."
$readme += ""
$readme += "Canonical goal: make every transition explainable. No hidden time. No hidden state."
WriteUtf8NoBomLf (Join-Path $RepoRoot "README.md") ((@($readme) -join "`n") + "`n")

# --- SPEC ---
$spec = @()
$spec += "# ACompute Spec v1 (Foundation)"
$spec += ""
$spec += "ACompute teaches computation as deterministic state transitions across abstraction levels."
$spec += ""
$spec += "Core equation:"
$spec += ""
$spec += "State(t+1) = δ(State(t), Inputs(t), Control(t), Graph)"
WriteUtf8NoBomLf (Join-Path $RepoRoot "SPEC\ACompute_SPEC_v1.md") ((@($spec) -join "`n") + "`n")

# --- WBS + Ledger ---
$wbs = @()
$wbs += "# WBS v1"
$wbs += ""
$wbs += "- MVP1: gates + CMOS inverter + clock + DFF (demo)"
$wbs += "- MVP2: regfile + ALU + mux routing + micro-op stepping"
$wbs += "- MVP3: LSU + L1 tags + hit/miss + latency"
$wbs += "- MVP4: tiny ISA + fetch/decode/execute/mem/writeback"
WriteUtf8NoBomLf (Join-Path $RepoRoot "WBS\WBS_v1.md") ((@($wbs) -join "`n") + "`n")
$ledger = @()
$ledger += "# Progress Ledger v1"
$ledger += ""
$ledger += "- 2026-02-19: Canonical spec locked. Repo skeleton initialized."
WriteUtf8NoBomLf (Join-Path $RepoRoot "WBS\PROGRESS_LEDGER_v1.md") ((@($ledger) -join "`n") + "`n")

# --- NeverLost minimal placeholders (stub) ---
$tb = '{' + "`n" + '  \"version\": 1,' + "`n" + '  \"allowed_namespaces\": [\"acompute\"],' + "`n" + '  \"principals\": []' + "`n" + '}'
WriteUtf8NoBomLf (Join-Path $RepoRoot "proofs\trust\trust_bundle.json") $tb
WriteUtf8NoBomLf (Join-Path $RepoRoot "proofs\trust\allowed_signers") "# allowed_signers (stub)`n"
WriteUtf8NoBomLf (Join-Path $RepoRoot "proofs\receipts\neverlost.ndjson") ""

# --- scripts ---
WriteUtf8NoBomLf (Join-Path $RepoRoot "scripts\_lib_neverlost_v1.ps1") "# STUB: replace with canonical NeverLost lib when ready.`n"

# --- core/types.ts ---
$types = @()
$types += "export type Bit = 0 | 1;"
$types += "export type NodeId = string;"
$types += "export type EdgeId = string;"
$types += ""
$types += "export type NodeKind = \\"input\\" | \\"gate\\" | \\"dff\\" | \\"probe\\";"
$types += "export type GateOp = \\"NOT\\" | \\"AND\\" | \\"OR\\" | \\"XOR\\" | \\"NAND\\" | \\"NOR\\";"
WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\acompute\core\types.ts") ((@($types) -join "`n") + "`n")

# --- graph/graph.ts ---
$graph = @()
$graph += "import type { Bit, NodeId, EdgeId, NodeKind, GateOp } from \\"../core/types\\";"
$graph += ""
$graph += "export type Node = {"
$graph += "  id: NodeId;"
$graph += "  kind: NodeKind;"
$graph += "  label: string;"
$graph += "  op?: GateOp; // for kind=gate"
$graph += "  x: number; y: number; // layout coords for UI"
$graph += "};"
$graph += ""
$graph += "export type Edge = { id: EdgeId; from: NodeId; to: NodeId; inputIndex: number };"
$graph += ""
$graph += "export type Graph = { nodes: Node[]; edges: Edge[] };"
WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\acompute\graph\graph.ts") ((@($graph) -join "`n") + "`n")

# --- core/state.ts ---
$state = @()
$state += "import type { Bit, NodeId } from \\"./types\\";"
$state += ""
$state += "export type NodeState = { out: Bit };"
$state += "export type SystemState = {"
$state += "  // stable, deterministic map: NodeId -> NodeState"
$state += "  nodes: Record<NodeId, NodeState>;"
$state += "  // sequential storage (e.g., DFF Q)"
$state += "  seq: Record<NodeId, Bit>;"
$state += "  clk: Bit; prevClk: Bit;"
$state += "};"
$state += ""
$state += "export function initialState(): SystemState {"
$state += "  return { nodes: {}, seq: {}, clk: 0, prevClk: 0 };"
$state += "}"
WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\acompute\core\state.ts") ((@($state) -join "`n") + "`n")

# --- core/transition.ts ---
$tr = @()
$tr += "import type { Bit, GateOp, NodeId } from \\"./types\\";"
$tr += "import type { Graph, Node } from \\"../graph/graph\\";"
$tr += "import type { SystemState } from \\"./state\\";"
$tr += ""
$tr += "export type Inputs = Record<string, Bit>;"
$tr += ""
$tr += "function not(a: Bit): Bit { return a === 1 ? 0 : 1; }"
$tr += "function and(a: Bit,b: Bit): Bit { return (a & b) as Bit; }"
$tr += "function or(a: Bit,b: Bit): Bit { return (a | b) as Bit; }"
$tr += "function xor(a: Bit,b: Bit): Bit { return ((a ^ b) & 1) as Bit; }"

# --- demos/demo_not.ts ---
$dnot = @()
$dnot += "import type { Graph } from \\"../graph/graph\\";"
$dnot += ""
$dnot += "export const demoNot: Graph = {"
$dnot += "  nodes: ["
$dnot += "    { id: \\"A\\", kind: \\"input\\", label: \\"A\\", x: 40, y: 80 },"
$dnot += "    { id: \\"Y\\", kind: \\"gate\\", label: \\"NOT\\", op: \\"NOT\\", x: 220, y: 80 }"
$dnot += "  ],"
$dnot += "  edges: ["
$dnot += "    { id: \\"e1\\", from: \\"A\\", to: \\"Y\\", inputIndex: 0 }"
$dnot += "  ]"
$dnot += "};"
WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\acompute\demos\demo_not.ts") ((@($dnot) -join "`n") + "`n")

# --- minimal app entry (stubs) ---
WriteUtf8NoBomLf (Join-Path $RepoRoot "app\package.json") "{`n  \"name\": \"acompute-app\",`n  \"private\": true`n}`n"
WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\main.tsx") "console.log(\"ACompute skeleton ready\");`n"

# --- selftest script ---
$st = @()
$st += "param([Parameter(Mandatory=$true)][string]$RepoRoot)"
$st += "$ErrorActionPreference=\\"Stop\\""
$st += "Set-StrictMode -Version Latest"
$st += ""
$st += "Write-Host (\\"SELFTEST: repo initialized at \\" + $RepoRoot) -ForegroundColor Green"
WriteUtf8NoBomLf (Join-Path $RepoRoot "scripts\_selftest_core_v1.ps1") ((@($st) -join "`n") + "`n")

Write-Host ("BOOTSTRAP_OK: " + $RepoRoot) -ForegroundColor Green
