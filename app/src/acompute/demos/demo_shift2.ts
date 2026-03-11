export type Node = { id: string; label: string; x: number; y: number };
export type Edge = { id: string; from: string; to: string };

export type DemoGraph = {
  nodes: Node[];
  edges: Edge[];
};

// Visual-only graph for the panel.
export const demoShift2: DemoGraph = {
  nodes: [
    { id: "D0", label: "D0", x: 80,  y: 60 },
    { id: "Q0", label: "Q0", x: 260, y: 60 },
    { id: "D1", label: "D1", x: 260, y: 160 },
    { id: "Q1", label: "Q1", x: 440, y: 160 },
  ],
  edges: [
    { id: "e0", from: "D0", to: "Q0" },
    { id: "e1", from: "Q0", to: "D1" },
    { id: "e2", from: "D1", to: "Q1" },
  ],
};
