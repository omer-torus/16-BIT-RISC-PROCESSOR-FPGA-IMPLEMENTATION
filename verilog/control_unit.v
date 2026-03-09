/*
 * Control Unit Module
 * Decodes instructions and generates control signals
 * Based on opcode (4-bit)
 */

module control_unit(
    input wire [3:0] opcode,        // 4-bit opcode
    output reg reg_write,           // Write to register file
    output reg mem_write,           // Write to data memory
    output reg mem_read,            // Read from data memory
    output reg [1:0] mem_to_reg,    // Select source for register write (0:ALU, 1:Mem, 2:PC+1)
    output reg alu_src,             // Select immediate as ALU operand
    output reg [1:0] reg_dst,       // Select destination register (0:rt, 1:rd, 2:R7)
    output reg branch,              // Branch instruction
    output reg jump,                // Jump instruction
    output reg jump_reg,            // Jump register instruction
    output reg [3:0] alu_control    // ALU operation code
);

    // Opcode definitions
    localparam OP_ADD  = 4'h0;
    localparam OP_SUB  = 4'h1;
    localparam OP_AND  = 4'h2;
    localparam OP_OR   = 4'h3;
    localparam OP_SLT  = 4'h4;
    localparam OP_SLL  = 4'h5;
    localparam OP_SRL  = 4'h6;
    localparam OP_ADDI = 4'h7;
    localparam OP_LW   = 4'h8;
    localparam OP_SW   = 4'h9;
    localparam OP_BEQ  = 4'hA;
    localparam OP_BNE  = 4'hB;
    localparam OP_J    = 4'hC;
    localparam OP_JAL  = 4'hD;
    localparam OP_JR   = 4'hE;
    localparam OP_NOP  = 4'hF;
    
    always @(*) begin
        // Default values (Reset all signals to 0)
        reg_write = 1'b0;
        mem_write = 1'b0;
        mem_read = 1'b0;
        mem_to_reg = 2'b00;  // Default: ALU Result
        alu_src = 1'b0;      // Default: Register (rt)
        reg_dst = 2'b00;     // Default: rt
        branch = 1'b0;
        jump = 1'b0;
        jump_reg = 1'b0;
        alu_control = 4'h0;  // Default: ADD
        
        case (opcode)
            // R-Type instructions (ADD, SUB, AND, OR, SLT, SLL, SRL)
            OP_ADD, OP_SUB, OP_AND, OP_OR, OP_SLT, OP_SLL, OP_SRL: begin
                reg_write = 1'b1;
                reg_dst = 2'b01;      // Write to rd
                mem_to_reg = 2'b00;   // Select ALU result
                alu_control = opcode; // ALU func matches opcode
            end
            
            // I-Type Instructions
            OP_ADDI: begin
                reg_write = 1'b1;
                reg_dst = 2'b00;      // Write to rt
                mem_to_reg = 2'b00;   // Select ALU result
                alu_src = 1'b1;       // Use Immediate
                alu_control = OP_ADD; // Will perform ADD
            end
            
            OP_LW: begin
                reg_write = 1'b1;
                mem_read = 1'b1;
                mem_to_reg = 2'b01;   // Select Memory Output
                reg_dst = 2'b00;      // Write to rt
                alu_src = 1'b1;       // Calculate Addr (Base + Offset)
                alu_control = OP_ADD;
            end
            
            OP_SW: begin
                mem_write = 1'b1;
                alu_src = 1'b1;       // Calculate Addr (Base + Offset)
                alu_control = OP_ADD;
            end
            
            OP_BEQ, OP_BNE: begin
                branch = 1'b1;
                alu_src = 1'b0;       // Compare registers
                alu_control = OP_SUB; // Subtraction for comparison
            end
            
            // J-Type instructions
            OP_J: begin
                jump = 1'b1;
            end
            
            OP_JAL: begin
                jump = 1'b1;
                reg_write = 1'b1;
                reg_dst = 2'b10;      // Select R7 (Hardwired)
                mem_to_reg = 2'b10;   // Select PC + 1
            end
            
            OP_JR: begin
                jump_reg = 1'b1;
            end
            
            OP_NOP: begin
                // No Operation - All signals remain at default (0)
                // No register write, no memory access, no branch/jump
            end
            
            default: begin
                // All signals remain at default (0)
            end
        endcase
    end

endmodule

