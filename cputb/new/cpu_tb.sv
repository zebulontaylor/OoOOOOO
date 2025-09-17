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
        $display("=== Collatz Sequence Test (n=13) ===");
        $display("Expected: 13 -> 40 -> 20 -> 10 -> 5 -> 16 -> 8 -> 4 -> 2 -> 1 (9 steps)");

        // Load Collatz program into ROM BEFORE releasing reset
        // Program computes Collatz sequence starting from n=13
        // Stores intermediate values in RAM and final step count in RAM[255] (LED output)
        
        // Reset the CPU
        rst = 1;

        // PC=0: Write Imm 13 -> r1
        dut.irom.rom[0] = 16'h0D1B;

        // PC=1: Write Imm 0 -> r2
        dut.irom.rom[1] = 16'h002B;

        // PC=2: Write Imm 1 -> r4
        dut.irom.rom[2] = 16'h014B;

        // PC=3: Write Imm 3 -> r5
        dut.irom.rom[3] = 16'h035B;

        // PC=4: Write Imm 0 -> r6
        dut.irom.rom[4] = 16'h006B;

        // PC=5: Write Imm 10 -> r7 (target for first cjump to PC=10)
        dut.irom.rom[5] = 16'h0A7B;

        // PC=6: AND r1 & r4 -> r1
        dut.irom.rom[6] = 16'h4211;

        // PC=7: Cjump if r1 != 0 to PC=10 (using inverse cond=1 for ==0)
        dut.irom.rom[7] = 16'h721C;

        // PC=8: Shift r1 >> 1 -> r1
        dut.irom.rom[8] = 16'h4115;

        // PC=9: Jump to PC=13
        dut.irom.rom[9] = 16'h0D0A;

        // PC=10: Mult r1 * r5 -> r3
        dut.irom.rom[10] = 16'h5316;

        // PC=11: MOV r3 -> r1
        dut.irom.rom[11] = 16'h0314;

        // PC=12: ADD r1 + r4 -> r1
        dut.irom.rom[12] = 16'h4011;

        // PC=13: ADD r2 + r4 -> r2
        dut.irom.rom[13] = 16'h4021;

        // PC=14: NOP
        dut.irom.rom[14] = 16'h0000;

        // PC=15: Write RAM r1 -> ram[r6]
        dut.irom.rom[15] = 16'h1069;

        // PC=16: ADD r6 + r4 -> r6
        dut.irom.rom[16] = 16'h4061;

        // PC=17: MOV r1 -> r0
        dut.irom.rom[17] = 16'h0014;

        // PC=18: SUB r0 - r4 -> r0
        dut.irom.rom[18] = 16'h4101;

        // PC=19: Write Imm 22 -> r3 (target for second cjump to PC=22)
        dut.irom.rom[19] = 16'h163B;

        // PC=20: Cjump if r0 == 0 to PC=22 (using inverse cond=2 for !=0)
        dut.irom.rom[20] = 16'h320C;

        // PC=21: Jump to PC=6 (loop back)
        dut.irom.rom[21] = 16'h060A;

        // PC=22: Write Imm 255 -> r7
        dut.irom.rom[22] = 16'hFF7B;

        // PC=23: Write RAM r2 -> ram[r7]
        dut.irom.rom[23] = 16'h2079;

        // PC=24: Halt
        dut.irom.rom[24] = 16'h000F;

        // Initialize remaining ROM to NOPs
        for (int i = 25; i < 64; i++) begin
            dut.irom.rom[i] = 16'h0000; // NOP
        end

        $display("Program loaded. Releasing reset...");
        
        // Now release reset after ROM is fully loaded
        #20;
        rst = 0;
        #10;
        
        $display("Starting execution...");
        
        // Run for enough cycles
        repeat(600) @(posedge clk);
        
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
