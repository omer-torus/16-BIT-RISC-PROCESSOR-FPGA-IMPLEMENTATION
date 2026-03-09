/*
 * DEBUG HUD Controller - Enhanced UI
 * 
 * Retro-cyberpunk style debug interface for RISC Processor.
 * Features:
 * - Color-coded Pipeline Stages strip
 * - Dedicated Register View
 * - Real-time Memory View (Instruction & Data)
 * - Status Flags & Cycle Counter
 * - Live Assembly Disassembly on Pipeline Stages
 * - **NEW: Focused Instruction Window (PC to PC+4)**
 * - **NEW: Decimal Display for Cycles & PC**
 * 
 * Resolution: 640x480 (80x30 characters)
 */

module debug_hud(
    input  wire        clk_pix,
    input  wire        rst,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire        active,

    // CPU state inputs
    input  wire [7:0]  dbg_pc,
    input  wire [31:0] dbg_cycles,
    input  wire [15:0] dbg_if_inst,
    input  wire [7:0]  dbg_id_pc,
    input  wire [15:0] dbg_id_inst,
    input  wire        dbg_stall,
    input  wire        dbg_flush,
    input  wire        dbg_branch_taken,
    input  wire        dbg_jump_taken,

    // EX stage
    input  wire [7:0]  dbg_ex_pc,
    input  wire [15:0] dbg_ex_inst,
    input  wire [3:0]  dbg_ex_opcode,
    input  wire [2:0]  dbg_ex_rs,
    input  wire [2:0]  dbg_ex_rt,
    input  wire [2:0]  dbg_ex_rd,
    input  wire [2:0]  dbg_ex_shamt,
    input  wire [15:0] dbg_ex_imm,
    input  wire [15:0] dbg_ex_alu_result,

    // MEM stage
    input  wire [15:0] dbg_mem_inst,
    input  wire        dbg_mem_read,
    input  wire        dbg_mem_write,
    input  wire [7:0]  dbg_mem_addr,
    input  wire [15:0] dbg_mem_wdata,
    input wire [15:0] dbg_mem_rdata,

    // WB stage
    input  wire [15:0] dbg_wb_inst,
    input  wire        dbg_wb_we,
    input  wire [2:0]  dbg_wb_rd,
    input  wire [15:0] dbg_wb_wdata,

    // Hazard input
    input  wire [1:0]  dbg_forward_a,
    input  wire [1:0]  dbg_forward_b,

    // Memory debug ports
    input  wire [15:0] dbg_imem_data,
    input  wire [15:0] dbg_dmem_data,
    input  wire [127:0] dbg_regs_flat,

    // Memory address requests
    output reg  [7:0]  imem_addr_req,
    output reg  [7:0]  dmem_addr_req,

    // RGB output
    output reg  [7:0]  r,
    output reg  [7:0]  g,
    output reg  [7:0]  b
);

    // Grid Position
    wire [6:0] col = x[9:3];
    wire [4:0] row = y[8:4];
    wire [2:0] px  = x[2:0];
    wire [3:0] py  = y[3:0];
    wire [2:0] frow = py[3:1];

    wire frame_tick = active && (x==10'd0) && (y==10'd0);

    // Sampled State
    reg  [7:0]  pc_s;
    reg  [31:0] cyc_s;
    reg  [15:0] ifi_s;
    reg  [7:0]  idpc_s;
    reg  [15:0] idi_s;
    reg         stall_s, flush_s, br_s, jp_s;
    reg  [7:0]  expc_s;
    reg  [15:0] exi_s; 
    reg  [3:0]  exop_s;
    reg  [2:0]  exrs_s, exrt_s, exrd_s;
    reg  [15:0] exalu_s;
    reg  [15:0] memi_s; 
    reg         mr_s, mw_s;
    reg  [7:0]  maddr_s;
    reg  [15:0] mwdata_s, mrdata_s;
    reg  [15:0] wbi_s; 
    reg         wbwe_s;
    reg  [2:0]  wbrd_s;
    reg  [15:0] wbwd_s;
    reg  [1:0]  fwda_s, fwdb_s;
    reg  [127:0] regs_s;

    always @(posedge clk_pix) begin
        if (frame_tick) begin
            pc_s<=dbg_pc; cyc_s<=dbg_cycles; ifi_s<=dbg_if_inst; idpc_s<=dbg_id_pc; idi_s<=dbg_id_inst;
            stall_s<=dbg_stall; flush_s<=dbg_flush; br_s<=dbg_branch_taken; jp_s<=dbg_jump_taken;
            
            expc_s<=dbg_ex_pc; exi_s<=dbg_ex_inst; 
            exop_s<=dbg_ex_opcode; exrs_s<=dbg_ex_rs; exrt_s<=dbg_ex_rt; exrd_s<=dbg_ex_rd;
            exalu_s<=dbg_ex_alu_result;
            
            memi_s<=dbg_mem_inst; 
            mr_s<=dbg_mem_read; mw_s<=dbg_mem_write; maddr_s<=dbg_mem_addr; mwdata_s<=dbg_mem_wdata; mrdata_s<=dbg_mem_rdata;
            
            wbi_s<=dbg_wb_inst; 
            wbwe_s<=dbg_wb_we; wbrd_s<=dbg_wb_rd; wbwd_s<=dbg_wb_wdata;
            
            fwda_s<=dbg_forward_a; fwdb_s<=dbg_forward_b;
            
            regs_s<=dbg_regs_flat;
        end
    end

    // Memory layout logic - Instruction Window
    always @(*) begin
        imem_addr_req = pc_s; // Default

        // Show PC, PC+1, PC+2, PC+3, PC+4 on rows 22-26
        if (row >= 22 && row <= 26)
            imem_addr_req = pc_s + (row - 22);
        
        // DMEM: Two Column View
        // Col < 56: Base Address [0,2,4,6,8,A,C]
        // Col >= 56: Offset Address [E,10,12,14,16,18,1A] (Base + 14)
        dmem_addr_req = 8'd0; 
        if (row >= 22 && row <= 28) begin
            if (col < 56)
                dmem_addr_req = (row - 22) << 1; 
            else
                dmem_addr_req = ((row - 22) << 1) + 8'd14;
        end
    end

    // Helper Functions
    function [7:0] hex; input [3:0] v; begin 
        hex = (v<=9) ? 8'h30+v : 8'h41+(v-10); 
    end endfunction

    function [7:0] dec; input [2:0] v; begin
        dec = 8'h30 + {5'b0, v};
    end endfunction

    // Helper: Get Decimal Digit Character from a value
    // digit_pos: 0 for ones, 1 for tens, etc.
    function [7:0] get_dec_char;
        input [31:0] val;
        input [3:0]  digit_pos;
        reg [31:0]   temp;
        begin
            case(digit_pos)
                0: temp = val;
                1: temp = val / 10;
                2: temp = val / 100;
                3: temp = val / 1000;
                4: temp = val / 10000;
                5: temp = val / 100000;
                6: temp = val / 1000000;
                7: temp = val / 10000000;
                default: temp = 0;
            endcase
            get_dec_char = 8'h30 + (temp % 10);
        end
    endfunction

    // Simplified Disassembler
    function [7:0] disasm_char;
        input [15:0] inst;
        input [4:0]  idx;
        reg [3:0] op;
        reg [2:0] rs, rt, rd;
        reg [5:0] imm;
        begin
            op=inst[15:12]; rs=inst[11:9]; rt=inst[8:6]; rd=inst[5:3]; imm=inst[5:0];
            disasm_char = 8'h20; 

            if (inst == 16'h0000) begin 
               // NOP
               if(idx==0) disasm_char=8'h4E; if(idx==1) disasm_char=8'h4F; if(idx==2) disasm_char=8'h50; 
            end 
            else if (inst == 16'hF000) begin
                // END / HALT
               if(idx==0) disasm_char=8'h45; if(idx==1) disasm_char=8'h4E; if(idx==2) disasm_char=8'h44; 
            end
            else begin
                case(op)
                    4'h7: begin // ADDI Rt, Rs, Imm
                        case(idx) 0:disasm_char=8'h41; 1:disasm_char=8'h44; 2:disasm_char=8'h44; 3:disasm_char=8'h49; 
                        4:disasm_char=8'h20; 5:disasm_char=8'h52; 6:disasm_char=dec(rt);
                        7:disasm_char=8'h2C; 8:disasm_char=8'h52; 9:disasm_char=dec(rs);
                        10:disasm_char=8'h2C; 11:disasm_char=hex(imm[3:0]); // Show Lower Nibble only (Compact)
                        endcase
                    end
                    4'h0: begin // ADD Rd, Rs, Rt
                        case(idx) 0:disasm_char=8'h41; 1:disasm_char=8'h44; 2:disasm_char=8'h44; 
                        4:disasm_char=8'h20; 5:disasm_char=8'h52; 6:disasm_char=dec(rd);
                        7:disasm_char=8'h2C; 8:disasm_char=8'h52; 9:disasm_char=dec(rs);
                        10:disasm_char=8'h2C; 11:disasm_char=8'h52; 12:disasm_char=dec(rt);
                        endcase
                    end
                    4'h9: begin // SW Rt, Imm(Rs)
                        case(idx) 0:disasm_char=8'h53; 1:disasm_char=8'h57; 
                        3:disasm_char=8'h20; 4:disasm_char=8'h52; 5:disasm_char=dec(rt);
                        6:disasm_char=8'h2C; 7:disasm_char=8'h52; 8:disasm_char=dec(rs);
                        endcase
                    end
                    4'h8: begin // LW Rt, Imm(Rs)
                        case(idx) 0:disasm_char=8'h4C; 1:disasm_char=8'h57; 
                        3:disasm_char=8'h20; 4:disasm_char=8'h52; 5:disasm_char=dec(rt);
                        6:disasm_char=8'h2C; 7:disasm_char=8'h52; 8:disasm_char=dec(rs);
                        endcase
                    end
                    4'hA: begin // BEQ Rs, Rt, Imm
                        case(idx) 0:disasm_char=8'h42; 1:disasm_char=8'h45; 2:disasm_char=8'h51;
                        4:disasm_char=8'h20; 5:disasm_char=8'h52; 6:disasm_char=dec(rs);
                        7:disasm_char=8'h2C; 8:disasm_char=8'h52; 9:disasm_char=dec(rt);
                        10:disasm_char=8'h2C; 11:disasm_char=hex(imm[3:0]); // Show Imm
                        endcase
                    end
                    4'hB: begin // BNE Rs, Rt, Imm
                        case(idx) 0:disasm_char=8'h42; 1:disasm_char=8'h4E; 2:disasm_char=8'h45;
                        4:disasm_char=8'h20; 5:disasm_char=8'h52; 6:disasm_char=dec(rs);
                        7:disasm_char=8'h2C; 8:disasm_char=8'h52; 9:disasm_char=dec(rt);
                        10:disasm_char=8'h2C; 11:disasm_char=hex(imm[3:0]); // Show Imm
                        endcase
                    end
                    4'h4: begin // SLT Rd, Rs, Rt
                        case(idx) 0:disasm_char=8'h53; 1:disasm_char=8'h4C; 2:disasm_char=8'h54;
                        4:disasm_char=8'h20; 5:disasm_char=8'h52; 6:disasm_char=dec(rd);
                        7:disasm_char=8'h2C; 8:disasm_char=8'h52; 9:disasm_char=dec(rs);
                        10:disasm_char=8'h2C; 11:disasm_char=8'h52; 12:disasm_char=dec(rt);
                        endcase
                    end
                    4'hC: begin // J Addr
                        case(idx) 0:disasm_char=8'h4A;1:disasm_char=8'h20; 2:disasm_char=8'h4A; 3:disasm_char=8'h4D; 4:disasm_char=8'h50; endcase
                    end
                    default: begin 
                       // Show Hex: "DATA"
                       case(idx) 0:disasm_char=8'h44; 1:disasm_char=8'h41; 2:disasm_char=8'h54; 3:disasm_char=8'h41; endcase
                    end
                endcase
            end
        end
    endfunction

    // Character Map Generation
    function [7:0] get_char;
        input [4:0] r;
        input [6:0] c;
        reg [15:0] val;
        reg [15:0] r0,r1,r2,r3,r4,r5,r6,r7;
        reg [4:0] di;
        begin
            val = 16'h0000;
            
            r7=regs_s[127:112]; r6=regs_s[111:96]; r5=regs_s[95:80]; r4=regs_s[79:64];
            r3=regs_s[63:48];  r2=regs_s[47:32];  r1=regs_s[31:16];  r0=regs_s[15:0];
            
            get_char = 8'h20; // Default Space

            // HEADER
            if (r==0) begin
                if(c>=1 && c<=19) begin // "16-BIT CPU DEBUGGER"
                    case(c-1) 0:get_char=8'h31;1:get_char=8'h36;2:get_char=8'h2D;3:get_char=8'h42;4:get_char=8'h49;
                    5:get_char=8'h54;6:get_char=8'h20;7:get_char=8'h43;8:get_char=8'h50;9:get_char=8'h55;
                    10:get_char=8'h20;11:get_char=8'h44;12:get_char=8'h45;13:get_char=8'h42;14:get_char=8'h55;
                    15:get_char=8'h47;16:get_char=8'h47;17:get_char=8'h45;18:get_char=8'h52; endcase
                end
                else if (c>=65) begin // "CYCLES: 00000000" (DECIMAL)
                    case(c-65) 0:get_char=8'h43;1:get_char=8'h59;2:get_char=8'h43;3:get_char=8'h3A;
                    // Display Cycles in Decimal (8 digits)
                    5:get_char=get_dec_char(cyc_s, 7);
                    6:get_char=get_dec_char(cyc_s, 6);
                    7:get_char=get_dec_char(cyc_s, 5);
                    8:get_char=get_dec_char(cyc_s, 4);
                    9:get_char=get_dec_char(cyc_s, 3);
                    10:get_char=get_dec_char(cyc_s, 2);
                    11:get_char=get_dec_char(cyc_s, 1);
                    12:get_char=get_dec_char(cyc_s, 0); endcase
                end
            end
            
            // LEFT COLUMN: REGISTERS
            else if (r==2 && c==1) begin 
                get_char=8'h52; 
            end 
            else if (r>=3 && r<=10 && c>=1 && c<=25) begin
                case(r) 3:val=r0; 4:val=r1; 5:val=r2; 6:val=r3; 7:val=r4; 8:val=r5; 9:val=r6; 10:val=r7; default:val=0; endcase
                case(c)
                    1:get_char=8'h52; 2:get_char=dec(r-3); 3:get_char=8'h3A; 
                    5:get_char=hex(val[15:12]); 6:get_char=hex(val[11:8]); 7:get_char=hex(val[7:4]); 8:get_char=hex(val[3:0]); 
                endcase
            end

            // RIGHT COLUMN: STATE (PC DECIMAL)
            else if (r==3 && c>=35) begin 
                case(c-35)
                    0:get_char=8'h50;1:get_char=8'h43;2:get_char=8'h3A; 
                    // PC in Decimal (3 digits)
                    4:get_char=get_dec_char({24'd0, pc_s}, 2);
                    5:get_char=get_dec_char({24'd0, pc_s}, 1);
                    6:get_char=get_dec_char({24'd0, pc_s}, 0);
                endcase
            end
            else if (r==5 && c>=35) begin 
                // ALU: XXXX    STALL: X   FLUSH: X
                // c=35..43 (ALU)
                case(c-35)
                    0:get_char=8'h41;1:get_char=8'h4C;2:get_char=8'h55;3:get_char=8'h3D; 
                    5:get_char=hex(exalu_s[15:12]);6:get_char=hex(exalu_s[11:8]);7:get_char=hex(exalu_s[7:4]);8:get_char=hex(exalu_s[3:0]);
                endcase
                
                // STALL (Col 48)
                if(c>=45 && c<=50) begin case(c-45) 0:get_char=8'h53;1:get_char=8'h54;2:get_char=8'h41;3:get_char=8'h4C;4:get_char=8'h4C;5:get_char=8'h3A; endcase end
                if(c==52) get_char=hex({3'b0, stall_s});

                // FLUSH (Col 56)
                if(c>=55 && c<=60) begin case(c-55) 0:get_char=8'h46;1:get_char=8'h4C;2:get_char=8'h55;3:get_char=8'h53;4:get_char=8'h48;5:get_char=8'h3A; endcase end
                if(c==62) get_char=hex({3'b0, flush_s});
            end
            else if (r==6 && c>=35) begin
                 // FWDA: X   FWDB: X
                 if(c>=45 && c<=49) begin case(c-45) 0:get_char=8'h46;1:get_char=8'h57;2:get_char=8'h44;3:get_char=8'h41;4:get_char=8'h3A; endcase end
                 if(c==51) get_char=hex({2'b0, fwda_s}); 
                 
                 if(c>=55 && c<=59) begin case(c-55) 0:get_char=8'h46;1:get_char=8'h57;2:get_char=8'h44;3:get_char=8'h42;4:get_char=8'h3A; endcase end
                 if(c==61) get_char=hex({2'b0, fwdb_s}); 
            end

            // PIPELINE STRIP TEXT (Row 12) - SPACING INCREASED
            else if (r==12) begin
                // FETCH (Cols 2-13) - Center ~7
                if(c>=5 && c<=9) begin case(c-5) 0:get_char=8'h46;1:get_char=8'h45;2:get_char=8'h54;3:get_char=8'h43;4:get_char=8'h48; endcase end
                if(c==15) get_char=8'h3E; // >
                
                // DECODE (Cols 17-28) - Center ~22
                if(c>=20 && c<=25) begin case(c-20) 0:get_char=8'h44;1:get_char=8'h45;2:get_char=8'h43;3:get_char=8'h4F;4:get_char=8'h44;5:get_char=8'h45; endcase end
                if(c==30) get_char=8'h3E; // >
                
                // EXECUTE (Cols 32-43) - Center ~37
                if(c>=34 && c<=40) begin case(c-34) 0:get_char=8'h45;1:get_char=8'h58;2:get_char=8'h45;3:get_char=8'h43;4:get_char=8'h55;5:get_char=8'h54;6:get_char=8'h45; endcase end
                if(c==45) get_char=8'h3E; // >
                
                // MEMORY (Cols 47-58) - Center ~52
                if(c>=50 && c<=55) begin case(c-50) 0:get_char=8'h4D;1:get_char=8'h45;2:get_char=8'h4D;3:get_char=8'h4F;4:get_char=8'h52;5:get_char=8'h59; endcase end
                if(c==60) get_char=8'h3E; // >
                
                // WRITEBK (Cols 62-73) - Center ~67
                if(c>=64 && c<=70) begin case(c-64) 0:get_char=8'h57;1:get_char=8'h52;2:get_char=8'h49;3:get_char=8'h54;4:get_char=8'h45;5:get_char=8'h42;6:get_char=8'h4B; endcase end
            end

            // PIPE STAGE ASSEMBLY OVERLAY (Row 13) - WIDER RANGES
            else if (r==13) begin
                // FETCH (Cols 1-14)
                if(c>=1 && c<=14) begin di=c-1; get_char = disasm_char(ifi_s, di); end
                // DECODE (Cols 16-29)
                if(c>=16 && c<=29) begin di=c-16; get_char = disasm_char(idi_s, di); end
                // EXECUTE (Cols 31-44)
                if(c>=31 && c<=44) begin di=c-31; get_char = disasm_char(exi_s, di); end
                // MEM (Cols 46-59)
                if(c>=46 && c<=59) begin di=c-46; get_char = disasm_char(memi_s, di); end
                // WB (Cols 61-75)
                if(c>=61 && c<=75) begin di=c-61; get_char = disasm_char(wbi_s, di); end
            end

            // PIPELINE DETAILS (Row 15) - ALIGNED
            else if (r==15) begin
                // IF Detail (Align w/ 2-13)
                if(c==4) get_char=hex(ifi_s[15:12]); if(c==5) get_char=hex(ifi_s[11:8]); 
                if(c==6) get_char=hex(ifi_s[7:4]); if(c==7) get_char=hex(ifi_s[3:0]);
                
                // ID Detail (Align w/ 17-28)
                if(c==19) get_char=8'h4F; if(c==20) get_char=8'h50; if(c==21) get_char=8'h3A; if(c==22) get_char=hex(idi_s[15:12]);
                
                // EX Detail (Align w/ 32-43)
                if(c==34) get_char=8'h52; if(c==35) get_char=8'h53; if(c==36) get_char=dec(exrs_s);
                if(c==38) get_char=8'h52; if(c==39) get_char=8'h54; if(c==40) get_char=dec(exrt_s);

                // MEM Detail (Align w/ 47-58)
                if(c==52) get_char=mr_s?8'h52:mw_s?8'h57:8'h2D; // R/W/-
                
                // WB Detail (Align w/ 62-73)
                if(c==64) get_char=8'h52; if(c==65) get_char=dec(wbrd_s); if(c==67) get_char=8'h3D;
                if(c==68) get_char=hex(wbwd_s[7:4]); if(c==69) get_char=hex(wbwd_s[3:0]);
            end
            
            // MEMORY HEADERS
            else if (r==20) begin
                // INSTRUCTION MEM
                if(c==1) get_char=8'h49; if(c==2) get_char=8'h4E; if(c==3) get_char=8'h53; if(c==4) get_char=8'h54; 
                
                // DATA MEM 1
                if(c==42) get_char=8'h44; if(c==43) get_char=8'h41; if(c==44) get_char=8'h54; if(c==45) get_char=8'h41; 
                
                // DATA MEM 2
                if(c==59) get_char=8'h44; if(c==60) get_char=8'h41; if(c==61) get_char=8'h54; if(c==62) get_char=8'h41; 
            end
            
            // MEMORY CONTENT WINDOWS (Rows 22-28)
            else if (r>=22 && r<=28) begin
                // LEFT SIDE: INSTRUCTION MEMORY (Rows 22-26, PC -> PC+4)
                if (r<=26 && c<=35) begin
                    if(c==1) get_char=8'h3E; // > Cursor
                    
                    // Show Address [XXX] in Decimal
                    if(c==3) get_char=8'h5B;
                    if(c==4) get_char=get_dec_char({24'd0, imem_addr_req}, 2); // Hundreds
                    if(c==5) get_char=get_dec_char({24'd0, imem_addr_req}, 1); // Tens
                    if(c==6) get_char=get_dec_char({24'd0, imem_addr_req}, 0); // Ones
                    if(c==7) get_char=8'h5D;
                    
                    // Show Assembly
                    if(c>=9 && c<=25) begin
                        di=c-9;
                        get_char=disasm_char(dbg_imem_data, di);
                    end
                    
                    // Show Hex
                    if(c==27) get_char=hex(dbg_imem_data[15:12]);
                    if(c==28) get_char=hex(dbg_imem_data[11:8]);
                    if(c==29) get_char=hex(dbg_imem_data[7:4]);
                    if(c==30) get_char=hex(dbg_imem_data[3:0]);
                end
                
                // RIGHT SIDE: DATA MEMORY 1 (Rows 22-28, Cols 41-55)
                else if(c>=41 && c<=55) begin
                     case(c-40)
                       1:get_char=hex(dmem_addr_req[7:4]); 2:get_char=hex(dmem_addr_req[3:0]); 3:get_char=8'h3A;
                       5:get_char=hex(dbg_dmem_data[15:12]); 6:get_char=hex(dbg_dmem_data[11:8]);
                       7:get_char=hex(dbg_dmem_data[7:4]); 8:get_char=hex(dbg_dmem_data[3:0]);
                    endcase
                end
                
                // RIGHT SIDE: DATA MEMORY 2 (Rows 22-28, Cols 58-72)
                else if(c>=58 && c<=72) begin
                     case(c-57)
                       1:get_char=hex(dmem_addr_req[7:4]); 2:get_char=hex(dmem_addr_req[3:0]); 3:get_char=8'h3A;
                       5:get_char=hex(dbg_dmem_data[15:12]); 6:get_char=hex(dbg_dmem_data[11:8]);
                       7:get_char=hex(dbg_dmem_data[7:4]); 8:get_char=hex(dbg_dmem_data[3:0]);
                    endcase
                end
            end
        end
    endfunction

    wire [7:0] ch = get_char(row, col);
    wire [7:0] glyph;
    
    font_min u_font(
        .char_code(ch),
        .row_index(frow),
        .row_pixels(glyph)
    );

    wire pixel_on = glyph[7-px];

    reg [7:0] bg_r, bg_g, bg_b;
    reg [7:0] fg_r, fg_g, fg_b;

    // Logic to fetch "Old" register value for change detection
    reg [15:0] old_reg_val;
    always @(*) begin
        case(wbrd_s)
            0: old_reg_val = regs_s[15:0];
            1: old_reg_val = regs_s[31:16];
            2: old_reg_val = regs_s[47:32];
            3: old_reg_val = regs_s[63:48];
            4: old_reg_val = regs_s[79:64];
            5: old_reg_val = regs_s[95:80];
            6: old_reg_val = regs_s[111:96];
            7: old_reg_val = regs_s[127:112];
            default: old_reg_val = 16'h0000;
        endcase
    end

    always @(*) begin
        bg_r = 8'h05; bg_g = 8'h05; bg_b = 8'h15; // Dark Blue
        fg_r = 8'hFF; fg_g = 8'hFF; fg_b = 8'hFF; // White

        if (!active) begin
            r=0; g=0; b=0;
        end else begin
            if (row < 2) begin bg_r=8'h20; bg_g=8'h20; bg_b=8'h40; end
            if (row >= 3 && row <= 10 && col <= 20) begin bg_r=8'h00; bg_g=8'h00; bg_b=8'h30; end

            if (row==12) begin
                if(col>=2 && col<=13)  begin bg_r=8'h00; bg_g=8'h00; bg_b=8'h80; end // IF
                if(col>=17 && col<=28) begin bg_r=8'h00; bg_g=8'h40; bg_b=8'h00; end // ID
                if(col>=32 && col<=43) begin bg_r=8'h40; bg_g=8'h00; bg_b=8'h40; end // EX
                if(col>=47 && col<=58) begin bg_r=8'h40; bg_g=8'h40; bg_b=8'h00; end // MEM
                if(col>=62 && col<=73) begin bg_r=8'h80; bg_g=8'h00; bg_b=8'h00; end // WB
            end
            
            if (row==0) begin fg_r=8'h00; fg_g=8'hFF; fg_b=8'h00; end 
            if (row==2 && col==1) begin fg_r=8'hFF; fg_g=8'hFF; fg_b=8'h00; end 
            if (row==20) begin fg_r=8'h00; fg_g=8'hFF; fg_b=8'hFF; end 
            
            // Highlight Assembly Text on Row 13 (Moved from 11) with Yellow
            if (row==13) begin fg_r=8'hFF; fg_g=8'hFF; fg_b=8'h00; end

            // Highlight Current Instruction Line
            if (row==22) begin fg_r=8'h00; fg_g=8'hFF; fg_b=8'h00; end // Green Text for PC

            // Highlight Changing Register (Writeback Stage)
            // Color Green ONLY if Value Changes
            if (row >= 3 && row <= 10 && col <= 25) begin
                if (wbwe_s && (wbrd_s == (row - 3)) && (wbwd_s != old_reg_val)) begin
                    fg_r=8'h00; fg_g=8'hFF; fg_b=8'h00; // Green
                end
            end

            // Highlight Changing Memory (Memory Stage)
            // Color Green ONLY if Value Changes (New Write Data != Old Read Data)
            if (row >= 22 && row <= 28 && col >= 41) begin
                if (mw_s && (dmem_addr_req == maddr_s) && (mwdata_s != mrdata_s)) begin
                    fg_r=8'h00; fg_g=8'hFF; fg_b=8'h00; // Green
                end
            end

            if (pixel_on) begin
                r = fg_r; g = fg_g; b = fg_b;
            end else begin
                r = bg_r; g = bg_g; b = bg_b;
            end
        end
    end

endmodule
