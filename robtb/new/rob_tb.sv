`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/07/2025 04:27:08 PM
// Design Name: 
// Module Name: rob_tb
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


module rob_tb();

    // Inputs
    reg clk;
    reg rst;
    reg rob_transmit;
    reg [3:0] robid;
    reg [7:0] flags;
    reg [7:0] wbs;
    reg [7:0] value;

    // Outputs
    wire prf_transmit;
    wire [3:0] prf_id;
    wire [7:0] prf_value;
    wire branch_transmit;
    wire [7:0] new_pc;
    wire retire_transmit;
    wire [3:0] retire_id;

    // Instantiate the Unit Under Test (UUT)
    rob uut (
        .clk(clk), 
        .rst(rst), 
        .rob_transmit(rob_transmit), 
        .robid(robid), 
        .flags(flags), 
        .wbs(wbs), 
        .value(value), 
        .prf_transmit(prf_transmit), 
        .prf_id(prf_id), 
        .prf_value(prf_value), 
        .branch_transmit(branch_transmit), 
        .new_pc(new_pc), 
        .retire_transmit(retire_transmit), 
        .retire_id(retire_id)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        // Initialize Inputs
        rst = 1;
        rob_transmit = 0;
        robid = 0;
        flags = 0;
        wbs = 0;
        value = 0;

        // Reset
        #10;
        rst = 0;
        #10;

        // Send instructions to ROB. Some are out of order.
        // Note: flags[7] is WB, flags[5] is Branch

        // Instruction with robid = 0 (WB) - First instruction
        rob_transmit = 1;
        robid = 0;
        flags = 8'b10000000; // WB enabled
        wbs = 8'hA0; // retire_id=A, prf_id=0
        value = 8'h0A;
        #10;

        // Instruction with robid = 2 (WB)
        robid = 2;
        flags = 8'b10000000; // WB enabled
        wbs = 8'hC2; // retire_id=C, prf_id=2
        value = 8'h22;
        #10;

        // Instruction with robid = 3 (WB)
        robid = 3;
        flags = 8'b10000000; // WB enabled
        wbs = 8'hD3; // retire_id=D, prf_id=3
        value = 8'h33;
        #10;
        
        // Instruction with robid = 1 (Branch)
        robid = 1;
        flags = 8'b00100000; // Branch
        wbs = 8'hB1; // Should be ignored
        value = 8'hBC;
        #10;
        
        rob_transmit = 0;

        // ROB now has entries for robid 0, 1, 2, 3.
        // Execution finished out of order, but they should retire in order.
        // Expected retirement order: 0, 1, 2, 3

        // Wait for all instructions to retire
        #100;
        
        $finish;
    end

endmodule
