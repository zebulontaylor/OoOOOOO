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
    
    //input cdb_transmit_in,  - PRF GETS PRIORITY
    
    input[3:0] requested_id,
    input requesting,
    
    input[7:0] wb_val,
    input[3:0] wb_id,
    input[3:0] old_wb,
    input wb_ena,

    output reg[PRF_SIZE-1:0] ready_regs,

    output reg cdb_transmit,
    output reg[3:0] cdb_id,
    output reg[7:0] cdb_val
);
    reg[PRF_SIZE-1:0][7:0] rf;
    
    always @(*) begin
        if (rst)
            rf = 0;
    end
    
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
        if (wb_ena) begin
            rf[wb_id] <= wb_val;
            ready_regs[wb_id] <= 1;
            ready_regs[old_wb] <= 0; // retired
        end
    end
    
endmodule
