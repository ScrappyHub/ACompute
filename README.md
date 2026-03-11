# ACompute

**ACompute** is a deterministic digital computation and circuit simulation instrument designed to make digital logic understandable, inspectable, and verifiable.

The system allows users to design circuits, simulate them step-by-step, inspect internal state, and visualize signal behavior through waveform traces.

ACompute also bridges digital simulation with **physical hardware design**, helping learners understand how logic maps to real electronic components and PCB layouts.

---

# Project Goals

ACompute exists to solve a major learning gap in digital electronics:

Most tools either simulate circuits **or** help design PCBs — but very few teach **how computation actually flows through hardware**.

ACompute focuses on:

* deterministic simulation
* full internal state introspection
* waveform visibility
* execution trace analysis
* educational signal explanation
* bridging logic simulation to PCB design

---

# Current Capabilities

The current prototype includes:

### Digital Logic Engine

A deterministic engine that evaluates logic graphs and sequential components.

Supports:

* combinational logic
* sequential elements
* clocked state transitions

---

### Waveform Visualization

Signals are recorded per tick and visualized as digital waveforms.

Examples:

```
clk
D0
Q0
Q1
```

This allows users to observe signal timing behavior over time.

---

### Execution Trace Ledger

Every simulation step produces a trace entry:

```
tick
phase
inputs
outputs
clock
mode
```

This creates a verifiable history of the system's execution.

---

### Full State Introspection

The simulator exposes the complete internal state at any tick.

Example:

```json
{
  "tick": 60,
  "phase": "low",
  "mode": "engine",
  "d0": 1,
  "clk": 0,
  "seq": {
    "Q0": 1,
    "Q1": 0
  },
  "outs": {
    "D0": 1,
    "Q0": 1,
    "D1": 1,
    "Q1": 0
  }
}
```

Nothing inside the simulation is hidden.

---

### Workbench / PCB Bridge

ACompute includes a hardware-education layer that maps logical signals to physical components.

Example system:

```
D0 → U1(D Flip-Flop) → U2(D Flip-Flop)
```

Board representation:

```
J1   Input Header
U1   D Flip-Flop
U2   D Flip-Flop
CLK  Clock generator
TP1  Probe Q0
TP2  Probe Q1
```

Net mapping:

```
NET_D0          J1.D0 → U1.D
NET_Q0_TO_U2D   U1.Q → U2.D
NET_CLK         CLK → U1.CLK / U2.CLK
```

This helps learners understand how digital systems translate into real hardware.

---

# Example Demonstration

The current demo simulates a **2-stage shift register**.

```
D0 → Q0 → Q1
```

Clock pulse:

```
clk: 0 → 1 → 0
```

Behavior:

* rising clock edge captures input
* data shifts through the register chain
* waveform and trace logs update in real time

---

# Roadmap

## Workbench v2

Interactive circuit design environment:

* drag-and-drop components
* wire connections
* signal highlighting
* probe system

---

## Verification Engine

Automated circuit validation:

* floating input detection
* combinational loop detection
* driver conflict detection
* clock domain checks

---

## PCB Bridge

Export designs for hardware implementation:

* netlist generation
* component mapping
* pin validation

---

## Educational Mode

Step-by-step explanations of digital logic behavior.

Example:

```
Clock rising edge detected
U1 captured D=1
Q0 updated to 1
```

---

# Project Structure

```
acompute
│
├─ app
│   ├─ src
│   │   ├─ acompute
│   │   │   ├─ core
│   │   │   ├─ engine
│   │   │   ├─ ui
│   │   │   └─ demos
│
├─ scripts
│   └─ _scratch
│
├─ docs
│
└─ README.md
```

---

# Why This Project Exists

Digital computation powers every modern device, yet most people never see how it actually works.

ACompute is designed to make computation **visible, inspectable, and understandable**.

Instead of treating circuits as black boxes, ACompute shows exactly how signals move through a system and how state evolves over time.

---

# Status

Early prototype.

Core simulation engine and visualization systems are operational.

Current milestone:

**Workbench v2 — interactive circuit design surface**

---

# License

License will be added once the first stable release is completed.
