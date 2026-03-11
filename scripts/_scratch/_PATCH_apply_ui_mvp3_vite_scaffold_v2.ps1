param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ throw "EnsureDir: empty path" }
  if(-not (Test-Path -LiteralPath $p -PathType Container)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}

function WriteUtf8NoBomLf([string]$Path,[string]$Text){
  if([string]::IsNullOrWhiteSpace($Path)){ throw "WriteUtf8NoBomLf: empty path" }
  $enc = New-Object System.Text.UTF8Encoding($false)
  $t = $Text -replace "`r`n","`n"
  $t = $t -replace "`r","`n"
  if(-not $t.EndsWith("`n")){ $t += "`n" }
  EnsureDir (Split-Path -Parent $Path)
  [System.IO.File]::WriteAllText($Path,$t,$enc)
}

function BackupFile([string]$Path,[string]$BackupDir){
  if(Test-Path -LiteralPath $Path -PathType Leaf){
    EnsureDir $BackupDir
    $name = [System.IO.Path]::GetFileName($Path)
    $dst  = Join-Path $BackupDir $name
    Copy-Item -LiteralPath $Path -Destination $dst -Force
  }
}

function WriteLines([string]$Path, [string[]]$Lines){
  $txt = ((@($Lines) -join "`n") + "`n")
  WriteUtf8NoBomLf $Path $txt
}

$ts = (Get-Date).ToString("yyyyMMdd_HHmmssfff")
$BackupDir = Join-Path $RepoRoot ("scripts\_scratch\backups\ui_mvp3_v2_" + $ts)

$app = Join-Path $RepoRoot "app"
EnsureDir $app
EnsureDir (Join-Path $app "src")

# ----------------------------
# index.html
# ----------------------------
$indexHtmlPath = Join-Path $app "index.html"
BackupFile $indexHtmlPath $BackupDir
WriteLines $indexHtmlPath @(
  '<!doctype html>'
  '<html lang="en">'
  '  <head>'
  '    <meta charset="UTF-8" />'
  '    <meta name="viewport" content="width=device-width, initial-scale=1.0" />'
  '    <title>ACompute UI</title>'
  '  </head>'
  '  <body>'
  '    <div id="root"></div>'
  '    <script type="module" src="/src/main.tsx"></script>'
  '  </body>'
  '</html>'
)

# ----------------------------
# package.json (Vite + React + TS)
# NOTE: overwrites the minimal package.json you currently have.
# ----------------------------
$pkgPath = Join-Path $app "package.json"
BackupFile $pkgPath $BackupDir
WriteLines $pkgPath @(
  '{'
  '  "name": "acompute-ui",'
  '  "private": true,'
  '  "version": "0.0.0",'
  '  "type": "module",'
  '  "scripts": {'
  '    "dev": "vite",'
  '    "build": "tsc -b && vite build",'
  '    "preview": "vite preview"'
  '  },'
  '  "dependencies": {'
  '    "react": "^18.2.0",'
  '    "react-dom": "^18.2.0"'
  '  },'
  '  "devDependencies": {'
  '    "@types/react": "^18.2.0",'
  '    "@types/react-dom": "^18.2.0",'
  '    "@vitejs/plugin-react": "^4.2.0",'
  '    "typescript": "^5.3.3",'
  '    "vite": "^5.0.0"'
  '  }'
  '}'
)

# ----------------------------
# vite.config.ts
# ----------------------------
$viteCfgPath = Join-Path $app "vite.config.ts"
BackupFile $viteCfgPath $BackupDir
WriteLines $viteCfgPath @(
  'import { defineConfig } from "vite";'
  'import react from "@vitejs/plugin-react";'
  ''
  'export default defineConfig({'
  '  plugins: [react()],'
  '});'
)

# ----------------------------
# tsconfig.json
# ----------------------------
$tscPath = Join-Path $app "tsconfig.json"
BackupFile $tscPath $BackupDir
WriteLines $tscPath @(
  '{'
  '  "compilerOptions": {'
  '    "target": "ES2020",'
  '    "useDefineForClassFields": true,'
  '    "lib": ["ES2020", "DOM", "DOM.Iterable"],'
  '    "module": "ESNext",'
  '    "skipLibCheck": true,'
  '    "moduleResolution": "Bundler",'
  '    "resolveJsonModule": true,'
  '    "isolatedModules": true,'
  '    "noEmit": true,'
  '    "jsx": "react-jsx",'
  '    "strict": true'
  '  },'
  '  "include": ["src"]'
  '}'
)

# ----------------------------
# src/vite-env.d.ts
# ----------------------------
$envPath = Join-Path $app "src\vite-env.d.ts"
BackupFile $envPath $BackupDir
WriteLines $envPath @(
  '/// <reference types="vite/client" />'
)

# ============================================================
# ACompute minimal engine + demo graph (so Vite build works)
# ============================================================
EnsureDir (Join-Path $app "src\acompute\core")
EnsureDir (Join-Path $app "src\acompute\engine")
EnsureDir (Join-Path $app "src\acompute\demos")
EnsureDir (Join-Path $app "src\acompute\ui")

WriteLines (Join-Path $app "src\acompute\core\types.ts") @(
  'export type Bit = 0 | 1;'
)

WriteLines (Join-Path $app "src\acompute\core\state.ts") @(
  'import type { Bit } from "./types";'
  ''
  'export type SeqState = {'
  '  Q0: Bit;'
  '  Q1: Bit;'
  '};'
  ''
  'export type SimState = {'
  '  clk: Bit;'
  '  seq: SeqState;'
  '};'
  ''
  'export function initialState(): SimState {'
  '  return {'
  '    clk: 0,'
  '    seq: { Q0: 0, Q1: 0 },'
  '  };'
  '}'
)

WriteLines (Join-Path $app "src\acompute\demos\demo_shift2.ts") @(
  'export type Node = { id: string; label: string; x: number; y: number };'
  'export type Edge = { id: string; from: string; to: string };'
  ''
  'export type DemoGraph = {'
  '  nodes: Node[];'
  '  edges: Edge[];'
  '};'
  ''
  '// Visual-only graph for the panel.'
  'export const demoShift2: DemoGraph = {'
  '  nodes: ['
  '    { id: "D0", label: "D0", x: 80,  y: 60 },'
  '    { id: "Q0", label: "Q0", x: 260, y: 60 },'
  '    { id: "D1", label: "D1", x: 260, y: 160 },'
  '    { id: "Q1", label: "Q1", x: 440, y: 160 },'
  '  ],'
  '  edges: ['
  '    { id: "e0", from: "D0", to: "Q0" },'
  '    { id: "e1", from: "Q0", to: "D1" },'
  '    { id: "e2", from: "D1", to: "Q1" },'
  '  ],'
  '};'
)

WriteLines (Join-Path $app "src\acompute\engine\eval.ts") @(
  'import type { Bit } from "../core/types";'
  'import type { SimState } from "../core/state";'
  'import type { DemoGraph } from "../demos/demo_shift2";'
  ''
  'export type Outs = Record<string, Bit>;'
  ''
  '// For this MVP, outs are just the inputs + current sequential Qs.'
  'export function evalGraph(s: SimState, _g: DemoGraph, inputs: { D0: Bit }): Outs {'
  '  const outs: Outs = {};'
  '  outs["D0"] = inputs.D0;'
  '  outs["Q0"] = s.seq.Q0;'
  '  outs["D1"] = s.seq.Q0;'
  '  outs["Q1"] = s.seq.Q1;'
  '  return outs;'
  '}'
)

WriteLines (Join-Path $app "src\acompute\core\transition.ts") @(
  'import type { Bit } from "./types";'
  'import type { SimState } from "./state";'
  'import type { DemoGraph } from "../demos/demo_shift2";'
  'import { evalGraph } from "../engine/eval";'
  ''
  '// Rising-edge capture for a 2-stage shift register:'
  '// Q0 <= D0, Q1 <= prior Q0'
  'export function transition(s: SimState, g: DemoGraph, inputs: { D0: Bit }, nextClk: Bit): SimState {'
  '  const prevClk = s.clk;'
  '  const rising = prevClk === 0 && nextClk === 1;'
  '  if (!rising) {'
  '    return { ...s, clk: nextClk };'
  '  }'
  '  const outs = evalGraph(s, g, inputs);'
  '  const nextQ0 = inputs.D0;'
  '  const nextQ1 = outs["Q0"] ?? 0;'
  '  return {'
  '    clk: nextClk,'
  '    seq: {'
  '      Q0: nextQ0,'
  '      Q1: nextQ1,'
  '    },'
  '  };'
  '}'
)

# ----------------------------
# DemoShift2Panel.tsx
# ----------------------------
$panelPath = Join-Path $app "src\acompute\ui\DemoShift2Panel.tsx"
BackupFile $panelPath $BackupDir
WriteLines $panelPath @(
  'import React, { useMemo, useState } from "react";'
  'import type { Bit } from "../core/types";'
  'import { initialState } from "../core/state";'
  'import { transition } from "../core/transition";'
  'import { evalGraph } from "../engine/eval";'
  'import { demoShift2 } from "../demos/demo_shift2";'
  ''
  'type Outs = Record<string, Bit>;'
  ''
  'function bitLabel(b: Bit): string {'
  '  return b === 1 ? "1" : "0";'
  '}'
  ''
  'function SvgGraph(props: { outs: Outs }) {'
  '  const { outs } = props;'
  '  const g = demoShift2;'
  '  const w = 520;'
  '  const h = 220;'
  '  return ('
  '    <svg width={w} height={h} style={{ border: "1px solid #333", borderRadius: 12, background: "#0b0f14" }}>'
  '      {g.edges.map((e) => {'
  '        const a = g.nodes.find((n) => n.id === e.from);'
  '        const b = g.nodes.find((n) => n.id === e.to);'
  '        if (!a || !b) return null;'
  '        const x1 = a.x + 48;'
  '        const y1 = a.y;'
  '        const x2 = b.x - 48;'
  '        const y2 = b.y;'
  '        const mx = (x1 + x2) / 2;'
  '        const d = `M ${x1} ${y1} C ${mx} ${y1}, ${mx} ${y2}, ${x2} ${y2}`;'
  '        return <path key={e.id} d={d} fill="none" stroke="#6aa9ff" strokeWidth={2} opacity={0.8} />;'
  '      })}'
  ''
  '      {g.nodes.map((n) => {'
  '        const out = (outs[n.id] ?? 0) as Bit;'
  '        const rx = 44;'
  '        const ry = 20;'
  '        return ('
  '          <g key={n.id}>'
  '            <rect x={n.x - rx} y={n.y - ry} width={rx * 2} height={ry * 2} rx={10} ry={10} fill="#111a24" stroke="#3b4a5f" />'
  '            <text x={n.x} y={n.y - 2} textAnchor="middle" fontSize="12" fill="#e7eefc" fontFamily="ui-sans-serif, system-ui">{n.label}</text>'
  '            <text x={n.x} y={n.y + 14} textAnchor="middle" fontSize="12" fill="#8dffb0" fontFamily="ui-monospace, SFMono-Regular, Menlo">{bitLabel(out as Bit)}</text>'
  '          </g>'
  '        );'
  '      })}'
  '    </svg>'
  '  );'
  '}'
  ''
  'export function DemoShift2Panel() {'
  '  const [d0, setD0] = useState<Bit>(0);'
  '  const [s, setS] = useState(() => initialState());'
  '  const outs = useMemo(() => evalGraph(s, demoShift2, { D0: d0 }), [s, d0]);'
  ''
  '  function pulse() {'
  '    const s1 = transition(s, demoShift2, { D0: d0 }, 1);'
  '    const s2 = transition(s1, demoShift2, { D0: d0 }, 0);'
  '    setS(s2);'
  '  }'
  ''
  '  const q0 = (outs["Q0"] ?? 0) as Bit;'
  '  const q1 = (outs["Q1"] ?? 0) as Bit;'
  ''
  '  return ('
  '    <div style={{ padding: 16, color: "#e7eefc", fontFamily: "ui-sans-serif, system-ui", background: "#070b10", minHeight: "100vh" }}>'
  '      <h1 style={{ margin: 0, fontSize: 22 }}>ACompute — MVP3 Shift Register (2x DFF)</h1>'
  '      <div style={{ marginTop: 8, opacity: 0.85 }}>D0 -&gt; Q0, and Q0 -&gt; D1 -&gt; Q1. Pulse performs clk 0-&gt;1-&gt;0 (rising edge capture).</div>'
  ''
  '      <div style={{ display: "flex", gap: 12, marginTop: 14, alignItems: "center", flexWrap: "wrap" }}>'
  '        <button onClick={() => setD0(d0 === 1 ? 0 : 1)} style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #3b4a5f", background: "#111a24", color: "#e7eefc" }}>'
  '          Toggle D0 (now {bitLabel(d0)})'
  '        </button>'
  '        <button onClick={pulse} style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #3b4a5f", background: "#18263a", color: "#e7eefc" }}>'
  '          Pulse (0-&gt;1-&gt;0)'
  '        </button>'
  '        <div style={{ fontFamily: "ui-monospace, SFMono-Regular, Menlo", opacity: 0.9 }}>Q0={bitLabel(q0)} Q1={bitLabel(q1)} clk={bitLabel(s.clk)}</div>'
  '      </div>'
  ''
  '      <div style={{ marginTop: 14 }}><SvgGraph outs={outs} /></div>'
  ''
  '      <div style={{ marginTop: 14, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>'
  '        <div style={{ border: "1px solid #2a3646", borderRadius: 12, padding: 12, background: "#0b0f14" }}>'
  '          <div style={{ fontWeight: 700, marginBottom: 6 }}>Sequential state (s.seq)</div>'
  '          <pre style={{ margin: 0, fontSize: 12, whiteSpace: "pre-wrap" }}>{JSON.stringify(s.seq, null, 2)}</pre>'
  '        </div>'
  '        <div style={{ border: "1px solid #2a3646", borderRadius: 12, padding: 12, background: "#0b0f14" }}>'
  '          <div style={{ fontWeight: 700, marginBottom: 6 }}>Combinational outs</div>'
  '          <pre style={{ margin: 0, fontSize: 12, whiteSpace: "pre-wrap" }}>{JSON.stringify(outs, null, 2)}</pre>'
  '        </div>'
  '      </div>'
  '    </div>'
  '  );'
  '}'
)

# ----------------------------
# src/main.tsx
# ----------------------------
$mainPath = Join-Path $app "src\main.tsx"
BackupFile $mainPath $BackupDir
WriteLines $mainPath @(
  'import React from "react";'
  'import { createRoot } from "react-dom/client";'
  'import { DemoShift2Panel } from "./acompute/ui/DemoShift2Panel";'
  ''
  'const el = document.getElementById("root");'
  'if (!el) {'
  '  throw new Error("Missing #root");'
  '}'
  ''
  'createRoot(el).render('
  '  <React.StrictMode>'
  '    <DemoShift2Panel />'
  '  </React.StrictMode>'
  ');'
)

# ----------------------------
# UI selftest (no Node required)
# ----------------------------
EnsureDir (Join-Path $RepoRoot "scripts")
$stPath = Join-Path $RepoRoot "scripts\_selftest_ui_mvp3_shift2_v1.ps1"
BackupFile $stPath $BackupDir
WriteLines $stPath @(
  'param([Parameter(Mandatory=$true)][string]$RepoRoot)'
  '$ErrorActionPreference="Stop"'
  'Set-StrictMode -Version Latest'
  ''
  'function MustExist([string]$p){'
  '  if(-not (Test-Path -LiteralPath $p -PathType Leaf)){'
  '    throw ("MISSING: " + $p)'
  '  }'
  '}'
  ''
  '$panel = Join-Path $RepoRoot "app\src\acompute\ui\DemoShift2Panel.tsx"'
  '$main  = Join-Path $RepoRoot "app\src\main.tsx"'
  '$pkg   = Join-Path $RepoRoot "app\package.json"'
  ''
  'MustExist $panel'
  'MustExist $main'
  'MustExist $pkg'
  ''
  '$pkgTxt = [System.IO.File]::ReadAllText($pkg)'
  'if($pkgTxt -notmatch ''"dev"\s*:\s*"vite"''){'
  '  throw "SELFTEST_FAIL: package.json missing dev script"'
  '}'
  ''
  'Write-Host "SELFTEST_UI_MVP3_OK: scaffold + panel + dev script present" -ForegroundColor Green'
)

Write-Host ("APPLY_OK: Vite scaffold + ACompute MVP3 UI written. BackupDir=" + $BackupDir) -ForegroundColor Green
Write-Host ("WROTE_SELFTEST: " + $stPath) -ForegroundColor Green
