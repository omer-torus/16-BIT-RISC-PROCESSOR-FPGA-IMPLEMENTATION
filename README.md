# 16-Bit RISC Processor Design Project

![Python Version](https://img.shields.io/badge/python-3.8%2B-blue)
![Verilog](https://img.shields.io/badge/Verilog-IEEE%201364--2001-orange)
![FPGA](https://img.shields.io/badge/FPGA-Tang%20Nano%209K-purple)
![Logisim](https://img.shields.io/badge/Logisim-Circuit%20Simulation-yellow)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey)

A 16-bit RISC processor designed from scratch as a Computer Organization course project. The design covers three levels: a visual datapath built in Logisim, a synthesizable Verilog implementation deployed on a real FPGA board, and a Python-based software simulator with a graphical interface.

*Computer Organization Course — 2025/2026 Fall Semester*

---

## Table of Contents

- [Project Overview](#project-overview)
- [Repository Structure](#repository-structure)
- [Logisim Circuit](#logisim-circuit)
- [Verilog and FPGA Implementation](#verilog-and-fpga-implementation)
- [Python Simulator — Installation and Usage](#python-simulator--installation-and-usage)
- [Architecture](#architecture)
- [Instruction Set](#instruction-set)
- [Technical Specifications](#technical-specifications)

---

## Project Overview

| Level | Tool | Description |
|-------|------|-------------|
| Gate Level | Logisim | Visual datapath circuit simulation |
| RTL Level | Verilog + Icarus / ModelSim | Synthesizable HDL with testbenches |
| FPGA Hardware | Tang Nano 9K (Gowin) | Real hardware with HDMI debug display |
| Software | Python + PySide6 | GUI simulator with step-by-step visualization |

The processor implements:
- 5-stage pipeline (IF, ID, EX, MEM, WB)
- Data forwarding unit (EX/MEM and MEM/WB paths)
- Load-use hazard detection with stall insertion
- Branch and jump with pipeline flush
- 15-instruction RISC instruction set

---

## Repository Structure

```
16-BIT-RISC-PROCESSOR-DESIGN-PROJECT/
|
|-- DataPath.circ               # Logisim datapath circuit
|
|-- verilog/                    # Verilog RTL and FPGA files
|   |
|   |-- Core Modules
|   |   |-- processor_top.v     # Top-level processor (for simulation)
|   |   |-- fpga_top.v          # FPGA top module (Tang Nano 9K)
|   |   |-- cpu_top.v           # CPU core with debug port
|   |   |-- alu.v               # Arithmetic Logic Unit
|   |   |-- control_unit.v      # Instruction decoder
|   |   |-- register_file.v     # 8 x 16-bit register file
|   |   |-- pipeline_registers.v
|   |   |-- hazard_detection_unit.v
|   |   |-- forwarding_unit.v
|   |   |-- instruction_memory.v
|   |   |-- data_memory.v
|   |   |-- debug_hud.v         # HDMI debug display generator
|   |   |-- hdmi_top.v          # HDMI/TMDS signal output
|   |   |-- font_min.v          # Embedded font for HUD
|   |   `-- defines.vh          # Global constants and opcodes
|   |
|   |-- Testbenches
|   |   |-- tb_processor.v
|   |   |-- tb_cpu_top.v
|   |   |-- tb_alu.v
|   |   |-- tb_hazard_forwarding.v
|   |   |-- tb_control_hazards.v
|   |   `-- tb_pipeline_visualization.v
|   |
|   |-- FPGA Constraints
|   |   |-- tangnano9k.cst
|   |   `-- tangnano9k_hdmi.cst
|   |
|   `-- Scripts
|       |-- Makefile
|       `-- run_all_tests.bat
|
|-- modern_simulator.py         # Python GUI simulator
|-- requirements.txt
`-- README.md
```

---

## Logisim Circuit

**File:** `DataPath.circ`  
**Tool:** [Logisim Evolution](https://github.com/logisim-evolution/logisim-evolution)

The circuit provides an interactive, gate-level simulation of the 16-bit datapath. It includes the ALU, 8x16-bit register file, instruction and data memory, control unit, and all datapath connections.

**How to open:**
1. Download [Logisim Evolution](https://github.com/logisim-evolution/logisim-evolution/releases)
2. Open `DataPath.circ` from the File menu
3. Go to Simulate > Tick Enabled to start clocking the circuit

---

## Verilog and FPGA Implementation

**Directory:** `verilog/`  
**Simulation:** Icarus Verilog + GTKWave (or ModelSim)  
**FPGA board:** Gowin Tang Nano 9K (GW1NR-9C)  
**Synthesis tool:** Gowin EDA (GIDE)

### Simulation

Install Icarus Verilog:
- Windows: http://bleyer.org/icarus/
- Linux: `sudo apt-get install iverilog gtkwave`
- macOS: `brew install icarus-verilog gtkwave`

Run all tests:

```bash
cd verilog
make test-all
```

Run individual tests:

```bash
make processor    # Full processor test
make alu          # ALU unit test
make hazard       # Hazard and forwarding test
make control      # Branch and jump test
make pipeline     # Pipeline visualization
```

View waveforms:

```bash
gtkwave processor_test.vcd
```

### FPGA Deployment (Tang Nano 9K)

The `fpga_top.v` module connects the CPU to button controls and an HDMI debug display.

| Input | Function |
|-------|----------|
| BTN1 | Reset the CPU |
| BTN2 (short press) | Execute one clock cycle |
| BTN2 (hold > 1 second) | Auto-run at ~5 Hz |

The LEDs show the lower 6 bits of register R1. The HDMI output (640x480 at 60 Hz) displays all pipeline stages, register contents, data memory, hazard signals, and the cycle counter.

**Synthesis steps:**
1. Open Gowin GIDE
2. Create a project targeting the GW1NR-9C device
3. Add all `.v` and `.vh` files from `verilog/`
4. Set `fpga_top` as the top module
5. Add `tangnano9k_hdmi.cst` as the constraint file
6. Run Synthesize, then Place & Route, then Program Device

### Expected Test Results

ALU test:
```
ADD: 100 + 50 = 150
SUB: 100 - 50 = 50
AND: 0xFF00 & 0x0F0F = 0x0F00
SLT: 10 < 20 = 1
```

Register file after full processor test:
```
R0 = 0x0000    R1 = 0x000A (10)
R2 = 0x0014    R3 = 0x001E (30)
R4 = 0x000A    R5 = 0x001E (30)
R6 = 0x0028    R7 = 0x0000
```

---

## Python Simulator — Installation and Usage

**File:** `modern_simulator.py`  
**Framework:** PySide6

### Prerequisites

- Python 3.8 or higher
- pip (Python package manager)

### Installation

```bash
# Step 1: Clone the repository
git clone https://github.com/omer-torus/16-BIT-RISC-PROCESSOR-DESIGN-PROJECT.git
cd 16-BIT-RISC-PROCESSOR-DESIGN-PROJECT

# Step 2: Install dependencies
pip install -r requirements.txt

# Step 3: Run the simulator
python modern_simulator.py
```

### Features

| Feature | Description |
|---------|-------------|
| Assembly editor | Write and assemble programs directly in the GUI |
| Step execution | Advance one clock cycle at a time |
| Continuous run | Run at adjustable speed |
| Pipeline view | Live view of all 5 stages |
| Memory viewer | Register file and data memory contents |
| Hazard display | Visual indicators for stalls, flushes, and forwarding |
| Performance stats | Cycle count and CPI |

---

## Architecture

### Pipeline Structure

```
+------+------+------+------+------+
|  IF  |  ID  |  EX  | MEM  |  WB  |
+------+------+------+------+------+
  Fetch  Decode  ALU   Mem   Write
```

- **IF:** Fetch instruction from instruction memory
- **ID:** Decode instruction, read registers
- **EX:** ALU operation; forwarding is applied here
- **MEM:** Load/store to data memory
- **WB:** Write result back to register file

### Hazard Handling

#### 1. Data Forwarding (EX/MEM and MEM/WB paths)
```
Result from EX or MEM stage forwarded directly to EX stage input.
No stall required for most RAW hazards.
```

#### 2. Load-Use Hazard
```
LW  R1, 0(R0)     <- load from memory
ADD R2, R1, R3    <- needs R1 immediately: 1 stall cycle inserted
```

#### 3. Control Hazards
```
BEQ R1, R2, LOOP  <- branch decision resolved in EX stage
INST1             <- flushed if branch is taken
INST2             <- flushed if branch is taken
```

### Memory Organization

| Memory | Size | Words |
|--------|------|-------|
| Instruction Memory | 512 bytes | 256 x 16-bit |
| Data Memory | 512 bytes | 256 x 16-bit |
| Register File | 16 bytes | 8 x 16-bit (R0 always 0) |

---

## Instruction Set

### Encoding Formats

#### R-Type (Arithmetic / Logic)
```
+--------+--------+--------+--------+--------+
| opcode |   rs   |   rt   |   rd   | shamt  |
| 4 bits | 3 bits | 3 bits | 3 bits | 3 bits |
+--------+--------+--------+--------+--------+
```

#### I-Type (Immediate / Memory / Branch)
```
+--------+--------+--------+-----------------+
| opcode |   rs   |   rt   |    immediate    |
| 4 bits | 3 bits | 3 bits |     6 bits      |
+--------+--------+--------+-----------------+
```

#### J-Type (Jump)
```
+--------+----------------------------------+
| opcode |            address               |
| 4 bits |            12 bits               |
+--------+----------------------------------+
```

### Complete Instruction Set

| Mnemonic | Opcode | Type | Operation | Example |
|----------|--------|------|-----------|---------|
| ADD  | 0x0 | R | rd = rs + rt | `add r3, r1, r2` |
| SUB  | 0x1 | R | rd = rs - rt | `sub r3, r1, r2` |
| AND  | 0x2 | R | rd = rs & rt | `and r3, r1, r2` |
| OR   | 0x3 | R | rd = rs \| rt | `or r3, r1, r2` |
| SLT  | 0x4 | R | rd = (rs < rt) ? 1 : 0 | `slt r3, r1, r2` |
| SLL  | 0x5 | R | rd = rt << shamt | `sll r2, r1, 3` |
| SRL  | 0x6 | R | rd = rt >> shamt | `srl r2, r1, 2` |
| ADDI | 0x7 | I | rt = rs + imm | `addi r1, r0, 10` |
| LW   | 0x8 | I | rt = mem[rs + offset] | `lw r1, 4(r2)` |
| SW   | 0x9 | I | mem[rs + offset] = rt | `sw r1, 8(r2)` |
| BEQ  | 0xA | I | if rs == rt: PC = label | `beq r1, r2, loop` |
| BNE  | 0xB | I | if rs != rt: PC = label | `bne r1, r2, loop` |
| J    | 0xC | J | PC = target | `j main` |
| JAL  | 0xD | J | R7 = PC+1; PC = target | `jal func` |
| JR   | 0xE | R | PC = rs | `jr r7` |

**Immediate value range:** 6-bit signed, -32 to +31. Values outside this range will cause an assembly error.

---

## Technical Specifications

| Parameter | Value |
|-----------|-------|
| Data width | 16-bit |
| Instruction width | 16-bit |
| Register count | 8 (R0 always 0) |
| Pipeline depth | 5 stages |
| Instruction memory | 512 bytes (256 words) |
| Data memory | 512 bytes (256 words) |
| FPGA clock input | 27 MHz |
| HDMI output | 640x480 at 60 Hz |
| FPGA device | Gowin GW1NR-9C (Tang Nano 9K) |

---

## Acknowledgments

- MIPS architecture — design reference
- PySide6 — Python GUI framework
- Gowin EDA — FPGA synthesis toolchain
- Logisim Evolution — circuit simulation
- Icarus Verilog and GTKWave — open-source HDL simulation
- Course instructors — project specifications and guidance
