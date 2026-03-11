param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){ if([string]::IsNullOrWhiteSpace($p)){ throw "EnsureDir: empty path" }; if(-not (Test-Path -LiteralPath $p -PathType Container)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBomLf([string]$Path,[string]$Text){ if([string]::IsNullOrWhiteSpace($Path)){ throw "WriteUtf8NoBomLf: empty path" }; $enc=New-Object System.Text.UTF8Encoding($false); $t=(($Text -replace "`r`n","`n") -replace "`r","`n"); if(-not $t.EndsWith("`n")){ $t += "`n" }; EnsureDir (Split-Path -Parent $Path); [System.IO.File]::WriteAllText($Path,$t,$enc) }

$panelPath = Join-Path $RepoRoot "app\src\acompute\ui\DemoShift2Panel.tsx"
if(-not (Test-Path -LiteralPath $panelPath -PathType Leaf)){ throw ("MISSING_PANEL: " + $panelPath) }
$raw = [System.IO.File]::ReadAllText($panelPath, (New-Object System.Text.UTF8Encoding($false)))

$lineA = 'import * as React from "react";'
$lineB = 'import React, { useEffect, useMemo, useRef, useState } from "react";'
if($raw -notmatch [regex]::Escape($lineB)){ throw "PATCH_FAIL: expected default React+hooks import not found (lineB)" }
if($raw -notmatch [regex]::Escape($lineA)){ Write-Host "PATCH_SKIPPED: no duplicate import * as React line found" -ForegroundColor Yellow; return }

$raw2 = $raw -replace ("(?m)^\s*" + [regex]::Escape($lineA) + "\s*\r?\n"), ""
WriteUtf8NoBomLf $panelPath $raw2
Write-Host ("PATCH_OK: removed duplicate React import line: " + $panelPath) -ForegroundColor Green
