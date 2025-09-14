`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2025 11:03:33 AM
// Design Name: 
// Module Name: decoder
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
    logic [3:0] all_fuids [15:0];
    
    initial begin
        all_flags = '{
            16'b0000000000000000, // Noop
            16'b0000000000001101, // ALU
            16'b0000111000000001, // Add Imm
            16'b0000011000000001, // Xor Imm
            16'b0000000000000110, // Mov
            16'b0000000000000110, // Shift
            16'b0000000000001110, // Mult
            16'b0000000000000110, // Hash
            16'b0000001000000110, // Read RAM
            16'b0000000000001100, // Write RAM
            16'b1000001100000000, // Jump
            16'b0000001000000001, // Write Imm
            16'b0000000100001100, // Cjump
            16'b1000000000000000, //
            16'b1000000000000000, //
            16'b0001000000000000  // Halt
        };
        all_fuids = '{
            4'b0000, // Noop
            4'b0000, // ALU
            4'b0000, // Add Imm
            4'b0000, // Xor Imm
            4'b0001, // Mov
            4'b0101, // Shift
            4'b0010, // Mult
            4'b0011, // Hash
            4'b0110, // Read RAM
            4'b0110, // Write RAM
            4'b0001, // Jump
            4'b0001, // Write Imm
            4'b0100, // Cjump
            4'b0001, //
            4'b0001, //
            4'b0001  // Halt
        };
    end
    
    reg[15:0] flags;
    reg[3:0] a, b, c;
    
    always_comb begin
        flags = all_flags[4'd15-instr[3:0]];
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
        
        fuid = all_fuids[4'd15-instr[3:0]];
        halt = flagouts[4];
    end
endmodule
