/*
 * ALU Module
 * Performs arithmetic and logic operations
 * Supports all operations from instruction set
 */

module alu(
    input wire [15:0] operand_a,    // First operand
    input wire [15:0] operand_b,    // Second operand
    input wire [2:0] shamt,         // Shift amount
    input wire [3:0] alu_control,   // ALU operation control
    output reg [15:0] alu_result,   // ALU result
    output wire zero                // Zero flag (for branches)
);

    // ALU operation codes (matching opcodes from Python simulator)
    localparam OP_ADD  = 4'h0;
    localparam OP_SUB  = 4'h1;
    localparam OP_AND  = 4'h2;
    localparam OP_OR   = 4'h3;
    localparam OP_SLT  = 4'h4;
    localparam OP_SLL  = 4'h5;
    localparam OP_SRL  = 4'h6;
    localparam OP_ADDI = 4'h7;
    
    // Signed comparison wires
    wire signed [15:0] signed_a = operand_a;
    wire signed [15:0] signed_b = operand_b;
    
    // ALU operations
    always @(*) begin
        case (alu_control)
            OP_ADD, OP_ADDI: begin
                alu_result = operand_a + operand_b;
            end
            
            OP_SUB: begin
                alu_result = operand_a - operand_b;
            end
            
            OP_AND: begin
                alu_result = operand_a & operand_b;
            end
            
            OP_OR: begin
                alu_result = operand_a | operand_b;
            end
            
            OP_SLT: begin
                alu_result = (signed_a < signed_b) ? 16'h0001 : 16'h0000;
            end
            
            OP_SLL: begin
                alu_result = operand_b << shamt;
            end
            
            OP_SRL: begin
                alu_result = operand_b >> shamt;
            end
            
            default: begin
                alu_result = 16'h0000;
            end
        endcase
    end
    
    // Zero flag for branches
    assign zero = (alu_result == 16'h0000);

endmodule

