import type { Bit } from "./types";

export type SeqState = {
  Q0: Bit;
  Q1: Bit;
};

export type SimState = {
  clk: Bit;
  seq: SeqState;
};

export function initialState(): SimState {
  return {
    clk: 0,
    seq: { Q0: 0, Q1: 0 },
  };
}
