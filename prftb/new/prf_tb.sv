`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/07/2025 12:28:29 PM
// Design Name: 
// Module Name: prf_tb
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


module prf_tb();

    // Parameters
    localparam PRF_SIZE = 16;

    // Signals
    reg clk;
    reg rst;
    reg [3:0] requested_id;
    reg requesting;
    reg [7:0] wb_val;
    reg [3:0] wb_id;
    reg [3:0] old_wb;
    reg wb_ena;

    wire [PRF_SIZE-1:0] ready_regs;
    wire cdb_transmit;
    wire [3:0] cdb_id;
    wire [7:0] cdb_val;

    // Instantiate the PRF
    prf #(
        .PRF_SIZE(PRF_SIZE)
    ) uut (
        .clk(clk),
        .rst(rst),
        .requested_id(requested_id),
        .requesting(requesting),
        .wb_val(wb_val),
        .wb_id(wb_id),
        .old_wb(old_wb),
        .wb_ena(wb_ena),
        .ready_regs(ready_regs),
        .cdb_transmit(cdb_transmit),
        .cdb_id(cdb_id),
        .cdb_val(cdb_val)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        requested_id = 0;
        requesting = 0;
        wb_val = 0;
        wb_id = 0;
        old_wb = 0;
        wb_ena = 0;

        // Reset the DUT
        #10;
        rst = 0;
        #10;

        // Write to PRF
        wb_ena = 1;
        wb_id = 1;
        old_wb = 0; // Not retiring anything important yet
        wb_val = 8'hA5;
        #10;
        
        wb_id = 2;
        wb_val = 8'hB6;
        #10;

        wb_id = 3;
        wb_val = 8'hC7;
        #10;
        wb_ena = 0;
        
        #10;

        // Request a value
        requesting = 1;
        requested_id = 1;
        #10;
        
        if (cdb_val === 8'hA5)
            $display("Test 1 PASSED: Read value %h", cdb_val);
        else
            $display("Test 1 FAILED: Expected %h, got %h", 8'hA5, cdb_val);

        requested_id = 2;
        #10;
        
        if (cdb_val === 8'hB6)
            $display("Test 2 PASSED: Read value %h", cdb_val);
        else
            $display("Test 2 FAILED: Expected %h, got %h", 8'hB6, cdb_val);
            
        requested_id = 3;
        #10;

        if (cdb_val === 8'hC7)
            $display("Test 3 PASSED: Read value %h", cdb_val);
        else
            $display("Test 3 FAILED: Expected %h, got %h", 8'hC7, cdb_val);
            
        requesting = 0;

        #20;

        // Retire a register and write a new value
        wb_ena = 1;
        wb_id = 4;
        old_wb = 1; // Retire physical register 1
        wb_val = 8'hD8;
        #10;
        wb_ena = 0;

        #10;

        $display("Simulation finished");
        $finish;
    end

endmodule
