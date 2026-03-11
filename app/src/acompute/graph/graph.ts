import type { NodeId, EdgeId, NodeKind, GateOp } from "../core/types";

export type Node = {
  id: NodeId;
  kind: NodeKind;
  label: string;
  op?: GateOp;
  x: number; y: number;
};

export type Edge = { id: EdgeId; from: NodeId; to: NodeId; inputIndex: number };
export type Graph = { nodes: Node[]; edges: Edge[] };
