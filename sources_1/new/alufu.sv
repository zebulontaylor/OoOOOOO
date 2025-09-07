`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2025 11:03:33 AM
// Design Name: 
// Module Name: alufu
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


module alufu(
    // INPUTS
    input input_transmit,
    input[7:0] operand,
    input[7:0] wbs,
    input[7:0] flags,
    input[7:0] robid,
    
    // CDB OUTPUT
    input cdb_transmit,
    
    output reg cdb_transmit_out,
    output reg[3:0] cdb_id,
    output reg[7:0] cdb_val,
    
    // ROB OUTPUT
    input rob_transmit,
    
    output reg[7:0] robid_out,
    output reg[7:0] flags_out,
    output reg[7:0] wbs_out,
    output reg[7:0] value_out,
    output reg rob_transmit_out,
    
    // STALLING
    output reg busy
);
endmodule
