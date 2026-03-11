import type { Bit } from "./types";
import type { SimState } from "./state";
import type { DemoGraph } from "../demos/demo_shift2";
import { evalGraph } from "../engine/eval";

// Rising-edge capture for a 2-stage shift register:
// Q0 <= D0, Q1 <= prior Q0
export function transition(s: SimState, g: DemoGraph, inputs: { D0: Bit }, nextClk: Bit): SimState {
  const prevClk = s.clk;
  const rising = prevClk === 0 && nextClk === 1;
  if (!rising) {
    return { ...s, clk: nextClk };
  }
  const outs = evalGraph(s, g, inputs);
  const nextQ0 = inputs.D0;
  const nextQ1 = outs["Q0"] ?? 0;
  return {
    clk: nextClk,
    seq: {
      Q0: nextQ0,
      Q1: nextQ1,
    },
  };
}
