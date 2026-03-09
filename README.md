# 16-bit RISC Processor Simulator

![Python Version](https://img.shields.io/badge/python-3.8%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey)

**A fully-featured 16-bit RISC processor simulator with 5-stage pipeline architecture**

*Built for Computer Organization Course - 2025/2026 Fall Semester*


## Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Instruction Set](#-instruction-set)
- [Technical Specifications](#-technical-specifications)
- [Project Structure](#-project-structure)

---

## Overview

This project implements a **complete 16-bit RISC processor simulator** with a modern graphical interface. The simulator features a **5-stage pipeline architecture** inspired by MIPS, complete with hazard detection, forwarding unit, and real-time visualization of pipeline stages.

### Key Highlights

-  **Full Pipeline Implementation**: IF → ID → EX → MEM → WB
-  **Hazard Management**: Data forwarding, stall insertion, and pipeline flushing
-  **Professional GUI**: Modern interface built with PySide6
-  **Real-time Visualization**: Watch instructions flow through pipeline stages
-  **Assembly Language Support**: Built-in assembler with error checking
-  **Performance Metrics**: CPI, hazard statistics, and execution tracking

---

## Features

### Core Processor Features

| Feature | Description |
|---------|-------------|
| **16-bit Architecture** | Complete 16-bit data path and instruction width |
| **8 Registers** | General-purpose registers R0-R7 (R0 hardwired to 0) |
| **512-Byte Memory** | Separate instruction and data memories (256 words each) |
| **15 Instructions** | Comprehensive RISC instruction set |
| **Pipeline Stages** | 5-stage pipeline with stage-by-stage visualization |
| **Forwarding Unit** | Automatic data forwarding to minimize stalls |
| **Hazard Detection** | Load-use hazard detection with automatic stalling |

### Simulator Features

| Feature | Description |
|---------|-------------|
| **Modern GUI** | Professional interface with intuitive controls |
| **Assembly Editor** | Syntax-highlighted code editor with line numbers |
| **Step Execution** | Execute one clock cycle at a time for debugging |
| **Continuous Run** | Run programs at adjustable speed |
| **Memory Viewer** | Real-time register and memory content display |
| **Hazard Alerts** | Visual indicators for pipeline hazards |
| **Performance Stats** | Cycle count, CPI, and hazard statistics |

---

## Architecture

### Pipeline Structure

```
┌────────────────────────────────────────────────────────────────┐
│                    5-Stage Pipeline                             │
├──────┬──────┬──────┬──────┬──────┬──────────────────────────────┤
│  IF  │  ID  │  EX  │ MEM  │  WB  │  Description                 │
├──────┼──────┼──────┼──────┼──────┼──────────────────────────────┤
│ Inst │ Inst │ Inst │ Inst │ Inst │  Full pipeline (best case)   │
│   A  │   B  │   C  │   D  │   E  │                              │
├──────┼──────┼──────┼──────┼──────┼──────────────────────────────┤
│ Inst │ Inst │ ---- │ Inst │ Inst │  Stall (load-use hazard)     │
│   X  │   Y  │      │   C  │   D  │                              │
├──────┼──────┼──────┼──────┼──────┼──────────────────────────────┤
│ Inst │ ---- │ ---- │ Inst │ Inst │  Flush (branch taken)        │
│   M  │      │      │   C  │   D  │                              │
└──────┴──────┴──────┴──────┴──────┴──────────────────────────────┘
```

### Memory Organization

| Memory Type | Size | Address Range | Purpose |
|-------------|------|---------------|---------|
| **Instruction Memory** | 512 bytes | 0x0000 - 0x01FF | Store program instructions |
| **Data Memory** | 512 bytes | 0x0000 - 0x01FF | Runtime data storage |
| **Registers** | 8 × 16-bit | R0 - R7 | General-purpose registers |

### Hazard Handling Mechanisms

#### 1. Data Forwarding (EX/MEM & MEM/WB)
```
   ALU Result
      ↓
   ┌──────┐
   │ FWD  │ → Forward to EX stage
   └──────┘
```

#### 2. Load-Use Hazard Detection
```
LW  R1, 0(R0)     ← Load data
ADD R2, R1, R3    ← Needs R1 (stall required!)
```

#### 3. Control Hazard Management
```
BEQ R1, R2, LOOP  ← Branch decision in EX stage
INST1             ← Flushed if branch taken
INST2             ← Flushed if branch taken
```

---

## Installation

### Prerequisites

- **Python 3.8 or higher**
- **pip** (Python package manager)

### Step 1: Clone or Download

```bash
cd risc_processor
```

### Step 2: Install Dependencies

```bash
pip install -r requirements.txt
```

### Step 3: Run the Simulator

```bash
python modern_simulator.py
```

## Instruction Set

### Instruction Formats

#### R-Type Format (Arithmetic/Logic)
```
┌────────┬────────┬────────┬────────┬────────┐
│ opcode │   rs   │   rt   │   rd   │ shamt  │
│ 4 bits │ 3 bits │ 3 bits │ 3 bits │ 3 bits │
└────────┴────────┴────────┴────────┴────────┘
```

#### I-Type Format (Immediate/Memory)
```
┌────────┬────────┬────────┬─────────────────┐
│ opcode │   rs   │   rt   │   immediate     │
│ 4 bits │ 3 bits │ 3 bits │     6 bits      │
└────────┴────────┴────────┴─────────────────┘
```

#### J-Type Format (Jump)
```
┌────────┬──────────────────────────────────┐
│ opcode │          address                 │
│ 4 bits │           12 bits                │
└────────┴──────────────────────────────────┘
```

### Complete Instruction Set

| Mnemonic | Opcode | Type | Format | Description | Example |
|----------|--------|------|--------|-------------|---------|
| **ADD** | 0x0 | R | `add rd, rs, rt` | rd = rs + rt | `add r3, r1, r2` |
| **SUB** | 0x1 | R | `sub rd, rs, rt` | rd = rs - rt | `sub r3, r1, r2` |
| **AND** | 0x2 | R | `and rd, rs, rt` | rd = rs & rt | `and r3, r1, r2` |
| **OR** | 0x3 | R | `or rd, rs, rt` | rd = rs \| rt | `or r3, r1, r2` |
| **SLT** | 0x4 | R | `slt rd, rs, rt` | rd = (rs < rt) ? 1 : 0 | `slt r3, r1, r2` |
| **SLL** | 0x5 | R | `sll rd, rt, shamt` | rd = rt << shamt | `sll r2, r1, 3` |
| **SRL** | 0x6 | R | `srl rd, rt, shamt` | rd = rt >> shamt | `srl r2, r1, 2` |
| **ADDI** | 0x7 | I | `addi rt, rs, imm` | rt = rs + imm | `addi r1, r0, 10` |
| **LW** | 0x8 | I | `lw rt, offset(rs)` | rt = mem[rs + offset] | `lw r1, 4(r2)` |
| **SW** | 0x9 | I | `sw rt, offset(rs)` | mem[rs + offset] = rt | `sw r1, 8(r2)` |
| **BEQ** | 0xA | I | `beq rs, rt, label` | if (rs == rt) PC = label | `beq r1, r2, loop` |
| **BNE** | 0xB | I | `bne rs, rt, label` | if (rs != rt) PC = label | `bne r1, r2, loop` |
| **J** | 0xC | J | `j label` | PC = label | `j main` |
| **JAL** | 0xD | J | `jal label` | R7 = PC+1, PC = label | `jal func` |
| **JR** | 0xE | R | `jr rs` | PC = rs | `jr r7` |

### Immediate Value Constraints

- **6-bit signed immediate**: Range **-32 to +31**
- **Out-of-range values** will trigger assembly errors
- **Automatic range checking** prevents invalid encodings


## Technical Specifications

### Processor Core

| Specification | Value |
|---------------|-------|
| Architecture | 16-bit RISC |
| Data Path Width | 16 bits |
| Instruction Width | 16 bits |
| Register Count | 8 (R0-R7) |
| Register Width | 16 bits |
| Pipeline Stages | 5 (IF, ID, EX, MEM, WB) |
| Instruction Memory | 512 bytes (256 words) |
| Data Memory | 512 bytes (256 words) |
| Memory Addressing | Word-addressable (internal), Byte-addressable (display) |

### Instruction Encoding

| Field | Bits | Purpose |
|-------|------|---------|
| Opcode | 4 | Instruction type (16 possible) |
| Register | 3 | Register address (8 registers) |
| Immediate | 6 | Signed immediate value (-32 to +31) |
| Shift Amount | 3 | Shift value (0-7) |
| Jump Address | 12 | Jump target (4096 locations) |


## Project Structure

```
risc_processor/
│
├── modern_simulator.py      # Main simulator application
│   ├── ProcessorCore       # 5-stage pipeline processor
│   ├── Assembler            # Assembly to machine code converter
│   ├── PipelineWidget       # Pipeline visualization
│   └── ModernSimulator      # GUI application
│
├── requirements.txt         # Python dependencies
│   ├── PySide6             # GUI framework
│   └── (other dependencies)
│
├── README.md               # This documentation
│
└── (test programs)         # Example assembly programs
```


---

## Acknowledgments

- **MIPS Architecture**: Design inspiration
- **PySide6**: Excellent GUI framework
- **Course Instructors**: Guidance and project specifications

---
