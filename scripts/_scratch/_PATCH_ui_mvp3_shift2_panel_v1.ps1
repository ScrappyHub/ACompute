param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){ if([string]::IsNullOrWhiteSpace($p)){ throw "EnsureDir: empty path" } if(-not (Test-Path -LiteralPath $p -PathType Container)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBomLf([string]$Path,[string]$Text){ if([string]::IsNullOrWhiteSpace($Path)){ throw "WriteUtf8NoBomLf: empty path" }; $enc = New-Object System.Text.UTF8Encoding($false); $t = $Text -replace "`r`n","`n"; $t = $t -replace "`r","`n"; if(-not $t.EndsWith("`n")){ $t += "`n" }; EnsureDir (Split-Path -Parent $Path); [System.IO.File]::WriteAllText($Path,$t,$enc) }

$uiDir = Join-Path $RepoRoot "app\src\acompute\ui"
EnsureDir $uiDir
EnsureDir (Join-Path $RepoRoot "app\src")

# ------------------------------------------------------------
# DemoShift2Panel.tsx — minimal SVG graph renderer + pulse
# ------------------------------------------------------------
$tsx = New-Object System.Collections.Generic.List[string]
[void]$tsx.Add('import React, { useMemo, useState } from "react";')
[void]$tsx.Add('import type { Bit } from "../core/types";')
[void]$tsx.Add('import { initialState } from "../core/state";')
WriteUtf8NoBomLf (Join-Path $uiDir "DemoShift2Panel.tsx") ((@($tsx.ToArray()) -join "`n") + "`n")

# ------------------------------------------------------------
# main.tsx — mount DemoShift2Panel (no router required)
# ------------------------------------------------------------
$main = New-Object System.Collections.Generic.List[string]
[void]$main.Add('import React from "react";')
[void]$main.Add('import { createRoot } from "react-dom/client";')
[void]$main.Add('import { DemoShift2Panel } from "./acompute/ui/DemoShift2Panel";')
[void]$main.Add('')
[void]$main.Add('const el = document.getElementById("root");')
[void]$main.Add('if (!el) { throw new Error("Missing #root"); }')
[void]$main.Add('createRoot(el).render(<React.StrictMode><DemoShift2Panel /></React.StrictMode>);')
WriteUtf8NoBomLf (Join-Path $RepoRoot "app\src\main.tsx") ((@($main.ToArray()) -join "`n") + "`n")

# ------------------------------------------------------------
# scripts/_selftest_ui_mvp3_shift2_v1.ps1 — no node required
# ------------------------------------------------------------
$st = New-Object System.Collections.Generic.List[string]
[void]$st.Add('param([Parameter(Mandatory=$true)][string]$RepoRoot)')
[void]$st.Add('$ErrorActionPreference="Stop"')
[void]$st.Add('Set-StrictMode -Version Latest')
[void]$st.Add('')
[void]$st.Add('function MustExist([string]$p){ if(-not (Test-Path -LiteralPath $p -PathType Leaf)){ throw ("MISSING: " + $p) } }')
[void]$st.Add('$panel = Join-Path $RepoRoot "app\src\acompute\ui\DemoShift2Panel.tsx"' )
[void]$st.Add('$main  = Join-Path $RepoRoot "app\src\main.tsx"' )
[void]$st.Add('MustExist $panel' )
[void]$st.Add('MustExist $main' )
[void]$st.Add('$pTxt = [System.IO.File]::ReadAllText($panel)' )
[void]$st.Add('if($pTxt -notmatch "export function DemoShift2Panel"){ throw "SELFTEST_FAIL: DemoShift2Panel export missing" }' )
[void]$st.Add('if($pTxt -notmatch "Pulse \\(0→1→0\\)"){ throw "SELFTEST_FAIL: pulse UI text missing (expected 0→1→0)" }' )
[void]$st.Add('$mTxt = [System.IO.File]::ReadAllText($main)' )
[void]$st.Add('if($mTxt -notmatch "DemoShift2Panel"){ throw "SELFTEST_FAIL: main.tsx not mounting DemoShift2Panel" }' )
[void]$st.Add('Write-Host "SELFTEST_UI_MVP3_OK: panel exists + mounted" -ForegroundColor Green' )
WriteUtf8NoBomLf (Join-Path $RepoRoot "scripts\_selftest_ui_mvp3_shift2_v1.ps1") ((@($st.ToArray()) -join "`n") + "`n")

Write-Host "APPLY_OK: UI panel + main mount + ui selftest written" -ForegroundColor Green
