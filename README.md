# ACompute

ACompute is a logic-computation and circuit-learning instrument for designing, simulating, inspecting, and teaching digital systems.

It is being built as an educational and engineering bridge between:

- logic simulation
- execution tracing and state introspection
- waveform and timing understanding
- workbench-style board planning
- future PCB design and verification surfaces

## Current Surface

The current working surface includes:

- graph-based logic demos
- sequential shift-register demonstration
- waveform strip visualization
- trace introspection ledger
- workbench / PCB educator bridge

## Direction

ACompute is intended to become a serious learner-to-builder instrument so users can:

- understand logic behavior before hardware layout
- inspect full internal state transitions
- map nets, stages, probes, and clocks to physical boards
- design and verify PCB-oriented logic systems with confidence

## Repository Layout

- app/: UI and simulation surface
- SPEC/: canonical project specification
- WBS/: work breakdown structure and progress ledger
- scripts/: deterministic PowerShell runners, selftests, and repair surfaces
- proofs/: trust and receipt artifacts

## Current Documentation

- SPEC/ACompute_SPEC_v1.md
- WBS/WBS_v1.md
- WBS/PROGRESS_LEDGER_v1.md
- docs/ACOMPUTE_SPEC.md
- docs/ACOMPUTE_WBS.md
- docs/ENGINE_MODEL.md
- docs/WORKBENCH_SPEC.md
- docs/PCB_BRIDGE_SPEC.md

## Notes

- Public repository text avoids internal tier terminology.
- Deterministic scripting and explicit evidence remain core project rules.
