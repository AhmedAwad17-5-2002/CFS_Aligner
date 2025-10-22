Here’s your `README.md` file — perfectly formatted and ready to drop into your repo:

---

```markdown
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
```

UVM_Environment/
└── 5th/
└── aligner/
├── Design/
│   └── design.sv
├── TB/
│   ├── TB.sv
│   └── messages.f
├── regression.tcl       # <- this script
└── Simulation_Reports/  # created automatically if missing

````

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
````

* `iterations_num` — number of iterations per test (use >1 for multiple random seeds)
* `top_module` — top-level testbench module name (example: `TB`)

---

## Quick start — How to run

1. Open **QuestaSim** (or launch the `vsim` terminal).
2. From the transcript or command window, run:

   ```tcl
   do regression.tcl
   ```

The script will:

* create `work` library and `Simulation_Reports/<timestamp>/` folder
* compile design and TB sources
* run each test listed in `multi_iter_tests` for `iterations_num` iterations
* save per-test coverage UCDBs
* merge UCDBs into `full_coverage.ucdb` and `full_cvg_asser.ucdb`
* generate textual coverage reports

---

## What the script does (summary)

* `vlib` / `vmap` work library setup
* Creates timestamped run directory `Simulation_Reports/YYYY_MM_DD_HHMM/`
* Compiles `design.sv`, UVM sources, and `TB.sv` (using `vlog`)
* Loops tests × iterations; for each run it calls `vsim -coverage` with:

  * `+UVM_TESTNAME=<testname>`
  * `-sv_seed random` (for randomized runs)
  * Redirects transcript to `transcript.log`
  * Saves UCDB coverage files per test/iteration
* Uses `vcover merge` to combine per-test UCDBs
* Runs `vcover report` to produce detailed & summary coverage text files

---

## Generated outputs

All outputs are placed under:

```
Simulation_Reports/<YYYY_MM_DD_HHMM>/
```

Common files:

* `transcript.log` — full simulation transcript from runs
* `<test>_iter<k>.ucdb` — per-test, per-iteration coverage DBs
* `full_coverage.ucdb` — merged functional coverage DB
* `full_cvg_asser.ucdb` — merged assertion coverage DB
* `Coverage.txt` — detailed functional coverage report (annotated)
* `Coverage_Summary.txt` — summary of functional coverage
* `cvg_asser_Coverage.txt` — detailed assertion coverage report
* `cvg_asser_Coverage_Summary.txt` — assertion coverage summary

---

## Troubleshooting & tips

* **vlog include errors**
  Ensure `+incdir` paths point to valid UVM/Questa UVM pkg locations and that `uvm_pkg.sv` and `uvm_macros.svh` exist.

* **work library not found**
  The script attempts `vlib $WORK_DIR` and `vmap` automatically. Check write permissions.

* **Coverage merge warnings**
  Ensure UCDBs exist before merging. If a run fails early, its UCDB may be missing — check `transcript.log`.

* **Increase test randomness**
  Increase `iterations_num` or set `-sv_seed <fixed|random>` per run.
  For reproducibility use a fixed seed (e.g., `-sv_seed 12345`).

* **Run a single test**
  Change `multi_iter_tests` to a single-item list.

* **Questa/ModelSim versions**
  Behavior/flags can differ slightly across versions — adjust `-voptargs` or coverage flags if needed.

---

## Customization examples

**Run single test:**

```tcl
set multi_iter_tests { md_random_test }
set iterations_num 1
```

**Run 5 iterations:**

```tcl
set iterations_num 5
```

**Use a fixed seed for reproducibility (modify `vsim` call inside script):**

```tcl
... -sv_seed 12345 ...
```

---

## Author

**Ahmed Awad-Allah Mohamed**
Aligner UVM Environment — Regression Script (2025)

---

## License

Add a `LICENSE` file of your choice (e.g. MIT) or remove this section if you prefer to keep the repository proprietary.

```

---

Would you like me to generate the `.md` file for download (e.g. `README.md`) or also create an Arabic version (`README_AR.md`)?
```
