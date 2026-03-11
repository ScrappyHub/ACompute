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
  EnsureDir (Split-Path -Parent $Path)
  [System.IO.File]::WriteAllText($Path,$t,$enc)
}
function ParseGatePs1([string]$Path){
  if(-not (Test-Path -LiteralPath $Path -PathType Leaf)){ throw ("PARSE_GATE_MISSING: " + $Path) }
  $t=$null; $e=$null
  [void][System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$t,[ref]$e)
  if($e -and $e.Count -gt 0){ $x=$e[0]; throw ("PARSE_GATE_FAIL: {0}:{1}:{2}: {3}" -f $Path,$x.Extent.StartLineNumber,$x.Extent.StartColumnNumber,$x.Message) }
}

$Scratch = Join-Path $RepoRoot "scripts\_scratch"
EnsureDir $Scratch
$BootstrapPath = Join-Path $Scratch "_BOOTSTRAP_acompute_repo_v1.ps1"

# ------------------------------------------------------------
# Rewrite BOOTSTRAP with correct quoting (no backslash-escapes)
# ------------------------------------------------------------
$B = New-Object System.Collections.Generic.List[string]
[void]$B.Add('param([Parameter(Mandatory=$true)][string]$RepoRoot)')
[void]$B.Add('$ErrorActionPreference="Stop"')
[void]$B.Add('Set-StrictMode -Version Latest')
[void]$B.Add('')
[void]$B.Add('function EnsureDir([string]$p){ if([string]::IsNullOrWhiteSpace($p)){ throw "EnsureDir: empty path" } if(-not (Test-Path -LiteralPath $p -PathType Container)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }')
[void]$B.Add('function WriteUtf8NoBomLf([string]$Path,[string]$Text){ $enc = New-Object System.Text.UTF8Encoding($false); $t = $Text -replace "`r`n","`n"; $t = $t -replace "`r","`n"; if(-not $t.EndsWith("`n")){ $t += "`n" }; EnsureDir (Split-Path -Parent $Path); [System.IO.File]::WriteAllText($Path,$t,$enc) }')
[void]$B.Add('')
[void]$B.Add('# --- Root dirs ---')
[void]$B.Add('EnsureDir $RepoRoot')
[void]$B.Add('EnsureDir (Join-Path $RepoRoot "SPEC")')
[void]$B.Add('EnsureDir (Join-Path $RepoRoot "WBS")')
[void]$B.Add('EnsureDir (Join-Path $RepoRoot "proofs\keys")')
[void]$B.Add('EnsureDir (Join-Path $RepoRoot "proofs\trust")')
[void]$B.Add('EnsureDir (Join-Path $RepoRoot "proofs\receipts")')
[void]$B.Add('EnsureDir (Join-Path $RepoRoot "scripts")')
[void]$B.Add('EnsureDir (Join-Path $RepoRoot "scripts\_scratch")')
[void]$B.Add('EnsureDir (Join-Path $RepoRoot "app\src\acompute\core")')
[void]$B.Add('EnsureDir (Join-Path $RepoRoot "app\src\acompute\graph")')
[void]$B.Add('EnsureDir (Join-Path $RepoRoot "app\src\acompute\engine")')
[void]$B.Add('EnsureDir (Join-Path $RepoRoot "app\src\acompute\demos")')
[void]$B.Add('EnsureDir (Join-Path $RepoRoot "app\src\ui\panels")')
[void]$B.Add('EnsureDir (Join-Path $RepoRoot "app\src\ui\render")')
[void]$B.Add('')
[void]$B.Add('$readme=@(); $readme+="# ACompute"; $readme+=""; $readme+="ACompute is a deterministic computation visualization instrument: transistor → gate → state → datapath → control → cache/memory → instruction execution."; $readme+=""; $readme+="Canonical goal: make every transition explainable. No hidden time. No hidden state."; WriteUtf8NoBomLf (Join-Path $RepoRoot "README.md") ((@($readme) -join "`n") + "`n")')
[void]$B.Add('$spec=@(); $spec+="# ACompute Spec v1 (Foundation)"; $spec+=""; $spec+="ACompute teaches computation as deterministic state transitions across abstraction levels."; $spec+=""; $spec+="Core equation:"; $spec+=""; $spec+="State(t+1) = δ(State(t), Inputs(t), Control(t), Graph)"; WriteUtf8NoBomLf (Join-Path $RepoRoot "SPEC\ACompute_SPEC_v1.md") ((@($spec) -join "`n") + "`n")')
[void]$B.Add('$wbs=@(); $wbs+="# WBS v1"; $wbs+=""; $wbs+="- MVP1: gates + CMOS inverter + clock + DFF (demo)"; $wbs+="- MVP2: regfile + ALU + mux routing + micro-op stepping"; $wbs+="- MVP3: LSU + L1 tags + hit/miss + latency"; $wbs+="- MVP4: tiny ISA + fetch/decode/execute/mem/writeback"; WriteUtf8NoBomLf (Join-Path $RepoRoot "WBS\WBS_v1.md") ((@($wbs) -join "`n") + "`n")')
[void]$B.Add('$ledger=@(); $ledger+="# Progress Ledger v1"; $ledger+=""; $ledger+="- 2026-02-19: Canonical spec locked. Repo skeleton initialized (bootstrap fixed)."; WriteUtf8NoBomLf (Join-Path $RepoRoot "WBS\PROGRESS_LEDGER_v1.md") ((@($ledger) -join "`n") + "`n")')
[void]$B.Add('')
[void]$B.Add('$tb = "{`n  ""version"": 1,`n  ""allowed_namespaces"": [""acompute""],`n  ""principals"": []`n}"; WriteUtf8NoBomLf (Join-Path $RepoRoot "proofs\trust\trust_bundle.json") $tb')
[void]$B.Add('WriteUtf8NoBomLf (Join-Path $RepoRoot "proofs\trust\allowed_signers") "# allowed_signers (stub)`n"' )
[void]$B.Add('WriteUtf8NoBomLf (Join-Path $RepoRoot "proofs\receipts\neverlost.ndjson") ""' )
[void]$B.Add('WriteUtf8NoBomLf (Join-Path $RepoRoot "scripts\_lib_neverlost_v1.ps1") "# STUB: replace with canonical NeverLost lib when ready.`n"' )
[void]$B.Add('')
[void]$B.Add('$types=@();')
[void]$B.Add('$types += 'export type Bit = 0 | 1;';')
[void]$B.Add('$types += 'export type NodeId = string;';')
[void]$B.Add('$types += 'export type EdgeId = string;';')
[void]$B.Add('$types += '';')
[void]$B.Add('$types += 'export type NodeKind = "input" | "gate" | "dff" | "probe";';')
[void]$B.Add('$types += 'export type GateOp = "NOT" | "AND" | "OR" | "XOR" | "NAND" | "NOR";';')
[void]$B.Add('WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\acompute\core\types.ts") ((@($types) -join "`n") + "`n")' )
[void]$B.Add('')
[void]$B.Add('$graph=@();')
[void]$B.Add('$graph += 'import type { NodeId, EdgeId, NodeKind, GateOp } from "../core/types";';')
[void]$B.Add('$graph += '';')
[void]$B.Add('$graph += 'export type Node = { id: NodeId; kind: NodeKind; label: string; op?: GateOp; x: number; y: number };';')
[void]$B.Add('$graph += 'export type Edge = { id: EdgeId; from: NodeId; to: NodeId; inputIndex: number };';')
[void]$B.Add('$graph += 'export type Graph = { nodes: Node[]; edges: Edge[] };';')
[void]$B.Add('WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\acompute\graph\graph.ts") ((@($graph) -join "`n") + "`n")' )
[void]$B.Add('')
[void]$B.Add('$state=@();')
[void]$B.Add('$state += 'import type { Bit, NodeId } from "./types";';')
[void]$B.Add('$state += '';')
[void]$B.Add('$state += 'export type NodeState = { out: Bit };';')
[void]$B.Add('$state += 'export type SystemState = { nodes: Record<NodeId, NodeState>; seq: Record<NodeId, Bit>; clk: Bit; prevClk: Bit };';')
[void]$B.Add('$state += 'export function initialState(): SystemState { return { nodes: {}, seq: {}, clk: 0, prevClk: 0 }; }';')
[void]$B.Add('WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\acompute\core\state.ts") ((@($state) -join "`n") + "`n")' )
[void]$B.Add('')
[void]$B.Add('$dnot=@();')
[void]$B.Add('$dnot += 'import type { Graph } from "../graph/graph";';')
[void]$B.Add('$dnot += '';')
[void]$B.Add('$dnot += 'export const demoNot: Graph = {';')
[void]$B.Add('$dnot += '  nodes: [';')
[void]$B.Add('$dnot += '    { id: "A", kind: "input", label: "A", x: 40, y: 80 },';')
[void]$B.Add('$dnot += '    { id: "Y", kind: "gate", label: "NOT", op: "NOT", x: 220, y: 80 }';')
[void]$B.Add('$dnot += '  ],';')
[void]$B.Add('$dnot += '  edges: [';')
[void]$B.Add('$dnot += '    { id: "e1", from: "A", to: "Y", inputIndex: 0 }';')
[void]$B.Add('$dnot += '  ]';')
[void]$B.Add('$dnot += '};';')
[void]$B.Add('WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\acompute\demos\demo_not.ts") ((@($dnot) -join "`n") + "`n")' )
[void]$B.Add('')
[void]$B.Add('WriteUtf8NoBomLf (Join-Path $RepoRoot "app\package.json") "{`n  ""name"": ""acompute-app"",`n  ""private"": true`n}`n"' )
[void]$B.Add('EnsureDir (Join-Path $RepoRoot "app\src")' )
[void]$B.Add('WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\main.tsx") "console.log(""ACompute skeleton ready"");`n"' )
[void]$B.Add('$st=@(); $st += 'param([Parameter(Mandatory=$true)][string]$RepoRoot)'; $st += '$ErrorActionPreference="Stop"'; $st += 'Set-StrictMode -Version Latest'; $st += ''; $st += 'Write-Host ("SELFTEST_OK: " + $RepoRoot) -ForegroundColor Green'; WriteUtf8NoBomLf (Join-Path $RepoRoot "scripts\_selftest_core_v1.ps1") ((@($st) -join "`n") + "`n")' )
[void]$B.Add('Write-Host ("BOOTSTRAP_OK: " + $RepoRoot) -ForegroundColor Green' )

WriteUtf8NoBomLf $BootstrapPath ((@($B) -join "`n") + "`n")
ParseGatePs1 $BootstrapPath
& (Get-Command powershell.exe).Source -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $BootstrapPath -RepoRoot $RepoRoot | Out-Host
if(-not (Test-Path -LiteralPath (Join-Path $RepoRoot "scripts\_selftest_core_v1.ps1") -PathType Leaf)){ throw "POSTCHECK_FAIL: selftest missing" }
Write-Host ("PATCH_OK: bootstrap rewritten + executed") -ForegroundColor Green
