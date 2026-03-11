import { initialState } from "../core/state";
import { demoNot } from "../demos/demo_not";
import { evalGraph } from "./eval";
import type { Bit } from "../core/types";

function expect(name: string, got: Bit, want: Bit) {
  if (got !== want) {
    throw new Error(`ASSERT_FAIL ${name}: got=${got} want=${want}`);
  }
}

export function runDemoNot(): void {
  const prev = initialState();
  const out0 = evalGraph(prev, demoNot, { A: 0 });
  const out1 = evalGraph(prev, demoNot, { A: 1 });
  console.log("DEMO_NOT A=0 => Y=", out0["Y"]);
  console.log("DEMO_NOT A=1 => Y=", out1["Y"]);
  expect("NOT(0)", (out0["Y"] ?? 0) as Bit, 1);
  expect("NOT(1)", (out1["Y"] ?? 0) as Bit, 0);
}

// Allow direct execution in future bundlers; harmless if imported.
try {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const g: any = (globalThis as any);
  if (g && g.__ACOMPUTE_AUTO_RUN__ === true) { runDemoNot(); }
} catch { /* ignore */ }
