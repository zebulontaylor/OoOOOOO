`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2025 11:03:33 AM
// Design Name: 
// Module Name: rob
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

// More of a results buffer than a ROB
module rob(
    input clk,
    input rst,
    
    // INPUTS
    input rob_transmit,
    input[3:0] robid,
    input[7:0] flags,
    input[7:0] wbs,
    input[7:0] value,
    
    // PRF MANAGEMENT
    output reg prf_transmit,
    output reg[3:0] prf_id,
    output reg[7:0] prf_value,
    
    // BRANCH MANAGEMENT
    output reg branch_transmit,
    output reg[7:0] new_pc,
    output reg branch_not_taken,
    
    // RETIRING MANAGEMENT
    output reg retire_transmit,
    output reg[3:0] retire_id
    
    // MEMORY MANAGEMENT is uh... to be implemented
);
    reg[15:0][7:0] values_rf;
    reg[15:0][7:0] wbs_rf;
    reg[15:0][7:0] flags_rf;
    reg[15:0] ready;
    
    reg[3:0] pos;

    always @(*) begin
        if (rst) begin
            pos <= 0;
            ready <= 0;
            values_rf <= 0;
            wbs_rf <= 0;
            flags_rf <= 0;
        end
    end
    
    always @(posedge clk) begin
        prf_transmit = 0;
        
        if (rob_transmit) begin
            values_rf[robid] <= value;
            wbs_rf[robid] <= wbs;
            flags_rf[robid] <= flags;
            ready[robid] <= 1;

            prf_transmit = 1;
            prf_id <= wbs_rf[robid][3:0];
            prf_value <= values_rf[robid];
        end
        
        branch_transmit = 0;
        retire_transmit = 0;
        
        if (ready[pos]) begin
            pos <= pos + 1;
            ready[pos] <= 0;
            
            if (!flags_rf[pos][0]) begin  // Reg WB enabled
                //prf_transmit = 1;
                retire_transmit = 1;
                //prf_id <= wbs_rf[pos][3:0];
                //prf_value <= values_rf[pos];
                retire_id <= wbs_rf[pos][7:4];
            end
            
            if (flags_rf[pos][4]) begin  // Halt
            end
            
            if (flags_rf[pos][0]) begin  // Branch
                branch_transmit = 1;
                branch_not_taken = flags_rf[pos][5];
                new_pc <= values_rf[pos];
            end
        end
    end

endmodule
