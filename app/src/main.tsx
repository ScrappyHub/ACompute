import React from "react";
import { createRoot } from "react-dom/client";
import { DemoShift2Panel } from "./acompute/ui/DemoShift2Panel";

const el = document.getElementById("root");
if (!el) {
  throw new Error("Missing #root");
}

createRoot(el).render(
  <React.StrictMode>
    <DemoShift2Panel />
  </React.StrictMode>
);
