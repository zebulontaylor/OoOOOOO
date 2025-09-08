`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/06/2025 05:30:10 PM
// Design Name: 
// Module Name: issuer_tb
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


module issuer_tb;

    // Parameters
    localparam FU_COUNT = 8;
    localparam RS_DEPTH = 4;

    // Inputs
    reg clk;
    reg rst;
    reg [15:0] readyregs;
    reg [1:0][4:0] readregs;
    reg [7:0] flags;
    reg [7:0] wbs;
    reg [7:0] operand;
    reg [7:0] robid;
    reg [$clog2(FU_COUNT)-1:0] fuid;
    reg [7:0] cdbval;
    reg [3:0] cdbid;
    reg cdbtransmit;
    reg [FU_COUNT-1:0] fus_busy;
    reg issue_instr;

    // Outputs
    wire stall;
    wire [7:0] fu_operands [FU_COUNT];
    wire [7:0] fu_wbs [FU_COUNT];
    wire [7:0] fu_flags [FU_COUNT];
    wire [7:0] fu_robids [FU_COUNT];
    wire [1:0][7:0] fu_depvals [FU_COUNT];

    // Instantiate the issuer
    issuer #(.FU_COUNT(FU_COUNT), .RS_DEPTH(RS_DEPTH)) uut (
        .clk(clk),
        .rst(rst),
        .readyregs(readyregs),
        .readregs(readregs),
        .flags(flags),
        .wbs(wbs),
        .operand(operand),
        .robid(robid),
        .fuid(fuid),
        .cdbval(cdbval),
        .cdbid(cdbid),
        .cdbtransmit(cdbtransmit),
        .stall(stall),
        .fu_operands(fu_operands),
        .fu_wbs(fu_wbs),
        .fu_flags(fu_flags),
        .fu_robids(fu_robids),
        .fu_depvals(fu_depvals),
        .fus_busy(fus_busy),
        .issue_instr(issue_instr)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;
        readyregs = 0;
        readregs = 0;
        flags = 0;
        wbs = 0;
        operand = 0;
        robid = 0;
        fuid = 0;
        cdbval = 0;
        cdbid = 0;
        cdbtransmit = 0;
        fus_busy = 0;
        issue_instr = 0;

        // Reset
        #10 rst = 0;

        // Test case 1: Simple issue
        #10;
        readyregs = 16'h0000;
        readregs = '{5'b00011, 5'b00101}; // Read from phys regs 1 and 2
        operand = 8'h01;
        robid = 8'h01;
        fuid = 3'h0;
        issue_instr = 1;
        #10;
        issue_instr = 0;
        $display("T=%0t: Issue instr to FU 0. FU operands: %h", $time, fu_operands[0]);

        // Test case 2: Wait for CDB
        #10;
        readregs = '{5'b00011, 5'b00101}; // Read from phys regs 1 and 2
        robid = 8'h02;
        fuid = 3'h1;
        issue_instr = 1;
        #10;
        issue_instr = 0;
        $display("T=%0t: Issue instr to FU 1, waiting for regs 1 and 2. FU operands: %h", $time, fu_operands[1]);

        #10;
        // Broadcast value for reg 1
        cdbtransmit = 1;
        cdbid = 4'h1;
        cdbval = 8'hAA;
        $display("T=%0t: CDB broadcast for reg 1. FU operands: %h, depvals: %h", $time, fu_operands[1], fu_depvals[1]);
        
        #5;
        cdbtransmit = 0;
        #5;

        // Broadcast value for reg 2
        cdbtransmit = 1;
        cdbid = 4'h2;
        cdbval = 8'hBB;
        $display("T=%0t: CDB broadcast for reg 2. FU operands: %h, depvals: %h", $time, fu_operands[1], fu_depvals[1]);

        #50;

        // Test case 3: Stall logic
        $display("T=%0t: --- Starting Stall Logic Test ---", $time);
        
        // Setup: Fill reservation stations for FU 0.
        // To prevent RS from clearing, we make the FU busy.
        fus_busy = 8'b00000001; // FU 0 is busy
        fuid = 3'h0;
        readregs = '{5'h0, 5'h0}; // Not waiting on any regs
        cdbval = 8'h0;
        cdbid = 4'h0;
        cdbtransmit = 1;

        for (int i = 0; i < RS_DEPTH; i = i + 1) begin
            robid = 8'h10 + i;
            operand = 8'h10 + i;
            issue_instr = 1;
            #10; // 1 clock cycle
            issue_instr = 0;
            $display("T=%0t: Issued setup instruction %d to FU 0 (robid=%h)", $time, i, robid);
        end
        
        #10;
        
        // Attempt to issue one more instruction, which should stall.
        robid = 8'h20;
        operand = 8'h20;
        issue_instr = 1;
        $display("T=%0t: Attempting to issue to full RS queue for FU 0 (robid=%h). Expecting stall.", $time, robid);
        
        #2; // Let signals propagate
        if (stall) begin
            $display("T=%0t: Stall signal is HIGH, as expected.", $time);
        end else begin
            $display("T=%0t: ERROR: Stall signal is LOW, but was expected to be HIGH.", $time);
            //$finish;
        end

        // Hold issue_instr high. Stall should remain high.
        #20;
        if (stall) begin
            $display("T=%0t: Stall signal remains HIGH while issue_instr is held, as expected.", $time);
        end else begin
            $display("T=%0t: ERROR: Stall signal went LOW prematurely.", $time);
            //$finish;
        end
        
        // Now, make the FU available. One instruction should issue from RS, freeing a slot.
        // The stalled instruction should then be accepted, and stall should go low.
        $display("T=%0t: Setting fus_busy[0] to 0 to free up FU.", $time);
        fus_busy = 8'b00000000;
        
        #10; // Wait one clock cycle for stall to resolve
        if (!stall) begin
            $display("T=%0t: Stall signal is LOW, as expected.", $time);
        end else begin
            $display("T=%0t: ERROR: Stall signal remains HIGH, but was expected to be LOW.", $time);
            //$finish;
        end
        
        issue_instr = 0;
        
        #100;
        $finish;
    end

endmodule
