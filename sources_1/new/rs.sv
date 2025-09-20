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


module rs(
    input rst,
    input clk,
    
    // Data
    input[7:0] operandin,
    input[7:0] wbsin,
    input[7:0] flagin,
    input[3:0] robidin,
    
    output reg[7:0] operandout,
    output reg[7:0] wbsout,
    output reg[1:0][7:0] depvalsout,
    output reg[7:0] flagout,
    output reg[3:0] robidout,
    
    // CAM/CDB
    input[1:0][3:0] depidsin,
    input[3:0] depins,
    input[7:0] depinval,
    
    // Bus ctrl
    input fuclaimed,
    output logic futransmitout,
    output logic fuclaimedout,
    
    input camtransmit,
    output logic camtransmitout,
    
    // Occupancy tracking
    output logic rs_full
);
    
    reg camlocked;
    reg[1:0][3:0] depids;
    reg[7:0] operand, wbs, flag;
    reg[3:0] robid;
    reg[1:0][7:0] depvals;
    
    reg[1:0] deplocks;
    
    initial camlocked = 0;
    initial deplocks = 0;
    
    wire can_release;
    
    assign can_release = (deplocks == 2'b11) && camlocked && ~fuclaimed;
    assign rs_full = camlocked;
    
    always @(posedge clk) begin
        // Lock inputs if unclaimed
        if (camtransmit & ~camlocked) begin
            camlocked = 1;
            
            // Lock data
            depids = depidsin;
            operand <= operandin;
            wbs <= wbsin;
            robid <= robidin;
            flag <= flagin;
        end

        // Lock deps
        for (integer i=0; i < 2; i = i+1) begin
            if (depins == depids[i] && camlocked) begin
                deplocks[i] = 1;
                depvals[i] <= depinval;
            end
        end

        if (rst) begin
            camlocked = 0;
            deplocks = 0;
            depids = 0;
            operand <= 0;
            wbs <= 0;
            robid <= 0;
            flag <= 0;
            depvals <= 0;
        end else if (can_release) begin
            deplocks = 0;
            camlocked = 0;
        end
    end
    
    always @(*) begin
        camtransmitout = camlocked ? camtransmit : 0;

        if (can_release) begin
            operandout = operand;
            wbsout = wbs;
            depvalsout = depvals;
            flagout = flag;
            robidout = robid;
            futransmitout = 1;
            fuclaimedout = 1;
        end else begin
            operandout = 0;
            wbsout = 0;
            depvalsout = '{default: '0};
            flagout = 0;
            robidout = 0;
            futransmitout = 0;
            fuclaimedout = fuclaimed;
        end
    end
endmodule


