`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2025 06:15:23 PM
// Design Name: 
// Module Name: hashfu_tb
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


module hashfu_tb();
    reg clk;
    reg rst;

    reg input_transmit;
    reg[7:0] operand;
    reg[1:0][7:0] depvals;
    reg[7:0] wbs;
    reg[7:0] flags;
    reg[3:0] robid;

    reg cdb_transmit;
    wire cdb_transmit_out;
    wire[3:0] cdb_id;
    wire[7:0] cdb_val;

    reg rob_transmit;
    wire[3:0] robid_out;
    wire[7:0] flags_out;
    wire[7:0] wbs_out;
    wire[7:0] value_out;
    wire rob_transmit_out;

    wire busy;

    hashfu dut (
        .clk(clk),
        .rst(rst),
        .input_transmit(input_transmit),
        .operand(operand),
        .depvals(depvals),
        .wbs(wbs),
        .flags(flags),
        .robid(robid),
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

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task reset_dut;
        rst = 1;
        input_transmit = 0;
        operand = 0;
        depvals = 0;
        wbs = 0;
        flags = 0;
        robid = 0;
        cdb_transmit = 0;
        rob_transmit = 0;
        repeat(2) @(posedge clk);
        rst = 0;
        @(posedge clk);
    endtask

    // Function to compute expected hash value
    function [7:0] calculate_hash;
        input [7:0] val;
        begin
            calculate_hash = val;
            calculate_hash = calculate_hash ^ (calculate_hash << 3);
            calculate_hash = calculate_hash + 8'h61;
            calculate_hash = calculate_hash ^ (calculate_hash >> 5);
            calculate_hash = calculate_hash + 8'h61;
            calculate_hash = calculate_hash ^ (calculate_hash << 7);
        end
    endfunction

    task apply_and_check;
        input [7:0] val;
        input [7:0] wb_val;
        input [3:0] rob_id_val;
        begin
            reg [7:0] expected_result;
            @(posedge clk);
            wait(busy == 0);

            // Send instruction
            input_transmit = 1;
            depvals = {8'b0, val}; // hashfu only uses one depval
            wbs = wb_val;
            robid = rob_id_val;
            flags = 0;
            operand = 0;
            @(posedge clk);
            input_transmit = 0;

            wait(cdb_transmit_out == 1);
            
            expected_result = calculate_hash(val);

            // Check result
            if (value_out !== expected_result) begin
                $display("HASH test failed. Val: %h. Expected %h, got %h", val, expected_result, value_out);
            end else begin
                $display("HASH test passed. Val: %h -> %h", val, value_out);
            end

            wait(busy == 0);
        end
    endtask

    initial begin
        $dumpfile("hashfu_tb.vcd");
        $dumpvars(0, hashfu_tb);

        reset_dut();

        apply_and_check(8'h12, 8'hC1, 4'h1);
        apply_and_check(8'hA5, 8'hC2, 4'h2);
        apply_and_check(8'hFF, 8'hC3, 4'h3);
        apply_and_check(8'h00, 8'hC4, 4'h4);

        $finish;
    end

endmodule
