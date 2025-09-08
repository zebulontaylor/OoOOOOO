`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/07/2025 06:42:00 PM
// Design Name: 
// Module Name: alufu_tb
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


module alufu_tb();
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

    alufu dut (
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
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);
    endtask

    task apply_op;
        input [7:0] op;
        input [1:0][7:0] vals;
        input [7:0] wb_val;
        input [7:0] flag_val;
        input [3:0] rob_id_val;
        begin
            input_transmit = 1;
            operand = op;
            depvals = vals;
            wbs = wb_val;
            flags = flag_val;
            robid = rob_id_val;
        end
    endtask

    initial begin
        $dumpfile("alufu_tb.vcd");
        $dumpvars(0, alufu_tb);

        reset_dut();

        // Test case 1: ADD
        @(posedge clk);
        apply_op(8'h04, {8'd10, 8'd20}, 8'hA1, 8'hF0, 4'h1);
        #1;
        if (value_out !== 30) $display("ADD failed");
        @(posedge clk);
        input_transmit = 0;

        // Test case 2: SUB
        @(posedge clk);
        apply_op(8'h14, {8'd20, 8'd10}, 8'hA2, 8'hF1, 4'h2);
        #1;
        if (value_out !== 10) $display("SUB failed");
        @(posedge clk);
        input_transmit = 0;

        // Test case 3: AND
        @(posedge clk);
        apply_op(8'h24, {8'hF0, 8'h0F}, 8'hA3, 8'hF2, 4'h3);
        #1;
        if (value_out !== 8'h00) $display("AND failed");
        @(posedge clk);
        input_transmit = 0;
        
        // Test case 4: OR
        @(posedge clk);
        apply_op(8'h34, {8'hF0, 8'h0F}, 8'hA4, 8'hF3, 4'h4);
        #1;
        if (value_out !== 8'hFF) $display("OR failed");
        @(posedge clk);
        input_transmit = 0;

        // Test stall
        @(posedge clk);
        rob_transmit = 1;
        cdb_transmit = 1;
        apply_op(8'h04, {8'd5, 8'd6}, 8'hA5, 8'hF4, 4'h5);
        @(posedge clk);
        input_transmit = 0;
        rob_transmit = 0;
        cdb_transmit = 0;
        #1;
        if (value_out !== 11) $display("Stall test failed");
        @(posedge clk);
        @(posedge clk);


        // Test case 5: Back-to-back operations
        $display("Starting back-to-back test");
        @(posedge clk);
        // First operation
        apply_op(8'h04, {8'd1, 8'd2}, 8'hA6, 8'hF5, 4'h6); // ADD 1+2=3
        #1;
        if (value_out !== 3) $display("Back-to-back test (ADD) failed. Expected 3, got %d", value_out);

        @(posedge clk);
        // Second operation, immediately on the next cycle
        apply_op(8'h14, {8'd10, 8'd5}, 8'hA7, 8'hF6, 4'h7); // SUB 10-5=5
        #1;
        if (value_out !== 5) $display("Back-to-back test (SUB) failed. Expected 5, got %d", value_out);
        
        @(posedge clk);
        input_transmit = 0;
        @(posedge clk);
        
        $finish;
    end

endmodule
