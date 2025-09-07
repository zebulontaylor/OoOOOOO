`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/06/2025 05:30:32 PM
// Design Name: 
// Module Name: renamer_tb
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


module renamer_tb;

    // Parameters

    // Inputs
    reg [3:0] read1in;
    reg [3:0] read2in;
    reg [3:0] writein;
    reg [4:0] retirein;
    reg clk;
    reg rst;

    // Outputs
    wire [4:0] read1out;
    wire [4:0] read2out;
    wire [3:0] writeout;
    wire [3:0] oldwrite;

    // Instantiate the renamer
    renamer uut (
        .read1in(read1in),
        .read2in(read2in),
        .writein(writein),
        .retirein(retirein),
        .read1out(read1out),
        .read2out(read2out),
        .writeout(writeout),
        .oldwrite(oldwrite),
        .clk(clk),
        .rst(rst)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;
        read1in = 0;
        read2in = 0;
        writein = 0;
        retirein = 0;

        // Reset
        #10 rst = 0;

        #10;
        // Test case 1: Write to reg 1
        writein = 4'b0011; // Write to arch reg 1 (addr=1, valid=1)
        #10;
        $display("T=%0t: Write to arch reg 1, new phys reg %d, old phys reg %d", $time, writeout, oldwrite);
        writein = 4'b0;

        #10;
        // Test case 2: Read from reg 1
        read1in = 4'b0011; // Read from arch reg 1 (addr=1, valid=1)
        #10;
        $display("T=%0t: Read from arch reg 1, got phys reg %d", $time, read1out);
        read1in = 4'b0;
        
        #10;
        // Test case 3: Write to reg 2
        writein = 4'b0101; // Write to arch reg 2 (addr=2, valid=1)
        #10;
        $display("T=%0t: Write to arch reg 2, new phys reg %d, old phys reg %d", $time, writeout, oldwrite);
        writein = 4'b0;
        
        #10;
        // Test case 4: Read from reg 1 and 2
        read1in = 4'b0011; // Read from arch reg 1 (addr=1, valid=1)
        read2in = 4'b0101; // Read from arch reg 2 (addr=2, valid=1)
        #10;
        $display("T=%0t: Read arch regs 1 & 2, got phys regs %d & %d", $time, read1out, read2out);
        read1in = 4'b0;
        read2in = 4'b0;
        
        #10;
        // Test case 5: Write to reg 1 again
        writein = 4'b0011; // Write to arch reg 1 (addr=1, valid=1)
        #10;
        $display("T=%0t: Write to arch reg 1 again, new phys reg %d, old phys reg %d", $time, writeout, oldwrite);
        writein = 4'b0;

        #10;
        // Test case 6: Read from reg 1
        read1in = 4'b0011; // Read from arch reg 1 (addr=1, valid=1)
        #10;
        $display("T=%0t: Read from arch reg 1, got phys reg %d", $time, read1out);
        read1in = 4'b0;

        #10;
        // Test case 7: Retire the physical register from the first write to reg 1
        // The first write to arch reg 1 was mapped to phys reg 0.
        retirein = 5'b00001; // Retire phys reg 0 (addr=0, valid=1)
        #10;
        $display("T=%0t: Retiring physical register 0", $time);
        retirein = 5'b0;
        
        #10;
        $finish;
    end

endmodule
