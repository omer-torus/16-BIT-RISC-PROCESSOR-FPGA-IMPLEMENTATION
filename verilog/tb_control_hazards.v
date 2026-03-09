/*
 * Test Bench for Control Hazards (Branch and Jump)
 * Tests pipeline flush behavior
 */

`timescale 1ns / 1ps

module tb_control_hazards;

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
    
    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        $dumpfile("control_hazards.vcd");
        $dumpvars(0, tb_control_hazards);
        
        rst = 1;
        #25;
        rst = 0;
        
        $display("========================================");
        $display("   Control Hazard Test (Branch/Jump)   ");
        $display("========================================");
        $display("");
        
        // Monitor
        $monitor("Time=%0t | Cycle=%0d | PC=%0d | Inst=0x%04h", 
                 $time, cycle_count, pc, instruction);
        
        #1000;
        
        $display("");
        $display("========================================");
        $display("   Test Results                        ");
        $display("========================================");
        $display("Total Cycles: %0d", cycle_count);
        $display("Final PC: %0d", pc);
        $display("");
        $display("Register Contents:");
        $display("R1 = %0d", uut.regfile.registers[1]);
        $display("R2 = %0d", uut.regfile.registers[2]);
        $display("R3 = %0d", uut.regfile.registers[3]);
        $display("R7 = %0d (return address for JAL)", uut.regfile.registers[7]);
        
        $finish;
    end
    
    // Load test program with branches and jumps
    initial begin
        // Test Program: Branch and Jump instructions
        //
        // 0: ADDI R1, R0, 5     (R1 = 5)
        // 1: ADDI R2, R0, 5     (R2 = 5)
        // 2: BEQ R1, R2, EQUAL  (Branch to address 5 if R1 == R2)
        // 3: ADDI R3, R0, 99    (Should be skipped due to branch)
        // 4: J END              (Should be skipped due to branch)
        // 5: EQUAL: ADDI R3, R0, 100  (R3 = 100, branch target)
        // 6: ADDI R1, R1, 1     (R1 = 6)
        // 7: BNE R1, R2, NEXT   (Branch to address 9 if R1 != R2)
        // 8: ADDI R3, R0, 77    (Should be skipped)
        // 9: NEXT: JAL FUNC     (Jump to FUNC, save return address in R7)
        // 10: ADDI R2, R2, 10   (Should be skipped by JAL)
        // 11: FUNC: ADDI R3, R3, 1  (R3 = 101)
        // 12: JR R7             (Return to address after JAL)
        // 13: ADDI R2, R2, 20   (R2 = 25, return point)
        
        uut.imem.memory[0]  = 16'b0111_000_001_000101;  // ADDI R1, R0, 5
        uut.imem.memory[1]  = 16'b0111_000_010_000101;  // ADDI R2, R0, 5
        uut.imem.memory[2]  = 16'b1010_001_010_000010;  // BEQ R1, R2, +2 (to addr 5)
        uut.imem.memory[3]  = 16'b0111_000_011_011111;  // ADDI R3, R0, 99 (skipped)
        uut.imem.memory[4]  = 16'b1100_000000001101;    // J 13 (END, skipped)
        uut.imem.memory[5]  = 16'b0111_000_011_011001;  // ADDI R3, R0, 100
        uut.imem.memory[6]  = 16'b0111_001_001_000001;  // ADDI R1, R1, 1
        uut.imem.memory[7]  = 16'b1011_001_010_000001;  // BNE R1, R2, +1 (to addr 9)
        uut.imem.memory[8]  = 16'b0111_000_011_001101;  // ADDI R3, R0, 77 (skipped)
        uut.imem.memory[9]  = 16'b1101_000000001011;    // JAL 11 (FUNC)
        uut.imem.memory[10] = 16'b0111_010_010_001010;  // ADDI R2, R2, 10 (skipped)
        uut.imem.memory[11] = 16'b0111_011_011_000001;  // ADDI R3, R3, 1
        uut.imem.memory[12] = 16'b1110_111_000000000;   // JR R7
        uut.imem.memory[13] = 16'b0111_010_010_010100;  // ADDI R2, R2, 20
        
        // Expected results:
        // R1 = 6
        // R2 = 25
        // R3 = 101
        // R7 = 10 (return address after JAL)
    end

endmodule

