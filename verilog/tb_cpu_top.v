`timescale 1ns/1ps
`include "defines.vh"

module tb_cpu_top;
    reg clk, rst;
    wire [15:0] debug_r1, debug_instruction;
    wire debug_halted;
    cpu_top dut (.clk(clk), .rst(rst), .debug_r1(debug_r1), .debug_instruction(debug_instruction), .debug_halted(debug_halted));
    
    initial begin clk = 0; forever #5 clk = ~clk; end
    
    integer test_num, pass_count, fail_count;
    
    task check_register;
        input [2:0] reg_addr;
        input [15:0] expected;
        input [255:0] test_name;
        begin
            if (reg_addr == 0) begin
                if (16'h0000 !== expected) begin
                    $display("[FAIL] %s: r%0d = 0x%04h (expected 0x%04h)", test_name, reg_addr, 16'h0000, expected);
                    fail_count = fail_count + 1;
                end else begin
                    $display("[PASS] %s: r%0d = 0x%04h", test_name, reg_addr, 16'h0000);
                    pass_count = pass_count + 1;
                end
            end else begin
                if (dut.u_regfile.registers[reg_addr] !== expected) begin
                    $display("[FAIL] %s: r%0d = 0x%04h (expected 0x%04h)", test_name, reg_addr, dut.u_regfile.registers[reg_addr], expected);
                    fail_count = fail_count + 1;
                end else begin
                    $display("[PASS] %s: r%0d = 0x%04h", test_name, reg_addr, dut.u_regfile.registers[reg_addr]);
                    pass_count = pass_count + 1;
                end
            end
        end
    endtask
    
    initial begin
        $display("============================================");
        $display("  16-bit RISC Processor Testbench");
        $display("  Phase 3: Hazard Management Verification");
        $display("============================================");
        pass_count = 0; fail_count = 0;
        $dumpfile("cpu_top.vcd"); $dumpvars(0, tb_cpu_top);
        
        rst = 1; repeat(2) @(posedge clk); rst = 0;
        
        // Test 1: Data Forwarding (EX/MEM and MEM/WB)
        // FIXED: Use 6-bit immediate values only (0-31 for positive values)
        $display("\n--- Test 1: Data Forwarding ---");
        dut.u_imem.memory[0] = 16'b0111_000_001_000101;  // addi r1, r0, 5 (FIXED: 0111=ADDI)
        dut.u_imem.memory[1] = 16'b0111_000_010_001010;  // addi r2, r0, 10 (FIXED: 0111=ADDI)
        dut.u_imem.memory[2] = 16'b0000_001_010_011_000;  // add r3, r1, r2  (r3 = 5 + 10 = 15, forward both)
        dut.u_imem.memory[3] = 16'b0001_011_001_100_000;  // sub r4, r3, r1  (r4 = 15 - 5 = 10, forward r3 from EX/MEM)
        dut.u_imem.memory[4] = 16'hFFFF;                  // halt
        repeat(20) @(posedge clk);
        check_register(1, 16'd5, "Test1: r1=5");
        check_register(2, 16'd10, "Test1: r2=10");
        check_register(3, 16'd15, "Test1: r3=15");
        check_register(4, 16'd10, "Test1: r4=10");
        
        rst = 1; repeat(2) @(posedge clk); rst = 0;
        
        // Test 2: Load-Use Hazard (Stall)
        // FIXED: Use 6-bit immediate values (changed from 100/200 to 20/40)
        $display("\n--- Test 2: Load-Use Hazard (Stall Detection) ---");
        dut.u_imem.memory[0] = 16'b0111_000_001_010100;  // addi r1, r0, 20 (FIXED: 0111=ADDI, 010100 = 20)
        dut.u_imem.memory[1] = 16'b1001_000_001_000000;  // sw r1, 0(r0)
        dut.u_imem.memory[2] = 16'b1000_000_010_000000;  // lw r2, 0(r0) (FIXED: 1000=LW)
        dut.u_imem.memory[3] = 16'b0000_010_001_011_000;  // add r3, r2, r1 (r3 = 20 + 20 = 40, STALL!)
        dut.u_imem.memory[4] = 16'hFFFF;                  // halt
        repeat(20) @(posedge clk);
        check_register(1, 16'd20, "Test2: r1=20");
        check_register(2, 16'd20, "Test2: r2=20");
        check_register(3, 16'd40, "Test2: r3=40");
        
        rst = 1; repeat(2) @(posedge clk); rst = 0;
        
        // Test 3: Branch and Jump (Flush)
        // FIXED: Use 6-bit immediate value (changed from 99 to 25)
        $display("\n--- Test 3: Branch/Jump Control Hazards ---");
        dut.u_imem.memory[0] = 16'b0111_000_001_000101;  // addi r1, r0, 5 (FIXED: 0111=ADDI)
        dut.u_imem.memory[1] = 16'b0111_000_010_000101;  // addi r2, r0, 5 (FIXED: 0111=ADDI)
        dut.u_imem.memory[2] = 16'b1010_001_010_000001;  // beq r1, r2, +1 (taken, skip next instruction)
        dut.u_imem.memory[3] = 16'b0111_000_011_011001;  // addi r3, r0, 25 (FIXED: 0111=ADDI, 011001 = 25, FLUSHED!)
        dut.u_imem.memory[4] = 16'b0111_000_100_001010;  // addi r4, r0, 10 (FIXED: 0111=ADDI)
        dut.u_imem.memory[5] = 16'hFFFF;                  // halt
        repeat(20) @(posedge clk);
        check_register(1, 16'd5, "Test3: r1=5");
        check_register(2, 16'd5, "Test3: r2=5");
        check_register(3, 16'd0, "Test3: r3=0 (flushed, not 25)");
        check_register(4, 16'd10, "Test3: r4=10");
        
        rst = 1; repeat(2) @(posedge clk); rst = 0;
        
        // Test 4: JAL Instruction (R7 = PC+1)
        // JAL should store the return address (PC+1) in R7
        // J-Type format: [opcode(4)][address(12)]
        $display("\n--- Test 4: JAL Instruction (R7 Link Register) ---");
        dut.u_imem.memory[0] = 16'b0111_000_001_000011;  // addi r1, r0, 3
        dut.u_imem.memory[1] = 16'b1101_000000000100;    // jal 4 (PC will jump to 4, R7 = 2)
        dut.u_imem.memory[2] = 16'b0111_000_010_111111;  // addi r2, r0, 63 (SKIPPED due to JAL)
        dut.u_imem.memory[3] = 16'b0111_000_011_111111;  // addi r3, r0, 63 (SKIPPED due to JAL)
        dut.u_imem.memory[4] = 16'b0111_000_100_001111;  // addi r4, r0, 15
        dut.u_imem.memory[5] = 16'b0111_000_101_010100;  // addi r5, r0, 20
        dut.u_imem.memory[6] = 16'hFFFF;                  // halt
        repeat(25) @(posedge clk);
        check_register(1, 16'd3, "Test4: r1=3");
        check_register(7, 16'd2, "Test4: r7=2 (JAL return address)");  // R7 = PC+1 when JAL executed (PC was 1, so R7 = 2)
        check_register(2, 16'd0, "Test4: r2=0 (skipped by JAL)");
        check_register(3, 16'd0, "Test4: r3=0 (skipped by JAL)");
        check_register(4, 16'd15, "Test4: r4=15 (after jump target)");
        check_register(5, 16'd20, "Test4: r5=20");
        
        rst = 1; repeat(2) @(posedge clk); rst = 0;
        
        // Test 5: JAL and JR Subroutine Call/Return
        // This tests the complete subroutine mechanism using JAL and JR
        $display("\n--- Test 5: JAL/JR Subroutine Call and Return ---");
        // Main program:
        // 0: addi r1, r0, 7     - Initialize r1
        // 1: jal 5              - Call subroutine at address 5, R7 = 2
        // 2: addi r6, r0, 30   - This executes AFTER returning from subroutine
        // 3: halt
        // 4: nop (padding)
        // Subroutine at address 5:
        // 5: addi r2, r0, 10   - Subroutine work
        // 6: addi r3, r0, 12   - More subroutine work
        // 7: jr r7             - Return to caller (address in R7)
        dut.u_imem.memory[0] = 16'b0111_000_001_000111;  // addi r1, r0, 7
        dut.u_imem.memory[1] = 16'b1101_000000000101;    // jal 5 (R7 = PC+1 = 2)
        dut.u_imem.memory[2] = 16'b0111_000_110_011110;  // addi r6, r0, 30 (executes after JR return)
        dut.u_imem.memory[3] = 16'hFFFF;                  // halt
        dut.u_imem.memory[4] = 16'h0000;                  // nop (padding)
        dut.u_imem.memory[5] = 16'b0111_000_010_001010;  // addi r2, r0, 10 (subroutine start)
        dut.u_imem.memory[6] = 16'b0111_000_011_001100;  // addi r3, r0, 12
        dut.u_imem.memory[7] = 16'b1110_111_000_000_000;  // jr r7 (return to address 2)
        dut.u_imem.memory[8] = 16'hFFFF;                  // halt (safety)
        repeat(35) @(posedge clk);
        check_register(1, 16'd7, "Test5: r1=7 (before JAL)");
        check_register(7, 16'd2, "Test5: r7=2 (JAL return address)");
        check_register(2, 16'd10, "Test5: r2=10 (subroutine executed)");
        check_register(3, 16'd12, "Test5: r3=12 (subroutine executed)");
        check_register(6, 16'd30, "Test5: r6=30 (after JR return)");
        
        $display("\n============================================");
        $display("  Test Summary");
        $display("============================================");
        $display("  PASSED: %0d", pass_count);
        $display("  FAILED: %0d", fail_count);
        if (fail_count == 0) begin
            $display("\n  *** ALL TESTS PASSED ***");
            $display("  Hazard Management: VERIFIED");
        end else begin
            $display("\n  *** SOME TESTS FAILED ***");
        end
        $display("============================================\n");
        $finish;
    end
    
    initial begin #10000; $display("\n[ERROR] Simulation timeout!"); $finish; end
endmodule
