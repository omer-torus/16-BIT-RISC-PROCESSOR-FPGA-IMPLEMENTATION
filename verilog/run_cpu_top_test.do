# ================================================================================
# ModelSim Simulation Script - CPU Top Hazard Test
# ================================================================================

echo ""
echo "========================================"
echo "   CPU Top - Hazard Management Test"
echo "========================================"
echo ""

# Clean and create work library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile all source files
echo "Compiling Verilog source files..."
vlog -reportprogress 300 -work work \
    register_file.v \
    alu.v \
    control_unit.v \
    hazard_detection_unit.v \
    forwarding_unit.v \
    pipeline_registers.v \
    instruction_memory.v \
    data_memory.v \
    processor_top.v \
    cpu_top.v \
    tb_cpu_top.v

# Check for compilation errors
if {[catch {vlog -work work}]} {
    echo "ERROR: Compilation failed!"
    quit -f
}

echo "Compilation successful!"
echo ""

# Start simulation
echo "Starting simulation..."
vsim -voptargs=+acc work.tb_cpu_top

# Add waves for debugging
add wave -position insertpoint  \
    sim:/tb_cpu_top/clk \
    sim:/tb_cpu_top/rst

add wave -divider "Register File"
add wave -position insertpoint -radix unsigned \
    sim:/tb_cpu_top/dut/u_regfile/registers

add wave -divider "Instruction Memory"
add wave -position insertpoint -radix hexadecimal \
    sim:/tb_cpu_top/dut/u_imem/memory

add wave -divider "Control Signals"
add wave -position insertpoint \
    sim:/tb_cpu_top/dut/stall \
    sim:/tb_cpu_top/dut/flush \
    sim:/tb_cpu_top/dut/pc

add wave -divider "Forwarding"
add wave -position insertpoint \
    sim:/tb_cpu_top/dut/forward_a \
    sim:/tb_cpu_top/dut/forward_b

# Run simulation
echo "Running simulation..."
run -all

echo ""
echo "========================================"
echo "   Simulation Complete!"
echo "========================================"
echo ""
echo "Check the test results above."
echo "To view waveforms: view wave"
echo "To quit: quit"
echo ""

