/*
 * Instruction Memory Module for FPGA (Synthesizable ROM)
 * 256 words x 16 bits
 * Contains CPU Demo Program: Binary Counter on R1
 */

module instruction_memory(
    input wire [7:0] address,       // 8-bit address
    output reg [15:0] instruction   // 16-bit instruction
);

    // ROM implementation using case statement
    // Program: 
    // R1 counts from 1 to 63, then resets.
    // LEDs will show R1 value in binary.
    always @(*) begin
        case (address)
            // Init: R1=1, R2=1, R3=63
            8'd0:  instruction = 16'b0111_000_001_000001;  // addi r1, r0, 1
            8'd1:  instruction = 16'b0111_000_010_000001;  // addi r2, r0, 1
            8'd2:  instruction = 16'b0111_000_011_111111;  // addi r3, r0, 63
            
            // Loop Body: R1 = R1 + R2
            8'd3:  instruction = 16'b0000_001_010_001_000;  // add r1, r1, r2
            
            // NOPs for visibility delay (though clock is slow)
            8'd4:  instruction = 16'b0000_000_000_000_000;  // nop
            8'd5:  instruction = 16'b0000_000_000_000_000;  // nop
            
            // Check: if R1 != 63, goto Loop Body (addr 3)
            // Branch offset: target(3) - (PC+1)(8) = -5
            // 2's complement of 5 (6 bits): 000101 -> 111010 + 1 = 111011
            8'd6:  instruction = 16'b1011_001_011_111011;  // bne r1, r3, -5
            
            // Reset: R1 = 0
            8'd7:  instruction = 16'b0111_000_001_000000;  // addi r1, r0, 0
            
            // Jump back to Loop Body (addr 3)
            8'd8:  instruction = 16'b1100_000000000011;    // j 3
            
            default: instruction = 16'hF000; // NOP
        endcase
    end

endmodule
