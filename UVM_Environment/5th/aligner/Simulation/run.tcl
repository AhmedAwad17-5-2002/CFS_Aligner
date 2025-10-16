# ----------------------------------------------------------------------
# Questa DO-file - Robust UVM-1.2 Regression Script
# ----------------------------------------------------------------------
set DESIGN_PATH "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/Design"
set TB_PATH     "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB"
set WORK_DIR    "work"
set SIM_DIR     "Simulation_Reports"
set UVM_VER     "uvm-1.2"

# Multi-iteration test list / iterations
set multi_iter_tests {
    test_reg_access
    md_random_test
    algn_test_random_rx_err
}
set iterations_num 1
set top_module "TB"

# ----------------------------------------------------------------------
# Prepare work lib and simulation dir
# ----------------------------------------------------------------------
vlib $WORK_DIR
if {![file exists $WORK_DIR]} { vlib $WORK_DIR }
vmap $WORK_DIR $WORK_DIR

file mkdir $SIM_DIR

# -------- Create Timestamped Subfolder --------
set timestamp [clock format [clock seconds] -format "%Y_%m_%d_%H%M"]
set RUN_DIR [file join $SIM_DIR $timestamp]
file mkdir $RUN_DIR

# -------- Redirect transcript --------
transcript file [file join $RUN_DIR transcript.log]
transcript on

# ----------------------------------------------------------------------
# Compile Design and TB
# ----------------------------------------------------------------------
vlog $DESIGN_PATH/design.sv +cover -covercells

vlog +incdir+C:/questasim64_2021.1/verilog_src/uvm-1.2/src \
     C:/questasim64_2021.1/verilog_src/uvm-1.2/src/uvm_macros.svh \
     C:/questasim64_2021.1/verilog_src/uvm-1.2/src/uvm_pkg.sv \
     +incdir+C:/questasim64_2021.1/verilog_src/questa_uvm_pkg-1.2/src \
     C:/questasim64_2021.1/verilog_src/questa_uvm_pkg-1.2/src/questa_uvm_pkg.sv \
     $TB_PATH/TB.sv +cover -covercells
  

# ----------------------------------------------------------------------
# Run tests (multi-iteration loop)
# ----------------------------------------------------------------------
for {set j 0} {$j < $iterations_num} {incr j} {
    foreach test_file $multi_iter_tests {
        puts "Running multi-iteration test: $test_file (Iteration $j)"
        set cov_file        [file join $RUN_DIR "${test_file}_iter${j}.ucdb"]
        set cvg_asser_file  [file join $RUN_DIR "${test_file}_iter${j}_cvg_asser.ucdb"]

        vsim -voptargs="+acc" -coverage -cvgperinstance work.$top_module +UVM_TESTNAME=$test_file -sv_seed random -f $TB_PATH/messages.f \
        -do "
            set NoQuitOnFinish 1
            log /* -r
            run -all
            coverage save $cov_file -instance TB/DUT
            coverage save $cvg_asser_file -cvg -assert
            quit -sim
        "
    }
}

# ----------------------------------------------------------------------
# Merge coverage results
# ----------------------------------------------------------------------
set merged_cov_file        [file join $RUN_DIR "full_coverage.ucdb"]
set merged_cvg_asser_file  [file join $RUN_DIR "full_cvg_asser.ucdb"]

for {set j 0} {$j < $iterations_num} {incr j} {
    foreach test_file $multi_iter_tests {
        set f1 $merged_cov_file
        set f2 [file join $RUN_DIR "${test_file}_iter${j}.ucdb"]
        if {[file exists $f2]} {
            vcover merge -out $merged_cov_file $f1 $f2
        }

        set g1 $merged_cvg_asser_file
        set g2 [file join $RUN_DIR "${test_file}_iter${j}_cvg_asser.ucdb"]
        if {[file exists $g2]} {
            vcover merge -out $merged_cvg_asser_file $g1 $g2
        }
    }
}

# ----------------------------------------------------------------------
# Generate coverage reports
# ----------------------------------------------------------------------
vcover report $merged_cov_file -details -all -annotate -output [file join $RUN_DIR "Coverage.txt"]
vcover report $merged_cov_file -summary -output [file join $RUN_DIR "Coverage_Summary.txt"]
vcover report $merged_cvg_asser_file -details -all -annotate -output [file join $RUN_DIR "cvg_asser_Coverage.txt"]
vcover report $merged_cvg_asser_file -summary -output [file join $RUN_DIR "cvg_asser_Coverage_Summary.txt"]

puts "✅ All coverage reports are available in: $RUN_DIR/"
quit
# ----------------------------------------------------------------------
