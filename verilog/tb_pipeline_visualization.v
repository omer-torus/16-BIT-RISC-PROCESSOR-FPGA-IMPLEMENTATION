/*
 * Pipeline Visualization Test Bench
 * Displays detailed pipeline stage information for debugging
 */

`timescale 1ns / 1ps

module tb_pipeline_visualization;

    reg clk;
    reg rst;
    wire [7:0] pc;
    wire [15:0] instruction;
    wire stall;
    wire [31:0] cycle_count;
    
    processor_top uut(
        .clk(clk),
        .rst(rst),
        .pc_out(pc),
        .instruction_out(instruction),
        .stall_out(stall),
        .cycle_count(cycle_count)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // Detailed pipeline monitoring
    always @(posedge clk) begin
        if (!rst && cycle_count > 0) begin
            $display("========== Cycle %0d ==========", cycle_count);
            $display("PC = %0d", pc);
            
            // IF/ID Stage
            if (uut.if_id_valid) begin
                $display("IF/ID: Valid | PC=%0d | Inst=0x%04h", 
                         uut.id_pc, uut.id_instruction);
            end else begin
                $display("IF/ID: Bubble");
            end
            
            // ID/EX Stage
            if (uut.id_ex_valid) begin
                $display("ID/EX: Valid | PC=%0d | RegWrite=%b | MemRead=%b | MemWrite=%b", 
                         uut.ex_pc, uut.ex_reg_write, uut.ex_mem_read, uut.ex_mem_write);
                $display("       RS=R%0d | RT=R%0d | RD=R%0d", 
                         uut.ex_rs, uut.ex_rt, uut.ex_rd);
            end else begin
                $display("ID/EX: Bubble");
            end
            
            // EX/MEM Stage
            if (uut.ex_mem_valid) begin
                $display("EX/MEM: Valid | ALU_Result=%0d | RD=R%0d | RegWrite=%b", 
                         uut.mem_alu_result, uut.mem_rd, uut.mem_reg_write);
            end else begin
                $display("EX/MEM: Bubble");
            end
            
            // MEM/WB Stage
            if (uut.mem_wb_valid) begin
                $display("MEM/WB: Valid | RD=R%0d | WriteData=%0d | RegWrite=%b", 
                         uut.wb_rd, uut.wb_write_data, uut.wb_reg_write);
            end else begin
                $display("MEM/WB: Bubble");
            end
            
            // Hazard information
            if (stall) begin
                $display(">>> HAZARD: Pipeline Stall (Load-Use Hazard)");
            end
            if (uut.flush) begin
                $display(">>> HAZARD: Pipeline Flush (Branch/Jump Taken)");
            end
            if (uut.forward_a != 2'b00 || uut.forward_b != 2'b00) begin
                $display(">>> FORWARDING: Forward_A=%b, Forward_B=%b", 
                         uut.forward_a, uut.forward_b);
            end
            
            $display("");
        end
    end
    
    initial begin
        $dumpfile("pipeline_viz.vcd");
        $dumpvars(0, tb_pipeline_visualization);
        
        rst = 1;
        #25;
        rst = 0;
        
        $display("========================================");
        $display("   Pipeline Visualization Test         ");
        $display("========================================");
        $display("");
        
        #800;
        
        $display("========================================");
        $display("   Final State                         ");
        $display("========================================");
        $display("Total Cycles: %0d", cycle_count);
        $display("");
        $display("Registers:");
        $display("R0=%0d | R1=%0d | R2=%0d | R3=%0d", 
                 uut.regfile.registers[0], uut.regfile.registers[1],
                 uut.regfile.registers[2], uut.regfile.registers[3]);
        $display("R4=%0d | R5=%0d | R6=%0d | R7=%0d", 
                 uut.regfile.registers[4], uut.regfile.registers[5],
                 uut.regfile.registers[6], uut.regfile.registers[7]);
        
        $finish;
    end
    
    // Load simple test program
    initial begin
        // Simple program with forwarding and hazards
        uut.imem.memory[0] = 16'b0111_000_001_001010;  // ADDI R1, R0, 10
        uut.imem.memory[1] = 16'b0111_000_010_000101;  // ADDI R2, R0, 5
        uut.imem.memory[2] = 16'b0000_001_010_011_000;  // ADD R3, R1, R2 (forwarding)
        uut.imem.memory[3] = 16'b1001_000_011_000000;  // SW R3, 0(R0)
        uut.imem.memory[4] = 16'b1000_000_100_000000;  // LW R4, 0(R0)
        uut.imem.memory[5] = 16'b0000_100_001_101_000;  // ADD R5, R4, R1 (load-use hazard!)
    end

endmodule

