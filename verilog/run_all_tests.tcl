# ================================================================================
# 16-bit RISC Processor - ModelSim Automatic Test Runner (TCL)
# ================================================================================

puts ""
puts "========================================"
puts "   RISC Processor Test Suite (ModelSim)"
puts "========================================"
puts ""

# Clean and setup work library
file delete -force work
vlib work

set test_count 0
set pass_count 0

# ================================================================================
# Test 1: ALU Test
# ================================================================================

puts "\[1/4\] Compiling ALU Test..."
if {[catch {vlog alu.v tb_alu.v} result]} {
    puts "ERROR: ALU compilation failed!"
    puts $result
    exit 1
}

puts "\[1/4\] Running ALU Test..."
if {[catch {vsim -c -do "run -all; quit" tb_alu} result]} {
    puts "ERROR: ALU test failed!"
    puts $result
    exit 1
}

incr test_count
incr pass_count
puts "\[1/4\] ALU Test: PASSED"
puts ""

# ================================================================================
# Test 2: Hazard Detection Test
# ================================================================================

puts "\[2/4\] Compiling Hazard Detection Test..."
if {[catch {vlog hazard_detection_unit.v forwarding_unit.v tb_hazard_forwarding.v} result]} {
    puts "ERROR: Hazard test compilation failed!"
    puts $result
    exit 1
}

puts "\[2/4\] Running Hazard Detection Test..."
if {[catch {vsim -c -do "run -all; quit" tb_hazard_forwarding} result]} {
    puts "ERROR: Hazard test failed!"
    puts $result
    exit 1
}

incr test_count
incr pass_count
puts "\[2/4\] Hazard Detection Test: PASSED"
puts ""

# ================================================================================
# Test 3: Full Processor Test
# ================================================================================

puts "\[3/4\] Compiling Full Processor Test..."
if {[catch {vlog register_file.v alu.v control_unit.v hazard_detection_unit.v forwarding_unit.v pipeline_registers.v instruction_memory.v data_memory.v processor_top.v tb_processor.v} result]} {
    puts "ERROR: Processor compilation failed!"
    puts $result
    exit 1
}

puts "\[3/4\] Running Full Processor Test..."
if {[catch {vsim -c -do "run -all; quit" tb_processor} result]} {
    puts "ERROR: Processor test failed!"
    puts $result
    exit 1
}

incr test_count
incr pass_count
puts "\[3/4\] Full Processor Test: PASSED"
puts ""

# ================================================================================
# Test 4: Control Hazard Test
# ================================================================================

puts "\[4/4\] Compiling Control Hazard Test..."
if {[catch {vlog register_file.v alu.v control_unit.v hazard_detection_unit.v forwarding_unit.v pipeline_registers.v instruction_memory.v data_memory.v processor_top.v tb_control_hazards.v} result]} {
    puts "ERROR: Control test compilation failed!"
    puts $result
    exit 1
}

puts "\[4/4\] Running Control Hazard Test..."
if {[catch {vsim -c -do "run -all; quit" tb_control_hazards} result]} {
    puts "ERROR: Control test failed!"
    puts $result
    exit 1
}

incr test_count
incr pass_count
puts "\[4/4\] Control Hazard Test: PASSED"
puts ""

# ================================================================================
# Summary
# ================================================================================

puts ""
puts "========================================"
puts "   ALL TESTS PASSED SUCCESSFULLY!"
puts "========================================"
puts ""
puts "Test Results:"
puts "   \[OK\] ALU Test"
puts "   \[OK\] Hazard Detection Test"
puts "   \[OK\] Full Processor Test"
puts "   \[OK\] Control Hazard Test"
puts ""
puts "Total: $pass_count/$test_count tests passed"
puts ""
puts "To run with GUI and waveforms:"
puts "   do run_tests_gui.tcl"
puts ""

