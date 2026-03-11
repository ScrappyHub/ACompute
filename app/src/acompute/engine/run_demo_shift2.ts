import type { Bit } from "../core/types";
import { initialState } from "../core/state";
import { evalGraph } from "./eval";
import { transition } from "../core/transition";
import { demoShift2 } from "../demos/demo_shift2";

function expect(name: string, got: Bit, want: Bit){ if(got !== want){ throw new Error(`EXPECT_FAIL ${name}: got=${got} want=${want}`); } }

export function runDemoShift2(){
  let s = initialState();
  # Step 1 (rising): D0=1 => Q0 captures 1, Q1 captures old Q0(0)
  s = transition(s, demoShift2, { D0: 1 }, 1 as Bit);
  const o1 = evalGraph(s, demoShift2, { D0: 1 });
  console.log("SHIFT2 step1 Q0=", o1["Q0"], "Q1=", o1["Q1"]);
  expect("step1 Q0", (o1["Q0"] ?? 0) as Bit, 1);
  expect("step1 Q1", (o1["Q1"] ?? 0) as Bit, 0);

  # Step 2 (rising): D0=0 => Q0 captures 0, Q1 captures previous Q0(1)
  s = transition(s, demoShift2, { D0: 0 }, 1 as Bit);
  const o2 = evalGraph(s, demoShift2, { D0: 0 });
  console.log("SHIFT2 step2 Q0=", o2["Q0"], "Q1=", o2["Q1"]);
  expect("step2 Q0", (o2["Q0"] ?? 0) as Bit, 0);
  expect("step2 Q1", (o2["Q1"] ?? 0) as Bit, 1);
}
