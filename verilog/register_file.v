/*
 * Register File Module
 * 
 * 8x16-bit general-purpose register file with:
 * - R0 hardwired to zero
 * - Dual read ports
 * - Single write port
 * - Debug outputs for HUD display
 */

module register_file(
    input  wire        clk,
    input  wire        rst,
    input  wire        reg_write,
    input  wire [2:0]  read_reg1,
    input  wire [2:0]  read_reg2,
    input  wire [2:0]  write_reg,
    input  wire [15:0] write_data,
    output wire [15:0] read_data1,
    output wire [15:0] read_data2,

    // Debug outputs
    output wire [15:0]  dbg_r1,          // R1 value for LED display
    output wire [127:0] dbg_regs_flat    // All registers concatenated: {R7,R6,R5,R4,R3,R2,R1,R0}
);

    reg [15:0] registers [0:7];
    integer i;

    // Write logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1)
                registers[i] <= 16'h0000;
        end else begin
            if (reg_write && (write_reg != 3'b000))
                registers[write_reg] <= write_data;
            registers[0] <= 16'h0000;  // R0 always zero
        end
    end

    // Read logic with forwarding
    assign read_data1 = (read_reg1 == 3'b000) ? 16'h0000 :
                        ((reg_write && (read_reg1 == write_reg)) ? write_data : registers[read_reg1]);
    
    assign read_data2 = (read_reg2 == 3'b000) ? 16'h0000 :
                        ((reg_write && (read_reg2 == write_reg)) ? write_data : registers[read_reg2]);

    // Debug outputs
    assign dbg_r1 = registers[1];
    
    assign dbg_regs_flat = {
        registers[7], registers[6], registers[5], registers[4],
        registers[3], registers[2], registers[1], registers[0]
    };

endmodule