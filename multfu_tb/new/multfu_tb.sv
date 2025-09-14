`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2025 05:45:13 PM
// Design Name: 
// Module Name: multfu_tb
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


module multfu_tb();
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

    multfu dut (
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

    task apply_and_check;
        input [1:0][7:0] vals;
        input [7:0] wb_val;
        input [3:0] rob_id_val;
        input [7:0] expected_result;
        begin
            @(posedge clk);
            wait(busy == 0);

            // Send instruction
            input_transmit = 1;
            depvals = vals;
            wbs = wb_val;
            robid = rob_id_val;
            flags = 0; // multfu doesn't use flags
            operand = 0; // multfu doesn't use operand
            @(posedge clk);
            input_transmit = 0;
            
            $display("Sent instruction at time %t", $time);

            // FU should be busy for multiple cycles
            if (busy !== 1) $display("MULT test failed: FU did not become busy.");
            
            wait(cdb_transmit_out == 1);
            $display("FU finished computation at time %t", $time);


            // Check result
            if (value_out !== expected_result) begin
                $display("MULT test failed. Vals: %d * %d. Expected %d, got %d", vals[0], vals[1], expected_result, value_out);
            end else begin
                $display("MULT test passed. Vals: %d * %d = %d", vals[0], vals[1], value_out);
            end

            wait(busy == 0);
        end
    endtask

    initial begin
        $dumpfile("multfu_tb.vcd");
        $dumpvars(0, multfu_tb);

        reset_dut();

        apply_and_check({8'd5, 8'd10}, 8'hB1, 4'h1, 8'd50);
        apply_and_check({8'd7, 8'd8}, 8'hB2, 4'h2, 8'd56);
        apply_and_check({8'd25, 8'd10}, 8'hB3, 4'h3, 8'd250);
        apply_and_check({8'd1, 8'd1}, 8'hB4, 4'h4, 8'd1);

        $finish;
    end

endmodule
