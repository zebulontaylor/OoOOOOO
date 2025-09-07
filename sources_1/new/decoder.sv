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
    output reg[3:0] fuid
    );
    logic [15:0] all_flags [15:0];
    
    initial begin
        all_flags = '{
        16'b0000000000000000, // Noop
        16'b0000000000001110, // ALU
        16'b0000000000000000, // ALU Imm
        16'b0000000000000000, // etc
        16'b0000000000000000,
        16'b0000000000000000,
        16'b0000000000000000,
        16'b0000000000000000,
        16'b0000000000000000,
        16'b0000000000000000,
        16'b0000000000000000,
        16'b0000000000000000,
        16'b0000000000000000,
        16'b0000000000000000,
        16'b0000000000000000,
        16'b0000000000000000
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
    end
endmodule
