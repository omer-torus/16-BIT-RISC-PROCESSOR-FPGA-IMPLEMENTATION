"""
Modern 16-bit Processor Simulator
Professional Interface with PySide6
5-Stage Pipeline Architecture
"""

import sys
import re
from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                               QHBoxLayout, QLabel, QPushButton, QTextEdit, 
                               QFrame, QGridLayout, QScrollArea, QGroupBox, QTableWidget,
                               QTableWidgetItem, QHeaderView, QMessageBox)
from PySide6.QtCore import Qt, QTimer, Signal, Slot, QPoint
from PySide6.QtGui import QFont, QPalette, QColor, QPainter, QLinearGradient, QPen, QPolygon, QBrush


def to_signed_16bit(value):
    """Convert unsigned 16-bit value to signed representation."""
    value &= 0xFFFF
    return value - 0x10000 if value >= 0x8000 else value


class ProcessorCore:
    """16-bit RISC Processor Core - 5-Stage Pipeline"""
    
    # Opcode definitions (4-bit) - Official opcodes
    # R-Type instructions (each has unique opcode)
    OP_ADD = 0b0000    # 0x0 - Add registers
    OP_SUB = 0b0001    # 0x1 - Subtract registers
    OP_AND = 0b0010    # 0x2 - Logical AND
    OP_OR = 0b0011     # 0x3 - Logical OR
    OP_SLT = 0b0100    # 0x4 - Set if Less Than
    OP_SLL = 0b0101    # 0x5 - Shift Left Logical
    OP_SRL = 0b0110    # 0x6 - Shift Right Logical
    
    # I-Type instructions
    OP_ADDI = 0b0111   # 0x7 - Add Immediate
    OP_LW = 0b1000     # 0x8 - Load Word
    OP_SW = 0b1001     # 0x9 - Store Word
    OP_BEQ = 0b1010    # 0xA - Branch if Equal
    OP_BNE = 0b1011    # 0xB - Branch if Not Equal
    
    # J-Type instructions
    OP_J = 0b1100      # 0xC - Jump
    OP_JAL = 0b1101    # 0xD - Jump and Link
    OP_JR = 0b1110     # 0xE - Jump Register
    OP_NOP = 0b1111    # 0xF - No Operation
    
    def __init__(self):
        self.reset()
        
    def reset(self):
        """Reset processor state"""
        self.registers = [0] * 8  # R0-R7 (R0 always 0)
        self.pc = 0
        self.instruction_memory = [0] * 256  # 256 instructions (word-addressed)
        self.data_memory = [0] * 512  # 512 bytes (byte-addressed)
        self.written_memory = set()  # Track which memory addresses have been written to (byte addresses)
        self.program_end = 0  # End of loaded program
        
        # Pipeline registers
        self.IF_ID = {'instruction': 0, 'pc': 0, 'valid': False}
        self.ID_EX = {
            'control': {'RegWrite': False, 'MemWrite': False, 'MemRead': False, 
                       'Branch': False, 'ALUSrc': False, 'Jump': False, 'JumpReg': False},
            'rs_val': 0, 'rt_val': 0, 'rs': 0, 'rt': 0, 'rd': 0,
            'imm': 0, 'shamt': 0, 'opcode': 0, 'funct': 0,
            'pc': 0, 'jump_addr': 0, 'valid': False
        }
        # GÜNCELLEME: Opcode alanları eklendi
        self.EX_MEM = {
            'control': {'RegWrite': False, 'MemWrite': False, 'MemRead': False, 
                       'Branch': False, 'Jump': False},
            'alu_result': 0, 'rt_val': 0, 'rd': 0, 'zero': False,
            'pc': 0, 'jump_addr': 0, 'opcode': 0, 'valid': False
        }
        # GÜNCELLEME: Opcode alanları eklendi
        self.MEM_WB = {
            'control': {'RegWrite': False, 'MemRead': False},
            'mem_data': 0, 'alu_result': 0, 'rd': 0, 'pc': 0, 'opcode': 0, 'valid': False
        }
        self.MEM_WB_old = {}  # Backup for forwarding timing
        
        # Forwarding paths
        self.forward_A = 0  # 0: no forward, 1: from EX/MEM, 2: from MEM/WB
        self.forward_B = 0
        
        # Statistics
        self.cycle = 0
        self.instructions_completed = 0
        self.stalls = 0
        self.data_hazards = 0
        self.control_hazards = 0
        self.forwarding_count = 0  # Track successful forwarding operations
        
        # Hazard flags
        self.stall_flag = False
        self.flush_flag = False
        self.jump_flag = False
        self.hazard_reason = ""  # Detailed hazard explanation
        self.forwarding_log = []  # Track forwarding operations
        
    def clock_cycle(self):
        """Bir clock cycle çalıştır"""
        self.cycle += 1
        self.hazard_reason = ""  # Clear hazard reason at start of cycle
        self.forwarding_log = []  # Clear forwarding log at start of cycle
        
        # Save MEM/WB state for forwarding (before it gets overwritten)
        import copy
        self.MEM_WB_old = copy.deepcopy(self.MEM_WB)
        
        # Pipeline stages (reverse order)
        self.writeback_stage()
        self.memory_stage()
        self.execute_stage()
        self.decode_stage()
        self.fetch_stage()
        
        # Hazard flags'i temizle
        old_stall = self.stall_flag
        old_flush = self.flush_flag
        self.stall_flag = False
        self.flush_flag = False
        
        return old_stall, old_flush
        
    def fetch_stage(self):
        """IF: Instruction Fetch"""
        if self.stall_flag:
            return
            
        if self.flush_flag:
            self.IF_ID['valid'] = False
            return
            
        # Word-addressable: PC counts instructions (1 per instruction)
        if self.pc < self.program_end and self.pc < len(self.instruction_memory):
            self.IF_ID['instruction'] = self.instruction_memory[self.pc]
            self.IF_ID['pc'] = self.pc
            self.IF_ID['valid'] = True
            self.pc += 1  # next instruction
        else:
            self.IF_ID['valid'] = False
            
    def decode_stage(self):
        """ID: Instruction Decode - Unified Format"""
        # Don't decode if: no valid instruction, stall needed, or flush requested
        if not self.IF_ID['valid'] or self.stall_flag or self.flush_flag:
            self.ID_EX['valid'] = False
            return
            
        instruction = self.IF_ID['instruction']
        
        # Decode opcode (4 bits)
        opcode = (instruction >> 12) & 0xF
        
        # Unified R-Type format: opcode(4) | rs(3) | rt(3) | rd(3) | shamt(3)
        # All R-type instructions use same format!
        rs = (instruction >> 9) & 0x7
        rt = (instruction >> 6) & 0x7
        rd = (instruction >> 3) & 0x7
        shamt = instruction & 0x7
        
        # Decode based on instruction type
        if opcode in [self.OP_J, self.OP_JAL]:  # J-type
            jump_addr = instruction & 0xFFF
            rs = 0
            rt = 0
            rd = 7 if opcode == self.OP_JAL else 0  # JAL writes to R7
            shamt = 0
            imm = 0
            
        elif opcode == self.OP_JR:  # JR
            rs = (instruction >> 9) & 0x7
            rt = 0
            rd = 0
            shamt = 0
            imm = 0
            jump_addr = 0
            
        elif opcode in [self.OP_ADDI, self.OP_LW, self.OP_SW, self.OP_BEQ, self.OP_BNE]:  # I-type
            # I-type: opcode(4) | rs(3) | rt(3) | immediate(6)
            rs = (instruction >> 9) & 0x7
            rt = (instruction >> 6) & 0x7
            imm = instruction & 0x3F
            
            # Sign extend immediate (6-bit to 16-bit)
            if imm & 0x20:  # If bit 5 is 1 (negative)
                imm = imm | 0xFFC0
                
            rd = rt  # For I-type, destination is rt
            shamt = 0
            jump_addr = 0
            
        else:  # R-type (unified format)
            # Already decoded: rs, rt, rd, shamt
            imm = 0
            jump_addr = 0
        
        # Get control signals (no funct needed!)
        control = self.get_control_signals(opcode)
        
        # Load-use hazard detection
        if self.detect_load_use_hazard(rs, rt, opcode):
            self.stall_flag = True
            self.stalls += 1
            self.data_hazards += 1
            self.ID_EX['valid'] = False
            return
        
        # Read registers (R0 always returns 0)
        rs_val = 0 if rs == 0 else self.registers[rs]
        rt_val = 0 if rt == 0 else self.registers[rt]
        
        # Store in ID/EX register
        self.ID_EX['control'] = control
        self.ID_EX['rs_val'] = rs_val
        self.ID_EX['rt_val'] = rt_val
        self.ID_EX['rs'] = rs
        self.ID_EX['rt'] = rt
        self.ID_EX['rd'] = rd
        self.ID_EX['imm'] = imm
        self.ID_EX['shamt'] = shamt
        self.ID_EX['opcode'] = opcode
        self.ID_EX['pc'] = self.IF_ID['pc']
        self.ID_EX['jump_addr'] = jump_addr
        self.ID_EX['valid'] = True
        
    def execute_stage(self):
        """EX: Execute - ALU Operations with Forwarding"""
        if not self.ID_EX['valid']:
            self.EX_MEM['valid'] = False
            return
        
        # Get operands with forwarding
        rs_val = self.get_forwarded_value('A', self.ID_EX['rs_val'], self.ID_EX['rs'])
        rt_val = self.get_forwarded_value('B', self.ID_EX['rt_val'], self.ID_EX['rt'])
        
        opcode = self.ID_EX['opcode']
        imm = self.ID_EX['imm']
        shamt = self.ID_EX['shamt']
        
        # ALU Operation (direct opcode check - no funct!)
        alu_result = 0
        zero = False
        
        # R-Type ALU operations
        if opcode == self.OP_ADD:
            alu_result = (rs_val + rt_val) & 0xFFFF
            
        elif opcode == self.OP_SUB:
            alu_result = (rs_val - rt_val) & 0xFFFF
            
        elif opcode == self.OP_AND:
            alu_result = rs_val & rt_val
            
        elif opcode == self.OP_OR:
            alu_result = rs_val | rt_val
            
        elif opcode == self.OP_SLT:
            # Signed comparison
            rs_signed = rs_val if rs_val < 32768 else rs_val - 65536
            rt_signed = rt_val if rt_val < 32768 else rt_val - 65536
            alu_result = 1 if rs_signed < rt_signed else 0
            
        elif opcode == self.OP_SLL:
            # Shift left logical: rd = rt << shamt
            alu_result = (rt_val << shamt) & 0xFFFF
            
        elif opcode == self.OP_SRL:
            # Shift right logical: rd = rt >> shamt
            alu_result = (rt_val >> shamt) & 0xFFFF
            
        # I-Type operations
        elif opcode == self.OP_ADDI:
            alu_result = (rs_val + imm) & 0xFFFF
            
        elif opcode in [self.OP_LW, self.OP_SW]:
            # Memory address calculation
            alu_result = (rs_val + imm) & 0xFFFF
            
        elif opcode in [self.OP_BEQ, self.OP_BNE]:
            # Branch comparison
            alu_result = (rs_val - rt_val) & 0xFFFF
            zero = (alu_result == 0)
            
            # Branch decision
            branch_taken = (opcode == self.OP_BEQ and zero) or (opcode == self.OP_BNE and not zero)
            
            if branch_taken:
                # Sign extend immediate for proper branch calculation
                signed_imm = imm if imm < 32768 else imm - 65536
                new_pc = (self.ID_EX['pc'] + 1 + signed_imm) & 0xFF
                self.pc = new_pc
                self.flush_flag = True
                self.control_hazards += 1
                branch_type = "BEQ" if opcode == self.OP_BEQ else "BNE"
                self.hazard_reason = f"Control Hazard: {branch_type} condition met (R{self.ID_EX['rs']} {'==' if opcode == self.OP_BEQ else '!='} R{self.ID_EX['rt']}). Jumping to PC={new_pc}. Flushing pipeline."
        
        # Jump operations
        elif opcode == self.OP_JR:
            new_pc = rs_val & 0xFF
            self.pc = new_pc
            self.flush_flag = True
            self.control_hazards += 1
            self.hazard_reason = f"Control Hazard: JR instruction. Jumping to address in R{self.ID_EX['rs']} (PC={new_pc}). Flushing pipeline."
            
        elif opcode in [self.OP_J, self.OP_JAL]:
            new_pc = self.ID_EX['jump_addr'] & 0xFF
            self.pc = new_pc
            self.flush_flag = True
            self.control_hazards += 1
            jump_type = "JAL" if opcode == self.OP_JAL else "J"
            self.hazard_reason = f"Control Hazard: {jump_type} instruction. Jumping to address {new_pc}. " + ("Saving return address to R7. " if opcode == self.OP_JAL else "") + "Flushing pipeline."
            
            if opcode == self.OP_JAL:
                alu_result = (self.ID_EX['pc'] + 1) & 0xFFFF
        
        elif opcode == self.OP_NOP:
            alu_result = 0
            zero = False
        
        # Pass to MEM stage
        self.EX_MEM['control'] = self.ID_EX['control']
        self.EX_MEM['alu_result'] = alu_result
        self.EX_MEM['rt_val'] = rt_val
        self.EX_MEM['rd'] = self.ID_EX['rd']
        self.EX_MEM['zero'] = zero
        self.EX_MEM['pc'] = self.ID_EX['pc']
        # GÜNCELLEME: Opcode taşınıyor
        self.EX_MEM['opcode'] = opcode
        self.EX_MEM['valid'] = True
        
    def memory_stage(self):
        """MEM: Memory Access (LW/SW) - BYTE-ADDRESSABLE"""
        if not self.EX_MEM['valid']:
            self.MEM_WB['valid'] = False
            return
        
        mem_data = 0
        mem_addr = self.EX_MEM['alu_result'] & 0x1FF
        
        # Auto-align to word boundary (even address)
        aligned_addr = (mem_addr // 2) * 2
        
        if self.EX_MEM['control']['MemRead']:
            if aligned_addr >= 0 and aligned_addr < len(self.data_memory) - 1:
                low_byte = self.data_memory[aligned_addr]
                high_byte = self.data_memory[aligned_addr + 1]
                mem_data = (high_byte << 8) | low_byte
                mem_data &= 0xFFFF
                
        elif self.EX_MEM['control']['MemWrite']:
            if aligned_addr >= 0 and aligned_addr < len(self.data_memory) - 1:
                value = self.EX_MEM['rt_val'] & 0xFFFF
                self.data_memory[aligned_addr] = value & 0xFF
                self.data_memory[aligned_addr + 1] = (value >> 8) & 0xFF
                self.written_memory.add(aligned_addr)
        
        # Pass to WB stage
        self.MEM_WB['control'] = self.EX_MEM['control']
        self.MEM_WB['mem_data'] = mem_data
        self.MEM_WB['alu_result'] = self.EX_MEM['alu_result']
        self.MEM_WB['rd'] = self.EX_MEM['rd']
        self.MEM_WB['pc'] = self.EX_MEM['pc']
        # GÜNCELLEME: Opcode taşınıyor
        self.MEM_WB['opcode'] = self.EX_MEM.get('opcode', 0)
        self.MEM_WB['valid'] = True
        
    def writeback_stage(self):
        """WB: Write Back to Register File"""
        if not self.MEM_WB['valid']:
            return
        
        # GÜNCELLEME: Sadece NOP olmayan komutları say
        # "Useful Work" prensibi: NOP instructions are NOT counted in statistics
        current_opcode = self.MEM_WB.get('opcode', 0)
        if current_opcode != self.OP_NOP:
            self.instructions_completed += 1
        
        # Write to register (except R0)
        if self.MEM_WB['control']['RegWrite'] and self.MEM_WB['rd'] != 0:
            if self.MEM_WB['control']['MemRead']:
                # LW - write memory data
                self.registers[self.MEM_WB['rd']] = self.MEM_WB['mem_data'] & 0xFFFF
            else:
                # Other instructions - write ALU result
                self.registers[self.MEM_WB['rd']] = self.MEM_WB['alu_result'] & 0xFFFF
        
        # Ensure R0 stays 0
        self.registers[0] = 0
            
    def get_control_signals(self, opcode):
        """Generate control signals based on opcode only (no funct!)"""
        control = {
            'RegWrite': False,
            'MemWrite': False,
            'MemRead': False,
            'Branch': False,
            'ALUSrc': False,
            'Jump': False,
            'JumpReg': False
        }
        
        # R-Type instructions (all write to register)
        if opcode in [self.OP_ADD, self.OP_SUB, self.OP_AND, self.OP_OR, 
                      self.OP_SLT, self.OP_SLL, self.OP_SRL]:
            control['RegWrite'] = True
            
        # ADDI
        elif opcode == self.OP_ADDI:
            control['RegWrite'] = True
            control['ALUSrc'] = True
            
        # LW
        elif opcode == self.OP_LW:
            control['RegWrite'] = True
            control['MemRead'] = True
            control['ALUSrc'] = True
            
        # SW
        elif opcode == self.OP_SW:
            control['MemWrite'] = True
            control['ALUSrc'] = True
            
        # BEQ, BNE
        elif opcode in [self.OP_BEQ, self.OP_BNE]:
            control['Branch'] = True
            
        # J, JAL
        elif opcode in [self.OP_J, self.OP_JAL]:
            control['Jump'] = True
            if opcode == self.OP_JAL:
                control['RegWrite'] = True  # Write return address to R7
                
        # JR
        elif opcode == self.OP_JR:
            control['JumpReg'] = True
            
        # NOP
        elif opcode == self.OP_NOP:
            # No Operation - All signals remain at default (False)
            # No register write, no memory access, no branch/jump
            pass
            
        return control
    
    def detect_load_use_hazard(self, rs, rt, opcode):
        """Detect load-use data hazard (needs stall)"""
        # Check if previous instruction is LW
        if self.ID_EX['valid'] and self.ID_EX['control']['MemRead']:
            lw_dest = self.ID_EX['rd']
            
            # Check if current instruction uses the LW result
            if lw_dest != 0:
                hazard_detected = False
                dependent_reg = ""
                
                # R-type instructions: check both rs and rt
                if opcode in [self.OP_ADD, self.OP_SUB, self.OP_AND, self.OP_OR, self.OP_SLT]:
                    if lw_dest == rs:
                        hazard_detected = True
                        dependent_reg = f"R{rs}"
                    elif lw_dest == rt:
                        hazard_detected = True
                        dependent_reg = f"R{rt}"
                
                # Shift instructions: check rt only
                elif opcode in [self.OP_SLL, self.OP_SRL]:
                    if lw_dest == rt:
                        hazard_detected = True
                        dependent_reg = f"R{rt}"
                
                # I-type: check rs and rt (for branches)
                elif opcode == self.OP_ADDI:
                    if lw_dest == rs:
                        hazard_detected = True
                        dependent_reg = f"R{rs}"
                        
                elif opcode in [self.OP_BEQ, self.OP_BNE]:
                    if lw_dest == rs:
                        hazard_detected = True
                        dependent_reg = f"R{rs}"
                    elif lw_dest == rt:
                        hazard_detected = True
                        dependent_reg = f"R{rt}"
                
                # LW/SW: check base register (rs)
                elif opcode in [self.OP_LW, self.OP_SW]:
                    if lw_dest == rs:
                        hazard_detected = True
                        dependent_reg = f"R{rs}"
                
                # JR: check rs
                elif opcode == self.OP_JR:
                    if lw_dest == rs:
                        hazard_detected = True
                        dependent_reg = f"R{rs}"
                
                if hazard_detected:
                    self.hazard_reason = f"Load-Use Hazard: Current instruction depends on {dependent_reg}, which is being loaded from memory (LW). Pipeline must stall 1 cycle."
                    return True
        
        return False
    
    def get_forwarded_value(self, operand, original_value, reg_num):
        """Get forwarded value from EX/MEM or MEM/WB stage"""
        if reg_num == 0:
            return 0  # R0 is always 0
        
        # Check EX/MEM forwarding (priority)
        if (self.EX_MEM['valid'] and 
            self.EX_MEM['control']['RegWrite'] and 
            self.EX_MEM['rd'] != 0 and 
            self.EX_MEM['rd'] == reg_num):
            # Log forwarding operation (only if not already logged for this register in this cycle)
            source_stage = "EX/MEM"
            log_msg = f"Forwarded R{reg_num} from {source_stage} stage (value: {self.EX_MEM['alu_result']})"
            if log_msg not in self.forwarding_log:
                self.forwarding_log.append(log_msg)
                self.forwarding_count += 1  # Count successful forwarding
            return self.EX_MEM['alu_result']
        
        # Check MEM/WB forwarding (use old state before memory_stage overwrites it)
        if (self.MEM_WB_old.get('valid') and 
            self.MEM_WB_old.get('control', {}).get('RegWrite') and 
            self.MEM_WB_old.get('rd', 0) != 0 and 
            self.MEM_WB_old.get('rd') == reg_num):
            # Log forwarding operation (only if not already logged for this register in this cycle)
            source_stage = "MEM/WB"
            forwarded_value = self.MEM_WB_old['mem_data'] if self.MEM_WB_old['control']['MemRead'] else self.MEM_WB_old['alu_result']
            log_msg = f"Forwarded R{reg_num} from {source_stage} stage (value: {forwarded_value})"
            if log_msg not in self.forwarding_log:
                self.forwarding_log.append(log_msg)
                self.forwarding_count += 1  # Count successful forwarding
            
            if self.MEM_WB_old['control']['MemRead']:
                return self.MEM_WB_old['mem_data']
            else:
                return self.MEM_WB_old['alu_result']
        
        # No forwarding needed
        return original_value


class Assembler:
    """Assembly to Machine Code Converter - Unified Format"""
    
    # Opcode definitions (4-bit) - Official opcodes
    # R-Type instructions
    OP_ADD = 0b0000    # 0x0 - Add registers
    OP_SUB = 0b0001    # 0x1 - Subtract registers
    OP_AND = 0b0010    # 0x2 - Logical AND
    OP_OR = 0b0011     # 0x3 - Logical OR
    OP_SLT = 0b0100    # 0x4 - Set if Less Than
    OP_SLL = 0b0101    # 0x5 - Shift Left Logical
    OP_SRL = 0b0110    # 0x6 - Shift Right Logical
    
    # I-Type instructions
    OP_ADDI = 0b0111   # 0x7 - Add Immediate
    OP_LW = 0b1000     # 0x8 - Load Word
    OP_SW = 0b1001     # 0x9 - Store Word
    OP_BEQ = 0b1010    # 0xA - Branch if Equal
    OP_BNE = 0b1011    # 0xB - Branch if Not Equal
    
    # J-Type instructions
    OP_J = 0b1100      # 0xC - Jump
    OP_JAL = 0b1101    # 0xD - Jump and Link
    OP_JR = 0b1110     # 0xE - Jump Register
    OP_NOP = 0b1111    # 0xF - No Operation
    
    def __init__(self):
        self.labels = {}
        
    def assemble(self, code):
        """Assemble code to machine code"""
        lines = code.strip().split('\n')
        machine_code = []
        errors = []
        self.labels = {}
        assembly_lines = []
        
        # First pass: collect labels
        pc = 0
        for line in lines:
            clean = self.clean_line(line)
            if not clean:
                continue
                
            # Handle labels
            if ':' in clean:
                label = clean.split(':')[0].strip()
                self.labels[label.upper()] = pc
                clean = clean.split(':', 1)[1].strip()
                
            if clean:
                assembly_lines.append(clean)
                pc += 1  # Word-addressable: each instruction is 1 address
        
        # Second pass: encode instructions
        pc = 0
        for line_num, line in enumerate(assembly_lines, 1):
            try:
                instruction = self.encode_instruction(line, pc)
                machine_code.append(instruction)
                pc += 1  # Advance PC by 1 per instruction
            except Exception as e:
                errors.append(f"Line {line_num}: {str(e)}")
        
        return machine_code, assembly_lines, errors
    
    def clean_line(self, line):
        """Remove comments and whitespace"""
        if '#' in line:
            line = line[:line.index('#')]
        return line.strip()
    
    def encode_instruction(self, line, pc):
        """Encode single instruction - Unified Format (No Funct!)"""
        parts = re.split(r'[,\s()]+', line.upper().strip())
        parts = [p for p in parts if p]
        
        if not parts:
            return 0
        
        mnemonic = parts[0]
        
        # Unified R-Type: opcode(4) | rs(3) | rt(3) | rd(3) | shamt(3)
        # ADD, SUB, AND, OR, SLT: use rs, rt, rd (shamt=0)
        if mnemonic in ['ADD', 'SUB', 'AND', 'OR', 'SLT']:
            rd = self.parse_register(parts[1])
            rs = self.parse_register(parts[2])
            rt = self.parse_register(parts[3])
            shamt = 0  # Not used for these instructions
            
            opcode_map = {
                'ADD': self.OP_ADD,
                'SUB': self.OP_SUB,
                'AND': self.OP_AND,
                'OR': self.OP_OR,
                'SLT': self.OP_SLT
            }
            opcode = opcode_map[mnemonic]
            
            # Format: opcode(4) | rs(3) | rt(3) | rd(3) | shamt(3)
            return (opcode << 12) | (rs << 9) | (rt << 6) | (rd << 3) | shamt
        
        # Shift: SLL, SRL - use rt, rd, shamt (rs field unused)
        elif mnemonic in ['SLL', 'SRL']:
            rd = self.parse_register(parts[1])
            rt = self.parse_register(parts[2])
            shamt = self.parse_immediate(parts[3]) & 0x7
            rs = 0  # Unused in shift instructions
            
            opcode = self.OP_SLL if mnemonic == 'SLL' else self.OP_SRL
            
            # Format: opcode(4) | rs(3) | rt(3) | rd(3) | shamt(3)
            return (opcode << 12) | (rs << 9) | (rt << 6) | (rd << 3) | shamt
        
        # I-Type: ADDI
        elif mnemonic == 'ADDI':
            rt = self.parse_register(parts[1])
            rs = self.parse_register(parts[2])
            imm = self.parse_immediate(parts[3])
            
            # 6-bit signed immediate range check: -32 to +31
            if not (-32 <= imm <= 31):
                raise ValueError(f"ADDI immediate value {imm} out of range! Must be between -32 and +31 (6-bit signed).")
            
            imm = imm & 0x3F
            # Format: opcode(4) | rs(3) | rt(3) | imm(6)
            return (self.OP_ADDI << 12) | (rs << 9) | (rt << 6) | imm
        
        # I-Type: LW
        elif mnemonic == 'LW':
            rt = self.parse_register(parts[1])
            offset = self.parse_immediate(parts[2])
            
            # 6-bit signed offset range check: -32 to +31
            if not (-32 <= offset <= 31):
                raise ValueError(f"LW offset value {offset} out of range! Must be between -32 and +31 (6-bit signed).")
            
            offset = offset & 0x3F
            rs = self.parse_register(parts[3]) if len(parts) > 3 else 0
            # Format: opcode(4) | rs(3) | rt(3) | offset(6)
            return (self.OP_LW << 12) | (rs << 9) | (rt << 6) | offset
        
        # I-Type: SW
        elif mnemonic == 'SW':
            rt = self.parse_register(parts[1])
            offset = self.parse_immediate(parts[2])
            
            # 6-bit signed offset range check: -32 to +31
            if not (-32 <= offset <= 31):
                raise ValueError(f"SW offset value {offset} out of range! Must be between -32 and +31 (6-bit signed).")
            
            offset = offset & 0x3F
            rs = self.parse_register(parts[3]) if len(parts) > 3 else 0
            # Format: opcode(4) | rs(3) | rt(3) | offset(6)
            return (self.OP_SW << 12) | (rs << 9) | (rt << 6) | offset
        
        # I-Type: BEQ
        elif mnemonic == 'BEQ':
            rs = self.parse_register(parts[1])
            rt = self.parse_register(parts[2])
            label = parts[3].upper()
            target_addr = self.labels.get(label, pc)
            offset = target_addr - (pc + 1)  # Relative to next instruction
            
            # 6-bit signed branch offset range check: -32 to +31
            if not (-32 <= offset <= 31):
                raise ValueError(f"BEQ branch offset {offset} out of range! Label '{label}' is too far (must be within -32 to +31 instructions).")
            
            offset = offset & 0x3F
            # Format: opcode(4) | rs(3) | rt(3) | offset(6)
            return (self.OP_BEQ << 12) | (rs << 9) | (rt << 6) | offset
        
        # I-Type: BNE
        elif mnemonic == 'BNE':
            rs = self.parse_register(parts[1])
            rt = self.parse_register(parts[2])
            label = parts[3].upper()
            target_addr = self.labels.get(label, pc)
            offset = target_addr - (pc + 1)  # Relative to next instruction
            
            # 6-bit signed branch offset range check: -32 to +31
            if not (-32 <= offset <= 31):
                raise ValueError(f"BNE branch offset {offset} out of range! Label '{label}' is too far (must be within -32 to +31 instructions).")
            
            offset = offset & 0x3F
            # Format: opcode(4) | rs(3) | rt(3) | offset(6)
            return (self.OP_BNE << 12) | (rs << 9) | (rt << 6) | offset
        
        # J-Type: J
        elif mnemonic == 'J':
            label = parts[1].upper()
            address = self.labels.get(label, 0) & 0xFFF
            # Format: opcode(4) | address(12)
            return (self.OP_J << 12) | address
        
        # J-Type: JAL
        elif mnemonic == 'JAL':
            label = parts[1].upper()
            address = self.labels.get(label, 0) & 0xFFF
            # Format: opcode(4) | address(12)
            return (self.OP_JAL << 12) | address
        
        # JR
        elif mnemonic == 'JR':
            rs = self.parse_register(parts[1])
            # Format: opcode(4) | rs(3) | zeros(9)
            return (self.OP_JR << 12) | (rs << 9)
        
        # NOP
        elif mnemonic == 'NOP':
            # Format: opcode(4) | zeros(12)
            return (self.OP_NOP << 12)
        
        else:
            raise ValueError(f"Unknown instruction: {mnemonic}")
    
    def parse_register(self, reg):
        """Parse register name to number"""
        reg = reg.upper().strip()
        if reg.startswith('R'):
            num = int(reg[1:])
            if 0 <= num <= 7:
                return num
            raise ValueError(f"Invalid register: {reg}")
        raise ValueError(f"Invalid register format: {reg}")
    
    def parse_immediate(self, imm):
        """Parse immediate value (returns signed integer, no conversion yet)"""
        imm = imm.strip()
        if imm.startswith('0X') or imm.startswith('0x'):
            return int(imm, 16)
        else:
            # Return raw signed integer value
            # Two's complement conversion happens AFTER range check
            return int(imm)


class PipelineWidget(QWidget):
    """Pipeline görselleştirme widget'ı"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setMinimumHeight(180)
        self.setMaximumHeight(180)
        self.setMinimumWidth(750)
        self.processor = None
        self.assembly_lines = []
        self.is_stall = False
        self.is_bubble = False
        
    def set_processor(self, processor):
        self.processor = processor
        
    def set_assembly_lines(self, assembly_lines):
        self.assembly_lines = assembly_lines
        
    def set_hazard_state(self, stall, flush):
        """Set current hazard state for visualization"""
        self.is_stall = stall
        self.is_bubble = flush
        
    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)
        painter.setRenderHint(QPainter.TextAntialiasing)
        
        # Background
        painter.fillRect(self.rect(), QColor('#ffffff'))
        
        if not self.processor:
            return
            
        width = self.width()
        height = self.height()
        
        # DÜZELTME: WB aşaması için 'MEM_WB' yerine 'MEM_WB_old' kullanıyoruz.
        # MEM_WB_old: Cycle başında WB'nin işleyeceği veriyi tutar.
        # MEM_WB: Cycle sonunda MEM'in ürettiği (bir sonraki cycle WB'ye gidecek) veriyi tutar.
        stages = [
            ('IF', 'Instruction\nFetch', self.processor.IF_ID, '#d4e3fc', '#1a73e8'),
            ('ID', 'Instruction\nDecode', self.processor.ID_EX, '#ceead6', '#34a853'),
            ('EX', 'Execute', self.processor.EX_MEM, '#fef7e0', '#fbbc04'),
            ('MEM', 'Memory\nAccess', self.processor.MEM_WB, '#fce8e6', '#ea4335'),
            ('WB', 'Write\nBack', self.processor.MEM_WB_old, '#f3e8fd', '#9334e9')
        ]
        
        stage_width = 140
        stage_height = 110
        spacing = 28
        total_width = len(stages) * stage_width + (len(stages) - 1) * spacing
        start_x = max(10, (width - total_width) // 2)
        y = 25  # Comfortable top padding
        
        for i, (name, full_name, data, light_color, dark_color) in enumerate(stages):
            x = start_x + i * (stage_width + spacing)
            
            # DÜZELTME: Artık 'data' değişkeni doğru kaynağı gösterdiği için
            # WB (i==4) için özel kontrole gerek kalmadı.
            is_active = data.get('valid', False)
            
            # Check if this stage has a bubble (flushed/invalid instruction due to flush)
            # A bubble is an invalid instruction inserted by pipeline flush, NOT a NOP instruction
            is_bubble = False
            if i == 0 and self.is_bubble:  # IF stage gets bubble on flush
                is_bubble = True
            elif i == 1 and not is_active and self.is_bubble and self.processor.cycle > 0:  # ID stage bubble only on flush
                is_bubble = True
            
            # Check if this stage is stalled
            is_stalled = False
            if self.is_stall and i <= 1:  # Stall affects IF and ID stages
                is_stalled = True
            
            # Renk seç
            if is_bubble:
                # Bubble: light gray with dashed border
                bg_color = QColor('#fafafa')
                border_color = QColor('#ff9800')
                text_color = QColor('#ff9800')
            elif is_stalled:
                # Stall: pink tint (pembe)
                bg_color = QColor('#fce4ec')
                border_color = QColor('#ec407a')
                text_color = QColor('#d81b60')
            elif is_active:
                bg_color = QColor(light_color)
                border_color = QColor(dark_color)
                text_color = QColor(dark_color)
            else:
                bg_color = QColor('#f1f3f4')
                border_color = QColor('#dadce0')
                text_color = QColor('#9aa0a6')
            
            # Kutu çiz (yuvarlatılmış köşeler)
            painter.setBrush(bg_color)
            if is_bubble:
                # Dashed border for bubbles
                pen = QPen(border_color, 2, Qt.DashLine)
            else:
                pen = QPen(border_color, 2)
            painter.setPen(pen)
            painter.drawRoundedRect(x, y, stage_width, stage_height, 10, 10)
            
            # İsim (büyük)
            painter.setPen(text_color)
            font = QFont('Segoe UI', 14, QFont.Bold)
            painter.setFont(font)
            text_rect = painter.boundingRect(x, y + 10, stage_width, 25, 
                                            Qt.AlignCenter, name)
            painter.drawText(text_rect, Qt.AlignCenter, name)
            
            # Instruction or status indicator
            if is_bubble:
                # Show BUBBLE indicator
                font = QFont('Segoe UI', 10, QFont.Bold)
                painter.setFont(font)
                painter.setPen(QColor('#ff9800'))
                bubble_rect = painter.boundingRect(x + 5, y + 38, stage_width - 10, 30,
                                                Qt.AlignCenter, "BUBBLE")
                painter.drawText(bubble_rect, Qt.AlignCenter, "BUBBLE")
                
                # Small explanation
                font = QFont('Segoe UI', 7)
                painter.setFont(font)
                painter.setPen(QColor('#f57c00'))
                exp_rect = painter.boundingRect(x + 5, y + 55, stage_width - 10, 20,
                                               Qt.AlignCenter, "(NOP)")
                painter.drawText(exp_rect, Qt.AlignCenter, "(NOP)")
                
            elif is_stalled:
                # Show STALL indicator
                font = QFont('Segoe UI', 10, QFont.Bold)
                painter.setFont(font)
                painter.setPen(QColor('#d81b60'))
                stall_rect = painter.boundingRect(x + 5, y + 38, stage_width - 10, 30,
                                                Qt.AlignCenter, "STALLED")
                painter.drawText(stall_rect, Qt.AlignCenter, "STALLED")
                
                # Small explanation
                font = QFont('Segoe UI', 7)
                painter.setFont(font)
                painter.setPen(QColor('#c2185b'))
                exp_rect = painter.boundingRect(x + 5, y + 55, stage_width - 10, 20,
                                               Qt.AlignCenter, "(waiting)")
                painter.drawText(exp_rect, Qt.AlignCenter, "(waiting)")
                
            elif is_active and self.assembly_lines:
                # DÜZELTME: PC bilgisini doğrudan ilgili sözlükten alıyoruz
                pc = data.get('pc', -1)
                
                # Assembly instruction'ı al
                asm_index = -1
                if pc >= 0:
                    asm_index = pc  # word-addressable: PC = instruction index
                if 0 <= asm_index < len(self.assembly_lines):
                    instruction = self.assembly_lines[asm_index]
                    # Çok uzunsa kısalt
                    if len(instruction) > 18:
                        instruction = instruction[:15] + "..."
                    
                    font = QFont('Consolas', 8)
                    painter.setFont(font)
                    painter.setPen(text_color)
                    inst_rect = painter.boundingRect(x + 5, y + 38, stage_width - 10, 30,
                                                    Qt.AlignCenter | Qt.TextWordWrap, instruction)
                    painter.drawText(inst_rect, Qt.AlignCenter | Qt.TextWordWrap, instruction)
            
            # Alt yazı (küçük)
            font = QFont('Segoe UI', 8)
            painter.setFont(font)
            painter.setPen(QColor('#5f6368') if is_active else QColor('#9aa0a6'))
            text_rect = painter.boundingRect(x, y + 80, stage_width, 28,
                                            Qt.AlignCenter | Qt.TextWordWrap, full_name)
            painter.drawText(text_rect, Qt.AlignCenter | Qt.TextWordWrap, full_name)
            
            # Ok çiz (daha ince ve modern)
            if i < len(stages) - 1:
                arrow_x1 = x + stage_width + 8
                arrow_x2 = x + stage_width + spacing - 8
                arrow_y = y + stage_height // 2
                
                # Ok gövdesi
                arrow_pen = QPen(QColor('#dadce0'), 2)
                painter.setPen(arrow_pen)
                painter.drawLine(arrow_x1, arrow_y, arrow_x2, arrow_y)
                
                # Ok başı (üçgen şeklinde)
                painter.setBrush(QColor('#dadce0'))
                painter.setPen(Qt.NoPen)
                arrow_head = QPolygon([
                    QPoint(arrow_x2, arrow_y),
                    QPoint(arrow_x2 - 8, arrow_y - 5),
                    QPoint(arrow_x2 - 8, arrow_y + 5)
                ])
                painter.drawPolygon(arrow_head)


class ModernSimulator(QMainWindow):
    """Modern İşlemci Simülatörü Ana Pencere"""
    
    def __init__(self):
        super().__init__()
        self.processor = ProcessorCore()
        self.assembler = Assembler()
        self.is_running = False
        self.machine_code = []
        self.assembly_lines = []
        self.original_code_lines = []  # Original code with comments/labels
        self.pc_to_line_map = {}  # Maps PC to original line number
        
        # Track updated registers and memory for highlighting
        self.last_updated_register = -1
        self.last_updated_memory = -1
        
        self.init_ui()
        self.apply_styles()
        
    def init_ui(self):
        """Arayüzü oluştur"""
        self.setWindowTitle("16-bit Processor Simulator - Pipeline Architecture")
        self.setGeometry(100, 100, 1600, 950)
        
        # Ana widget ve layout
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        main_layout = QVBoxLayout(main_widget)
        main_layout.setSpacing(10)
        main_layout.setContentsMargins(15, 15, 15, 15)
        
        # Ana içerik (sabit layout, genişlik oranları ayarlı)
        content_layout = QHBoxLayout()
        content_layout.setSpacing(12)
        content_layout.setContentsMargins(0, 0, 0, 0)
        
        # Sol panel (%47)
        left_panel = self.create_left_panel()
        content_layout.addWidget(left_panel, 47)  # 47 / (47+53) ≈ %47
        
        # Sağ panel (%53)
        right_panel = self.create_right_panel()
        content_layout.addWidget(right_panel, 53)  # 53 / (47+53) ≈ %53
        
        main_layout.addLayout(content_layout)
        
    def create_left_panel(self):
        """Sol panel - Assembly ve Machine Code"""
        panel = QWidget()
        layout = QVBoxLayout(panel)
        layout.setSpacing(10)
        layout.setContentsMargins(0, 0, 0, 0)
        
        # Assembly Programı
        asm_frame = QFrame()
        asm_frame.setObjectName("sectionFrame")
        asm_main_layout = QVBoxLayout(asm_frame)
        asm_main_layout.setContentsMargins(20, 15, 20, 15)
        asm_main_layout.setSpacing(12)
        
        # Başlık
        asm_title_layout = QHBoxLayout()
        
        asm_title = QLabel("Assembly Code Editor")
        asm_title.setObjectName("sectionTitle")
        asm_title_layout.addWidget(asm_title)
        asm_title_layout.addStretch()
        asm_main_layout.addLayout(asm_title_layout)
        
        self.code_editor = QTextEdit()
        self.code_editor.setObjectName("codeEditor")
        self.code_editor.setFont(QFont("Consolas", 11))  # Font boyutu büyütüldü: 10 → 11
        self.code_editor.setPlainText("")  # Start with empty editor
        asm_main_layout.addWidget(self.code_editor)
        
        # Kontrol butonları (küçük ve kompakt)
        btn_frame = QFrame()
        btn_layout = QHBoxLayout(btn_frame)
        btn_layout.setContentsMargins(0, 10, 0, 0)
        btn_layout.setSpacing(10)
        
        # Run button
        self.run_btn = QPushButton("▶ Run")
        self.run_btn.setObjectName("runButton")
        self.run_btn.setMinimumHeight(36)
        self.run_btn.clicked.connect(self.run_program)
        btn_layout.addWidget(self.run_btn)
        
        # Step button
        self.step_btn = QPushButton("⏭ Step")
        self.step_btn.setObjectName("stepButton")
        self.step_btn.setMinimumHeight(36)
        self.step_btn.clicked.connect(self.step_execution)
        btn_layout.addWidget(self.step_btn)
        
        # Reset button
        self.reset_btn = QPushButton("⭯ Reset")
        self.reset_btn.setObjectName("resetButton")
        self.reset_btn.setMinimumHeight(36)
        self.reset_btn.clicked.connect(self.reset_processor)
        btn_layout.addWidget(self.reset_btn)
        
        btn_layout.addStretch()
        
        # Cycle ve PC bilgileri (sağ altta)
        self.cycle_label = QLabel("Cycle: 0")
        self.cycle_label.setObjectName("infoLabel")
        self.cycle_label.setStyleSheet("font-size: 12px; color: #5f6368; font-weight: 600;")
        btn_layout.addWidget(self.cycle_label)
        
        self.pc_label = QLabel("PC: 0")
        self.pc_label.setObjectName("infoLabel")
        self.pc_label.setStyleSheet("font-size: 12px; color: #5f6368; font-weight: 600;")
        btn_layout.addWidget(self.pc_label)
        
        asm_main_layout.addWidget(btn_frame)
        
        layout.addWidget(asm_frame)
        
        # Machine Code Tablosu
        mc_frame = QFrame()
        mc_frame.setObjectName("sectionFrame")
        mc_main_layout = QVBoxLayout(mc_frame)
        mc_main_layout.setContentsMargins(20, 15, 20, 15)
        mc_main_layout.setSpacing(12)
        
        # Başlık
        mc_title_layout = QHBoxLayout()
        
        mc_title = QLabel("Instruction Memory")
        mc_title.setObjectName("sectionTitle")
        mc_title_layout.addWidget(mc_title)
        mc_title_layout.addStretch()
        mc_main_layout.addLayout(mc_title_layout)
        
        self.machine_table = QTableWidget()
        self.machine_table.setObjectName("machineTable")
        self.machine_table.setColumnCount(4)
        self.machine_table.setHorizontalHeaderLabels(["Address", "Assembly", "Machine Code (Binary)", "Hex"])
        self.machine_table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.machine_table.setFont(QFont("Consolas", 9))
        self.machine_table.setShowGrid(False)  # Izgarayı kapat (CSS ile sadece alt çizgi veriyoruz)
        self.machine_table.verticalHeader().setVisible(False) # Soldaki satır numaralarını (1,2,3) gizle
        self.machine_table.verticalHeader().setDefaultSectionSize(45) # Satır yüksekliğini artır (Daha ferah)
        self.machine_table.setFocusPolicy(Qt.NoFocus) # Tıklayınca çıkan nokta nokta çizgiyi kaldırır
        self.machine_table.setSelectionMode(QTableWidget.NoSelection) # Seçimi tamamen kapat
        mc_main_layout.addWidget(self.machine_table)
        
        layout.addWidget(mc_frame)
        
        return panel
        
    def create_right_panel(self):
        """Sağ panel - Pipeline, Registers, Memory"""
        panel = QWidget()
        layout = QVBoxLayout(panel)
        layout.setSpacing(10)
        layout.setContentsMargins(0, 0, 0, 0)
        
        # Hazard Durumları
        hazard_frame = QFrame()
        hazard_frame.setObjectName("hazardFrame")
        hazard_main_layout = QVBoxLayout(hazard_frame)
        hazard_main_layout.setContentsMargins(20, 15, 20, 15)
        hazard_main_layout.setSpacing(15)
        
        # Başlık
        title_layout = QHBoxLayout()
        
        title_label = QLabel("Pipeline Hazard Detection")
        title_label.setObjectName("hazardTitle")
        title_layout.addWidget(title_label)
        title_layout.addStretch()
        hazard_main_layout.addLayout(title_layout)
        
        # Hazard mesajı (büyük alan)
        self.hazard_label = QLabel("No hazard detected yet")
        self.hazard_label.setObjectName("hazardMessage")
        self.hazard_label.setAlignment(Qt.AlignCenter)
        self.hazard_label.setMinimumHeight(80)
        hazard_main_layout.addWidget(self.hazard_label)
        
        # Ayırıcı çizgi
        separator = QFrame()
        separator.setFrameShape(QFrame.HLine)
        separator.setStyleSheet("background-color: #e8eaed; max-height: 1px;")
        hazard_main_layout.addWidget(separator)
        
        # Legend (Data, Control, Bubble, Stall)
        legend_layout = QHBoxLayout()
        legend_layout.setSpacing(20)
        
        for color, text in [("FDD835", "Data Hazard"), ("42A5F5", "Control Hazard"), 
                            ("FF9800", "Bubble"), ("EC407A", "Stall")]:
            legend_item = QHBoxLayout()
            legend_item.setSpacing(8)
            
            dot = QLabel("●")
            dot.setStyleSheet(f"color: #{color}; font-size: 14px;")
            legend_item.addWidget(dot)
            
            label = QLabel(text)
            label.setObjectName("legendText")
            legend_item.addWidget(label)
            
            legend_layout.addLayout(legend_item)
        
        legend_layout.addStretch()
        hazard_main_layout.addLayout(legend_layout)
        
        layout.addWidget(hazard_frame)
        
        # Pipeline Görselleştirme
        pipeline_frame = QFrame()
        pipeline_frame.setObjectName("sectionFrame")
        pipeline_frame.setMaximumHeight(220)
        pipeline_main_layout = QVBoxLayout(pipeline_frame)
        pipeline_main_layout.setContentsMargins(20, 10, 20, 10)
        pipeline_main_layout.setSpacing(5)
        
        # Başlık
        pipeline_title_layout = QHBoxLayout()
        
        pipeline_title = QLabel("Pipeline Stages")
        pipeline_title.setObjectName("sectionTitle")
        pipeline_title_layout.addWidget(pipeline_title)
        pipeline_title_layout.addStretch()
        pipeline_main_layout.addLayout(pipeline_title_layout)
        
        self.pipeline_widget = PipelineWidget()
        self.pipeline_widget.set_processor(self.processor)
        pipeline_main_layout.addWidget(self.pipeline_widget)
        
        layout.addWidget(pipeline_frame)
        
        # Alt bölüm - Registers ve Memory (sabit layout, splitter yok)
        
        # Registers
        reg_frame = QFrame()
        reg_frame.setObjectName("sectionFrame")
        reg_main_layout = QVBoxLayout(reg_frame)
        reg_main_layout.setContentsMargins(20, 15, 20, 15)
        reg_main_layout.setSpacing(12)
        
        # Başlık
        reg_title_layout = QHBoxLayout()
        
        reg_title = QLabel("Register File (R0-R7)")
        reg_title.setObjectName("sectionTitle")
        reg_title_layout.addWidget(reg_title)
        reg_title_layout.addStretch()
        reg_main_layout.addLayout(reg_title_layout)
        
        # Register table
        self.register_table = QTableWidget()
        self.register_table.setObjectName("registerTable")
        self.register_table.setColumnCount(3)
        self.register_table.setHorizontalHeaderLabels(["Register", "Değer (Dec)", "Değer (Hex)"])
        self.register_table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.register_table.setFont(QFont("Consolas", 9))
        self.register_table.setRowCount(8)
        self.register_table.setAlternatingRowColors(False)
        self.register_table.setShowGrid(False)  # Izgarayı kapat (CSS ile sadece alt çizgi veriyoruz)
        self.register_table.verticalHeader().setVisible(False) # Soldaki satır numaralarını (1,2,3) gizle
        self.register_table.verticalHeader().setDefaultSectionSize(38) # Satır yüksekliğini azalt (45 → 38)
        self.register_table.setFocusPolicy(Qt.NoFocus) # Tıklayınca çıkan nokta nokta çizgiyi kaldırır
        self.register_table.setSelectionMode(QTableWidget.NoSelection) # Seçimi tamamen kapat
        
        # Scroll policy - tüm satırları göster, scroll bar'ı kaldır
        self.register_table.setVerticalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.register_table.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        
        # Sabit yükseklik ayarla (8 satır + header + padding)
        # Header: ~35px, Her satır: 38px, Padding: ~10px
        fixed_height = 35 + (8 * 38) + 10
        self.register_table.setMinimumHeight(fixed_height)
        self.register_table.setMaximumHeight(fixed_height)
        
        # Initialize register rows
        for i in range(8):
            reg_item = QTableWidgetItem(f"R{i}")
            dec_item = QTableWidgetItem("0")
            hex_item = QTableWidgetItem("0x0000")
            
            # İlk açılışta beyaz arka plan ata
            white_bg = QColor(255, 255, 255)
            reg_item.setBackground(white_bg)
            dec_item.setBackground(white_bg)
            hex_item.setBackground(white_bg)
            
            # Yazı rengini de siyah yapalım (garanti olsun)
            text_color = QColor(32, 33, 36)
            reg_item.setForeground(text_color)
            dec_item.setForeground(text_color)
            hex_item.setForeground(text_color)
            
            self.register_table.setItem(i, 0, reg_item)
            self.register_table.setItem(i, 1, dec_item)
            self.register_table.setItem(i, 2, hex_item)
        
        reg_main_layout.addWidget(self.register_table)
        
        # Memory
        mem_frame = QFrame()
        mem_frame.setObjectName("sectionFrame")
        mem_main_layout = QVBoxLayout(mem_frame)
        mem_main_layout.setContentsMargins(20, 15, 20, 15)
        mem_main_layout.setSpacing(12)
        
        # Başlık
        mem_title_layout = QHBoxLayout()
        
        mem_title = QLabel("Data Memory")
        mem_title.setObjectName("sectionTitle")
        mem_title_layout.addWidget(mem_title)
        mem_title_layout.addStretch()
        mem_main_layout.addLayout(mem_title_layout)
        
        self.memory_table = QTableWidget()
        self.memory_table.setObjectName("memoryTable")
        self.memory_table.setColumnCount(3)
        self.memory_table.setHorizontalHeaderLabels(["Address", "Value (Dec)", "Value (Hex)"])
        self.memory_table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.memory_table.setFont(QFont("Consolas", 9))
        self.memory_table.setAlternatingRowColors(False)
        self.memory_table.setShowGrid(False)  # Izgarayı kapat (CSS ile sadece alt çizgi veriyoruz)
        self.memory_table.verticalHeader().setVisible(False) # Soldaki satır numaralarını (1,2,3) gizle
        self.memory_table.verticalHeader().setDefaultSectionSize(45) # Satır yüksekliğini artır (Daha ferah)
        self.memory_table.setFocusPolicy(Qt.NoFocus) # Tıklayınca çıkan nokta nokta çizgiyi kaldırır
        self.memory_table.setSelectionMode(QTableWidget.NoSelection) # Seçimi tamamen kapat
        mem_main_layout.addWidget(self.memory_table)
        
        # Splitter yerine sabit layout kullan (siyah çubuk kalkacak)
        bottom_container = QWidget()
        bottom_layout = QHBoxLayout(bottom_container)
        bottom_layout.setContentsMargins(0, 0, 0, 0)  # Kenar boşluklarını sıfırla
        bottom_layout.setSpacing(10)  # İki tablo arasına hafif boşluk
        
        # Tabloları ekle (stretch=1 ikisine de eşit alan verir)
        bottom_layout.addWidget(reg_frame, 1)
        bottom_layout.addWidget(mem_frame, 1)
        
        # Konteyneri ana layout'a ekle (Buradaki 1, üstteki pipeline'dan kalan alanı buraya verir)
        layout.addWidget(bottom_container, 1)
        
        return panel
        
    def apply_styles(self):
        """Modern stiller uygula - Premium Web-Style Tasarım"""
        self.setStyleSheet("""
            QMainWindow {
                background-color: #f8f9fa; /* Hafif gri arka plan, gözü yormaz */
            }
            
            /* --- TABLO GENEL TASARIMI --- */
            QTableWidget {
                background-color: #ffffff;
                border: 1px solid #e0e0e0;
                border-radius: 8px;
                gridline-color: transparent; /* Varsayılan ızgarayı gizle */
                font-family: 'Segoe UI', 'Roboto', sans-serif;
                font-size: 13px;
                color: #333333;
                selection-background-color: #e8f0fe;
                selection-color: #1967d2;
                outline: none;
            }
            
            /* Hücre Tasarımı - Ferah görünüm */
            QTableWidget::item {
                border-bottom: 1px solid #f0f0f0; /* Sadece alt çizgi */
                padding-left: 15px; /* Soldan boşluk */
                padding-right: 15px;
                padding-top: 5px;
                padding-bottom: 5px;
            }
            
            /* Seçili Hücre */
            QTableWidget::item:selected {
                background-color: #e8f0fe;
                color: #1967d2;
                border-bottom: 1px solid #e8f0fe;
            }

            /* --- HEADER (BAŞLIK) TASARIMI --- */
            QHeaderView {
                background-color: transparent;
                border: none;
            }
            
            QHeaderView::section {
                background-color: #ffffff;
                color: #80868b; /* Daha soft gri başlıklar */
                font-weight: 700;
                font-size: 11px;
                text-transform: uppercase; /* Modern his için büyük harf */
                border: none;
                border-bottom: 2px solid #eaeaea;
                padding: 12px 15px; /* Başlık boşlukları */
                text-align: left;
            }
            
            /* --- ÇERÇEVELER VE KARTLAR --- */
            #sectionFrame, #hazardFrame {
                background-color: white;
                border: 1px solid #eaecf0;
                border-radius: 12px;
                /* Hafif gölge efekti (PySide'da CSS ile sınırlıdır ama border ile desteklenir) */
            }

            #sectionTitle, #hazardTitle {
                font-size: 15px;
                font-weight: 700;
                color: #1a1a1a;
                padding-bottom: 5px;
            }

            /* --- BUTONLAR --- */
            QPushButton#runButton {
                background-color: #000000; /* Simsiyah modern buton */
                color: white;
                border-radius: 6px;
                padding: 8px 20px;
                font-weight: 600;
                border: none;
            }
            QPushButton#runButton:hover { background-color: #333333; }
            
            QPushButton#stepButton, QPushButton#resetButton {
                background-color: white;
                color: #37352f;
                border: 1px solid #d0d7de;
                border-radius: 6px;
                padding: 8px 16px;
                font-weight: 600;
            }
            QPushButton#stepButton:hover, QPushButton#resetButton:hover { 
                background-color: #f3f4f6; 
            }

            /* --- SCROLLBAR --- */
            QScrollBar:vertical {
                border: none;
                background: #f1f1f1;
                width: 8px;
                border-radius: 4px;
            }
            QScrollBar::handle:vertical {
                background: #c1c1c1;
                border-radius: 4px;
            }
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical { height: 0px; }

            /* --- KOD EDITORU (Assembly Code Editor) --- */
            #codeEditor {
                background-color: #ffffff;
                border: 1px solid #dadce0;
                border-radius: 8px;
                padding: 12px;
                color: #000000;
                font-weight: normal;
                selection-background-color: #d2e3fc;
            }

            /* --- LEGEND TEXT --- */
            #legendText {
                font-size: 12px;
                color: #5f6368;
            }
        """)
        
    @Slot()
    def run_program(self):
        """Programı çalıştır"""
        if not self.is_running:
            if self.assemble_and_load():
                self.is_running = True
                self.run_loop()
        
    def run_loop(self):
        """Çalışma döngüsü"""
        if self.is_running:
            # Track register and memory updates
            old_registers = self.processor.registers.copy()
            old_memory = self.processor.data_memory.copy()
            
            stall, flush = self.processor.clock_cycle()
            
            # Detect which register was updated
            self.last_updated_register = -1
            for i in range(8):
                if self.processor.registers[i] != old_registers[i]:
                    self.last_updated_register = i
                    break
            
            # Detect which memory was updated (word-aligned byte address)
            self.last_updated_memory = -1
            # Check for newly written addresses (word-aligned)
            for addr in self.processor.written_memory:
                if addr < len(self.processor.data_memory) - 1:
                    # Check if this word changed
                    old_low = old_memory[addr]
                    old_high = old_memory[addr + 1]
                    new_low = self.processor.data_memory[addr]
                    new_high = self.processor.data_memory[addr + 1]
                    if old_low != new_low or old_high != new_high:
                        self.last_updated_memory = addr  # Store byte address
                        break
            
            # Update pipeline widget with hazard state
            self.pipeline_widget.set_hazard_state(stall, flush)
            
            self.update_all_displays()
            self.update_hazard_display(stall, flush)
            
            # Check if finished
            if not any([self.processor.IF_ID['valid'], self.processor.ID_EX['valid'],
                       self.processor.EX_MEM['valid'], self.processor.MEM_WB['valid']]):
                self.is_running = False
                
                # Görselleştirmeyi temizle (Böylece ekranda 'NOP' asılı kalmaz)
                self.processor.MEM_WB_old['valid'] = False 
                self.pipeline_widget.update()
                
                self.show_completion_message()
                return
            
            QTimer.singleShot(50, self.run_loop)
        
    def show_completion_message(self):
        """Show program completion message with statistics"""
        # Calculate performance metrics
        total_cycles = self.processor.cycle
        instr_count = max(self.processor.instructions_completed, 1)
        cpi = total_cycles / instr_count
        efficiency = (instr_count / total_cycles * 100) if total_cycles > 0 else 100
        
        # Calculate forwarding effectiveness
        forwarding_ops = self.processor.forwarding_count
        stalls_prevented = forwarding_ops
        
        # Colors based on hazard presence
        dh_class = "hazard-ok" if self.processor.data_hazards == 0 else "hazard-bad"
        ch_class = "hazard-ok" if self.processor.control_hazards == 0 else "hazard-bad"
        stall_class = "hazard-ok" if self.processor.stalls == 0 else "hazard-bad"
        
        message = f"""
<html>
  <head>
    <style>
      body {{
        margin: 0;
        background: #1f1f1f;
        font-family: 'Segoe UI', 'Roboto', sans-serif;
      }}
      .container {{
        background: #2D2D2D;
        color: #E0E0E0;
        border-radius: 10px;
        padding: 20px;
        box-shadow: 0 10px 24px rgba(0,0,0,0.45);
      }}
      h2 {{
        text-align: center;
        color: #4DD0E1;
        margin: 0 0 14px 0;
        font-weight: 700;
      }}
      hr {{
        border: 0;
        border-top: 1px solid #4DD0E1;
        margin: 10px 0 14px 0;
      }}
      .card {{
        width: 100%;
        background: #383838;
        border-radius: 8px;
        padding: 15px;
        border-collapse: collapse;
        margin-bottom: 14px;
      }}
      .card td {{
        padding: 6px 10px;
        vertical-align: top;
        border: none;
      }}
      .value {{
        font-size: 24px;
        font-weight: 700;
        color: #FFFFFF;
      }}
      .value-accent-green {{ color: #76FF03; }}
      .value-accent-gold {{ color: #FFD740; }}
      .label {{
        display: block;
        margin-top: 2px;
        font-size: 12px;
        color: #B0B0B0;
        font-weight: 500;
      }}
      .hazard-ok {{
        color: #76FF03;
        font-weight: 700;
      }}
      .hazard-bad {{
        color: #FF5252;
        font-weight: 700;
      }}
    </style>
  </head>
  <body>
    <div class="container">
      <h2>Simulation Results</h2>
      
      <table class="card">
        <tr>
          <td>
            <span class="value">{total_cycles}</span>
            <span class="label">Total Cycles</span>
          </td>
          <td>
            <span class="value">{instr_count}</span>
            <span class="label">Instruction Count</span>
          </td>
          <td>
            <span class="value value-accent-green">{cpi:.2f}</span>
            <span class="label">CPI</span>
          </td>
          <td>
            <span class="value value-accent-gold">{efficiency:.1f}%</span>
            <span class="label">Efficiency</span>
          </td>
        </tr>
      </table>
      
      <hr />
      <h4 style="margin:0 0 6px 0; color:#B0BEC5;">Hazard Analysis</h4>
      <table class="card">
        <tr>
          <td>
            <span class="value {dh_class}">{self.processor.data_hazards}</span>
            <span class="label">Data Hazards</span>
          </td>
          <td>
            <span class="value {ch_class}">{self.processor.control_hazards}</span>
            <span class="label">Control Hazards</span>
          </td>
          <td>
            <span class="value {stall_class}">{self.processor.stalls}</span>
            <span class="label">Stalls</span>
          </td>
        </tr>
      </table>
      
      <h4 style="margin:0 0 6px 0; color:#B0BEC5;">Performance</h4>
      <table class="card">
        <tr>
          <td>
            <span class="value">{forwarding_ops}</span>
            <span class="label">Forwarding Operations</span>
          </td>
          <td>
            <span class="value">{stalls_prevented}</span>
            <span class="label">Stalls Prevented</span>
          </td>
        </tr>
      </table>
    </div>
  </body>
</html>
"""
        
        msg_box = QMessageBox(self)
        msg_box.setWindowTitle("Program Completed")
        msg_box.setTextFormat(Qt.RichText)
        msg_box.setText(message)
        msg_box.setStandardButtons(QMessageBox.Ok)
        msg_box.exec()
    
    def update_hazard_display(self, stall, flush):
        """Update hazard status display based on current pipeline state"""
        if stall:
            title = "<b>Data Hazard Detected - Pipeline Stall</b>"
            reason = f"<br><span style='font-size:11px; font-weight:normal'>{self.processor.hazard_reason}</span>"
            self.hazard_label.setText(title + reason)
            self.hazard_label.setTextFormat(Qt.RichText)
            self.hazard_label.setStyleSheet("""
                font-size: 14px;
                color: #F9A825;
                background-color: #fffbf0;
                border: 1px solid #FDD835;
                border-radius: 8px;
                padding: 20px;
            """)
        elif flush:
            title = "<b>Control Hazard - Branch/Jump Taken (Pipeline Flush)</b>"
            reason = f"<br><span style='font-size:11px; font-weight:normal'>{self.processor.hazard_reason}</span>"
            self.hazard_label.setText(title + reason)
            self.hazard_label.setTextFormat(Qt.RichText)
            self.hazard_label.setStyleSheet("""
                font-size: 14px;
                color: #1976D2;
                background-color: #f0f7ff;
                border: 1px solid #42A5F5;
                border-radius: 8px;
                padding: 20px;
            """)
        elif self.processor.forwarding_log:
            # Forwarding detected - positive informational message
            title = "<b>✓ Data Dependency Resolved - Forwarding</b>"
            forwarding_details = "<br>".join(self.processor.forwarding_log)
            reason = f"<br><span style='font-size:11px; font-weight:normal'>{forwarding_details}</span>"
            self.hazard_label.setText(title + reason)
            self.hazard_label.setTextFormat(Qt.RichText)
            self.hazard_label.setStyleSheet("""
                font-size: 14px;
                color: #2E7D32;
                background-color: #f1f8f4;
                border: 1px solid #81C784;
                border-radius: 8px;
                padding: 20px;
            """)
        else:
            self.hazard_label.setText("No hazard detected yet")
            self.hazard_label.setTextFormat(Qt.PlainText)
            self.hazard_label.setStyleSheet("""
                font-size: 14px;
                color: #5f6368;
                background-color: #f8f9fa;
                border-radius: 8px;
                padding: 20px;
            """)
    
    @Slot()
    def step_execution(self):
        """Tek adım çalıştır"""
        if self.processor.cycle == 0:
            self.assemble_and_load()
        
        # Check if program is already finished (but not at the very start)
        # PC should be at or past program end AND pipeline should be empty
        if (self.processor.cycle > 0 and 
            self.processor.pc >= self.processor.program_end and
            not any([self.processor.IF_ID['valid'], self.processor.ID_EX['valid'],
                    self.processor.EX_MEM['valid'], self.processor.MEM_WB['valid']])):
            # Show completion message
            self.show_completion_message()
            return
        
        # Track register and memory updates
        old_registers = self.processor.registers.copy()
        old_memory = self.processor.data_memory.copy()
        
        stall, flush = self.processor.clock_cycle()
        
        # Detect which register was updated
        self.last_updated_register = -1
        for i in range(8):
            if self.processor.registers[i] != old_registers[i]:
                self.last_updated_register = i
                break
        
        # Detect which memory was updated (word-aligned byte address)
        self.last_updated_memory = -1
        # Check for newly written addresses (word-aligned)
        for addr in self.processor.written_memory:
            if addr < len(self.processor.data_memory) - 1:
                # Check if this word changed
                old_low = old_memory[addr]
                old_high = old_memory[addr + 1]
                new_low = self.processor.data_memory[addr]
                new_high = self.processor.data_memory[addr + 1]
                if old_low != new_low or old_high != new_high:
                    self.last_updated_memory = addr  # Store byte address
                    break
        
        # Update pipeline widget with hazard state
        self.pipeline_widget.set_hazard_state(stall, flush)
        
        self.update_all_displays()
        
        # === DEBUG OUTPUT TO TERMINAL ===
        print(f"\n{'='*80}")
        print(f"CYCLE {self.processor.cycle} | PC: {self.processor.pc}")
        print(f"{'='*80}")
        
        # Show pipeline stages
        if self.processor.IF_ID['valid']:
            pc = self.processor.IF_ID['pc']
            if 0 <= pc < len(self.assembly_lines):
                print(f"  [IF/ID]  PC={pc}: {self.assembly_lines[pc]}")
        
        if self.processor.ID_EX['valid']:
            pc = self.processor.ID_EX['pc']
            if 0 <= pc < len(self.assembly_lines):
                print(f"  [ID/EX]  PC={pc}: {self.assembly_lines[pc]}")
        
        if self.processor.EX_MEM['valid']:
            pc = self.processor.EX_MEM['pc']
            if 0 <= pc < len(self.assembly_lines):
                print(f"  [EX/MEM] PC={pc}: {self.assembly_lines[pc]}")
        
        if self.processor.MEM_WB['valid']:
            pc = self.processor.MEM_WB['pc']
            if 0 <= pc < len(self.assembly_lines):
                print(f"  [MEM/WB] PC={pc}: {self.assembly_lines[pc]}")
        
        # Show hazards/forwarding
        if stall:
            print(f"\n  ⚠️  STALL: {self.processor.hazard_reason}")
        elif flush:
            print(f"\n  🔵 FLUSH: {self.processor.hazard_reason}")
        elif self.processor.forwarding_log:
            print(f"\n  ✓ FORWARDING:")
            for fw in self.processor.forwarding_log:
                print(f"      {fw}")
        
        # Show register changes
        if self.last_updated_register != -1:
            old_val = old_registers[self.last_updated_register]
            new_val = self.processor.registers[self.last_updated_register]
            print(f"\n  📝 Register Update: R{self.last_updated_register}: {old_val} → {new_val}")
        
        # Show memory changes (display as 16-bit word)
        if self.last_updated_memory != -1:
            addr = self.last_updated_memory
            # Read old word value
            old_low = old_memory[addr]
            old_high = old_memory[addr + 1]
            old_word = (old_high << 8) | old_low
            # Read new word value
            new_low = self.processor.data_memory[addr]
            new_high = self.processor.data_memory[addr + 1]
            new_word = (new_high << 8) | new_low
            print(f"\n  💾 Memory Update: Byte[{addr}]: 0x{old_word:04X} → 0x{new_word:04X}")
        
        print()  # Empty line for readability
        
        # Update hazard display using shared method
        self.update_hazard_display(stall, flush)
        
        # Check if program finished after this step
        if not any([self.processor.IF_ID['valid'], self.processor.ID_EX['valid'],
                   self.processor.EX_MEM['valid'], self.processor.MEM_WB['valid']]):
            # Görselleştirmeyi temizle (Böylece ekranda son komut asılı kalmaz)
            self.processor.MEM_WB_old['valid'] = False 
            self.pipeline_widget.update()
            
            # Show completion message
            self.show_completion_message()
        
    @Slot()
    def reset_processor(self):
        """İşlemciyi sıfırla"""
        self.is_running = False
        self.processor.reset()
        self.machine_code = []
        self.assembly_lines = []
        self.original_code_lines = []
        self.pc_to_line_map = {}
        self.last_updated_register = -1
        self.last_updated_memory = -1
        
        # Reset assembly display to plain text (remove HTML formatting)
        if self.code_editor.toPlainText():
            plain_code = self.code_editor.toPlainText()
            # Remove any arrow markers if present
            lines = plain_code.split('\n')
            clean_lines = []
            for line in lines:
                if line.startswith('→ '):
                    clean_lines.append(line[2:])  # Remove arrow
                elif line.startswith('  '):
                    clean_lines.append(line[2:])  # Remove padding
                else:
                    clean_lines.append(line)
            self.code_editor.setPlainText('\n'.join(clean_lines))
        
        # Reset hazard display (clear hazard warnings)
        self.update_hazard_display(False, False)
        
        # Reset pipeline widget hazard state
        self.pipeline_widget.set_hazard_state(False, False)
        
        self.update_all_displays()
        self.machine_table.setRowCount(0)
        QMessageBox.information(self, "Reset", "Processor successfully reset!")
        
    def assemble_and_load(self):
        """Kodu derle ve yükle"""
        code = self.code_editor.toPlainText()
        machine_code, assembly_lines, errors = self.assembler.assemble(code)
        
        if errors:
            QMessageBox.critical(self, "Assembly Errors", "\n".join(errors))
            return False
        
        # Store original code lines
        self.original_code_lines = code.strip().split('\n')
        
        # Build PC to original line mapping
        self.pc_to_line_map = {}
        pc = 0
        for line_idx, line in enumerate(self.original_code_lines):
            # Clean line to check if it's an instruction
            clean = line.strip()
            if '#' in clean:
                clean = clean[:clean.index('#')].strip()
            
            # Skip empty lines
            if not clean:
                continue
            
            # Skip label-only lines
            if clean.endswith(':') and not any(clean.startswith(inst) for inst in 
                ['ADD', 'SUB', 'AND', 'OR', 'SLT', 'SLL', 'SRL', 'ADDI', 'LW', 'SW', 
                 'BEQ', 'BNE', 'J', 'JAL', 'JR', 'NOP']):
                continue
            
            # This line has an instruction, map PC to original line
            self.pc_to_line_map[pc] = line_idx
            pc += 1
            
        # Load to processor
        self.machine_code = machine_code
        self.assembly_lines = assembly_lines
        
        # Clear instruction memory (remove old program remnants)
        self.processor.instruction_memory = [0] * 256
        
        # Load new program
        for i, instruction in enumerate(machine_code):
            if i < len(self.processor.instruction_memory):
                self.processor.instruction_memory[i] = instruction
        
        # Set program end marker
        self.processor.program_end = len(machine_code)  # word-addressable PC
        
        # Update pipeline widget with assembly lines
        self.pipeline_widget.set_assembly_lines(assembly_lines)
        
        self.update_machine_code_table()
        return True
        
    def update_all_displays(self):
        """Tüm görüntüleri güncelle"""
        # Counters
        self.cycle_label.setText(f"Cycle: {self.processor.cycle}")
        self.pc_label.setText(f"PC: {self.processor.pc}")
        
        # Update Assembly Code Editor with current PC highlight
        self.update_assembly_display()
        
        # Pipeline
        self.pipeline_widget.update()
        
        # Registers - with proper highlighting (Görseldeki Yeşil Vurgu)
        for i in range(8):
            val = self.processor.registers[i]
            
            # Recreate items to force refresh
            for col in range(3):
                # Create NEW item each time
                item = QTableWidgetItem()
                
                # Set text based on column - ADD MARKER IF UPDATED
                if col == 0:
                    # First column: Add sparkle emoji + arrow if updated
                    if i == self.last_updated_register:
                        item.setText(f"→ R{i}")  # Sparkle emoji marker
                    else:
                        item.setText(f"   R{i}")  # Padding (3 spaces for alignment)
                elif col == 1:
                    item.setText(str(to_signed_16bit(val)))
                elif col == 2:
                    item.setText(f"0x{val:04X}")
                
                # Always center align
                item.setTextAlignment(Qt.AlignCenter)
                
                # Apply highlight if this register was updated
                if i == self.last_updated_register:
                    # Highlighted style - NEON GREEN BOLD TEXT for maximum visibility
                    item.setForeground(QColor(31, 95,196))    # Neon green text (more vibrant)
                    bold_font = QFont("Segoe UI", 11)          # Larger font size
                    bold_font.setBold(True)
                    item.setFont(bold_font)
                    # Vivid lime green background for strong contrast
                    item.setData(Qt.BackgroundRole, QColor(200, 255, 200))
                else:
                    # Normal style
                    item.setForeground(QColor(60, 60, 60))     # dark gray
                    item.setFont(QFont("Segoe UI", 9))
                    item.setData(Qt.BackgroundRole, QColor(255, 255, 255))
                
                # Disable editing
                item.setFlags(item.flags() & ~Qt.ItemIsEditable)
                
                # Set the item
                self.register_table.setItem(i, col, item)
        
        # Memory
        self.update_memory_table()
        
    def update_assembly_display(self):
        """Assembly code editor'da mevcut PC'yi highlight et"""
        # Only update if program is running or has run
        if not self.original_code_lines or self.processor.cycle == 0:
            return
        
        # Get current instruction in pipeline (IF/ID stage)
        # This shows the instruction currently being executed, not the next one
        if self.processor.IF_ID.get('valid', False):
            current_pc = self.processor.IF_ID.get('pc', self.processor.pc)
        else:
            # If IF/ID is invalid (bubble/flush), show PC
            current_pc = self.processor.pc
        
        # Get the original line number for current PC
        current_line_idx = self.pc_to_line_map.get(current_pc, -1)
        
        # Build HTML formatted assembly code with current instruction highlighted
        html_lines = []
        html_lines.append('<div style="font-family: Consolas, monospace; font-size: 11pt; line-height: 1.8; padding: 8px;">')
        
        for i, line in enumerate(self.original_code_lines):
            # Check if this is the current instruction line
            if i == current_line_idx and current_line_idx != -1:
                # Current instruction - BLUE BOLD with arrow
                html_lines.append(f'<div style="color: #1a73e8; font-weight: bold; background-color: #e8f0fe; padding: 2px 4px; border-radius: 3px; margin: 1px 0;">→ {line}</div>')
            else:
                # Normal line - preserve indentation and comments
                html_lines.append(f'<div style="color: #3c4043; padding: 2px 4px; margin: 1px 0;">  {line}</div>')
        
        html_lines.append('</div>')
        
        # Set HTML content
        html_content = ''.join(html_lines)
        
        # Update content
        self.code_editor.setHtml(html_content)
        
        # Auto-scroll to current line if needed
        if current_line_idx != -1 and current_line_idx > 5:
            # Scroll so current line is visible but not at top
            approx_line_height = 25  # pixels per line
            target_scroll = max(0, (current_line_idx - 3) * approx_line_height)
            self.code_editor.verticalScrollBar().setValue(target_scroll)
    
    def update_machine_code_table(self):
        """Machine code tablosunu güncelle"""
        self.machine_table.setRowCount(len(self.machine_code))
        
        for i, (instruction, asm) in enumerate(zip(self.machine_code, self.assembly_lines)):
            addr_item = QTableWidgetItem(f"{i}")  # Word-addressable: address = instruction index
            asm_item = QTableWidgetItem(asm)
            
            binary = f"{instruction:016b}"
            binary_formatted = f"{binary[:4]} {binary[4:8]} {binary[8:12]} {binary[12:]}"
            binary_item = QTableWidgetItem(binary_formatted)
            
            hex_item = QTableWidgetItem(f"0x{instruction:04X}")
            
            self.machine_table.setItem(i, 0, addr_item)
            self.machine_table.setItem(i, 1, asm_item)
            self.machine_table.setItem(i, 2, binary_item)
            self.machine_table.setItem(i, 3, hex_item)
            
    def update_memory_table(self):
        """Memory tablosunu güncelle - Yazılmış tüm adresleri göster (BYTE-ADDRESSABLE)"""
        # Get all written memory addresses (word-aligned byte addresses)
        written_addrs = sorted(self.processor.written_memory)
        
        # Read 16-bit words from byte-addressed memory
        written = []
        for addr in written_addrs:
            if addr < len(self.processor.data_memory) - 1:
                # Read word (little endian)
                low_byte = self.processor.data_memory[addr]
                high_byte = self.processor.data_memory[addr + 1]
                word_val = (high_byte << 8) | low_byte
                written.append((addr, word_val))
        
        # Store current row count before updating
        old_row_count = self.memory_table.rowCount()
        new_row_count = min(20, len(written))
        
        # Only update row count if different
        if old_row_count != new_row_count:
            self.memory_table.setRowCount(new_row_count)
        
        for row, (addr, val) in enumerate(written[:20]):
            # Recreate items to force refresh
            for col in range(3):
                # Create NEW item each time
                item = QTableWidgetItem()
                
                # Set text based on column - ADD MARKER IF UPDATED
                if col == 0:
                    # First column: Show BYTE address in hexadecimal with fire emoji if updated
                    hex_addr = f"0x{addr:04X}"  # Hexadecimal format (4 digits)
                    if addr == self.last_updated_memory:
                        item.setText(f"→ {hex_addr}")  # Fire emoji marker (byte address in hex)
                    else:
                        item.setText(f"    {hex_addr}")  # Padding (4 spaces for alignment)
                elif col == 1:
                    # Dec column (signed 16-bit)
                    signed_val = to_signed_16bit(val)
                    item.setText(str(signed_val))
                elif col == 2:
                    item.setText(f"0x{val:04X}")  # 16-bit values = 4 hex digits
                
                # Always center align
                item.setTextAlignment(Qt.AlignCenter)
                
                # Apply highlight if this memory location was updated
                if addr == self.last_updated_memory:
                    # Highlighted style - NEON ORANGE BOLD TEXT for maximum visibility
                    item.setForeground(QColor(255, 87, 34))   # Neon orange-red text (more vibrant)
                    bold_font = QFont("Segoe UI", 11)          # Larger font size
                    bold_font.setBold(True)
                    item.setFont(bold_font)
                    # Vivid orange-yellow background for strong contrast
                    item.setData(Qt.BackgroundRole, QColor(255, 224, 178))
                else:
                    # Normal style
                    item.setForeground(QColor(60, 60, 60))    # dark gray
                    item.setFont(QFont("Segoe UI", 9))
                    item.setData(Qt.BackgroundRole, QColor(255, 255, 255))
                
                # Disable editing
                item.setFlags(item.flags() & ~Qt.ItemIsEditable)
                
                # Set the item
                self.memory_table.setItem(row, col, item)


def main():
    app = QApplication(sys.argv)
    
    # Modern font
    app.setFont(QFont("Segoe UI", 10))
    
    window = ModernSimulator()
    window.show()
    
    sys.exit(app.exec())


if __name__ == "__main__":
    main()

