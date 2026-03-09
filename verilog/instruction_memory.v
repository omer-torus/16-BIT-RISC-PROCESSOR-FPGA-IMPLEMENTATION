/*
 * Instruction Memory Module
 * 
 * Read-only memory containing program instructions.
 * Loads machine code from 'program.hex' file.
 */

module instruction_memory(
    input  wire [7:0]  address,
    output wire [15:0] instruction,
    
    // Debug read port
    input  wire [7:0]  dbg_address,
    output wire [15:0] dbg_instruction
);

    // Memory Array (256 x 16-bit)
    reg [15:0] memory [0:255];
    integer i;

    // Initialize Memory from Hex File
    initial begin
        // 1. Initialize all to NOP (0xF000)
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = 16'hF000; 
        end
        // 2. Load Program from external Hex file
        // Ensure 'program.hex' is in the simulation/synthesis working directory
        $readmemh("program.hex", memory);
    end

    // Read Ports (Asynchronous Read)
    assign instruction = memory[address];
    assign dbg_instruction = memory[dbg_address];

endmodule