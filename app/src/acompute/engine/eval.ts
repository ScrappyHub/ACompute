import type { Bit } from "../core/types";
import type { SimState } from "../core/state";
import type { DemoGraph } from "../demos/demo_shift2";

export type Outs = Record<string, Bit>;

// For this MVP, outs are just the inputs + current sequential Qs.
export function evalGraph(s: SimState, _g: DemoGraph, inputs: { D0: Bit }): Outs {
  const outs: Outs = {};
  outs["D0"] = inputs.D0;
  outs["Q0"] = s.seq.Q0;
  outs["D1"] = s.seq.Q0;
  outs["Q1"] = s.seq.Q1;
  return outs;
}
