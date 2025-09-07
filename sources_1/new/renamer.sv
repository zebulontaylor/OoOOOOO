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
    input[3:0] writein,
    input[4:0] retirein,
    output reg[4:0] read1out,
    output reg[4:0] read2out,
    output reg[3:0] writeout,
    output reg[3:0] oldwrite,
    input clk,
    input rst
    );
    
    reg[3:0] regtable [7:0];
    reg[3:0] next_write;
    reg[15:0] claimed;
    
    always @(*) begin
        if (rst) begin
            claimed <= 0;
            foreach (regtable[i]) begin
                regtable[i] <= i;
            end
            oldwrite <= 0;
            writeout <= 0;
        end
    end
    
    always @(*) begin
        if (read1in[0])
            read1out <= {regtable[read1in[3:1]], 1'b1};
        else
            read1out <= 0;
        if (read2in[0])
            read2out <= {regtable[read2in[3:1]], 1'b1};
        else
            read2out <= 0;
    end
    
    highbit openbit (claimed, next_write);
    
    always @(*) begin
        oldwrite <= regtable[writein[3:1]];
        writeout <= next_write;
    end
    
    always @(posedge clk) begin
        // Write logic
        if (writein[0]) begin
            claimed[next_write] <= 1;
            regtable[writein[3:1]] <= next_write;
        end
        
        // Retire logic
        if (retirein[0]) begin
            claimed[retirein[4:1]] <= 0;
        end
    end
endmodule
