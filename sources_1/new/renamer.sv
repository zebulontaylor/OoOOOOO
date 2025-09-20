`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2025 11:03:33 AM
// Design Name: 
// Module Name: renamer
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


// From stackoverflow
module highbit #(
    parameter OUT_WIDTH = 4, // out uses one extra bit for not-found
    parameter IN_WIDTH = 1<<(OUT_WIDTH)
) (
    input [IN_WIDTH-1:0]in,
    output [OUT_WIDTH-1:0]out
);

wire [OUT_WIDTH-1:0]out_stage[0:IN_WIDTH];
assign out_stage[0] = 0;
generate genvar i;
    for(i=0; i<IN_WIDTH; i=i+1)
        assign out_stage[i+1] = ~in[i] ? i : out_stage[i]; 
endgenerate
assign out = out_stage[IN_WIDTH];

endmodule
// Endfrom


module renamer(
    input[3:0] read1in,
    input[3:0] read2in,
    input[1:0] read_ena_in,
    input[3:0] writein,
    input write_ena_in,
    input[3:0] retirein,
    input retire_ena_in,
    output reg[3:0] read1out,
    output reg[3:0] read2out,
    output reg[1:0] read_ena_out,
    output reg[7:0] wbsout,
    output stall,
    output full,
    input clk,
    input rst,
    input ena
);
    
    reg[3:0] regtable [7:0];
    reg[3:0] next_write;
    reg[15:0] claimed;
    
    always @(posedge clk) begin
        if (rst) begin
            claimed <= 16'h00FF;
            for (int i = 0; i < 8; i++) begin
                regtable[i] <= i;
            end
        end else if (write_ena_in && ena && !(&claimed)) begin
            claimed[next_write] <= 1;
            regtable[writein[3:0]] <= next_write;
        end
        if (retire_ena_in) begin
            claimed[retirein] <= 0;
        end

        claimed[0] <= 1;
    end
    
    always @(*) begin
        read_ena_out = read_ena_in;
        if (read_ena_in[0]) begin
            read1out = regtable[read1in[3:0]];
        end else begin
            read1out = 0;
        end
        
        if (read_ena_in[1]) begin
            read2out = regtable[read2in[3:0]];
        end else begin
            read2out = 0;
        end
    end
    
    highbit openbit (claimed, next_write);
    
    always @(*) begin
        if (write_ena_in && !(&claimed)) begin
            wbsout = {regtable[writein[3:0]], next_write};
        end else begin
            wbsout = 0;
        end
    end

    // Free list empty indicator
    assign full = &claimed;
    // Stall when all physical registers are claimed (free list empty) AND a write is requested
    assign stall = full & write_ena_in;
    
endmodule
