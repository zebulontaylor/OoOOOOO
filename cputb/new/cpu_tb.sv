`timescale 1ns / 1ps

module cpu_tb;

    logic clk;
    logic rst;
    logic [7:0] led;

    cpu dut (
        .clk(clk),
        .rst(rst),
        .led(led)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns clock period
    end

    initial begin
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);
    end

    initial begin
        // Reset the CPU
        rst = 1;
        #20;
        rst = 0;
        #10;

        $display("=== Collatz Sequence Test (n=13) ===");
        $display("Expected: 13 -> 40 -> 20 -> 10 -> 5 -> 16 -> 8 -> 4 -> 2 -> 1 (9 steps)");

        // Load Collatz program into ROM
        // Program computes Collatz sequence starting from n=13
        // Stores intermediate values in RAM and final step count in RAM[255] (LED output)

        // PC=0: Write Imm 13 -> r1 (initialize n=13)
        dut.irom.rom[0] = 16'h0D1B;  // imm=13, rd=1, op=11 (Write Imm)
        
        // PC=1: Write Imm 0 -> r2 (initialize steps=0)
        dut.irom.rom[1] = 16'h002B;  // imm=0, rd=2, op=11 (Write Imm)
        
        // PC=2: Write Imm 1 -> r4 (constant 1)
        dut.irom.rom[2] = 16'h014B;  // imm=1, rd=4, op=11 (Write Imm)
        
        // PC=3: Write Imm 3 -> r5 (constant 3)
        dut.irom.rom[3] = 16'h035B;  // imm=3, rd=5, op=11 (Write Imm)
        
        // PC=4: Write Imm 0 -> r6 (RAM address counter)
        dut.irom.rom[4] = 16'h006B;  // imm=0, rd=6, op=11 (Write Imm)

        // PC=5: LOOP_START: AND r1 & r4 -> r3 (check if n is odd: temp = n & 1)
        dut.irom.rom[5] = 16'h1431;  // rs1=1, rs2=4, rd=3 (AND), op=1 (ALU)
        
        // PC=6: Cjump if r3 != 0 to PC+4 (jump to odd path if LSB=1)
        dut.irom.rom[6] = 16'h304C;  // rs1=3, offset=4, op=12 (Cjump)
        
        // EVEN PATH:
        // PC=7: Shift r1 right by 1 -> r1 (n = n/2)
        dut.irom.rom[7] = 16'h1415;  // rs1=1, rs2=4 (shift amount=1), rd=1, op=5 (Shift)
        
        // PC=8: Jump to PC+5 (skip odd path, go to increment steps)
        dut.irom.rom[8] = 16'h05A;   // offset=5, op=10 (Jump)
        
        // ODD PATH:
        // PC=9: Mult r1 * r5 -> r3 (temp = n * 3)
        dut.irom.rom[9] = 16'h1536;  // rs1=1, rs2=5, rd=3, op=6 (Mult)
        
        // PC=10: ADD r3 + r4 -> r1 (n = temp + 1)
        dut.irom.rom[10] = 16'h3401; // rs1=3, rs2=4, rd=0 (ADD), op=1 (ALU)
        // Note: Need to move result from r0 to r1
        
        // PC=11: MOV r0 -> r1 (move ADD result to r1)
        dut.irom.rom[11] = 16'h0014; // rs1=0, rs2=1, rd=1, op=4 (MOV)

        // INCREMENT STEPS:
        // PC=12: ADD r2 + r4 -> r2 (steps++)
        dut.irom.rom[12] = 16'h2401; // rs1=2, rs2=4, rd=0 (ADD), op=1 (ALU)
        
        // PC=13: MOV r0 -> r2 (move result to r2)
        dut.irom.rom[13] = 16'h0024; // rs1=0, rs2=2, rd=2, op=4 (MOV)
        
        // PC=14: Write RAM r1 -> ram[r6] (store current n for debugging)
        dut.irom.rom[14] = 16'h6189; // rs1=6 (addr), rs2=1 (value), op=9 (Write RAM)
        
        // PC=15: ADD r6 + r4 -> r6 (increment RAM address)
        dut.irom.rom[15] = 16'h6401; // rs1=6, rs2=4, rd=0 (ADD), op=1 (ALU)
        
        // PC=16: MOV r0 -> r6 (move result to r6)
        dut.irom.rom[16] = 16'h0064; // rs1=0, rs2=6, rd=6, op=4 (MOV)
        
        // PC=17: SUB r1 - r4 -> r0 (check if n == 1)
        dut.irom.rom[17] = 16'h1411; // rs1=1, rs2=4, rd=1 (SUB), op=1 (ALU)
        
        // PC=18: Cjump if r1 == 0 to PC+7 (if n-1==0, jump to output)
        dut.irom.rom[18] = 16'h107C; // rs1=1, offset=7, op=12 (Cjump)
        
        // PC=19: Jump to PC-14 (loop back to check even/odd)
        dut.irom.rom[19] = 16'hF2A;  // offset=-14 (0xF2), op=10 (Jump)

        // OUTPUT AND HALT:
        // PC=20: Write Imm 255 -> r7 (set address for LED output)
        dut.irom.rom[20] = 16'hFF7B; // imm=255, rd=7, op=11 (Write Imm)
        
        // PC=21: Write RAM r2 -> ram[r7] (output step count to LED)
        dut.irom.rom[21] = 16'h7289; // rs1=7 (addr=255), rs2=2 (steps), op=9 (Write RAM)
        
        // PC=22: Halt
        dut.irom.rom[22] = 16'h000F; // op=15 (Halt)

        // Initialize remaining ROM to NOPs
        for (int i = 23; i < 64; i++) begin
            dut.irom.rom[i] = 16'h0000; // NOP
        end

        $display("Program loaded. Starting execution...");
        
        // Run for enough cycles to complete the Collatz sequence
        // Each instruction takes ~7-10 cycles minimum through pipeline
        // Multiply operations take additional cycles
        // Allow generous time: 23 instructions * 15 cycles average = ~350 cycles
        repeat(500) @(posedge clk);
        
        $display("\n=== Execution Complete ===");
        $display("LED Output (Steps): %d", led);
        $display("Expected Steps: 9");
        
        // Check some intermediate values stored in RAM for debugging
        $display("\n=== Debugging: Intermediate Values in RAM ===");
        for (int i = 0; i < 10; i++) begin
            if (dut.ramfu_instance.ram[i] != 0) begin
                $display("RAM[%0d] = %0d", i, dut.ramfu_instance.ram[i]);
            end
        end
        
        // Verify the result
        if (led == 9) begin
            $display("\n*** TEST PASSED: Collatz sequence completed correctly! ***");
        end else begin
            $display("\n*** TEST FAILED: Expected 9 steps, got %d ***", led);
        end
        
        // Additional verification - check if CPU halted properly
        if (dut.halt) begin
            $display("CPU halted properly.");
        end else begin
            $display("WARNING: CPU did not halt - may still be running.");
        end
        
        $display("\n=== Final Register States (Physical Register File) ===");
        for (int i = 0; i < 16; i++) begin
            // Note: Due to register renaming, architectural registers may be mapped
            // to different physical registers. This shows the raw physical register values.
            $display("PRF[%0d] = %0d", i, dut.prf_instance.rf[i]);
        end
        
        $finish;
    end

    // Monitor key signals during execution
    initial begin
        $monitor("Time=%0t PC=%0d Instr=%04h Halt=%b LED=%0d", 
                 $time, dut.pc, dut.decoder_instr, dut.halt, led);
    end

    // Timeout safety
    initial begin
        #50000; // 50us timeout
        $display("*** TIMEOUT: Test did not complete in expected time ***");
        $finish;
    end

endmodule
