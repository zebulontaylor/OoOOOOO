`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2025 11:03:33 AM
// Design Name: 
// Module Name: multfu
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

enum logic [1:0] {
    IDLE,
    CALC,
    DONE
} states;

module multfu(
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
    output busy
);
    // ROB stuff
    reg[7:0] robidin, wbsin, flagsin;
    // Values
    reg[7:0] a, b;
    reg[1:0] state;
    reg[2:0] counter;
    reg[7:0] result;

    initial state = IDLE;
    initial counter = 0;
    initial result = 0;

    wire output_busy;
    wire compute_busy;

    assign busy = output_busy | compute_busy;
    assign compute_busy = state != IDLE;

    always @(posedge clk) begin
        // Locking
        if (state == IDLE && input_transmit) begin
            a <= depvals[0];
            b <= depvals[1];
            state <= CALC;
            counter <= 0;
            result <= 0;

            robidin <= robid;
            wbsin <= wbs;
            flagsin <= flags;
        end
        
        if (state == CALC) begin
            // Suboptimal but good enough for now
            result <= result + ((a << counter) & {8{b[counter]}});
            counter <= counter + 1;
            if (counter == 3'd7) begin
                state <= DONE;
            end
        end
        if (state == DONE) begin
            state <= IDLE;
        end
    end

    fuoutput fuoutput_inst(
        .clk(clk),
        .rst(rst),
        .input_transmit(state == DONE),
        .cdb_write_en(~flagsin[7]),
        .wbs(wbsin),
        .flags(flagsin),
        .robid(robidin),
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
        .busy(output_busy)
    );
endmodule
