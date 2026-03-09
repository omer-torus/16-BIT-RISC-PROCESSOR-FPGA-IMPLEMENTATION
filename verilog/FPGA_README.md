# 16-Bit RISC Processor — Verilog and FPGA Implementation

This folder contains the complete Verilog RTL implementation of the 16-bit RISC processor, along with FPGA deployment files targeting the Gowin Tang Nano 9K board.

*Computer Organization Course — 2025/2026 Fall Semester*

---

## Table of Contents

- [File Overview](#file-overview)
- [Simulation with Icarus Verilog](#simulation-with-icarus-verilog)
- [Simulation with ModelSim](#simulation-with-modelsim)
- [FPGA Deployment](#fpga-deployment)
- [Expected Test Results](#expected-test-results)
- [Waveform Analysis](#waveform-analysis)
- [Troubleshooting](#troubleshooting)

---

## File Overview

### Core Processor Modules

| File | Description |
|------|-------------|
| `defines.vh` | Global constants, opcodes, and parameters |
| `processor_top.v` | Top-level processor module (for simulation) |
| `fpga_top.v` | FPGA top module — integrates CPU, HDMI, and button logic |
| `cpu_top.v` | CPU core with full debug output port |
| `alu.v` | Arithmetic Logic Unit (ADD, SUB, AND, OR, SLT, SLL, SRL) |
| `control_unit.v` | Instruction decoder — generates all control signals |
| `register_file.v` | 8 x 16-bit register file (R0 hardwired to 0) |
| `pipeline_registers.v` | IF/ID, ID/EX, EX/MEM, MEM/WB pipeline registers |
| `hazard_detection_unit.v` | Detects load-use hazards, generates stall signal |
| `forwarding_unit.v` | Data forwarding from EX/MEM and MEM/WB to EX stage |
| `instruction_memory.v` | 256-word instruction ROM with built-in test programs |
| `data_memory.v` | 256-word data RAM |

### FPGA Display Modules

| File | Description |
|------|-------------|
| `fpga_top.v` | Button debounce, clock gating, step/auto mode control |
| `debug_hud.v` | Generates the full debug display for HDMI output |
| `hdmi_top.v` | TMDS encoder and HDMI signal generator (640x480 60Hz) |
| `font_min.v` | Embedded 8x8 pixel font used by the debug HUD |

### Testbenches

| File | What it tests |
|------|---------------|
| `tb_processor.v` | Full processor execution with register/memory checks |
| `tb_cpu_top.v` | CPU top with debug interface |
| `tb_alu.v` | All ALU operations individually |
| `tb_hazard_forwarding.v` | Load-use stall and forwarding paths |
| `tb_control_hazards.v` | Branch taken/not-taken and jump instructions |
| `tb_pipeline_visualization.v` | Prints pipeline stage activity cycle by cycle |

### FPGA Constraint Files

| File | Description |
|------|-------------|
| `tangnano9k.cst` | Pin assignments — basic (LEDs + buttons) |
| `tangnano9k_hdmi.cst` | Pin assignments — with HDMI output |

### Scripts

| File | Description |
|------|-------------|
| `Makefile` | Icarus Verilog automation for Linux/macOS |
| `run_all_tests.bat` | Windows batch file to run all tests |

---

## Simulation with Icarus Verilog

### Install

- Windows: http://bleyer.org/icarus/
- Linux: `sudo apt-get install iverilog gtkwave`
- macOS: `brew install icarus-verilog gtkwave`

### Run all tests

```bash
make test-all
```

### Run individual tests

```bash
make processor    # Full processor test — most comprehensive
make alu          # ALU unit test
make hazard       # Hazard detection and forwarding test
make control      # Branch and jump control test
make pipeline     # Pipeline stage visualization
```

### View waveforms

```bash
make view-processor
make view-control
gtkwave processor_test.vcd
```

### Syntax check only

```bash
make check
```

### Manual compile and run (without Makefile)

```bash
# Compile full processor test
iverilog -g2012 -Wall -o processor_test.out \
    register_file.v alu.v control_unit.v \
    hazard_detection_unit.v forwarding_unit.v \
    pipeline_registers.v instruction_memory.v \
    data_memory.v processor_top.v tb_processor.v

# Run
vvp processor_test.out

# Open waveform
gtkwave processor_test.vcd
```

---

## Simulation with ModelSim

```tcl
# In the ModelSim console:
do run_modelsim.do
```

Or use the GUI scripts:

```tcl
do run_gui.do
do run_cpu_top_test.do
```

---

## FPGA Deployment

**Target board:** Gowin Tang Nano 9K (GW1NR-9C)  
**Synthesis tool:** Gowin EDA (GIDE)

### What the FPGA implementation includes

- Full 5-stage pipelined CPU running at a gated clock derived from 27 MHz
- Two operating modes controlled by the onboard buttons
- HDMI debug display (640x480 at 60 Hz) showing live processor state

### Button controls

| Button | Behavior |
|--------|----------|
| BTN1 | Active-low reset — restarts the CPU |
| BTN2 (short press) | Step mode — executes one clock cycle |
| BTN2 (hold > 1 second) | Auto mode — runs at approximately 5 Hz |

### LED output

The 6 onboard LEDs show the lower 6 bits of register R1. The separate status LED shows the current mode: on in Auto mode, off in Step mode.

### HDMI debug display

The debug HUD shows the following in real time:

- Program Counter value
- Current instruction in each pipeline stage (IF, ID, EX, MEM, WB)
- All 8 register values (R0–R7)
- Data memory contents (first 14 locations)
- Hazard signals: Stall, Flush, Forward A, Forward B
- Total cycle count

### Synthesis steps in Gowin GIDE

1. Create a new project and select device `GW1NR-9C` (Tang Nano 9K)
2. Add all `.v` and `.vh` files from this folder
3. Set `fpga_top` as the top module
4. Add `tangnano9k_hdmi.cst` as the physical constraints file
5. Run **Synthesize**
6. Run **Place & Route**
7. Connect the board and run **Program Device**

---

## Expected Test Results

### ALU Test (`make alu`)

```
ADD: 100 + 50 = 150   (Expected: 150)
SUB: 100 - 50 = 50    (Expected: 50)
AND: 0xFF00 & 0x0F0F = 0x0F00  (Expected: 0x0F00)
OR:  0xFF00 | 0x0F0F = 0xFF0F  (Expected: 0xFF0F)
SLT: 10 < 20 = 1      (Expected: 1)
SLL: 0x0001 << 3 = 0x0008  (Expected: 0x0008)
SRL: 0x0080 >> 4 = 0x0008  (Expected: 0x0008)
```

### Hazard Test (`make hazard`)

```
Test 1: Load-Use Hazard Detection
  Stall=1, PC_Write=0, IF_ID_Write=0  (Expected: match)

Test 2: No Hazard
  Stall=0, PC_Write=1, IF_ID_Write=1  (Expected: match)

Test 3: EX/MEM Forwarding
  Forward_A=10, Forward_B=00  (Expected: Forward_A=10)
```

### Full Processor Test (`make processor`)

```
Total cycles: 16
Final PC: 9

R0 = 0x0000    R1 = 0x000A (10)
R2 = 0x0014    R3 = 0x001E (30)
R4 = 0x000A    R5 = 0x001E (30)
R6 = 0x0028    R7 = 0x0000

MEM[0] = 0x001E (30)
MEM[1] = 0x000A (10)
MEM[2] = 0x0028 (40)
```

### Control Hazard Test (`make control`)

```
R1 = 6
R2 = 25
R3 = 101
R7 = 10  (return address stored by JAL)
```

---

## Waveform Analysis

Key signals to observe in GTKWave:

### Basic signals
- `uut.clk` — clock
- `uut.pc` — program counter
- `uut.instruction` — current instruction
- `uut.cycle_count` — cycle counter

### Pipeline validity
- `uut.if_id_valid`
- `uut.id_ex_valid`
- `uut.ex_mem_valid`
- `uut.mem_wb_valid`

### Hazard signals
- `uut.stall` — load-use stall
- `uut.flush` — branch/jump flush
- `uut.forward_a` — forwarding control A (2-bit)
- `uut.forward_b` — forwarding control B (2-bit)

### Registers
- `uut.regfile.registers[0]` through `uut.regfile.registers[7]`

---

## Troubleshooting

**"command not found: iverilog"**  
Icarus Verilog is not installed or not in PATH. Follow the install steps above.

**Test results do not match expected values**  
Run the pipeline visualization for a cycle-by-cycle trace:
```bash
make pipeline
```

**Waveform file not opening**  
Check that GTKWave is installed:
```bash
gtkwave --version
```

**FPGA synthesis errors in Gowin GIDE**  
Make sure all `.v` and `.vh` files are added to the project, not just a subset. The `defines.vh` file must be included.

**HDMI output not appearing**  
Verify that `tangnano9k_hdmi.cst` is used as the constraint file, not `tangnano9k.cst`. The HDMI pin assignments are only in the hdmi variant.
