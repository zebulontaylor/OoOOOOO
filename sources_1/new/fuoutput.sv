`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2025 05:05:05 PM
// Design Name: 
// Module Name: fuoutput
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


module fuoutput(
    input clk,
    input rst,

    // INPUTS
    input input_transmit,
    input cdb_write_en,
    input[7:0] wbs,
    input[7:0] flags,
    input[3:0] robid,
    input[7:0] result,
    
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
    reg[7:0] stored_result;
    reg[7:0] stored_wbs;
    reg[7:0] stored_flags;
    reg[3:0] stored_robid;
    reg awaiting_cdb;
    reg awaiting_rob;

    wire request_cdb = (input_transmit & cdb_write_en) | awaiting_cdb;
    wire grant_cdb = request_cdb & ~cdb_transmit;

    wire request_rob = input_transmit | awaiting_rob;
    wire grant_rob = request_rob & ~rob_transmit;

    always @(*) begin
        cdb_transmit_out = cdb_transmit | request_cdb;
        if (grant_cdb) begin
            cdb_id = awaiting_cdb ? stored_wbs[3:0] : wbs[3:0];
            cdb_val = awaiting_cdb ? stored_result : result;
        end else begin
            cdb_id = 4'b0;
            cdb_val = 8'b0;
        end
        
        rob_transmit_out = rob_transmit | request_rob;
        if (grant_rob) begin
            robid_out = awaiting_rob ? stored_robid : robid;
            flags_out = awaiting_rob ? stored_flags : flags;
            wbs_out = awaiting_rob ? stored_wbs : wbs;
            value_out = awaiting_rob ? stored_result : result;
        end else begin
            robid_out = 4'b0;
            flags_out = 8'b0;
            wbs_out = 8'b0;
            value_out = 8'b0;
        end
        
        busy = awaiting_cdb | awaiting_rob;
    end

    always @(posedge clk) begin
        if (rst) begin
            awaiting_cdb <= 0;
            awaiting_rob <= 0;
        end else begin
            if (input_transmit) begin
                if (cdb_transmit & cdb_write_en) awaiting_cdb <= 1;
                if (rob_transmit) awaiting_rob <= 1;
                
                if ((cdb_transmit & cdb_write_en) | rob_transmit) begin
                    stored_result <= result;
                    stored_wbs <= wbs;
                    stored_flags <= flags;
                    stored_robid <= robid;
                end
            end
            
            if (awaiting_cdb & grant_cdb) begin
                awaiting_cdb <= 0;
            end
            
            if (awaiting_rob & grant_rob) begin
                awaiting_rob <= 0;
            end
        end
    end
endmodule
