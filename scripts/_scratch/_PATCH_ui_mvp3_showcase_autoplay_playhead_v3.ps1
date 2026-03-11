param([Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference="Stop"
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
  $t = ($Text -replace "`r`n","`n") -replace "`r","`n"
  if(-not $t.EndsWith("`n")){ $t += "`n" }
  EnsureDir (Split-Path -Parent $Path)
  [System.IO.File]::WriteAllText($Path,$t,$enc)
}

$panelPath = Join-Path $RepoRoot "app\src\acompute\ui\DemoShift2Panel.tsx"
if(-not (Test-Path -LiteralPath $panelPath -PathType Leaf)){ throw ("MISSING_PANEL: " + $panelPath) }

$raw = [System.IO.File]::ReadAllText($panelPath, (New-Object System.Text.UTF8Encoding($false)))
if($raw -notmatch 'SHOWCASE v2 \+ WAVEFORM'){ throw "PATCH_GUARD_FAIL: expected SHOWCASE v2 + WAVEFORM marker not found" }

if($raw -match 'ACOMPUTE_SHOWCASE_AUTOPLAY_PLAYHEAD_V1'){
  Write-Host "PATCH_SKIPPED: already applied (ACOMPUTE_SHOWCASE_AUTOPLAY_PLAYHEAD_V1)" -ForegroundColor Yellow
  return
}

$raw2 = $raw

# ---- Waveform signature upgrade ----
$raw2 = $raw2 -replace 'function Waveform\(props: \{ samples: Sample\[\] \}\)', 'function Waveform(props: { samples: Sample[]; playhead: number; phase: string })'
$raw2 = $raw2 -replace 'const \{ samples \} = props;', 'const { samples, playhead, phase } = props;'

# Insert overlay after the header </text> (INNER STRINGS MUST BE @" "@)
$overlay = @"
      {/* ACOMPUTE_SHOWCASE_AUTOPLAY_PLAYHEAD_V1 */}
      {(() => {
        const nn = Math.max(2, samples.length);
        const step = (w - padL - padR) / (nn - 1);
        const x = padL + clamp(playhead, 0, nn - 1) * step;
        return (
          <g>
            <line x1={x} y1={6} x2={x} y2={h-6} stroke="#ffffff" strokeWidth={1} opacity={0.18} />
            <rect x={w - 210} y={6} width={196} height={22} rx={10} ry={10} fill="#0b1422" stroke="#2a3a52" />
            <text x={w - 200} y={22} fontSize={12} fill="#ffffff" fontFamily="ui-monospace, SFMono-Regular, Menlo" opacity={0.9}>
              phase={phase} idx={playhead}
            </text>
          </g>
        );
      })()}
"@

$raw2 = [regex]::Replace(
  $raw2,
  'Waveform \(last \{samples\.length\} samples\)\s*</text>',
  ('Waveform (last {samples.length} samples)</text>' + "`n" + $overlay),
  1
)

# ---- Showcase state machine ----
$anchor = 'const \[auto, setAuto\] = useState<boolean>\(true\);'
if($raw2 -notmatch $anchor){ throw "PATCH_FAIL: expected anchor for auto state not found" }

$showcaseBlock = @"
  const [showcase, setShowcase] = useState<boolean>(true);
  const [phase, setPhase] = useState<"low" | "rise" | "high" | "fall">("low");
  const [playhead, setPlayhead] = useState<number>(0);
  const showcaseRef = useRef<boolean>(true);
  const phaseRef = useRef<"low" | "rise" | "high" | "fall">("low");

  useEffect(() => { showcaseRef.current = showcase; }, [showcase]);
  useEffect(() => { phaseRef.current = phase; }, [phase]);

  function showcaseTick() {
    if (!showcaseRef.current) return;

    const p = phaseRef.current;
    const bits = onlyBits(seqTextRef.current);
    const bit = bits.length ? ((bits.charAt(seqIdxRef.current % bits.length) === "1") ? 1 : 0) as Bit : d0Ref.current;

    if (p === "low") { setPhase("rise"); return; }

    if (p === "rise") {
      setD0(bit);
      setClkVis(1);
      setS((prev) => {
        const next = (modeRef.current === "manual") ? manualShift(prev, bit) : transition(prev, demoShift2, { D0: bit }, 1);
        pushSample(bit, next, 1);
        return next;
      });
      setPhase("high");
      return;
    }

    if (p === "high") { setPhase("fall"); return; }

    setS((prev) => {
      if (modeRef.current === "manual") { pushSample(bit, prev, 0); return prev; }
      const next = transition(prev, demoShift2, { D0: bit }, 0);
      pushSample(bit, next, 0);
      return next;
    });
    setClkVis(0);
    setSeqIdx((x) => x + 1);
    setPlayhead((x) => x + 1);
    setPhase("low");
  }
"@

$raw2 = $raw2 -replace [regex]::Escape($anchor), ($anchor + "`n" + $showcaseBlock)

# ---- Replace existing auto useEffect ----
$fxNeedle = 'useEffect\(\(\) => \{\s*if \(!autoRef\.current\) return;[\s\S]*?return \(\) => window\.clearInterval\(id\);\s*\}, \[auto, periodMs\]\);'
$m = [regex]::Match($raw2, $fxNeedle)
if(-not $m.Success){ throw "PATCH_FAIL: expected auto interval useEffect not found" }

$fxReplacement = @"
  useEffect(() => {
    const base = clamp(periodRef.current, 180, 3000);
    const tickMs = clamp(Math.floor(base / 4), 60, 900);

    const id = window.setInterval(() => {
      if (showcaseRef.current) {
        showcaseTick();
      } else if (autoRef.current) {
        stepSequenceOnce();
      }
    }, tickMs);

    return () => window.clearInterval(id);
  }, [auto, periodMs, showcase]);
"@

$raw2 = [regex]::Replace($raw2, $fxNeedle, $fxReplacement, 1)

# ---- Controls row insert ----
$controlsNeedle = 'seqIdx=\{seqIdx\} nextBit=\{bitLabel\(bitNow\)\} samples=\{samples\.length\}'
if($raw2 -notmatch $controlsNeedle){ throw "PATCH_FAIL: expected status line needle not found" }

$controlsInsert = @"
          <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap", marginTop: 8 }}>
            <label style={{ display: "flex", gap: 8, alignItems: "center" }}>
              <span style={{ opacity: 0.95 }}>Showcase</span>
              <input type="checkbox" checked={showcase} onChange={(e) => setShowcase(e.target.checked)} />
            </label>

            <button
              onClick={() => { setPhase("low"); setClkVis(0); setPlayhead(0); }}
              style={{ padding: "6px 10px", borderRadius: 10, border: "1px solid #3b557a", background: "#0b1422", color: "#ffffff" }}
            >
              Reset showcase
            </button>

            <button
              onClick={() => { setShowcase(false); showcaseTick(); }}
              style={{ padding: "6px 10px", borderRadius: 10, border: "1px solid #3b557a", background: "#152540", color: "#ffffff" }}
            >
              Single tick
            </button>

            <div style={{ fontFamily: "ui-monospace, SFMono-Regular, Menlo", opacity: 0.9 }}>
              phase={phase} playhead={playhead}
            </div>
          </div>
"@

$raw2 = [regex]::Replace(
  $raw2,
  '(seqIdx=\{seqIdx\} nextBit=\{bitLabel\(bitNow\)\} samples=\{samples\.length\}\s*</div>)',
  ('$1' + "`n" + $controlsInsert),
  1
)

# ---- Update Waveform call ----
$raw2 = $raw2 -replace '<Waveform samples=\{samples\} />', '<Waveform samples={samples} playhead={playhead} phase={phase} />'

WriteUtf8NoBomLf $panelPath $raw2
Write-Host ("PATCH_OK: updated " + $panelPath) -ForegroundColor Green
