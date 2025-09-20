`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/20/2025 11:20:49 AM
// Design Name: 
// Module Name: bcdoutput
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


module bcdoutput (
        input clk,
        input rst,
        
        input [16:0] sw,
        
        output [7:0] led,
        
        output reg[6:0] seg,
        output reg dp,
        output reg[3:0] an
    );

    wire [7:0] bin;

    assign led = sw[7:0];

    cpu cpu_inst(
        .clk(clk),
        .rst(rst),
        .sw(sw),
        .led(bin)
    );

    wire [11:0] bcd;

    bin2bcd bin2bcd_inst(
        .bin(bin),
        .bcd(bcd)
    );

    reg [18:0] refresh_cnt;

    always @(posedge clk) begin
        if (rst) begin
            refresh_cnt <= '0;
        end else begin
            refresh_cnt <= refresh_cnt + 1'b1;
        end
    end

    wire [1:0] digit_sel = refresh_cnt[18:17];
    reg  [3:0] cur_nibble;

    always @* begin
        an = 4'b1111;
        dp = 1'b1;
        cur_nibble = 4'hF;

        case (digit_sel)
            2'd0: begin an = 4'b1110; cur_nibble = bcd[3:0];   end // ones
            2'd1: begin an = 4'b1101; cur_nibble = bcd[7:4];   end // tens
            2'd2: begin an = 4'b1011; cur_nibble = bcd[11:8];  end // hundreds
            2'd3: begin an = 4'b0111; cur_nibble = 4'hF;       end
        endcase

        case (cur_nibble)
            4'h0   : seg = 7'b1000000;
            4'h1   : seg = 7'b1111001;
            4'h2   : seg = 7'b0100100;
            4'h3   : seg = 7'b0110000;
            4'h4   : seg = 7'b0011001;
            4'h5   : seg = 7'b0010010;
            4'h6   : seg = 7'b0000010;
            4'h7   : seg = 7'b1111000;
            4'h8   : seg = 7'b0000000;
            4'h9   : seg = 7'b0011000;
            default: seg = 7'b1111111;
        endcase
    end

endmodule
