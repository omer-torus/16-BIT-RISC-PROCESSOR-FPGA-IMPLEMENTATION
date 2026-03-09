# ================================================================================
# ModelSim Simulation Script - Full Processor Test
# ================================================================================

echo ""
echo "========================================"
echo "   16-bit RISC Processor Simulation"
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
    tb_processor.v

if {[file exists cpu_top.v]} {
    vlog -reportprogress 300 -work work cpu_top.v
}

# Check for compilation errors
if {[catch {vlog -work work}]} {
    echo "ERROR: Compilation failed!"
    quit -f
}

echo "Compilation successful!"
echo ""

# Start simulation
echo "Starting simulation..."
vsim -voptargs=+acc work.tb_processor

# Add waves
add wave -position insertpoint  \
    sim:/tb_processor/clk \
    sim:/tb_processor/rst \
    sim:/tb_processor/pc \
    sim:/tb_processor/instruction \
    sim:/tb_processor/stall \
    sim:/tb_processor/cycle_count

add wave -position insertpoint -radix hexadecimal \
    sim:/tb_processor/uut/regfile/registers

add wave -position insertpoint -radix hexadecimal \
    sim:/tb_processor/uut/dmem/memory

# Run simulation
echo "Running simulation..."
run -all

echo ""
echo "========================================"
echo "   Simulation Complete!"
echo "========================================"
echo ""
echo "To view waveforms: view wave"
echo "To quit: quit"
echo ""

