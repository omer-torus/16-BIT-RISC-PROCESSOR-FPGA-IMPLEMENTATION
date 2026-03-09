/*
 * CPU Top Module with Full Debug Integration
 * 
 * Connects processor_top to fpga_top, passing all debug signals
 * straight through to the HDMI HUD.
 */

module cpu_top(
    input  wire        clk,
    input  wire        rst,
    
    // Debug memory address inputs (from HUD via fpga_top)
    input  wire [7:0]  dbg_imem_addr,
    input  wire [7:0]  dbg_dmem_addr,

    // Core state outputs
    output wire [7:0]  dbg_pc,
    output wire [31:0] dbg_cycles,
    output wire [15:0] dbg_if_inst,
    output wire [7:0]  dbg_id_pc,
    output wire [15:0] dbg_id_inst,
    output wire        dbg_stall,
    output wire        dbg_flush,
    output wire        dbg_branch_taken,
    output wire        dbg_jump_taken,

    // EX stage outputs
    output wire [7:0]  dbg_ex_pc,
    output wire [15:0] dbg_ex_inst, // NEW
    output wire [3:0]  dbg_ex_opcode,
    output wire [2:0]  dbg_ex_rs,
    output wire [2:0]  dbg_ex_rt,
    output wire [2:0]  dbg_ex_rd,
    output wire [2:0]  dbg_ex_shamt,
    output wire [15:0] dbg_ex_imm,
    output wire [15:0] dbg_ex_alu_result,

    // MEM stage outputs
    output wire [15:0] dbg_mem_inst, // NEW
    output wire        dbg_mem_read,
    output wire        dbg_mem_write,
    output wire [7:0]  dbg_mem_addr,
    output wire [15:0] dbg_mem_wdata,
    output wire [15:0] dbg_mem_rdata,

    // WB stage outputs
    output wire [15:0] dbg_wb_inst, // NEW
    output wire        dbg_wb_we,
    output wire [2:0]  dbg_wb_rd,
    output wire [15:0] dbg_wb_wdata,
    
    output wire [1:0]  dbg_forward_a,
    output wire [1:0]  dbg_forward_b,

    // Memory debug outputs
    output wire [15:0] dbg_imem_data,
    output wire [15:0] dbg_dmem_data,

    // Register file snapshot
    output wire [127:0] dbg_regs_flat
);

    // Instantiate processor_top with full debug interface
    processor_top u_processor(
        .clk              (clk),
        .rst              (rst),
        
        // Debug Inputs
        .dbg_imem_addr_req(dbg_imem_addr),
        .dbg_dmem_addr_req(dbg_dmem_addr),

        // Debug Outputs - Core State
        .dbg_pc           (dbg_pc),
        .dbg_cycles       (dbg_cycles),
        .dbg_if_inst      (dbg_if_inst),
        .dbg_id_pc        (dbg_id_pc),
        .dbg_id_inst      (dbg_id_inst),
        .dbg_stall        (dbg_stall),
        .dbg_flush        (dbg_flush),
        .dbg_branch_taken (dbg_branch_taken),
        .dbg_jump_taken   (dbg_jump_taken),

        // Debug Outputs - EX Stage
        .dbg_ex_pc        (dbg_ex_pc),
        .dbg_ex_inst      (dbg_ex_inst), // NEW
        .dbg_ex_opcode    (dbg_ex_opcode),
        .dbg_ex_rs        (dbg_ex_rs),
        .dbg_ex_rt        (dbg_ex_rt),
        .dbg_ex_rd        (dbg_ex_rd),
        .dbg_ex_shamt     (dbg_ex_shamt),
        .dbg_ex_imm       (dbg_ex_imm),
        .dbg_ex_alu_result(dbg_ex_alu_result),

        // Debug Outputs - MEM Stage
        .dbg_mem_inst     (dbg_mem_inst), // NEW
        .dbg_mem_read     (dbg_mem_read),
        .dbg_mem_write    (dbg_mem_write),
        .dbg_mem_addr     (dbg_mem_addr),
        .dbg_mem_wdata    (dbg_mem_wdata),
        .dbg_mem_rdata    (dbg_mem_rdata),

        // Debug Outputs - WB Stage
        .dbg_wb_inst      (dbg_wb_inst), // NEW
        .dbg_wb_we        (dbg_wb_we),
        .dbg_wb_rd        (dbg_wb_rd),
        .dbg_wb_wdata     (dbg_wb_wdata),
        
        .dbg_forward_a    (dbg_forward_a),
        .dbg_forward_b    (dbg_forward_b),

        // Debug Outputs - Memory Content
        .dbg_imem_data    (dbg_imem_data),
        .dbg_dmem_data    (dbg_dmem_data),
        
        // Debug Outputs - Registers
        .dbg_regs_flat    (dbg_regs_flat)
    );

endmodule