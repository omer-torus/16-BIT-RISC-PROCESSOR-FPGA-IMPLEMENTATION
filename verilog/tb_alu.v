/*
 * Test Bench for ALU Module
 * Tests all ALU operations
 */

`timescale 1ns / 1ps

module tb_alu;

    reg [15:0] operand_a;
    reg [15:0] operand_b;
    reg [2:0] shamt;
    reg [3:0] alu_control;
    wire [15:0] alu_result;
    wire zero;
    
    // Instantiate ALU
    alu uut(
        .operand_a(operand_a),
        .operand_b(operand_b),
        .shamt(shamt),
        .alu_control(alu_control),
        .alu_result(alu_result),
        .zero(zero)
    );
    
    // Test stimulus
    initial begin
        $display("========================================");
        $display("   ALU Module Test Bench               ");
        $display("========================================");
        $display("");
        
        // Test ADD
        operand_a = 16'd100;
        operand_b = 16'd50;
        alu_control = 4'h0;  // ADD
        shamt = 3'b000;
        #10;
        $display("ADD: %d + %d = %d (Expected: 150)", operand_a, operand_b, alu_result);
        
        // Test SUB
        operand_a = 16'd100;
        operand_b = 16'd50;
        alu_control = 4'h1;  // SUB
        #10;
        $display("SUB: %d - %d = %d (Expected: 50)", operand_a, operand_b, alu_result);
        
        // Test SUB (result = 0, zero flag should be high)
        operand_a = 16'd100;
        operand_b = 16'd100;
        alu_control = 4'h1;  // SUB
        #10;
        $display("SUB: %d - %d = %d, Zero=%b (Expected: 0, Zero=1)", 
                 operand_a, operand_b, alu_result, zero);
        
        // Test AND
        operand_a = 16'hFF00;
        operand_b = 16'h0F0F;
        alu_control = 4'h2;  // AND
        #10;
        $display("AND: 0x%04h & 0x%04h = 0x%04h (Expected: 0x0F00)", 
                 operand_a, operand_b, alu_result);
        
        // Test OR
        operand_a = 16'hFF00;
        operand_b = 16'h0F0F;
        alu_control = 4'h3;  // OR
        #10;
        $display("OR:  0x%04h | 0x%04h = 0x%04h (Expected: 0xFF0F)", 
                 operand_a, operand_b, alu_result);
        
        // Test SLT (less than)
        operand_a = 16'd10;
        operand_b = 16'd20;
        alu_control = 4'h4;  // SLT
        #10;
        $display("SLT: %d < %d = %d (Expected: 1)", operand_a, operand_b, alu_result);
        
        // Test SLT (not less than)
        operand_a = 16'd30;
        operand_b = 16'd20;
        alu_control = 4'h4;  // SLT
        #10;
        $display("SLT: %d < %d = %d (Expected: 0)", operand_a, operand_b, alu_result);
        
        // Test SLL (shift left)
        operand_a = 16'h0000;  // Not used for shift
        operand_b = 16'h0001;
        shamt = 3'd3;
        alu_control = 4'h5;  // SLL
        #10;
        $display("SLL: 0x%04h << %d = 0x%04h (Expected: 0x0008)", 
                 operand_b, shamt, alu_result);
        
        // Test SRL (shift right)
        operand_a = 16'h0000;  // Not used for shift
        operand_b = 16'h0080;
        shamt = 3'd4;
        alu_control = 4'h6;  // SRL
        #10;
        $display("SRL: 0x%04h >> %d = 0x%04h (Expected: 0x0008)", 
                 operand_b, shamt, alu_result);
        
        $display("");
        $display("========================================");
        $display("   ALU Test Complete                   ");
        $display("========================================");
        
        $finish;
    end

endmodule

