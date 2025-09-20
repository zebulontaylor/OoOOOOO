`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/14/2025 10:28:11 AM
// Design Name: 
// Module Name: ramfu
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

module ramfu(
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
    output reg busy,

    // SWITCH INPUT
    input [15:0] sw,

    // LED PORT
    output [7:0] led
);
    logic [7:0] ram [256];

    initial ram = '{default: 0};

    wire write_en = flags[1];  // Technically sel imm but we can reuse it
    reg [7:0] result;

    assign led = ram[255];

    always_comb begin
        if (!write_en) begin
            // Check if reading from switch addresses
            if (depvals[1] == 8'd254) begin
                result = sw[7:0];  // Lower 8 switches
            end else if (depvals[1] == 8'd253) begin
                result = sw[15:8]; // Upper 8 switches
            end else begin
                result = ram[depvals[1]]; // RAM[A] -> C
            end
        end else begin
            result = 0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            ram <= '{default: 0};
        end
        if (write_en) begin
            if (depvals[1] != 8'd254 && depvals[1] != 8'd253) begin
                ram[depvals[1]] <= depvals[0]; // B -> RAM[A]
            end
        end
    end

    fuoutput fuoutput_inst(
        .clk(clk),
        .rst(rst),
        .input_transmit(input_transmit),
        .cdb_write_en(~flags[7]),
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
