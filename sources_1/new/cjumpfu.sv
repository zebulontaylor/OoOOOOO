`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2025 11:03:33 AM
// Design Name: 
// Module Name: cjumpfu
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


module cjumpfu(
    input clk,
    input rst,

    // INPUTS
    input input_transmit,
    input[7:0] operand,
    input[1:0][7:0] depvals,
    input[7:0] wbs,
    input[7:0] flags,
    input[3:0] robid,
    
    // CDB OUTPUT
    input cdb_transmit,
    
    output reg cdb_transmit_out,
    output reg[3:0] cdb_id,
    output reg[7:0] cdb_val,
    
    // ROB OUTPUT
    input rob_transmit,
    
    output reg[3:0] robid_out,
    output reg[7:0] flags_out,
    output reg[7:0] wbs_out,
    output reg[7:0] value_out,
    output reg rob_transmit_out,
    
    // STALLING
    output reg busy
);
    reg[7:0] a, b;
    reg[3:0] cond;
    reg[7:0] updated_flags;

    always_comb begin
        a = depvals[0];
        b = depvals[1];
        cond = operand[7:4];
    end

    reg[7:0] stored_result;
    reg[7:0] stored_wbs;
    reg[7:0] stored_flags;
    reg[3:0] stored_robid;
    reg awaiting_cdb;
    reg awaiting_rob;

    reg[7:0] result;

    reg msb;
    reg lsbs;
    reg take_branch;
    always_comb begin
        msb = a[7];
        lsbs = |a[6:0];
        take_branch = cond[{msb, lsbs}];
        result = b;
        updated_flags = flags;
        updated_flags[5] = take_branch;
    end

    fuoutput fuoutput_inst(
        .clk(clk),
        .rst(rst),
        .input_transmit(input_transmit),
        .cdb_write_en(1'b1),
        .wbs(wbs),
        .flags(updated_flags),
        .robid(robid),
        .result(result),
        .cdb_transmit(cdb_transmit),
        .cdb_transmit_out(cdb_transmit_out),
        .cdb_id(cdb_id),
        .cdb_val(cdb_val),
        .rob_transmit(rob_transmit),
        .robid_out(robid_out),
        .flags_out(flags_out),
        .wbs_out(wbs_out),
        .value_out(value_out),
        .rob_transmit_out(rob_transmit_out),
        .busy(busy)
    );
endmodule
