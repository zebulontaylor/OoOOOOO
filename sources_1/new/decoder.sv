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
    output reg[1:0][3:0] readregs,
    output reg[1:0] read_ena,
    output reg[3:0] writereg,
    output reg write_ena,
    output reg[7:0] flagouts,
    output reg[3:0] fuid,
    output reg halt
);
    logic [15:0] all_flags [15:0];
    logic [3:0] all_fuids [15:0];
    
    initial begin
        all_flags = '{
            16'b1000000000000000, // Noop (NO_PRF_WRITE in flagouts[7])
            16'b0000000000001101, // ALU
            16'b0000111000000001, // Add Imm
            16'b0000011000000001, // Xor Imm
            16'b0000010000000110, // Mov
            16'b0000000000001101, // Shift
            16'b0000000000001110, // Mult
            16'b0000000000000110, // Hash
            16'b0000000000000110, // Read RAM
            16'b1000001000001100, // Write RAM (NO_PRF_WRITE)
            16'b1000011100000000, // Jump (NO_PRF_WRITE)
            16'b0000011000000001, // Write Imm
            16'b1000000100001100, // Cjump (NO_PRF_WRITE)
            16'b1000000000000000, //
            16'b1000000000000000, //
            16'b1001000000000000  // Halt (NO_PRF_WRITE)
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
        {b, c, a} = instr[15:4];
        flagouts = flags[15:8];
        
        if (flags[0]) begin
            writereg = a;
            write_ena = 1'b1;
        end else if (flags[1]) begin
            writereg = c;
            write_ena = 1'b1;
        end else begin
            writereg = 0;
            write_ena = 1'b0;
        end
        
        if (flags[2]) begin
            readregs[0] = a;
            read_ena[0] = 1'b1;
        end else begin
            readregs[0] = 0;
            read_ena[0] = 1'b0;
        end
        
        if (flags[3]) begin
            readregs[1] = b;
            read_ena[1] = 1'b1;
        end else begin
            readregs[1] = 0;
            read_ena[1] = 1'b0;
        end
        
        fuid = all_fuids[4'd15-instr[3:0]];
        halt = flagouts[4];
    end
endmodule
