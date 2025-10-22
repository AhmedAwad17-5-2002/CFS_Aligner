# Questa UVM Regression Script — Aligner Project

This repository contains a **QuestaSim** TCL DO-file (`regression.tcl`) that automates a UVM-1.2 regression flow for the **Aligner DUT**.  

The script compiles design and testbench sources, runs a configurable list of UVM tests (with optional iterations), collects per-test coverage, merges coverage results, and generates coverage reports inside a timestamped output folder.

---

## Table of Contents
- [Prerequisites](#prerequisites)
- [Repository layout](#repository-layout)
- [Script configuration variables](#script-configuration-variables)
- [Quick start — How to run](#quick-start--how-to-run)
- [What the script does](#what-the-script-does)
- [Generated outputs](#generated-outputs)
- [Troubleshooting & tips](#troubleshooting--tips)
- [Customization examples](#customization-examples)
- [Author & License](#author--license)

---

## Prerequisites
- **QuestaSim (ModelSim/Questa)** with UVM 1.2 support (tested with QuestaSim 2021.1+).  
- Proper **UVM sources** (`uvm_pkg.sv`, `uvm_macros.svh`) accessible from the include paths used in the script.  
- Permissions to create directories and write files under the repository.

---

## Repository layout
Place the `regression.tcl` (the DO-file) at the root of the testbench folder.

Expected layout:
UVM_Environment/
└── 5th/
└── aligner/
├── Design/
│ └── design.sv
├── TB/
│ ├── TB.sv
│ └── messages.f
├── regression.tcl # <- this script
└── Simulation_Reports/ # created automatically if missing
