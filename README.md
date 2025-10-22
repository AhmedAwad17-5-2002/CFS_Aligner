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
Place the `regression.tcl` (the DO-file) at the root of the 
---

## Script configuration variables
Edit the top of `regression.tcl` to match your environment:

- `DESIGN_PATH` — path to design files (e.g. `.../Design`)  
- `TB_PATH` — path to testbench files (e.g. `.../TB`)  
- `WORK_DIR` — simulation work library (default: `work`)  
- `SIM_DIR` — parent folder for run results (default: `Simulation_Reports`)  
- `UVM_VER` — UVM version label used (example: `uvm-1.2`)  
- `multi_iter_tests` — TCL list of UVM test names to run, e.g.  
  ```tcl
  set multi_iter_tests {
      test_reg_access
      md_random_test
      algn_test_random_rx_err
  }
 folder.


