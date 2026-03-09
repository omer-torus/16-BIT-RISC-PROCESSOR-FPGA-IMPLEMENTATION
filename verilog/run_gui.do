# ================================================================================
# ModelSim GUI Simulation Script
# Use this to run with GUI and see waveforms
# ================================================================================

echo ""
echo "========================================"
echo "   ModelSim GUI Mode"
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
    cpu_top.v

# Compile testbenches
vlog -reportprogress 300 -work work \
    tb_processor.v \
    tb_cpu_top.v \
    tb_alu.v \
    tb_control_hazards.v \
    tb_hazard_forwarding.v

echo ""
echo "Compilation successful!"
echo ""
echo "Available testbenches:"
echo "  1. tb_processor           - Full processor test (Fibonacci)"
echo "  2. tb_cpu_top             - Hazard management test"
echo "  3. tb_alu                 - ALU test"
echo "  4. tb_control_hazards     - Control hazards test"
echo "  5. tb_hazard_forwarding   - Hazard & forwarding test"
echo ""
echo "To start simulation, use:"
echo "  vsim work.tb_processor"
echo "  vsim work.tb_cpu_top"
echo "  etc."
echo ""

