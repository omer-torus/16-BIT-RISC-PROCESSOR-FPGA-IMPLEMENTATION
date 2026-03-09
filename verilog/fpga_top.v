/*
 * FPGA Top Module for Tang Nano 9K
 * 
 * Integrates:
 * - 16-bit RISC CPU with full debug interface
 * - HDMI output (640x480@60Hz) showing debug HUD
 * - LED outputs for quick status check
 * 
 * Features:
 * - STEP MODE: Press Step button to execute 1 cycle
 * - AUTO MODE: Hold Step button > 1 second for slow auto-run
 * - RESET: Press Reset button to restart CPU
 */

module fpga_top(
    input  wire       clk_27mhz,
    input  wire       btn_rst,      // Active-low: Press to RESET
    input  wire       btn_step,     // Active-low: Press to STEP (short) or AUTO (long)
    output wire [5:0] led,          // Active-low LEDs (shows R1[5:0])
    output wire       led_done,     // Shows MODE (On=Auto, Off=Step)
    output wire [2:0] tmds_d_p,     // HDMI TMDS data channels
    output wire       tmds_clk_p    // HDMI TMDS clock
);

    // =========================================================================
    // 1. INPUT DEBOUNCING & CONTROL LOGIC
    // =========================================================================

    reg [17:0] btn_cnt;
    reg        btn_step_clean;
    reg        btn_step_prev;
    
    always @(posedge clk_27mhz) begin
        if (btn_step == 1'b0) begin 
            if (btn_cnt < 18'd260000)
                btn_cnt <= btn_cnt + 1;
            else
                btn_step_clean <= 1'b1; 
        end else begin
            btn_cnt <= 0;
            btn_step_clean <= 1'b0; 
        end
        btn_step_prev <= btn_step_clean;
    end

    wire step_pulse = (btn_step_clean && !btn_step_prev);

    reg [24:0] auto_cnt;
    reg        auto_mode;
    
    always @(posedge clk_27mhz) begin
        if (btn_step == 1'b0) begin
            if (auto_cnt < 25'd27000000)
                auto_cnt <= auto_cnt + 1;
            else
                auto_mode <= 1'b1; 
        end else begin
            auto_cnt <= 0;
             auto_mode <= 1'b0; 
        end
    end

    reg [22:0] slow_clk_cnt;
    reg        enable_low_freq;
    
    always @(posedge clk_27mhz) begin
        if (slow_clk_cnt < 23'd5400000) 
            slow_clk_cnt <= slow_clk_cnt + 1;
        else begin
            slow_clk_cnt <= 0;
            enable_low_freq <= ~enable_low_freq; 
        end
    end
    
    wire auto_pulse = (slow_clk_cnt == 0); 
    wire cpu_clk_enable = step_pulse || (auto_mode && auto_pulse);

    // =========================================================================
    // 2. CPU CLOCK GENERATION
    // =========================================================================
     
    reg cpu_clk;
    
    // Reset signals
    wire rst   = ~btn_rst;  // CPU reset (active-high) - Button 1 (Left)
    wire rst_n = 1'b1;      // HDMI reset tied HIGH (Always Active)
    
    always @(posedge clk_27mhz) begin
        if (!btn_rst) begin 
             cpu_clk <= 0;
        end else begin
            if (cpu_clk_enable)
                cpu_clk <= 1'b1;
            else if (auto_mode)
               cpu_clk <= (slow_clk_cnt < 23'd2700000); 
            else
               cpu_clk <= (step_pulse | (auto_mode & enable_low_freq));
        end
    end
    
    wire clk_safe = (step_pulse || (auto_mode && enable_low_freq));


    // =========================================================================
    // 3. MODULE INSTANTIATIONS
    // =========================================================================

    wire [7:0] imem_addr_req, dmem_addr_req;

    wire [7:0]   dbg_pc;
    wire [31:0]  dbg_cycles;
    wire [15:0]  dbg_if_inst;
    wire [7:0]   dbg_id_pc;
    wire [15:0]  dbg_id_inst;
    wire         dbg_stall, dbg_flush, dbg_branch_taken, dbg_jump_taken;

    wire [7:0]   dbg_ex_pc;
    wire [15:0]  dbg_ex_inst; // NEW
    wire [3:0]   dbg_ex_opcode;
    wire [2:0]   dbg_ex_rs, dbg_ex_rt, dbg_ex_rd, dbg_ex_shamt;
    wire [15:0]  dbg_ex_imm, dbg_ex_alu_result;

    wire [15:0]  dbg_mem_inst; // NEW
    wire         dbg_mem_read, dbg_mem_write;
    wire [7:0]   dbg_mem_addr;
    wire [15:0]  dbg_mem_wdata, dbg_mem_rdata;

    wire [15:0]  dbg_wb_inst; // NEW
    wire         dbg_wb_we;
    wire [2:0]   dbg_wb_rd;
    wire [15:0]  dbg_wb_wdata;
    
    wire [1:0]  dbg_forward_a;
    wire [1:0]  dbg_forward_b;

    wire [15:0]  dbg_imem_data, dbg_dmem_data;
    wire [127:0] dbg_regs_flat;

    cpu_top u_cpu (
        .clk              (clk_safe), 
        .rst              (rst),
        .dbg_imem_addr    (imem_addr_req),
        .dbg_dmem_addr    (dmem_addr_req),

        .dbg_pc           (dbg_pc),
        .dbg_cycles       (dbg_cycles),
        .dbg_if_inst      (dbg_if_inst),
        .dbg_id_pc        (dbg_id_pc),
        .dbg_id_inst      (dbg_id_inst),
        .dbg_stall        (dbg_stall),
        .dbg_flush        (dbg_flush),
        .dbg_branch_taken (dbg_branch_taken),
        .dbg_jump_taken   (dbg_jump_taken),

        .dbg_ex_pc        (dbg_ex_pc),
        .dbg_ex_inst      (dbg_ex_inst), // NEW
        .dbg_ex_opcode    (dbg_ex_opcode),
        .dbg_ex_rs        (dbg_ex_rs),
        .dbg_ex_rt        (dbg_ex_rt),
        .dbg_ex_rd        (dbg_ex_rd),
        .dbg_ex_shamt     (dbg_ex_shamt),
        .dbg_ex_imm       (dbg_ex_imm),
        .dbg_ex_alu_result(dbg_ex_alu_result),

        .dbg_mem_inst     (dbg_mem_inst), // NEW
        .dbg_mem_read     (dbg_mem_read),
        .dbg_mem_write    (dbg_mem_write),
        .dbg_mem_addr     (dbg_mem_addr),
        .dbg_mem_wdata    (dbg_mem_wdata),
        .dbg_mem_rdata    (dbg_mem_rdata),

        .dbg_wb_inst      (dbg_wb_inst), // NEW
        .dbg_wb_we        (dbg_wb_we),
        .dbg_wb_rd        (dbg_wb_rd),
        .dbg_wb_wdata     (dbg_wb_wdata),
        
        .dbg_forward_a    (dbg_forward_a),
        .dbg_forward_b    (dbg_forward_b),

        .dbg_imem_data    (dbg_imem_data),
        .dbg_dmem_data    (dbg_dmem_data),
        .dbg_regs_flat    (dbg_regs_flat)
    );

    wire [15:0] r1_val = dbg_regs_flat[31:16];
    assign led = ~r1_val[5:0];  
    assign led_done = ~auto_mode; 

    wire [9:0] x, y;
    wire active;
    wire clk_pix;
    wire [7:0] r_pix, g_pix, b_pix;

    hdmi_top u_hdmi(
        .clk_27m     (clk_27mhz),
        .rst_n       (rst_n),
        .red_in      (r_pix),
        .green_in    (g_pix),
        .blue_in     (b_pix),
        .x_out       (x),
        .y_out       (y),
        .active_out  (active),
        .clk_pix_out (clk_pix),
        .tmds_d_p    (tmds_d_p),
        .tmds_clk_p  (tmds_clk_p)
    );

    debug_hud u_hud(
        .clk_pix      (clk_pix),
        .rst          (rst),
        .x            (x),
        .y            (y),
        .active       (active),
        .dbg_pc       (dbg_pc),
        .dbg_cycles   (dbg_cycles),
        .dbg_if_inst  (dbg_if_inst),
        .dbg_id_pc    (dbg_id_pc),
        .dbg_id_inst  (dbg_id_inst),
        .dbg_stall    (dbg_stall),
        .dbg_flush    (dbg_flush),
        .dbg_branch_taken(dbg_branch_taken),
        .dbg_jump_taken  (dbg_jump_taken),
        
        .dbg_ex_pc    (dbg_ex_pc),
        .dbg_ex_inst  (dbg_ex_inst), // NEW
        .dbg_ex_opcode(dbg_ex_opcode),
        .dbg_ex_rs    (dbg_ex_rs),
        .dbg_ex_rt    (dbg_ex_rt),
        .dbg_ex_rd    (dbg_ex_rd),
        .dbg_ex_shamt (dbg_ex_shamt),
        .dbg_ex_imm   (dbg_ex_imm),
        .dbg_ex_alu_result(dbg_ex_alu_result),
        
        .dbg_mem_inst (dbg_mem_inst), // NEW
        .dbg_mem_read (dbg_mem_read),
        .dbg_mem_write(dbg_mem_write),
        .dbg_mem_addr (dbg_mem_addr),
        .dbg_mem_wdata(dbg_mem_wdata),
        .dbg_mem_rdata(dbg_mem_rdata),
        
        .dbg_wb_inst  (dbg_wb_inst), // NEW
        .dbg_wb_we    (dbg_wb_we),
        .dbg_wb_rd    (dbg_wb_rd),
        .dbg_wb_wdata (dbg_wb_wdata),
        
        .dbg_forward_a(dbg_forward_a),
        .dbg_forward_b(dbg_forward_b),
        
        .dbg_imem_data(dbg_imem_data),
        .dbg_dmem_data(dbg_dmem_data),
        .dbg_regs_flat(dbg_regs_flat),
        .imem_addr_req(imem_addr_req),
        .dmem_addr_req(dmem_addr_req),
        .r            (r_pix),
        .g            (g_pix),
        .b            (b_pix)
    );

endmodule