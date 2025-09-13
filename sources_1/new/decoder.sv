`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2025 11:03:33 AM
// Design Name: 
// Module Name: rs
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


module decoder(
    input[15:0] instr,
    output reg[1:0][4:0] readregs,
    output reg[4:0] writereg,
    output reg[7:0] flagouts,
    output reg[3:0] fuid,
    output reg halt
);
    logic [15:0] all_flags [15:0];
    logic [15:0] all_fuids [3:0];
    
    initial begin
        all_flags = '{
            16'b0000000000000000, // Noop
            16'b0000000000000000, // ALU
            16'b0000000000000000, // Add Imm
            16'b0000000000000000, // Xor Imm
            16'b0000000000000000, // Mov
            16'b0000000000000000, // Shift
            16'b0000000000000000, // Mult
            16'b0000000000000000, // Hash
            16'b0000000000000000, // Read RAM
            16'b0000000000000000, // Write RAM
            16'b1000000000000000, // Jump
            16'b0000000000000000, // Write Imm
            16'b0000000000000000, // Cjump
            16'b1000000000000000, //
            16'b1000000000000000, //
            16'b0000000000000000  // Halt
        };
        all_fuids = '{
            4'b0001, // ALU
            4'b0001, // Add Imm
            4'b0001, // Xor Imm
            4'b0010, // Mov
            4'b0011, // Shift
            4'b0100, // Mult
            4'b0101, // Hash
            4'b0110, // Read RAM
            4'b0001, // Write RAM
            4'b0010, // Jump
            4'b0010, // Write Imm
            4'b0111, // Cjump
            4'b0001, //
            4'b0001, //
            4'b0010  // Halt
        };
    end
    
    reg[15:0] flags;
    reg[3:0] a, b, c;
    
    always_comb begin
        flags = all_flags[instr[3:0]];
        {a, b, c} = instr[15:4];
        flagouts = flags[15:8];
        
        if (flags[0])
            writereg = {a, 1'b1};
        else if (flags[1])
            writereg = {c, 1'b1};
        else
            writereg = 0;
        
        if (flags[2])
            readregs[0] = {a, 1'b1};
        else
            readregs[0] = 0;
        
        if (flags[3])
            readregs[1] = {b, 1'b1};
        else
            readregs[1] = 0;
        
        fuid = all_fuids[instr[3:0]];
        halt = flagouts[4];
    end
endmodule
