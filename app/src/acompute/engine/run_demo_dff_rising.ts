import { initialState } from "../core/state";
import { demoDffRising } from "../demos/demo_dff_rising";
import { transition } from "../core/transition";
import type { Bit } from "../core/types";

function expect(name: string, got: Bit, want: Bit) {
  if (got !== want) throw new Error(`ASSERT_FAIL ${name}: got=${got} want=${want}`);
}

export function runDemoDffRising(): void {
  // Start: Q=0 (default)
  let st = initialState();
  // Hold clk low: changing D should NOT update Q
  st = transition(st, demoDffRising, { D: 1 }, 0);
  expect("Q still 0 (no rising edge)", (st.seq["Q"] ?? 0) as Bit, 0);
  // Rising edge: clk 0 -> 1 captures D=1 into Q
  st = transition(st, demoDffRising, { D: 1 }, 1);
  expect("Q captured 1 (rising edge)", (st.seq["Q"] ?? 0) as Bit, 1);
  // Hold high or fall: should not recapture
  st = transition(st, demoDffRising, { D: 0 }, 1);
  expect("Q remains 1 (clk high)", (st.seq["Q"] ?? 0) as Bit, 1);
  st = transition(st, demoDffRising, { D: 0 }, 0);
  expect("Q remains 1 (falling edge)", (st.seq["Q"] ?? 0) as Bit, 1);
  console.log("DEMO_DFF_RISING OK");
}
