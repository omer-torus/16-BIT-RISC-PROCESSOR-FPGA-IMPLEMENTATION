/*
 * Data Memory Module (Byte Addressable)
 * 
 * Read/write data memory with debug read port.
 * Configuration:
 * - 8-bit Address Bus (Byte Addresses: 0x00, 0x02, 0x04...)
 * - 16-bit Data Bus
 * - Capacity: 128 Words (256 Bytes)
 * 
 * Addressing:
 * Input address is a BYTE address. Since memory is 16-bit (2 bytes wide),
 * internal addressing ignores the LSB (address[7:1]).
 * Example: Addr 0 and 1 map to Word 0. Addr 2 and 3 map to Word 1.
 */

module data_memory(
    input  wire        clk,
    input  wire        rst,       // Hardware reset to clear memory
    input  wire        mem_write,
    input  wire        mem_read,
    input  wire [7:0]  address,   // Byte address
    input  wire [15:0] write_data,
    output wire [15:0] read_data,

    // Debug read port (for HUD mem window)
    input  wire [7:0]  dbg_addr,  // Byte address
    output wire [15:0] dbg_data
);

    // 128 words of 16-bit memory 
    // (covers byte addresses 0x00 to 0xFE)
    // Force synthesis to use Registers/LUTs instead of BlockRAM to ensure synchronous reset works reliably
    reg [15:0] memory [0:127] /* synthesis syn_ramstyle = "registers" */;
    
    integer i;

    // Convert Byte Address to Word Address (Index)
    wire [6:0] word_addr = address[7:1];
    wire [6:0] dbg_word_addr = dbg_addr[7:1];

    // Write Logic & Reset
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 128; i = i + 1)
                memory[i] <= 16'h0000;
        end else if (mem_write) begin
            memory[word_addr] <= write_data;
        end
    end

    // Main read port (combinational)
    // Returns 0 if mem_read is low (optional safety)
    assign read_data = (mem_read) ? memory[word_addr] : 16'h0000;

    // Debug read port (combinational, independent)
    assign dbg_data = memory[dbg_word_addr];

endmodule
