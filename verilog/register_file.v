/*
 * Register File Module
 * 8 registers (R0-R7), 16-bit width
 * R0 is hardwired to 0
 * Supports Internal Forwarding (Solve WB hazard)
 */

module register_file(
    input wire clk,
    input wire rst,
    input wire reg_write,           // Write enable
    input wire [2:0] read_reg1,     // Read register 1 address
    input wire [2:0] read_reg2,     // Read register 2 address
    input wire [2:0] write_reg,     // Write register address
    input wire [15:0] write_data,   // Data to write
    output wire [15:0] read_data1,  // Data from register 1
    output wire [15:0] read_data2,  // Data from register 2
    output wire [15:0] debug_r1_out // Debug output for R1 (FPGA)
);

    // 8 registers, 16-bit each
    reg [15:0] registers [0:7];
    
    // Initialize registers
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                registers[i] <= 16'h0000;
            end
        end else begin
            // Write operation (only if reg_write is high and not writing to R0)
            if (reg_write && write_reg != 3'b000) begin
                registers[write_reg] <= write_data;
            end
            // Ensure R0 is always 0 (redundant but safe)
            registers[0] <= 16'h0000;
        end
    end
    
    // Read operations with Internal Forwarding
    // If we are writing to a register that is being read in the same cycle,
    // bypass the register file and output the write_data directly.
    // This solves the Write-Back stage hazard.
    
    assign read_data1 = (read_reg1 == 3'b000) ? 16'h0000 :
                        (reg_write && (read_reg1 == write_reg)) ? write_data :
                        registers[read_reg1];

    assign read_data2 = (read_reg2 == 3'b000) ? 16'h0000 :
                        (reg_write && (read_reg2 == write_reg)) ? write_data :
                        registers[read_reg2];

    // Debug output for FPGA
    assign debug_r1_out = registers[1];

endmodule
