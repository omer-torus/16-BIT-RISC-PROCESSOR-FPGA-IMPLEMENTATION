/*
 * Data Memory Module
 * 256 words x 16 bits = 512 bytes
 * Read/Write memory for runtime data storage
 */

module data_memory(
    input wire clk,
    input wire mem_write,           // Write enable
    input wire mem_read,            // Read enable
    input wire [7:0] address,       // 8-bit address (256 words)
    input wire [15:0] write_data,   // Data to write
    output wire [15:0] read_data    // Data read from memory
);

    // Data memory array
    reg [15:0] memory [0:255];
    
    // Loop variable
    integer i;
    
    // Initialize memory
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = 16'h0000;
        end
    end
    
    // Write operation (synchronous)
    always @(posedge clk) begin
        if (mem_write) begin
            memory[address] <= write_data;
        end
    end
    
    // Read operation (ASYNCHRONOUS / COMBINATIONAL)
    // Fixed: Changed from synchronous to combinational logic
    // This allows data to be ready within the same MEM stage cycle
    assign read_data = (mem_read) ? memory[address] : 16'h0000;

endmodule
