/*
 * Test Bench for Hazard Detection and Forwarding Units
 * Tests data hazard scenarios
 */

`timescale 1ns / 1ps

module tb_hazard_forwarding;

    // Hazard Detection Unit signals
    reg id_ex_mem_read;
    reg [2:0] id_ex_rt;
    reg [2:0] if_id_rs;
    reg [2:0] if_id_rt;
    reg [3:0] if_id_opcode;
    wire stall;
    wire if_id_write;
    wire pc_write;
    
    // Forwarding Unit signals
    reg ex_mem_reg_write;
    reg [2:0] ex_mem_rd;
    reg mem_wb_reg_write;
    reg [2:0] mem_wb_rd;
    reg [2:0] id_ex_rs;
    reg [2:0] id_ex_rt_fwd;
    wire [1:0] forward_a;
    wire [1:0] forward_b;
    
    // Instantiate Hazard Detection Unit
    hazard_detection_unit hazard_uut(
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_rt(id_ex_rt),
        .if_id_rs(if_id_rs),
        .if_id_rt(if_id_rt),
        .if_id_opcode(if_id_opcode),
        .stall(stall),
        .if_id_write(if_id_write),
        .pc_write(pc_write)
    );
    
    // Instantiate Forwarding Unit
    forwarding_unit forward_uut(
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_rd(ex_mem_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_rd(mem_wb_rd),
        .id_ex_rs(id_ex_rs),
        .id_ex_rt(id_ex_rt_fwd),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );
    
    initial begin
        $display("========================================");
        $display("   Hazard & Forwarding Test Bench      ");
        $display("========================================");
        $display("");
        
        // ========== Test 1: Load-Use Hazard Detection ==========
        $display("Test 1: Load-Use Hazard Detection");
        $display("Scenario: LW R1, 0(R0) followed by ADD R2, R1, R3");
        
        id_ex_mem_read = 1'b1;    // Previous instruction is LW
        id_ex_rt = 3'd1;          // LW destination is R1
        if_id_rs = 3'd1;          // Current instruction uses R1 as source
        if_id_rt = 3'd3;
        if_id_opcode = 4'h0;      // ADD instruction
        
        #10;
        $display("Result: Stall=%b, PC_Write=%b, IF_ID_Write=%b", stall, pc_write, if_id_write);
        $display("Expected: Stall=1, PC_Write=0, IF_ID_Write=0");
        $display("");
        
        // ========== Test 2: No Hazard (different registers) ==========
        $display("Test 2: No Hazard");
        $display("Scenario: LW R1, 0(R0) followed by ADD R2, R3, R4");
        
        id_ex_mem_read = 1'b1;    // Previous instruction is LW
        id_ex_rt = 3'd1;          // LW destination is R1
        if_id_rs = 3'd3;          // Current instruction uses R3 (no dependency)
        if_id_rt = 3'd4;          // Uses R4 (no dependency)
        if_id_opcode = 4'h0;      // ADD instruction
        
        #10;
        $display("Result: Stall=%b, PC_Write=%b, IF_ID_Write=%b", stall, pc_write, if_id_write);
        $display("Expected: Stall=0, PC_Write=1, IF_ID_Write=1");
        $display("");
        
        // ========== Test 3: EX/MEM Forwarding ==========
        $display("Test 3: EX/MEM Stage Forwarding");
        $display("Scenario: ADD R1, R2, R3 followed by SUB R4, R1, R5");
        
        ex_mem_reg_write = 1'b1;  // EX/MEM will write to register
        ex_mem_rd = 3'd1;         // Writing to R1
        mem_wb_reg_write = 1'b0;
        mem_wb_rd = 3'd0;
        id_ex_rs = 3'd1;          // Current instruction needs R1
        id_ex_rt_fwd = 3'd5;
        
        #10;
        $display("Result: Forward_A=%b, Forward_B=%b", forward_a, forward_b);
        $display("Expected: Forward_A=10 (from EX/MEM), Forward_B=00 (no forward)");
        $display("");
        
        // ========== Test 4: MEM/WB Forwarding ==========
        $display("Test 4: MEM/WB Stage Forwarding");
        $display("Scenario: Forwarding from MEM/WB stage");
        
        ex_mem_reg_write = 1'b0;  // No EX/MEM forwarding
        ex_mem_rd = 3'd0;
        mem_wb_reg_write = 1'b1;  // MEM/WB will write to register
        mem_wb_rd = 3'd2;         // Writing to R2
        id_ex_rs = 3'd2;          // Current instruction needs R2
        id_ex_rt_fwd = 3'd3;
        
        #10;
        $display("Result: Forward_A=%b, Forward_B=%b", forward_a, forward_b);
        $display("Expected: Forward_A=01 (from MEM/WB), Forward_B=00 (no forward)");
        $display("");
        
        // ========== Test 5: Double Data Hazard ==========
        $display("Test 5: Double Data Hazard (both operands need forwarding)");
        $display("Scenario: Both operands need forwarding from EX/MEM");
        
        ex_mem_reg_write = 1'b1;
        ex_mem_rd = 3'd1;
        mem_wb_reg_write = 1'b1;
        mem_wb_rd = 3'd2;
        id_ex_rs = 3'd1;          // Needs forwarding from EX/MEM
        id_ex_rt_fwd = 3'd2;      // Needs forwarding from MEM/WB
        
        #10;
        $display("Result: Forward_A=%b, Forward_B=%b", forward_a, forward_b);
        $display("Expected: Forward_A=10 (EX/MEM), Forward_B=01 (MEM/WB)");
        $display("");
        
        // ========== Test 6: R0 Protection (no forwarding to R0) ==========
        $display("Test 6: R0 Protection");
        $display("Scenario: Writing to R0 should not trigger forwarding");
        
        ex_mem_reg_write = 1'b1;
        ex_mem_rd = 3'd0;         // Writing to R0 (should be ignored)
        mem_wb_reg_write = 1'b0;
        mem_wb_rd = 3'd0;
        id_ex_rs = 3'd0;          // Reading R0
        id_ex_rt_fwd = 3'd1;
        
        #10;
        $display("Result: Forward_A=%b, Forward_B=%b", forward_a, forward_b);
        $display("Expected: Forward_A=00, Forward_B=00 (R0 never forwards)");
        $display("");
        
        $display("========================================");
        $display("   Hazard & Forwarding Test Complete   ");
        $display("========================================");
        
        $finish;
    end

endmodule

