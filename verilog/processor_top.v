/*
 * Processor Top Module with Full Debug Interface
 * 
 * 5-stage pipelined RISC processor
 * Updated to expose internal state for HDMI Debug HUD
 * Updated v2: Propagates Instruction Word through pipeline for visualization
 */

module processor_top(
    input  wire        clk,
    input  wire        rst,
    
    // Debug Memory Requests (from HUD)
    input  wire [7:0]  dbg_imem_addr_req,
    input  wire [7:0]  dbg_dmem_addr_req,

    // Core State Debug Outputs
    output wire [7:0]  dbg_pc,
    output wire [31:0] dbg_cycles,
    output wire [15:0] dbg_if_inst,
    output wire [7:0]  dbg_id_pc,
    output wire [15:0] dbg_id_inst,
    output wire        dbg_stall,
    output wire        dbg_flush,
    output wire        dbg_branch_taken,
    output wire        dbg_jump_taken,

    // EX Stage Debug Outputs
    output wire [7:0]  dbg_ex_pc,
    output wire [15:0] dbg_ex_inst, // NEW
    output wire [3:0]  dbg_ex_opcode,
    output wire [2:0]  dbg_ex_rs,
    output wire [2:0]  dbg_ex_rt,
    output wire [2:0]  dbg_ex_rd,
    output wire [2:0]  dbg_ex_shamt,
    output wire [15:0] dbg_ex_imm,
    output wire [15:0] dbg_ex_alu_result,

    // MEM Stage Debug Outputs
    output wire [15:0] dbg_mem_inst, // NEW
    output wire        dbg_mem_read,
    output wire        dbg_mem_write,
    output wire [7:0]  dbg_mem_addr,
    output wire [15:0] dbg_mem_wdata,
    output wire [15:0] dbg_mem_rdata,

    // WB Stage Debug Outputs
    output wire [15:0] dbg_wb_inst, // NEW
    output wire        dbg_wb_we,
    output wire [2:0]  dbg_wb_rd,
    output wire [15:0] dbg_wb_wdata,
    
    // Hazard/Forwarding Debug Outputs
    output wire [1:0]  dbg_forward_a,
    output wire [1:0]  dbg_forward_b,

    // Memory Windows (for HUD)
    output wire [15:0] dbg_imem_data,
    output wire [15:0] dbg_dmem_data,

    // Register File Snapshot
    output wire [127:0] dbg_regs_flat
);

    // ==================== Program Counter ====================
    reg [7:0] pc;
    reg [31:0] cycle_counter;
    
    // ==================== Pipeline Stage Signals ====================
    
    // IF Stage
    wire [15:0] if_instruction;
    wire pc_write;
    wire if_id_write;
    
    // IF/ID Pipeline Register
    wire [15:0] id_instruction;
    wire [7:0] id_pc;
    wire if_id_valid;
    
    // ID Stage
    wire [3:0] id_opcode = id_instruction[15:12];
    wire [2:0] id_rs = id_instruction[11:9];
    wire [2:0] id_rt = id_instruction[8:6];
    wire [2:0] id_rd = id_instruction[5:3];
    wire [2:0] id_shamt = id_instruction[2:0];
    wire [5:0] id_immediate = id_instruction[5:0];
    wire [11:0] id_jump_addr = id_instruction[11:0];
    
    // Sign extension
    wire [15:0] id_sign_ext_imm = (id_immediate[5]) ? 
                                   {10'b1111111111, id_immediate} : 
                                   {10'b0000000000, id_immediate};
    
    // Control signals
    wire id_reg_write, id_mem_write, id_mem_read;
    wire [1:0] id_mem_to_reg;
    wire [1:0] id_reg_dst;
    wire id_alu_src, id_branch, id_jump, id_jump_reg;
    wire [3:0] id_alu_control;
    
    // Register file read data
    wire [15:0] id_read_data1, id_read_data2;
    wire [15:0] dbg_r1;
    
    // Hazard detection
    wire stall;
    
    // ID/EX Pipeline Register
    wire [15:0] ex_instruction; // NEW
    wire ex_reg_write, ex_mem_write, ex_mem_read;
    wire [1:0] ex_mem_to_reg;
    wire [1:0] ex_reg_dst;
    wire ex_alu_src, ex_branch, ex_jump, ex_jump_reg;
    wire [3:0] ex_alu_control;
    wire [15:0] ex_read_data1, ex_read_data2, ex_sign_ext_imm;
    wire [2:0] ex_rs, ex_rt, ex_rd, ex_shamt;
    wire [7:0] ex_pc;
    wire [11:0] ex_jump_addr;
    wire [3:0] ex_opcode;
    wire id_ex_valid;
    
    // EX Stage
    wire [1:0] forward_a, forward_b;
    wire [15:0] ex_alu_operand_a, ex_alu_operand_b;
    wire [15:0] ex_forwarded_a, ex_forwarded_b;
    wire [15:0] ex_alu_result;
    wire ex_zero;
    wire [2:0] ex_write_reg_addr;
    
    // Branch/Jump control
    wire branch_taken;
    wire jump_taken;
    wire [7:0] branch_target;
    wire [7:0] jump_target;
    wire flush;
    
    // EX/MEM Pipeline Register
    wire [15:0] mem_instruction; // NEW
    wire mem_reg_write, mem_mem_write, mem_mem_read;
    wire [1:0] mem_mem_to_reg;
    wire [1:0] mem_reg_dst;
    wire [15:0] mem_alu_result, mem_write_data;
    wire [2:0] mem_write_reg;
    wire [7:0] mem_pc;
    wire mem_zero;
    wire ex_mem_valid;
    
    // MEM Stage
    wire [15:0] mem_read_data;
    
    // MEM/WB Pipeline Register
    wire [15:0] wb_instruction; // NEW
    wire wb_reg_write;
    wire [1:0] wb_mem_to_reg;
    wire [1:0] wb_reg_dst;
    wire [15:0] wb_read_data, wb_alu_result;
    wire [2:0] wb_write_reg;
    wire [7:0] wb_pc;
    wire mem_wb_valid;
    
    // WB Stage
    wire [15:0] wb_write_data;
    
    // ==================== Program Counter Logic ====================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 8'h00;
            cycle_counter <= 32'h00000000;
        end else begin
            cycle_counter <= cycle_counter + 1;
            
            if (pc_write) begin
                if (flush) begin
                    if (jump_taken) begin
                        pc <= jump_target;
                    end else if (branch_taken) begin
                        pc <= branch_target;
                    end else begin
                        pc <= pc + 1;
                    end
                end else begin
                    pc <= pc + 1;
                end
            end
        end
    end
    
    // ==================== IF Stage ====================
    instruction_memory imem(
        .address(pc),
        .instruction(if_instruction),
        .dbg_address(dbg_imem_addr_req),
        .dbg_instruction(dbg_imem_data)
    );
    
    // ==================== IF/ID Pipeline Register ====================
    if_id_register if_id_reg(
        .clk(clk),
        .rst(rst),
        .stall(!if_id_write),
        .flush(flush),
        .if_instruction(if_instruction),
        .if_pc(pc),
        .id_instruction(id_instruction),
        .id_pc(id_pc),
        .valid(if_id_valid)
    );
    
    // ==================== ID Stage ====================
    control_unit ctrl(
        .opcode(id_opcode),
        .reg_write(id_reg_write),
        .mem_write(id_mem_write),
        .mem_read(id_mem_read),
        .mem_to_reg(id_mem_to_reg),
        .alu_src(id_alu_src),
        .reg_dst(id_reg_dst),
        .branch(id_branch),
        .jump(id_jump),
        .jump_reg(id_jump_reg),
        .alu_control(id_alu_control)
    );
    
    register_file regfile(
        .clk(clk),
        .rst(rst),
        .reg_write(wb_reg_write),
        .read_reg1(id_rs),
        .read_reg2(id_rt),
        .write_reg(wb_write_reg),
        .write_data(wb_write_data),
        .read_data1(id_read_data1),
        .read_data2(id_read_data2),
        .dbg_r1(dbg_r1),
        .dbg_regs_flat(dbg_regs_flat)
    );
    
    hazard_detection_unit hazard_detect(
        .id_ex_mem_read(ex_mem_read),
        .id_ex_rt(ex_rt),
        .if_id_rs(id_rs),
        .if_id_rt(id_rt),
        .if_id_opcode(id_opcode),
        .stall(stall),
        .if_id_write(if_id_write),
        .pc_write(pc_write)
    );
    
    // ==================== ID/EX Pipeline Register ====================
    id_ex_register id_ex_reg(
        .clk(clk),
        .rst(rst),
        .flush(flush || stall),
        .id_instruction(id_instruction), // Wired NEW input
        
        .id_reg_write(id_reg_write && if_id_valid && !stall),
        .id_mem_write(id_mem_write && if_id_valid && !stall),
        .id_mem_read(id_mem_read && if_id_valid && !stall),
        .id_mem_to_reg(id_mem_to_reg),
        .id_alu_src(id_alu_src),
        .id_reg_dst(id_reg_dst),
        .id_branch(id_branch),
        .id_jump(id_jump),
        .id_jump_reg(id_jump_reg),
        .id_alu_control(id_alu_control),
        .id_read_data1(id_read_data1),
        .id_read_data2(id_read_data2),
        .id_sign_ext_imm(id_sign_ext_imm),
        .id_rs(id_rs),
        .id_rt(id_rt),
        .id_rd(id_rd),
        .id_shamt(id_shamt),
        .id_pc(id_pc),
        .id_jump_addr(id_jump_addr),
        .id_opcode(id_opcode),
        
        .ex_instruction(ex_instruction), // Wired NEW output
        
        .ex_reg_write(ex_reg_write),
        .ex_mem_write(ex_mem_write),
        .ex_mem_read(ex_mem_read),
        .ex_mem_to_reg(ex_mem_to_reg),
        .ex_alu_src(ex_alu_src),
        .ex_reg_dst(ex_reg_dst),
        .ex_branch(ex_branch),
        .ex_jump(ex_jump),
        .ex_jump_reg(ex_jump_reg),
        .ex_alu_control(ex_alu_control),
        .ex_read_data1(ex_read_data1),
        .ex_read_data2(ex_read_data2),
        .ex_sign_ext_imm(ex_sign_ext_imm),
        .ex_rs(ex_rs),
        .ex_rt(ex_rt),
        .ex_rd(ex_rd),
        .ex_shamt(ex_shamt),
        .ex_pc(ex_pc),
        .ex_jump_addr(ex_jump_addr),
        .ex_opcode(ex_opcode),
        .valid(id_ex_valid)
    );
    
    // ==================== EX Stage ====================
    assign ex_write_reg_addr = (ex_reg_dst == 2'b10) ? 3'b111 :
                                (ex_reg_dst == 2'b01) ? ex_rd :
                                ex_rt;
    
    forwarding_unit forward(
        .ex_mem_reg_write(mem_reg_write),
        .ex_mem_rd(mem_write_reg),
        .mem_wb_reg_write(wb_reg_write),
        .mem_wb_rd(wb_write_reg),
        .id_ex_rs(ex_rs),
        .id_ex_rt(ex_rt),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );
    
    assign ex_forwarded_a = (forward_a == 2'b10) ? mem_alu_result :
                            (forward_a == 2'b01) ? wb_write_data :
                            ex_read_data1;
    
    assign ex_forwarded_b = (forward_b == 2'b10) ? mem_alu_result :
                            (forward_b == 2'b01) ? wb_write_data :
                            ex_read_data2;
    
    assign ex_alu_operand_a = ex_forwarded_a;
    assign ex_alu_operand_b = ex_alu_src ? ex_sign_ext_imm : ex_forwarded_b;
    
    alu alu_unit(
        .operand_a(ex_alu_operand_a),
        .operand_b(ex_alu_operand_b),
        .shamt(ex_shamt),
        .alu_control(ex_alu_control),
        .alu_result(ex_alu_result),
        .zero(ex_zero)
    );
    
    assign branch_taken = ex_branch && (
        (ex_opcode == 4'hA && ex_zero) ||
        (ex_opcode == 4'hB && !ex_zero)
    );
    
    assign jump_taken = ex_jump || ex_jump_reg;
    assign branch_target = ex_pc + 1 + ex_sign_ext_imm[7:0];
    assign jump_target = ex_jump_reg ? ex_forwarded_a[7:0] : ex_jump_addr[7:0];
    assign flush = branch_taken || jump_taken;
    
    // ==================== EX/MEM Pipeline Register ====================
    ex_mem_register ex_mem_reg(
        .clk(clk),
        .rst(rst),
        .ex_instruction(ex_instruction), // Wired NEW input
        
        .ex_reg_write(ex_reg_write),
        .ex_mem_write(ex_mem_write),
        .ex_mem_read(ex_mem_read),
        .ex_mem_to_reg(ex_mem_to_reg),
        .ex_reg_dst(ex_reg_dst),
        .ex_alu_result(ex_alu_result),
        .ex_write_data(ex_forwarded_b),
        .ex_write_reg(ex_write_reg_addr),
        .ex_pc(ex_pc),
        .ex_zero(ex_zero),
        
        .mem_instruction(mem_instruction), // Wired NEW output
        
        .mem_reg_write(mem_reg_write),
        .mem_mem_write(mem_mem_write),
        .mem_mem_read(mem_mem_read),
        .mem_mem_to_reg(mem_mem_to_reg),
        .mem_reg_dst(mem_reg_dst),
        .mem_alu_result(mem_alu_result),
        .mem_write_data(mem_write_data),
        .mem_write_reg(mem_write_reg),
        .mem_pc(mem_pc),
        .mem_zero(mem_zero),
        .valid(ex_mem_valid)
    );
    
    // ==================== MEM Stage ====================
    data_memory dmem(
        .clk(clk),
        .rst(rst),
        .mem_write(mem_mem_write),
        .mem_read(mem_mem_read),
        .address(mem_alu_result[7:0]),
        .write_data(mem_write_data),
        .read_data(mem_read_data),
        .dbg_addr(dbg_dmem_addr_req),
        .dbg_data(dbg_dmem_data)
    );
    
    // ==================== MEM/WB Pipeline Register ====================
    mem_wb_register mem_wb_reg(
        .clk(clk),
        .rst(rst),
        .mem_instruction(mem_instruction), // Wired NEW input
        
        .mem_reg_write(mem_reg_write),
        .mem_mem_to_reg(mem_mem_to_reg),
        .mem_reg_dst(mem_reg_dst),
        .mem_read_data(mem_read_data),
        .mem_alu_result(mem_alu_result),
        .mem_write_reg(mem_write_reg),
        .mem_pc(mem_pc),
        
        .wb_instruction(wb_instruction), // Wired NEW output
        
        .wb_reg_write(wb_reg_write),
        .wb_mem_to_reg(wb_mem_to_reg),
        .wb_reg_dst(wb_reg_dst),
        .wb_read_data(wb_read_data),
        .wb_alu_result(wb_alu_result),
        .wb_write_reg(wb_write_reg),
        .wb_pc(wb_pc),
        .valid(mem_wb_valid)
    );
    
    // ==================== WB Stage ====================
    assign wb_write_data = (wb_mem_to_reg == 2'b10) ? {8'h00, wb_pc + 8'h01} :
                           (wb_mem_to_reg == 2'b01) ? wb_read_data :
                           wb_alu_result;
    
    // ==================== Output Assignments ====================
    
    // Core State
    assign dbg_pc = pc;
    assign dbg_cycles = cycle_counter;
    assign dbg_if_inst = if_instruction;
    
    // ID Stage
    assign dbg_id_pc = id_pc;
    assign dbg_id_inst = id_instruction;
    assign dbg_stall = stall;
    assign dbg_flush = flush;
    assign dbg_branch_taken = branch_taken;
    assign dbg_jump_taken = jump_taken;
    
    // EX Stage
    assign dbg_ex_pc = ex_pc;
    assign dbg_ex_inst = ex_instruction; // NEW
    assign dbg_ex_opcode = ex_opcode;
    assign dbg_ex_rs = ex_rs;
    assign dbg_ex_rt = ex_rt;
    assign dbg_ex_rd = ex_rd;
    assign dbg_ex_shamt = ex_shamt;
    assign dbg_ex_imm = ex_sign_ext_imm;
    assign dbg_ex_alu_result = ex_alu_result;
    
    // MEM Stage
    assign dbg_mem_inst = mem_instruction; // NEW
    assign dbg_mem_read = mem_mem_read;
    assign dbg_mem_write = mem_mem_write;
    assign dbg_mem_addr = mem_alu_result[7:0];
    assign dbg_mem_wdata = mem_write_data;
    assign dbg_mem_rdata = mem_read_data;
    
    // WB Stage
    assign dbg_wb_inst = wb_instruction; // NEW
    assign dbg_wb_we = wb_reg_write;
    assign dbg_wb_rd = wb_write_reg;
    assign dbg_wb_wdata = wb_write_data;

    // Hazard Debug Assignments
    assign dbg_forward_a = forward_a;
    assign dbg_forward_b = forward_b;

endmodule
