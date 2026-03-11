import type { Graph } from "../graph/graph";

// DFF Rising-Edge Demo
//  - Input D feeds DFF
//  - DFF output Q is the stored value (prev.seq["Q"])
//  - transition() updates Q only on rising edge (clk: 0 -> 1)

export const demoDffRising: Graph = {
  nodes: [
    { id: "D", kind: "input" },
    { id: "Q", kind: "dff" },
  ],
  edges: [
    { from: "D", to: "Q", inputIndex: 0 },
  ],
};
