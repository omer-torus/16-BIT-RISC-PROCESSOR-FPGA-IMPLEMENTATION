/*
 * FPGA Top Module for Tang Nano 9K
 * Wraps cpu_top with clock divider and LED connections
 */

module fpga_top(
    input wire clk_27mhz,       // 27 MHz onboard oscillator
    input wire btn_rst,         // S1 button (active low)
    output wire [5:0] led       // 6 onboard LEDs (active low)
);

    // ==================== Clock Divider ====================
    // 27 MHz -> ~1.6 Hz (Bit 23)
    reg [24:0] clk_counter;
    wire clk_slow;
    
    always @(posedge clk_27mhz or negedge btn_rst) begin
        if (!btn_rst)
            clk_counter <= 0;
        else
            clk_counter <= clk_counter + 1'b1;
    end
    
    assign clk_slow = clk_counter[23]; // Visible speed

    // ==================== Reset Synchronizer ====================
    reg [2:0] rst_sync;
    wire rst;
    
    always @(posedge clk_slow or negedge btn_rst) begin
        if (!btn_rst)
            rst_sync <= 3'b111;
        else
            rst_sync <= {rst_sync[1:0], 1'b0};
    end
    
    assign rst = rst_sync[2];
    
    // ==================== CPU Signals ====================
    wire [15:0] cpu_debug_r1;
    wire [15:0] cpu_debug_instruction;
    wire cpu_debug_halted;
    
    // ==================== CPU Instance ====================
    cpu_top u_cpu(
        .clk(clk_slow),
        .rst(rst),
        .debug_r1(cpu_debug_r1),
        .debug_instruction(cpu_debug_instruction),
        .debug_halted(cpu_debug_halted)
    );
    
    // ==================== LED Output ====================
    // Show lower 6 bits of R1 register on LEDs
    // LEDs are active low
    assign led = ~cpu_debug_r1[5:0];
    
endmodule
