import React, { useEffect, useMemo, useRef, useState } from "react";
import type { Bit } from "../core/types";
import { initialState } from "../core/state";
import { transition } from "../core/transition";
import { evalGraph } from "../engine/eval";
import { demoShift2 } from "../demos/demo_shift2";

type Outs = Record<string, Bit>;
type Mode = "engine" | "manual";
type Phase = "low" | "rise" | "high" | "fall";
type Sample = { d0: Bit; q0: Bit; q1: Bit; clk: Bit };
type TraceEntry = {
  tick: number;
  phase: Phase;
  d0: Bit;
  q0: Bit;
  q1: Bit;
  clk: Bit;
  mode: Mode;
  seqIdx: number;
};

type BoardPart = {
  ref: string;
  kind: string;
  purpose: string;
  pins: string[];
};

type NetRow = {
  net: string;
  from: string;
  to: string;
  meaning: string;
};

function bitLabel(b: Bit): string {
  return b === 1 ? "1" : "0";
}

function onlyBits(s: string): string {
  return (s || "").replace(/[^01]/g, "");
}

function clamp(n: number, lo: number, hi: number): number {
  if (n < lo) return lo;
  if (n > hi) return hi;
  return n;
}

function Waveform(props: { samples: Sample[]; playhead: number; phase: string }) {
  const { samples, playhead, phase } = props;
  const w = 860;
  const rowH = 34;
  const padL = 70;
  const padR = 16;
  const padT = 10;
  const n = Math.max(2, samples.length);
  const step = (w - padL - padR) / (n - 1);

  function yBase(row: number): number {
    return padT + row * rowH + 18;
  }

  function mkPath(get: (s: Sample) => Bit, row: number): string {
    if (samples.length === 0) return "";
    const y0 = yBase(row);
    const hi = y0 - 12;
    const lo = y0 + 8;
    let d = "";
    let x = padL;
    let y = get(samples[0]) ? hi : lo;
    d += `M ${x} ${y}`;
    for (let i = 1; i < samples.length; i++) {
      const nx = padL + i * step;
      const ny = get(samples[i]) ? hi : lo;
      d += ` L ${nx} ${y}`;
      if (ny !== y) d += ` L ${nx} ${ny}`;
      x = nx;
      y = ny;
    }
    return d;
  }

  const h = padT + rowH * 4 + 10;
  const px = padL + clamp(playhead, 0, n - 1) * step;

  return (
    <svg width={w} height={h} style={{ border: "1px solid #2a3a52", borderRadius: 12, background: "#070d16" }}>
      <text x={12} y={18} fontSize={12} fill="#ffffff" fontFamily="ui-monospace, SFMono-Regular, Menlo" opacity={0.9}>
        Waveform (last {samples.length} samples)
      </text>
      <line x1={px} y1={6} x2={px} y2={h - 6} stroke="#ffffff" strokeWidth={1} opacity={0.18} />
      <rect x={w - 210} y={6} width={196} height={22} rx={10} ry={10} fill="#0b1422" stroke="#2a3a52" />
      <text x={w - 200} y={22} fontSize={12} fill="#ffffff" fontFamily="ui-monospace, SFMono-Regular, Menlo" opacity={0.9}>
        phase={phase} idx={playhead}
      </text>

      {["D0", "Q0", "Q1", "clk"].map((lab, i) => (
        <g key={lab}>
          <text x={12} y={yBase(i)} fontSize={12} fill="#ffffff" fontFamily="ui-monospace, SFMono-Regular, Menlo" opacity={0.9}>
            {lab}
          </text>
          <line x1={padL} y1={yBase(i) + 8} x2={w - padR} y2={yBase(i) + 8} stroke="#1c2a3b" strokeWidth={1} />
          <line x1={padL} y1={yBase(i) - 12} x2={w - padR} y2={yBase(i) - 12} stroke="#101827" strokeWidth={1} />
        </g>
      ))}

      <path d={mkPath((s) => s.d0, 0)} fill="none" stroke="#93b8ff" strokeWidth={2.5} opacity={0.95} />
      <path d={mkPath((s) => s.q0, 1)} fill="none" stroke="#00ff95" strokeWidth={2.5} opacity={0.95} />
      <path d={mkPath((s) => s.q1, 2)} fill="none" stroke="#ffd166" strokeWidth={2.5} opacity={0.95} />
      <path d={mkPath((s) => s.clk, 3)} fill="none" stroke="#ff6b6b" strokeWidth={2.5} opacity={0.95} />
    </svg>
  );
}

function SvgGraph(props: { outs: Outs }) {
  const { outs } = props;
  const g = demoShift2;
  const w = 560;
  const h = 240;
  return (
    <svg width={w} height={h} style={{ border: "1px solid #2a3a52", borderRadius: 14, background: "#070d16" }}>
      {g.edges.map((e) => {
        const a = g.nodes.find((n) => n.id === e.from);
        const b = g.nodes.find((n) => n.id === e.to);
        if (!a || !b) return null;
        const x1 = a.x + 52;
        const y1 = a.y;
        const x2 = b.x - 52;
        const y2 = b.y;
        const mx = (x1 + x2) / 2;
        const d = `M ${x1} ${y1} C ${mx} ${y1}, ${mx} ${y2}, ${x2} ${y2}`;
        return <path key={e.id} d={d} fill="none" stroke="#93b8ff" strokeWidth={2.5} opacity={0.9} />;
      })}

      {g.nodes.map((n) => {
        const out = (outs[n.id] ?? 0) as Bit;
        const rx = 54;
        const ry = 24;
        return (
          <g key={n.id}>
            <rect x={n.x - rx} y={n.y - ry} width={rx * 2} height={ry * 2} rx={12} ry={12} fill="#0b1422" stroke="#3b557a" />
            <text x={n.x} y={n.y - 4} textAnchor="middle" fontSize="13" fill="#ffffff" fontFamily="ui-sans-serif, system-ui">
              {n.label}
            </text>
            <text x={n.x} y={n.y + 16} textAnchor="middle" fontSize="14" fill="#00ff95" fontFamily="ui-monospace, SFMono-Regular, Menlo">
              {bitLabel(out)}
            </text>
          </g>
        );
      })}
    </svg>
  );
}

function BoardPlanner(props: {
  seqText: string;
  q0: Bit;
  q1: Bit;
  d0: Bit;
  phase: Phase;
  mode: Mode;
}) {
  const { seqText, q0, q1, d0, phase, mode } = props;

  const parts: BoardPart[] = [
    { ref: "J1", kind: "Input Header", purpose: "External bit entry / learner input", pins: ["D0", "GND"] },
    { ref: "U1", kind: "D Flip-Flop", purpose: "Stores Q0", pins: ["D", "CLK", "Q"] },
    { ref: "U2", kind: "D Flip-Flop", purpose: "Stores Q1", pins: ["D", "CLK", "Q"] },
    { ref: "CLK1", kind: "Clock Source", purpose: "Clock / pulse generator", pins: ["CLK", "GND"] },
    { ref: "TP1", kind: "Test Point", purpose: "Probe Q0", pins: ["Q0"] },
    { ref: "TP2", kind: "Test Point", purpose: "Probe Q1", pins: ["Q1"] },
  ];

  const nets: NetRow[] = [
    { net: "NET_D0", from: "J1.D0", to: "U1.D", meaning: "External input drives first flip-flop" },
    { net: "NET_Q0_TO_U2D", from: "U1.Q", to: "U2.D", meaning: "Shift chain from stage 1 to stage 2" },
    { net: "NET_CLK", from: "CLK1.CLK", to: "U1.CLK / U2.CLK", meaning: "Shared clock rail for both stages" },
    { net: "NET_Q0_TP", from: "U1.Q", to: "TP1.Q0", meaning: "Probe point for first stored bit" },
    { net: "NET_Q1_TP", from: "U2.Q", to: "TP2.Q1", meaning: "Probe point for second stored bit" },
  ];

  return (
    <div style={{ border: "1px solid #2a3a52", borderRadius: 12, padding: 12, background: "#070d16" }}>
      <div style={{ fontWeight: 700, marginBottom: 8 }}>Workbench / PCB educator surface</div>
      <div style={{ opacity: 0.9, marginBottom: 10 }}>
        This is the board-planning bridge between logical simulation and future PCB authoring.
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1.1fr 1fr", gap: 12 }}>
        <div style={{ border: "1px solid #162235", borderRadius: 10, padding: 10 }}>
          <div style={{ fontWeight: 700, marginBottom: 8 }}>Starter board bill of materials</div>
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12 }}>
            <thead>
              <tr>
                <th style={{ textAlign: "left", padding: 6, borderBottom: "1px solid #22314a" }}>Ref</th>
                <th style={{ textAlign: "left", padding: 6, borderBottom: "1px solid #22314a" }}>Kind</th>
                <th style={{ textAlign: "left", padding: 6, borderBottom: "1px solid #22314a" }}>Purpose</th>
              </tr>
            </thead>
            <tbody>
              {parts.map((p) => (
                <tr key={p.ref}>
                  <td style={{ padding: 6, borderBottom: "1px solid #162235", fontFamily: "ui-monospace, SFMono-Regular, Menlo" }}>{p.ref}</td>
                  <td style={{ padding: 6, borderBottom: "1px solid #162235" }}>{p.kind}</td>
                  <td style={{ padding: 6, borderBottom: "1px solid #162235" }}>{p.purpose}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div style={{ border: "1px solid #162235", borderRadius: 10, padding: 10 }}>
          <div style={{ fontWeight: 700, marginBottom: 8 }}>Live board state</div>
          <pre style={{ margin: 0, fontSize: 12, whiteSpace: "pre-wrap", color: "#ffffff" }}>{JSON.stringify({
            mode,
            phase,
            inputSequence: seqText,
            currentInput: d0,
            storedStage1_Q0: q0,
            storedStage2_Q1: q1,
            educationalGoal: "Show how a logical shift register maps to physical parts, pins, nets, and probe points."
          }, null, 2)}</pre>
        </div>
      </div>

      <div style={{ marginTop: 12, border: "1px solid #162235", borderRadius: 10, padding: 10 }}>
        <div style={{ fontWeight: 700, marginBottom: 8 }}>Net / connection plan</div>
        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12 }}>
          <thead>
            <tr>
              <th style={{ textAlign: "left", padding: 6, borderBottom: "1px solid #22314a" }}>Net</th>
              <th style={{ textAlign: "left", padding: 6, borderBottom: "1px solid #22314a" }}>From</th>
              <th style={{ textAlign: "left", padding: 6, borderBottom: "1px solid #22314a" }}>To</th>
              <th style={{ textAlign: "left", padding: 6, borderBottom: "1px solid #22314a" }}>Meaning</th>
            </tr>
          </thead>
          <tbody>
            {nets.map((n) => (
              <tr key={n.net}>
                <td style={{ padding: 6, borderBottom: "1px solid #162235", fontFamily: "ui-monospace, SFMono-Regular, Menlo" }}>{n.net}</td>
                <td style={{ padding: 6, borderBottom: "1px solid #162235", fontFamily: "ui-monospace, SFMono-Regular, Menlo" }}>{n.from}</td>
                <td style={{ padding: 6, borderBottom: "1px solid #162235", fontFamily: "ui-monospace, SFMono-Regular, Menlo" }}>{n.to}</td>
                <td style={{ padding: 6, borderBottom: "1px solid #162235" }}>{n.meaning}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div style={{ marginTop: 12, display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 12 }}>
        <div style={{ border: "1px solid #162235", borderRadius: 10, padding: 10 }}>
          <div style={{ fontWeight: 700, marginBottom: 6 }}>What the learner should see</div>
          <div style={{ opacity: 0.9 }}>
            D0 is the entering bit, Q0 is stage 1 storage, Q1 is stage 2 storage. Each pulse pushes data one stage deeper.
          </div>
        </div>
        <div style={{ border: "1px solid #162235", borderRadius: 10, padding: 10 }}>
          <div style={{ fontWeight: 700, marginBottom: 6 }}>Why this matters for PCB</div>
          <div style={{ opacity: 0.9 }}>
            Before layout, the learner needs confidence in signal flow, pin mapping, probing strategy, and clock discipline.
          </div>
        </div>
        <div style={{ border: "1px solid #162235", borderRadius: 10, padding: 10 }}>
          <div style={{ fontWeight: 700, marginBottom: 6 }}>Next future slice</div>
          <div style={{ opacity: 0.9 }}>
            Replace this planner with a true component placement canvas, editable nets, and pin-validity checks.
          </div>
        </div>
      </div>
    </div>
  );
}

export function DemoShift2Panel() {
  useEffect(() => { console.log("ACOMPUTE: DemoShift2Panel mounted"); }, []);

  const [d0, setD0] = useState<Bit>(0);
  const [s, setS] = useState(() => initialState());
  const [mode, setMode] = useState<Mode>("engine");
  const [seqText, setSeqText] = useState<string>("1010010");
  const [seqIdx, setSeqIdx] = useState<number>(0);
  const [auto, setAuto] = useState<boolean>(true);
  const [showcase, setShowcase] = useState<boolean>(true);
  const [periodMs, setPeriodMs] = useState<number>(650);
  const [clkVis, setClkVis] = useState<Bit>(0);
  const [samples, setSamples] = useState<Sample[]>([]);
  const [phase, setPhase] = useState<Phase>("low");
  const [playhead, setPlayhead] = useState<number>(0);
  const [trace, setTrace] = useState<TraceEntry[]>([]);

  const modeRef = useRef<Mode>(mode);
  const d0Ref = useRef<Bit>(d0);
  const periodRef = useRef<number>(periodMs);
  const autoRef = useRef<boolean>(auto);
  const showcaseRef = useRef<boolean>(showcase);
  const seqTextRef = useRef<string>(seqText);
  const seqIdxRef = useRef<number>(seqIdx);
  const phaseRef = useRef<Phase>(phase);
  const tickRef = useRef<number>(0);

  useEffect(() => { modeRef.current = mode; }, [mode]);
  useEffect(() => { d0Ref.current = d0; }, [d0]);
  useEffect(() => { periodRef.current = periodMs; }, [periodMs]);
  useEffect(() => { autoRef.current = auto; }, [auto]);
  useEffect(() => { showcaseRef.current = showcase; }, [showcase]);
  useEffect(() => { seqTextRef.current = seqText; }, [seqText]);
  useEffect(() => { seqIdxRef.current = seqIdx; }, [seqIdx]);
  useEffect(() => { phaseRef.current = phase; }, [phase]);

  const outs = useMemo(() => {
    return evalGraph(s, demoShift2, { D0: d0 });
  }, [s, d0]);

  const q0 = (outs["Q0"] ?? 0) as Bit;
  const q1 = (outs["Q1"] ?? 0) as Bit;

  function appendTrace(bit: Bit, st: any, clk: Bit, nextPhase: Phase, nextSeqIdx: number) {
    const o = evalGraph(st, demoShift2, { D0: bit });
    const entry: TraceEntry = {
      tick: tickRef.current + 1,
      phase: nextPhase,
      d0: bit,
      q0: ((o["Q0"] ?? 0) as Bit),
      q1: ((o["Q1"] ?? 0) as Bit),
      clk,
      mode: modeRef.current,
      seqIdx: nextSeqIdx,
    };
    tickRef.current = entry.tick;
    setTrace((prev) => {
      const next = [...prev, entry];
      const keep = 24;
      if (next.length <= keep) return next;
      return next.slice(next.length - keep);
    });
  }

  function manualShift(prev: any, bit: Bit): any {
    const prevSeq = (prev && prev.seq) ? prev.seq : {};
    const prevQ0 = ((prevSeq["Q0"] ?? 0) as Bit);
    const nextSeq: any = { ...prevSeq, Q0: bit, Q1: prevQ0 };
    return { ...prev, clk: 0, seq: nextSeq };
  }

  function pushSample(bit: Bit, st: any, clk: Bit) {
    const o = evalGraph(st, demoShift2, { D0: bit });
    const nq0 = ((o["Q0"] ?? 0) as Bit);
    const nq1 = ((o["Q1"] ?? 0) as Bit);
    const smp: Sample = { d0: bit, q0: nq0, q1: nq1, clk };
    setSamples((prev) => {
      const next = [...prev, smp];
      const keep = 60;
      if (next.length <= keep) return next;
      return next.slice(next.length - keep);
    });
  }

  function pulseAnimated(bit: Bit) {
    const highMs = clamp(Math.floor(periodRef.current * 0.25), 80, 240);
    setClkVis(1);
    setPhase("rise");

    setS((prev) => {
      const next = (modeRef.current === "manual") ? manualShift(prev, bit) : transition(prev, demoShift2, { D0: bit }, 1);
      pushSample(bit, next, 1);
      appendTrace(bit, next, 1, "rise", seqIdxRef.current);
      return next;
    });

    window.setTimeout(() => {
      setPhase("fall");
      setS((prev) => {
        const next = (modeRef.current === "manual") ? prev : transition(prev, demoShift2, { D0: bit }, 0);
        pushSample(bit, next, 0);
        appendTrace(bit, next, 0, "fall", seqIdxRef.current);
        return next;
      });
      setClkVis(0);
      setPhase("low");
    }, highMs);
  }

  function currentSeqBit(): Bit {
    const bits = onlyBits(seqTextRef.current);
    if (bits.length === 0) return d0Ref.current;
    const i = seqIdxRef.current % bits.length;
    return (bits.charAt(i) === "1" ? 1 : 0) as Bit;
  }

  function stepSequenceOnce() {
    const bits = onlyBits(seqTextRef.current);
    if (bits.length === 0) {
      pulseAnimated(d0Ref.current);
      return;
    }
    const i = seqIdxRef.current % bits.length;
    const b = (bits.charAt(i) === "1" ? 1 : 0) as Bit;
    setD0(b);
    pulseAnimated(b);
    setSeqIdx(i + 1);
    setPlayhead((x) => x + 1);
  }

  function loadSequenceReset() {
    const bits = onlyBits(seqText);
    setSeqText(bits);
    setSeqIdx(0);
    setS(() => initialState());
    setSamples([]);
    setTrace([]);
    tickRef.current = 0;
    setClkVis(0);
    setPhase("low");
    setPlayhead(0);
    if (bits.length > 0) {
      const b = (bits.charAt(0) === "1" ? 1 : 0) as Bit;
      setD0(b);
    }
  }

  function showcaseTick() {
    if (!showcaseRef.current) return;
    const p = phaseRef.current;
    if (p === "low" || p === "fall") {
      stepSequenceOnce();
      return;
    }
  }

  useEffect(() => {
    const base = clamp(periodRef.current, 180, 3000);
    const tickMs = clamp(Math.floor(base), 120, 3000);
    const id = window.setInterval(() => {
      if (showcaseRef.current) {
        showcaseTick();
      } else if (autoRef.current) {
        stepSequenceOnce();
      }
    }, tickMs);
    return () => window.clearInterval(id);
  }, [auto, periodMs, showcase]);

  const clkDot = clkVis === 1 ? "#00ff95" : "#3b557a";
  const bitNow = currentSeqBit();
  const latestTrace = trace.length > 0 ? trace[trace.length - 1] : null;

  return (
    <div style={{ padding: 16, color: "#ffffff", fontFamily: "ui-sans-serif, system-ui", background: "#05070c", minHeight: "100vh" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", gap: 10, flexWrap: "wrap" }}>
        <h1 style={{ margin: 0, fontSize: 22 }}>ACompute - MVP3 Shift Register (2x DFF)</h1>
        <div style={{ fontFamily: "ui-monospace, SFMono-Regular, Menlo", opacity: 0.9 }}>SHOWCASE v3 + TRACE INTROSPECTION + WORKBENCH</div>
      </div>

      <div style={{ marginTop: 8, opacity: 0.92 }}>
        D0 -&gt; Q0, and Q0 -&gt; D1 -&gt; Q1. Pulse performs clk 0 -&gt; 1 -&gt; 0 (rising edge capture).
      </div>

      <div style={{ display: "flex", gap: 10, marginTop: 14, alignItems: "center", flexWrap: "wrap" }}>
        <button onClick={() => setD0(d0 === 1 ? 0 : 1)} style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #3b557a", background: "#0b1422", color: "#ffffff" }}>
          Toggle D0 (now {bitLabel(d0)})
        </button>
        <button onClick={() => pulseAnimated(d0)} style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #3b557a", background: "#152540", color: "#ffffff" }}>
          Pulse (0 -&gt; 1 -&gt; 0)
        </button>
        <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
          <div style={{ width: 10, height: 10, borderRadius: 999, background: clkDot, boxShadow: clkVis ? "0 0 12px rgba(0,255,149,0.55)" : "none" }} />
          <div style={{ fontFamily: "ui-monospace, SFMono-Regular, Menlo", opacity: 0.95 }}>
            Q0={bitLabel(q0)} Q1={bitLabel(q1)} clk={bitLabel(clkVis)} phase={phase}
          </div>
        </div>
      </div>

      <div style={{ display: "flex", gap: 10, marginTop: 12, alignItems: "center", flexWrap: "wrap" }}>
        <label style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <span style={{ opacity: 0.95 }}>Mode</span>
          <select value={mode} onChange={(e) => setMode(e.target.value as Mode)} style={{ padding: "6px 8px", borderRadius: 10, border: "1px solid #3b557a", background: "#0b1422", color: "#ffffff" }}>
            <option value="engine">Engine (transition)</option>
            <option value="manual">Manual (guaranteed shift)</option>
          </select>
        </label>
        <label style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <span style={{ opacity: 0.95 }}>Input bits</span>
          <input value={seqText} onChange={(e) => setSeqText(onlyBits(e.target.value))} placeholder="e.g. 101001" style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #3b557a", background: "#0b1422", color: "#ffffff", width: 220 }} />
        </label>
        <button onClick={loadSequenceReset} style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #3b557a", background: "#0b1422", color: "#ffffff" }}>
          Load (reset)
        </button>
        <button onClick={stepSequenceOnce} style={{ padding: "8px 12px", borderRadius: 10, border: "1px solid #3b557a", background: "#152540", color: "#ffffff" }}>
          Step next bit
        </button>
        <label style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <span style={{ opacity: 0.95 }}>Auto</span>
          <input type="checkbox" checked={auto} onChange={(e) => setAuto(e.target.checked)} />
        </label>
        <label style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <span style={{ opacity: 0.95 }}>Showcase</span>
          <input type="checkbox" checked={showcase} onChange={(e) => setShowcase(e.target.checked)} />
        </label>
        <label style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <span style={{ opacity: 0.95 }}>Period</span>
          <input type="range" min={180} max={1400} step={10} value={periodMs} onChange={(e) => setPeriodMs(parseInt(e.target.value || "650", 10))} />
          <span style={{ fontFamily: "ui-monospace, SFMono-Regular, Menlo", opacity: 0.9 }}>{periodMs}ms</span>
        </label>
        <div style={{ fontFamily: "ui-monospace, SFMono-Regular, Menlo", opacity: 0.9 }}>
          seqIdx={seqIdx} nextBit={bitLabel(bitNow)} samples={samples.length} ticks={tickRef.current}
        </div>
      </div>

      <div style={{ marginTop: 12 }}>
        <Waveform samples={samples} playhead={playhead} phase={phase} />
      </div>

      <div style={{ marginTop: 14, display: "flex", gap: 12, flexWrap: "wrap", alignItems: "flex-start" }}>
        <div><SvgGraph outs={outs} /></div>
        <div style={{ flex: 1, minWidth: 360, display: "grid", gap: 12 }}>
          <div style={{ border: "1px solid #2a3a52", borderRadius: 12, padding: 12, background: "#070d16" }}>
            <div style={{ fontWeight: 700, marginBottom: 6 }}>Latest introspection snapshot</div>
            <pre style={{ margin: 0, fontSize: 12, whiteSpace: "pre-wrap", color: "#ffffff" }}>{JSON.stringify({
              tick: tickRef.current,
              phase,
              mode,
              d0,
              clk: clkVis,
              seq: (s as any).seq,
              outs,
            }, null, 2)}</pre>
          </div>

          <div style={{ border: "1px solid #2a3a52", borderRadius: 12, padding: 12, background: "#070d16" }}>
            <div style={{ fontWeight: 700, marginBottom: 6 }}>Execution trace ledger</div>
            <div style={{ maxHeight: 260, overflow: "auto", border: "1px solid #162235", borderRadius: 10 }}>
              <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12 }}>
                <thead>
                  <tr>
                    <th style={{ textAlign: "left", padding: 8, borderBottom: "1px solid #22314a" }}>tick</th>
                    <th style={{ textAlign: "left", padding: 8, borderBottom: "1px solid #22314a" }}>phase</th>
                    <th style={{ textAlign: "left", padding: 8, borderBottom: "1px solid #22314a" }}>D0</th>
                    <th style={{ textAlign: "left", padding: 8, borderBottom: "1px solid #22314a" }}>Q0</th>
                    <th style={{ textAlign: "left", padding: 8, borderBottom: "1px solid #22314a" }}>Q1</th>
                    <th style={{ textAlign: "left", padding: 8, borderBottom: "1px solid #22314a" }}>clk</th>
                    <th style={{ textAlign: "left", padding: 8, borderBottom: "1px solid #22314a" }}>mode</th>
                    <th style={{ textAlign: "left", padding: 8, borderBottom: "1px solid #22314a" }}>seqIdx</th>
                  </tr>
                </thead>
                <tbody>
                  {trace.slice().reverse().map((t) => (
                    <tr key={`tick-${t.tick}-${t.phase}`}>
                      <td style={{ padding: 8, borderBottom: "1px solid #162235", fontFamily: "ui-monospace, SFMono-Regular, Menlo" }}>{t.tick}</td>
                      <td style={{ padding: 8, borderBottom: "1px solid #162235", fontFamily: "ui-monospace, SFMono-Regular, Menlo" }}>{t.phase}</td>
                      <td style={{ padding: 8, borderBottom: "1px solid #162235", fontFamily: "ui-monospace, SFMono-Regular, Menlo" }}>{bitLabel(t.d0)}</td>
                      <td style={{ padding: 8, borderBottom: "1px solid #162235", fontFamily: "ui-monospace, SFMono-Regular, Menlo" }}>{bitLabel(t.q0)}</td>
                      <td style={{ padding: 8, borderBottom: "1px solid #162235", fontFamily: "ui-monospace, SFMono-Regular, Menlo" }}>{bitLabel(t.q1)}</td>
                      <td style={{ padding: 8, borderBottom: "1px solid #162235", fontFamily: "ui-monospace, SFMono-Regular, Menlo" }}>{bitLabel(t.clk)}</td>
                      <td style={{ padding: 8, borderBottom: "1px solid #162235", fontFamily: "ui-monospace, SFMono-Regular, Menlo" }}>{t.mode}</td>
                      <td style={{ padding: 8, borderBottom: "1px solid #162235", fontFamily: "ui-monospace, SFMono-Regular, Menlo" }}>{t.seqIdx}</td>
                    </tr>
                  ))}
                  {trace.length === 0 ? (
                    <tr>
                      <td colSpan={8} style={{ padding: 12, opacity: 0.8 }}>No ticks yet. Press Pulse or enable Showcase/Auto.</td>
                    </tr>
                  ) : null}
                </tbody>
              </table>
            </div>
          </div>

          <div style={{ border: "1px solid #2a3a52", borderRadius: 12, padding: 12, background: "#070d16" }}>
            <div style={{ fontWeight: 700, marginBottom: 6 }}>Latest trace entry</div>
            <pre style={{ margin: 0, fontSize: 12, whiteSpace: "pre-wrap", color: "#ffffff" }}>{JSON.stringify(latestTrace, null, 2)}</pre>
          </div>
        </div>
      </div>

      <div style={{ marginTop: 14 }}>
        <BoardPlanner seqText={seqText} q0={q0} q1={q1} d0={d0} phase={phase} mode={mode} />
      </div>
    </div>
  );
}
