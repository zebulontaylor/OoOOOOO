`timescale 1ns / 1ps

module tb_rs;

    // Testbench signals
    reg clk;
    reg rst;

    // DUT Inputs
    reg [7:0] operandin;
    reg [7:0] wbsin;
    reg [7:0] flagin;
    reg [7:0] robidin;
    reg [7:0] depinval;
    reg [1:0][3:0] depidsin;
    reg [3:0] depins;
    reg fuclaimed;
    reg camtransmit;

    // DUT Outputs
    wire [7:0] operandout;
    wire [7:0] wbsout;
    wire [1:0][7:0] depvalsout;
    wire [7:0] flagout;
    wire [7:0] robidout;
    wire futransmitout;
    wire fuclaimedout;
    wire camtransmitout;

    // Instantiate the Device Under Test (DUT)
    rs dut (
        .clk(clk),
        .rst(rst),
        .operandin(operandin),
        .wbsin(wbsin),
        .flagin(flagin),
        .robidin(robidin),
        .operandout(operandout),
        .wbsout(wbsout),
        .depvalsout(depvalsout),
        .flagout(flagout),
        .robidout(robidout),
        .depidsin(depidsin),
        .depins(depins),
        .depinval(depinval),
        .fuclaimed(fuclaimed),
        .futransmitout(futransmitout),
        .fuclaimedout(fuclaimedout),
        .camtransmit(camtransmit),
        .camtransmitout(camtransmitout)
    );

    // Clock generator
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period, 100MHz clock
    end

    // Test sequence
    initial begin
        $display("--------------------------------------------------");
        $display("Starting Testbench for Reservation Station (rs)");
        $display("--------------------------------------------------");

        // 1. Initialization and Reset Test
        initialize_signals();
        apply_reset();
        
        // 2. Test Case 1: Simple Load, Snoop, and Release
        $display("\n[TC1] Start: Simple Load, Snoop, and Release");
        
        // Setup instruction data to be dispatched
        operandin = 8'hAA;
        wbsin     = 8'hBB;
        flagin      = 8'h10;
        robidin   = 8'h01;
        depidsin[0] = 4'h3; // Depends on tag 3
        depidsin[1] = 4'h7; // Depends on tag 7
        
        // Dispatch the instruction using camtransmit
        @(posedge clk);
        camtransmit = 1;
        $display("[%t] Asserting camtransmit to load instruction.", $time);
        
        @(posedge clk);
        camtransmit = 0;
        // Check if camtransmitout was de-asserted, indicating a successful lock
        if (camtransmitout === 1'b0) begin
            $display("[%t] SUCCESS: RS locked the instruction (camtransmitout is low).", $time);
        end else begin
            $error("[%t] FAILURE: RS did not lock the instruction.", $time);
        end
        
        // Simulate CDB broadcast for the first dependency
        @(posedge clk);
        depins = 4'h3;
        depinval = 8'hC3; // Value corresponding to tag 3
        $display("[%t] Broadcasting dependency tag 4'h3 with value 8'h%h.", $time, depinval);

        // Simulate CDB broadcast for a non-matching dependency
        @(posedge clk);
        depins = 4'h5;
        depinval = 8'hFF;
        $display("[%t] Broadcasting non-matching tag 4'h5.", $time);

        // Simulate CDB broadcast for the second dependency
        @(posedge clk);
        depins = 4'h7;
        depinval = 8'hD7; // Value corresponding to tag 7
        $display("[%t] Broadcasting dependency tag 4'h7 with value 8'h%h.", $time, depinval);
        
        @(posedge clk);
        // At this point, all dependencies are met. RS should request the FU.
        depins = 4'h0; // Clear the dependency bus
        
        if (futransmitout === 1'b1) begin
             $display("[%t] SUCCESS: RS is ready and transmitting to FU (futransmitout is high).", $time);
        end else begin
            $error("[%t] FAILURE: RS did not transmit after dependencies were met.", $time);
        end
        
        // Check the output data on the next cycle
        @(posedge clk);
        if (futransmitout === 1'b0 && operandout === 8'hAA && wbsout === 8'hBB && robidout === 8'h01) begin
            $display("[%t] SUCCESS: RS released and outputs are correct.", $time);
        end else begin
            $error("[%t] FAILURE: RS outputs are incorrect after release. futransmitout=%b, operandout=%h", $time, futransmitout, operandout);
        end
        $display("[TC1] End");


        // 3. Test Case 2: FU Bus is claimed (arbitration test)
        apply_reset();
        $display("\n[TC2] Start: FU Bus Claimed Test");

        // Load the same instruction as before
        // Setup instruction data to be dispatched
        operandin = 8'hAA;
        wbsin     = 8'hBB;
        flagin      = 8'h10;
        robidin   = 8'h01;
        depidsin[0] = 4'h3; // Depends on tag 3
        depidsin[1] = 4'h7; // Depends on tag 7;

        camtransmit = 1;
        @(posedge clk);
        camtransmit = 0;

        // Clear instruction data after load
        operandin = 8'h00;
        wbsin     = 8'h00;
        flagin      = 8'h00;
        robidin   = 8'h00;
        depidsin[0] = 4'h0;
        depidsin[1] = 4'h0;

        // Provide both dependencies at once
        @(posedge clk);
        fuclaimed = 1; // Simulate another RS has claimed the bus
        $display("[%t] Asserting fuclaimed to block the bus.", $time);
        
        // Satisfy first dependency
        depins = 4'h3;
        depinval = 8'hC3;
        
        @(posedge clk);
        // Satisfy second dependency
        depins = 4'h7;
        depinval = 8'hD7;

        @(posedge clk);
        depins = 4'h0;
        // The RS is ready, but should not transmit because fuclaimed is high
        if (futransmitout === 1'b0) begin
            $display("[%t] SUCCESS: RS is waiting because FU bus is claimed.", $time);
        end else begin
            $error("[%t] FAILURE: RS transmitted even though FU bus was claimed.", $time);
        end
        
        // Release the FU bus
        @(posedge clk);
        fuclaimed = 0;
        $display("[%t] De-asserting fuclaimed to free the bus.", $time);

        // Now the RS should transmit on the next cycle
        @(posedge clk);
        if (futransmitout === 1'b1) begin
            $display("[%t] SUCCESS: RS transmitted after FU bus was freed.", $time);
        end else begin
            $error("[%t] FAILURE: RS did not transmit after FU bus was freed.", $time);
        end
        $display("[TC2] End");

        // End simulation
        $display("\n--------------------------------------------------");
        $display("All test cases finished.");
        $display("--------------------------------------------------");
        $finish;
    end

    // Task to initialize all input signals to a known state
    task initialize_signals;
        operandin = 8'h0;
        wbsin     = 8'h0;
        flagin      = 8'h0;
        robidin   = 8'h0;
        depinval = 8'h0;
        depidsin  = 8'h0;
        depins    = 4'h0;
        fuclaimed  = 1'b0;
        camtransmit = 1'b0;
    endtask

    // Task to apply reset to the DUT
    task apply_reset;
        $display("[%t] Applying reset...", $time);
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        initialize_signals(); // Reset inputs after reset pulse
        $display("[%t] Reset released.", $time);
    endtask

endmodule