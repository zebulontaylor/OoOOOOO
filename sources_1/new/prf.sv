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


module prf #(
    parameter PRF_SIZE = 16
)(
    input clk,
    input rst,
    
    // CDB feedback input (shared CDB looped back)
    input shared_cdb_transmit,
    input[3:0] shared_cdb_id,
    input[7:0] shared_cdb_val,
    
    input[3:0] requested_id,
    input requesting,
    
    input[3:0] old_wb,
    input retire_ena,

    output reg[PRF_SIZE-1:0] ready_regs,

    output reg cdb_transmit,
    output reg[3:0] cdb_id,
    output reg[7:0] cdb_val
);
    reg[PRF_SIZE-1:0][7:0] rf;
    
    always @(*) begin
        cdb_transmit = requesting;
        if (requesting) begin
            cdb_id = requested_id;
            cdb_val = rf[requested_id];
        end else begin
            cdb_id = 0;
            cdb_val = 0;
        end
    end
    
    always @(posedge clk) begin
        if (retire_ena) begin
            ready_regs[old_wb] <= 0; // retired
        end
        
        // Write from shared CDB feedback (includes PRF and FU broadcasts)
        if (shared_cdb_transmit) begin
            rf[shared_cdb_id] <= shared_cdb_val;
            ready_regs[shared_cdb_id] <= 1;
        end

        if (rst) begin
            rf <= 0;
            ready_regs <= 0;
        end
    end
    
endmodule
