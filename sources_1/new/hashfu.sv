`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2025 11:03:33 AM
// Design Name: 
// Module Name: hashfu
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


module hashfu(
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
    wire[7:0] a;

    always_comb begin
        a = depvals[0];
    end

    reg[7:0] stored_result;
    reg[7:0] stored_wbs;
    reg[7:0] stored_flags;
    reg[3:0] stored_robid;
    reg awaiting_cdb;
    reg awaiting_rob;

    reg[7:0] result;
    always @(*) begin
        result = a;  // TODO: pipeline this....
        result ^= result << 3;
        result += 8'h61;
        result ^= result >> 5;
        result += 8'h61;
        result ^= result << 7;
    end

    // ------ Nonspecific to Hash ------
    wire request_cdb = input_transmit | awaiting_cdb;
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
        
        busy = request_cdb | request_rob;
    end

    always @(posedge clk) begin
        if (rst) begin
            awaiting_cdb <= 0;
            awaiting_rob <= 0;
        end else begin
            if (input_transmit) begin
                if (cdb_transmit) awaiting_cdb <= 1;
                if (rob_transmit) awaiting_rob <= 1;
                
                if (cdb_transmit | rob_transmit) begin
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
