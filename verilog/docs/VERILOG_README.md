# 16-bit RISC Processor - Verilog Implementation
## Phase 3: Verilog Implementation

**Due Date: January 20, 2025, 23:59**

---

## 📋 Project Overview

This directory contains the complete Verilog implementation of a 16-bit RISC processor with a 5-stage pipeline architecture. The design includes hazard detection, data forwarding, and comprehensive test benches for verification.

## 🏗️ Architecture

### Pipeline Stages
1. **IF (Instruction Fetch)** - Fetch instruction from memory
2. **ID (Instruction Decode)** - Decode instruction and read registers
3. **EX (Execute)** - Perform ALU operations
4. **MEM (Memory Access)** - Read/write data memory
5. **WB (Write Back)** - Write results to register file

### Key Features
- ✅ 16-bit data path and instruction width
- ✅ 8 general-purpose registers (R0-R7, R0 hardwired to 0)
- ✅ 512 bytes instruction memory (256 words)
- ✅ 512 bytes data memory (256 words)
- ✅ 15 RISC instructions (R-type, I-type, J-type)
- ✅ Data forwarding unit (EX/MEM and MEM/WB forwarding)
- ✅ Load-use hazard detection with automatic stalling
- ✅ Branch/jump pipeline flushing

---

## 📁 File Structure

### Core Modules
| File | Description | Lines |
|------|-------------|-------|
| `processor_top.v` | Top-level processor integration | ~400 |
| `register_file.v` | 8x16-bit register file | ~50 |
| `alu.v` | Arithmetic Logic Unit | ~80 |
| `control_unit.v` | Instruction decoder & control signals | ~130 |
| `hazard_detection_unit.v` | Load-use hazard detector | ~100 |
| `forwarding_unit.v` | Data forwarding logic | ~70 |
| `pipeline_registers.v` | IF/ID, ID/EX, EX/MEM, MEM/WB registers | ~200 |
| `instruction_memory.v` | Read-only instruction memory | ~40 |
| `data_memory.v` | Read/write data memory | ~50 |

### Test Benches
| File | Description | Purpose |
|------|-------------|---------|
| `tb_processor.v` | Full processor test | Tests complete instruction execution |
| `tb_alu.v` | ALU unit test | Verifies all ALU operations |
| `tb_hazard_forwarding.v` | Hazard/forwarding test | Tests data hazard scenarios |
| `tb_control_hazards.v` | Control hazard test | Tests branches and jumps |
| `tb_pipeline_visualization.v` | Pipeline debug test | Shows detailed pipeline state |

### Build Files
| File | Description |
|------|-------------|
| `Makefile` | Build automation for simulation |
| `VERILOG_README.md` | This documentation file |

---

## 🚀 Getting Started

### Prerequisites

Install the required tools:

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install iverilog gtkwave
```

**macOS (with Homebrew):**
```bash
brew install icarus-verilog gtkwave
```

**Windows:**
- Download Icarus Verilog from: http://bleyer.org/icarus/
- Download GTKWave from: http://gtkwave.sourceforge.net/

### Quick Start

1. **Run all tests:**
```bash
make test-all
```

2. **Run specific tests:**
```bash
make processor    # Full processor test
make alu          # ALU test only
make hazard       # Hazard detection test
make control      # Control hazard test
make pipeline     # Pipeline visualization
```

3. **View waveforms:**
```bash
make view-processor   # View processor waveform
make view-control     # View control hazard waveform
make view-pipeline    # View pipeline waveform
```

4. **Syntax check (no simulation):**
```bash
make check
```

5. **Clean generated files:**
```bash
make clean
```

---

## 🧪 Testing & Verification

### Test Coverage

#### 1. ALU Test (`tb_alu.v`)
Tests all ALU operations:
- ✅ Addition (ADD, ADDI)
- ✅ Subtraction (SUB)
- ✅ Logical AND
- ✅ Logical OR
- ✅ Set Less Than (SLT)
- ✅ Shift Left Logical (SLL)
- ✅ Shift Right Logical (SRL)
- ✅ Zero flag generation

#### 2. Hazard Detection Test (`tb_hazard_forwarding.v`)
Tests data hazard scenarios:
- ✅ Load-use hazard detection
- ✅ EX/MEM stage forwarding
- ✅ MEM/WB stage forwarding
- ✅ Double data hazard (both operands)
- ✅ R0 protection (no forwarding to/from R0)
- ✅ No-hazard scenarios

#### 3. Control Hazard Test (`tb_control_hazards.v`)
Tests branch and jump instructions:
- ✅ BEQ (Branch if Equal)
- ✅ BNE (Branch if Not Equal)
- ✅ J (Jump)
- ✅ JAL (Jump and Link)
- ✅ JR (Jump Register)
- ✅ Pipeline flush on branch taken

#### 4. Full Processor Test (`tb_processor.v`)
Tests complete instruction execution:
- ✅ Arithmetic operations
- ✅ Memory operations (LW/SW)
- ✅ Load-use hazard with stall
- ✅ Data forwarding
- ✅ Register file updates
- ✅ Memory updates

#### 5. Pipeline Visualization (`tb_pipeline_visualization.v`)
Provides detailed debug output:
- Pipeline stage contents per cycle
- Hazard detection events
- Forwarding operations
- Register and memory updates

---

## 📊 Expected Test Results

### ALU Test
```
ADD: 100 + 50 = 150 (Expected: 150) ✓
SUB: 100 - 50 = 50 (Expected: 50) ✓
AND: 0xFF00 & 0x0F0F = 0x0F00 (Expected: 0x0F00) ✓
OR:  0xFF00 | 0x0F0F = 0xFF0F (Expected: 0xFF0F) ✓
SLT: 10 < 20 = 1 (Expected: 1) ✓
SLL: 0x0001 << 3 = 0x0008 (Expected: 0x0008) ✓
SRL: 0x0080 >> 4 = 0x0008 (Expected: 0x0008) ✓
```

### Processor Test (after 9 instructions)
```
R1 = 10    (ADDI R1, R0, 10)
R2 = 20    (ADDI R2, R0, 20)
R3 = 30    (ADD R3, R1, R2)
R4 = 10    (SUB R4, R2, R1)
R5 = 30    (LW R5, 0(R0))
R6 = 40    (ADD R6, R5, R1 - with load-use hazard)
MEM[0] = 30 (SW R3, 0(R0))
MEM[1] = 10 (SW R4, 1(R0))
MEM[2] = 40 (SW R6, 2(R0))
```

### Control Hazard Test
```
R1 = 6     (After ADDI and branch)
R2 = 25    (After return from JAL)
R3 = 101   (After function call)
R7 = 10    (Return address saved by JAL)
```

---

## 🔍 Timing Analysis

### Pipeline Performance

#### Ideal Case (No Hazards)
```
CPI (Cycles Per Instruction) = 1.0
Instructions complete every cycle after pipeline fill
```

#### With Load-Use Hazard
```
1 cycle stall inserted
CPI increases by 1 for affected instruction
```

#### With Branch/Jump
```
2 instruction slots flushed
CPI penalty depends on branch frequency
```

### Example Execution Timeline
```
Cycle | IF    | ID    | EX    | MEM   | WB    | Notes
------|-------|-------|-------|-------|-------|------------------
  1   | ADD   | -     | -     | -     | -     | Pipeline filling
  2   | SUB   | ADD   | -     | -     | -     |
  3   | AND   | SUB   | ADD   | -     | -     |
  4   | OR    | AND   | SUB   | ADD   | -     |
  5   | SW    | OR    | AND   | SUB   | ADD   | Full pipeline
  6   | LW    | SW    | OR    | AND   | SUB   |
  7   | ADD   | LW    | SW    | OR    | AND   |
  8   | STALL | ADD   | Bubble| SW    | OR    | Load-use hazard!
  9   | ADD   | ADD   | LW    | Bubble| SW    | Stall resolved
 10   | XOR   | ADD   | ADD   | LW    | Bubble|
```

---

## 🛠️ Synthesis Considerations

### FPGA Implementation Notes

1. **Clock Frequency Target:** 50 MHz (20ns period)
2. **Critical Path:** ALU → Forwarding Mux → ALU (combinational)
3. **Memory Implementation:** Use BRAM primitives on FPGA
4. **Register File:** Use distributed RAM or registers

### Resource Estimates (Xilinx 7-Series)
- **LUTs:** ~1500
- **Flip-Flops:** ~500
- **Block RAMs:** 2 (instruction + data memory)
- **DSP Slices:** 0 (ALU uses LUTs only)

---

## 📝 Instruction Set Reference

### R-Type Instructions
```
Format: opcode(4) | rs(3) | rt(3) | rd(3) | shamt(3)

ADD  rd, rs, rt  - rd = rs + rt
SUB  rd, rs, rt  - rd = rs - rt
AND  rd, rs, rt  - rd = rs & rt
OR   rd, rs, rt  - rd = rs | rt
SLT  rd, rs, rt  - rd = (rs < rt) ? 1 : 0
SLL  rd, rt, shamt - rd = rt << shamt
SRL  rd, rt, shamt - rd = rt >> shamt
```

### I-Type Instructions
```
Format: opcode(4) | rs(3) | rt(3) | immediate(6)

ADDI rt, rs, imm   - rt = rs + imm
LW   rt, offset(rs) - rt = MEM[rs + offset]
SW   rt, offset(rs) - MEM[rs + offset] = rt
BEQ  rs, rt, label  - if (rs == rt) PC = label
BNE  rs, rt, label  - if (rs != rt) PC = label
```

### J-Type Instructions
```
Format: opcode(4) | address(12)

J    label    - PC = label
JAL  label    - R7 = PC+1, PC = label
JR   rs       - PC = rs
```

---

## 🐛 Debugging Tips

### Viewing Pipeline State
1. Run pipeline visualization test:
   ```bash
   make pipeline
   ```

2. Check terminal output for cycle-by-cycle pipeline state

3. View waveform in GTKWave:
   ```bash
   make view-pipeline
   ```

### Common Issues

**Issue:** Instructions not executing
- Check: Program loaded in instruction memory?
- Check: PC incrementing correctly?
- Check: Reset released?

**Issue:** Wrong register values
- Check: Forwarding unit working?
- Check: Register file write enable?
- Check: R0 staying at 0?

**Issue:** Load-use hazard not detected
- Check: Hazard detection unit opcodes
- Check: Register dependencies
- Check: Stall signal propagation

**Issue:** Branch not taken
- Check: Branch condition (zero flag)
- Check: Branch target calculation
- Check: Pipeline flush signal

---

## 📚 Additional Resources

### Module Interconnections
```
                    ┌─────────────────┐
                    │  Processor Top  │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼─────┐      ┌──────▼──────┐     ┌──────▼──────┐
   │   I-MEM  │      │  Registers  │     │   D-MEM     │
   └──────────┘      └──────┬──────┘     └─────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼─────┐      ┌──────▼──────┐     ┌──────▼──────┐
   │   ALU    │      │   Control   │     │  Hazard     │
   └──────────┘      │    Unit     │     │  Detection  │
                     └─────────────┘     └──────┬──────┘
                                                 │
                                         ┌───────▼──────┐
                                         │  Forwarding  │
                                         │     Unit     │
                                         └──────────────┘
```

### Signal Flow
1. **IF Stage:** PC → I-MEM → IF/ID
2. **ID Stage:** IF/ID → Control + RegFile → ID/EX
3. **EX Stage:** ID/EX → ALU (with forwarding) → EX/MEM
4. **MEM Stage:** EX/MEM → D-MEM → MEM/WB
5. **WB Stage:** MEM/WB → RegFile

---

## ✅ Phase 3 Deliverables Checklist

- [x] **Implementation of all processor units in Verilog**
  - [x] Register file
  - [x] ALU
  - [x] Control unit
  - [x] Memory modules
  
- [x] **Pipeline structure implementation**
  - [x] IF/ID register
  - [x] ID/EX register
  - [x] EX/MEM register
  - [x] MEM/WB register
  
- [x] **Hazard management units implementation**
  - [x] Hazard detection unit
  - [x] Forwarding unit
  - [x] Stall and flush logic
  
- [x] **Test bench preparation**
  - [x] ALU test bench
  - [x] Hazard detection test bench
  - [x] Control hazard test bench
  - [x] Full processor test bench
  - [x] Pipeline visualization test bench
  
- [x] **Simulation and verification**
  - [x] Makefile for automated testing
  - [x] Test programs with expected results
  - [x] Waveform generation
  
- [x] **Timing analysis**
  - [x] CPI calculation
  - [x] Pipeline efficiency metrics
  - [x] Hazard impact analysis

---

## 👨‍💻 Author

**Course:** Computer Organization - 2025/2026 Fall Semester  
**Project:** 16-bit RISC Processor - Phase 3  
**Due Date:** January 20, 2025, 23:59

---

## 📄 License

This project is created for educational purposes as part of the Computer Organization course.

---

**Good luck with your implementation! 🚀**

