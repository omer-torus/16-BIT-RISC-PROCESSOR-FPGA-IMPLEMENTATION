/*
 * Comprehensive Test Bench for RISC Processor
 * Tests various instruction types, hazards, and pipeline behavior
 */

`timescale 1ns / 1ps

module tb_processor;

    // Clock and Reset
    reg clk;
    reg rst;
    
    // Debug outputs
    wire [7:0] pc;
    wire [15:0] instruction;
    wire stall;
    wire [31:0] cycle_count;
    
    // Instantiate processor
    processor_top uut(
        .clk(clk),
        .rst(rst),
        .pc_out(pc),
        .instruction_out(instruction),
        .stall_out(stall),
        .cycle_count(cycle_count)
    );
    
    // Clock generation (50 MHz = 20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        $dumpfile("processor_test.vcd");
        $dumpvars(0, tb_processor);
        
        // Initialize
        rst = 1;
        #25;
        rst = 0;
        
        $display("========================================");
        $display("   RISC Processor Test Bench Started   ");
        $display("========================================");
        $display("");
        
        // Monitor signals
        $monitor("Time=%0t | Cycle=%0d | PC=%0d | Instruction=0x%04h | Stall=%b", 
                 $time, cycle_count, pc, instruction, stall);
        
        // Run simulation
        #2000;
        
        $display("");
        $display("========================================");
        $display("   Test Results Summary                ");
        $display("========================================");
        $display("Total Cycles: %0d", cycle_count);
        $display("Final PC: %0d", pc);
        
        // Display register file contents
        $display("");
        $display("Register File Contents:");
        $display("R0 = 0x%04h (should always be 0)", uut.regfile.registers[0]);
        $display("R1 = 0x%04h", uut.regfile.registers[1]);
        $display("R2 = 0x%04h", uut.regfile.registers[2]);
        $display("R3 = 0x%04h", uut.regfile.registers[3]);
        $display("R4 = 0x%04h", uut.regfile.registers[4]);
        $display("R5 = 0x%04h", uut.regfile.registers[5]);
        $display("R6 = 0x%04h", uut.regfile.registers[6]);
        $display("R7 = 0x%04h", uut.regfile.registers[7]);
        
        // Display first few memory locations
        $display("");
        $display("Data Memory Contents (first 10 locations):");
        $display("MEM[0] = 0x%04h", uut.dmem.memory[0]);
        $display("MEM[1] = 0x%04h", uut.dmem.memory[1]);
        $display("MEM[2] = 0x%04h", uut.dmem.memory[2]);
        $display("MEM[3] = 0x%04h", uut.dmem.memory[3]);
        $display("MEM[4] = 0x%04h", uut.dmem.memory[4]);
        $display("MEM[5] = 0x%04h", uut.dmem.memory[5]);
        
        $display("");
        $display("========================================");
        $display("   Simulation Complete                 ");
        $display("========================================");
        
        $finish;
    end
    
    // Load test program into instruction memory
    initial begin
        // Test Program 1: Basic arithmetic and load-use hazard
        // This program tests:
        // - Immediate instructions (ADDI)
        // - R-type arithmetic (ADD, SUB)
        // - Memory operations (SW, LW)
        // - Load-use hazard detection
        
        // Program:
        // 0: ADDI R1, R0, 10    (R1 = 10)
        // 1: ADDI R2, R0, 20    (R2 = 20)
        // 2: ADD  R3, R1, R2    (R3 = R1 + R2 = 30)
        // 3: SUB  R4, R2, R1    (R4 = R2 - R1 = 10)
        // 4: SW   R3, 0(R0)     (MEM[0] = 30)
        // 5: SW   R4, 1(R0)     (MEM[1] = 10)
        // 6: LW   R5, 0(R0)     (R5 = MEM[0] = 30)
        // 7: ADD  R6, R5, R1    (R6 = R5 + R1 = 40, load-use hazard!)
        // 8: SW   R6, 2(R0)     (MEM[2] = 40)
        
        // Encoding:
        // ADDI: opcode(4) | rs(3) | rt(3) | imm(6)
        // R-type: opcode(4) | rs(3) | rt(3) | rd(3) | shamt(3)
        // LW/SW: opcode(4) | rs(3) | rt(3) | offset(6)
        
        uut.imem.memory[0] = 16'b0111_000_001_001010;  // ADDI R1, R0, 10
        uut.imem.memory[1] = 16'b0111_000_010_010100;  // ADDI R2, R0, 20
        uut.imem.memory[2] = 16'b0000_001_010_011_000;  // ADD R3, R1, R2
        uut.imem.memory[3] = 16'b0001_010_001_100_000;  // SUB R4, R2, R1
        uut.imem.memory[4] = 16'b1001_000_011_000000;  // SW R3, 0(R0)
        uut.imem.memory[5] = 16'b1001_000_100_000001;  // SW R4, 1(R0)
        uut.imem.memory[6] = 16'b1000_000_101_000000;  // LW R5, 0(R0)
        uut.imem.memory[7] = 16'b0000_101_001_110_000;  // ADD R6, R5, R1 (hazard!)
        uut.imem.memory[8] = 16'b1001_000_110_000010;  // SW R6, 2(R0)
    end

endmodule

