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
    reg[3:0] op;
    reg[7:0] a, b;

    always_comb begin
        a = depvals[0];
        if (flags[2]) begin // Imm ALU
            b = operand;
            if (flags[3]) // Add Imm
                op = 4'h0;
            else // XOR Imm
                op = 4'h4;
        end else begin // Normal ALU
            b = depvals[1];
            op = operand[3:0];
        end
    end

    reg[7:0] result;
    always @(*) begin
        case (op)
            4'h0: result = a + b;
            4'h1: result = a - b;
            4'h2: result = a & b;
            4'h3: result = a | b;
            4'h4: result = a ^ b;
            4'h5: result = ~(a | b);
            4'h6: result = ~(a & b);
            4'h7: result = ~(a ^ b);
            default: result = 8'b0;
        endcase
    end

    fuoutput fuoutput_inst(
        .clk(clk),
        .rst(rst),
        .input_transmit(input_transmit),
        .cdb_write_en(1'b1),
        .wbs(wbs),
        .flags(flags),
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
