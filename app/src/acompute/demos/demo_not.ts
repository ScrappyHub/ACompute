import type { Graph } from "../graph/graph";

export const demoNot: Graph = {
  nodes: [
    { id: "A", kind: "input", label: "A", x: 40, y: 80 },
    { id: "Y", kind: "gate", label: "NOT", op: "NOT", x: 220, y: 80 }
  ],
  edges: [
    { id: "e1", from: "A", to: "Y", inputIndex: 0 }
  ]
};
