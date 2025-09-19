`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2025 11:03:33 AM
// Design Name: 
// Module Name: rom
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rom(
    input[5:0] pc,
    output[15:0] instr
    );
    
    reg[15:0] rom [63:0];

    initial begin
        // Collatz Sequence Program (reading input from lower 8 switches)
        // Reads switch value from RAM address 254, then computes Collatz sequence
        // Stores intermediate values in RAM and final step count in RAM[255] (LED output)
        
        // PC=0: Write Imm 254 -> r3 (address for switch input)
        rom[0] = 16'hFE3B;

        // PC=1: Read RAM ram[r3] -> r1 (get switch value)
        rom[1] = 16'h0138;

        // PC=2: Write Imm 0 -> r2
        rom[2] = 16'h002B;

        // PC=3: Write Imm 1 -> r4
        rom[3] = 16'h014B;

        // PC=4: Write Imm 3 -> r5
        rom[4] = 16'h035B;

        // PC=5: Write Imm 0 -> r6
        rom[5] = 16'h006B;

        // PC=6: Write Imm 13 -> r7 (target for first cjump to PC=13)
        rom[6] = 16'h0D7B;

        // PC=7: MOV r1 -> r0 (save original r1 value)
        /* 0 (unused) | 0 (target) | 1 (source) | 4 (opcode) */
        rom[7] = 16'h0014;

        // PC=8: AND r1 & r4 -> r1 (check if odd)
        /* 4 (b) | 2 (a) | 1 (op) | 1 (opcode) */
        rom[8] = 16'h4211;

        // PC=9: Cjump if r1 != 0 to PC=13 (using inverse cond=1 for ==0)
        /* 7 (target PC) | 2 (cond) | 1 (reg to evaluate) | C (opcode) */
        rom[9] = 16'h721C;

        // PC=10: Shift r0 >> 1 -> r0 (even case: r0 = original_r0 >> 1)
        /* 4 (b; 1) | 1 (op; >>) | 0 (a; r0) | 5 (opcode) */
        rom[10] = 16'h4105;

        // PC=11: MOV r0 -> r1
        /* 0 (unused) | 1 (target) | 0 (source) | 4 (opcode) */
        rom[11] = 16'h0104;

        // PC=12: Jump to PC=16
        rom[12] = 16'h100A;

        // PC=13: Mult r0 * r5 -> r3 (odd case: use original r1 value)
        rom[13] = 16'h5306;

        // PC=14: MOV r3 -> r1
        /* 0 (unused) | 1 (target) | 3 (source) | 4 (opcode) */
        rom[14] = 16'h0134;

        // PC=15: ADD r1 + r4 -> r1
        rom[15] = 16'h4011;

        // PC=16: ADD r2 + r4 -> r2
        rom[16] = 16'h4021;

        // PC=17: NOP
        rom[17] = 16'h0000;

        // PC=18: Write RAM r1 -> ram[r6]
        rom[18] = 16'h1069;

        // PC=19: ADD r6 + r4 -> r6
        rom[19] = 16'h4061;

        // PC=20: MOV r1 -> r0
        /* 0 (unused) | 0 (target) | 1 (source) | 4 (opcode) */
        rom[20] = 16'h0014;

        // PC=21: SUB r0 - r4 -> r0
        rom[21] = 16'h4101;

        // PC=22: Write Imm 25 -> r3 (target for second cjump to PC=25)
        rom[22] = 16'h193B;

        // PC=23: Cjump if r0 == 0 to PC=25 (using inverse cond=2 for !=0)
        rom[23] = 16'h310C;

        // PC=24: Jump to PC=7 (loop back to save r1 and check again)
        rom[24] = 16'h070A;

        // PC=25: Write Imm 255 -> r7
        rom[25] = 16'hFF7B;

        // PC=26: Write RAM r2 -> ram[r7]
        rom[26] = 16'h2079;

        // PC=27: Halt
        rom[27] = 16'h000F;

        // Initialize remaining ROM to NOPs
        for (int i = 28; i < 64; i++) begin
            rom[i] = 16'h0000; // NOP
        end
    end
    
    assign instr = rom[pc];
endmodule
