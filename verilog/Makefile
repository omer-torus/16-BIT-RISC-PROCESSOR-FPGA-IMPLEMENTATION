# Makefile for RISC Processor Verilog Simulation
# Requires Icarus Verilog (iverilog) and GTKWave

# Compiler
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Compiler flags
IFLAGS = -g2012  # SystemVerilog 2012 support
WFLAGS = -Wall   # All warnings

# Source files
SOURCES = register_file.v \
          alu.v \
          control_unit.v \
          hazard_detection_unit.v \
          forwarding_unit.v \
          pipeline_registers.v \
          instruction_memory.v \
          data_memory.v \
          processor_top.v

# Test benches
TB_PROCESSOR = tb_processor.v
TB_ALU = tb_alu.v
TB_HAZARD = tb_hazard_forwarding.v
TB_CONTROL = tb_control_hazards.v
TB_PIPELINE = tb_pipeline_visualization.v

# Output files
OUT_PROCESSOR = processor_test.out
OUT_ALU = alu_test.out
OUT_HAZARD = hazard_test.out
OUT_CONTROL = control_test.out
OUT_PIPELINE = pipeline_test.out

# VCD files
VCD_PROCESSOR = processor_test.vcd
VCD_CONTROL = control_hazards.vcd
VCD_PIPELINE = pipeline_viz.vcd

# Default target
all: processor

# Compile and run full processor test
processor: $(SOURCES) $(TB_PROCESSOR)
	@echo "========================================="
	@echo "  Compiling Processor Test Bench"
	@echo "========================================="
	$(IVERILOG) $(IFLAGS) $(WFLAGS) -o $(OUT_PROCESSOR) $(SOURCES) $(TB_PROCESSOR)
	@echo ""
	@echo "========================================="
	@echo "  Running Processor Simulation"
	@echo "========================================="
	$(VVP) $(OUT_PROCESSOR)
	@echo ""
	@echo "Waveform saved to $(VCD_PROCESSOR)"
	@echo "View with: make view-processor"

# Compile and run ALU test
alu: alu.v $(TB_ALU)
	@echo "========================================="
	@echo "  Compiling ALU Test Bench"
	@echo "========================================="
	$(IVERILOG) $(IFLAGS) $(WFLAGS) -o $(OUT_ALU) alu.v $(TB_ALU)
	@echo ""
	@echo "========================================="
	@echo "  Running ALU Test"
	@echo "========================================="
	$(VVP) $(OUT_ALU)

# Compile and run hazard detection test
hazard: hazard_detection_unit.v forwarding_unit.v $(TB_HAZARD)
	@echo "========================================="
	@echo "  Compiling Hazard Detection Test"
	@echo "========================================="
	$(IVERILOG) $(IFLAGS) $(WFLAGS) -o $(OUT_HAZARD) hazard_detection_unit.v forwarding_unit.v $(TB_HAZARD)
	@echo ""
	@echo "========================================="
	@echo "  Running Hazard Detection Test"
	@echo "========================================="
	$(VVP) $(OUT_HAZARD)

# Compile and run control hazard test
control: $(SOURCES) $(TB_CONTROL)
	@echo "========================================="
	@echo "  Compiling Control Hazard Test"
	@echo "========================================="
	$(IVERILOG) $(IFLAGS) $(WFLAGS) -o $(OUT_CONTROL) $(SOURCES) $(TB_CONTROL)
	@echo ""
	@echo "========================================="
	@echo "  Running Control Hazard Test"
	@echo "========================================="
	$(VVP) $(OUT_CONTROL)
	@echo ""
	@echo "Waveform saved to $(VCD_CONTROL)"
	@echo "View with: make view-control"

# Compile and run pipeline visualization test
pipeline: $(SOURCES) $(TB_PIPELINE)
	@echo "========================================="
	@echo "  Compiling Pipeline Visualization Test"
	@echo "========================================="
	$(IVERILOG) $(IFLAGS) $(WFLAGS) -o $(OUT_PIPELINE) $(SOURCES) $(TB_PIPELINE)
	@echo ""
	@echo "========================================="
	@echo "  Running Pipeline Visualization"
	@echo "========================================="
	$(VVP) $(OUT_PIPELINE)
	@echo ""
	@echo "Waveform saved to $(VCD_PIPELINE)"
	@echo "View with: make view-pipeline"

# Run all tests
test-all: alu hazard processor control pipeline
	@echo ""
	@echo "========================================="
	@echo "  All Tests Completed Successfully!"
	@echo "========================================="

# View waveforms
view-processor:
	$(GTKWAVE) $(VCD_PROCESSOR) &

view-control:
	$(GTKWAVE) $(VCD_CONTROL) &

view-pipeline:
	$(GTKWAVE) $(VCD_PIPELINE) &

# Syntax check only (no simulation)
check:
	@echo "Checking syntax of all Verilog files..."
	$(IVERILOG) $(IFLAGS) -t null $(SOURCES)
	@echo "Syntax check passed!"

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	rm -f *.out
	rm -f *.vcd
	rm -f *.lxt
	rm -f *.vvp
	@echo "Clean complete!"

# Help
help:
	@echo "========================================="
	@echo "  RISC Processor Makefile Help"
	@echo "========================================="
	@echo ""
	@echo "Available targets:"
	@echo "  make processor      - Run full processor test"
	@echo "  make alu            - Run ALU test"
	@echo "  make hazard         - Run hazard detection test"
	@echo "  make control        - Run control hazard test"
	@echo "  make pipeline       - Run pipeline visualization test"
	@echo "  make test-all       - Run all tests"
	@echo "  make check          - Syntax check only"
	@echo "  make clean          - Remove generated files"
	@echo "  make view-processor - View processor waveform"
	@echo "  make view-control   - View control hazard waveform"
	@echo "  make view-pipeline  - View pipeline waveform"
	@echo "  make help           - Show this help"
	@echo ""
	@echo "Requirements:"
	@echo "  - Icarus Verilog (iverilog)"
	@echo "  - GTKWave (for waveform viewing)"
	@echo ""

.PHONY: all processor alu hazard control pipeline test-all check clean help \
        view-processor view-control view-pipeline

