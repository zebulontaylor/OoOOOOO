`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2025 11:03:33 AM
// Design Name: 
// Module Name: issuer
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


/*
This needs to
- Take in an instr
- Output a stall signal
- Request the ready regs
- Instantiate and link and communicate with RS's
*/
module issuer #(
    parameter FU_COUNT = 8,
    parameter RS_DEPTH = 4
)(
    input clk,
    input rst,
    
    input[15:0] readyregs,
    
    input[1:0][3:0] readregs,
    input[1:0] read_ena,
    input[7:0] flags,
    input[7:0] wbs,
    input[7:0] operand,
    input[3:0] robid,
    input[$clog2(FU_COUNT)-1:0] fuid,
    input[FU_COUNT-1:0] fus_busy,
    
    input issue_instr,
    
    input[7:0] cdbval,
    input[3:0] cdbid,
    input cdbtransmit,
    
    output stall,
    
    output logic [7:0] fu_operands [FU_COUNT],
    output logic [7:0] fu_wbs [FU_COUNT],
    output logic [7:0] fu_flags [FU_COUNT],
    output logic [3:0] fu_robids [FU_COUNT],
    output logic [1:0][7:0] fu_depvals [FU_COUNT],  
    output logic [FU_COUNT-1:0] fu_issuing,

    output logic prf_requesting,
    output logic [3:0] prf_id
);
    
    wire[RS_DEPTH:0][FU_COUNT-1:0] fubus_claimed;
    wire[FU_COUNT-1:0][RS_DEPTH:0] camtransmit;
    
    wire [7:0] operandouts [FU_COUNT][RS_DEPTH];
    wire [7:0] wbsouts     [FU_COUNT][RS_DEPTH];
    wire [7:0] flagouts    [FU_COUNT][RS_DEPTH];
    wire [3:0] robidouts   [FU_COUNT][RS_DEPTH];
    
    wire [1:0][7:0] depvalsouts [FU_COUNT][RS_DEPTH];
    wire rs_full_signals [FU_COUNT][RS_DEPTH];

    reg[1:0] deps_pending_request;
    reg[1:0][3:0] deps_pending_id;

    reg stall_for_rs;
    reg stall_for_deps;

    reg instr_waiting;

    assign stall = stall_for_rs | stall_for_deps;

    always @(posedge clk) begin
        if (rst) begin
            deps_pending_request <= 0;
        end

        if ((issue_instr | instr_waiting) & !stall_for_deps) begin
            instr_waiting = 0;
            deps_pending_request <= {
                read_ena[1] && (readyregs[readregs[1]] | cdbid == readregs[1]),
                read_ena[0] && (readyregs[readregs[0]] | cdbid == readregs[0])
            };
            deps_pending_id <= {
                readregs[1],
                readregs[0]
            };
        end

        prf_requesting = 0;
        prf_id = 0;
        if (deps_pending_request[0]) begin
            instr_waiting = issue_instr | instr_waiting;
            deps_pending_request[0] <= 0;
            prf_requesting = 1;
            prf_id = deps_pending_id[0];
        end else if (deps_pending_request[1]) begin
            instr_waiting = issue_instr | instr_waiting;
            deps_pending_request[1] <= 0;
            prf_requesting = 1;
            prf_id = deps_pending_id[1];
        end
    end
    
    assign fubus_claimed[0] = fus_busy;

    always_comb begin
        for (int i = 0; i < FU_COUNT; i++) begin
            fu_operands[i] = '0;
            fu_wbs[i]      = '0;
            fu_flags[i]    = '0;
            fu_robids[i]   = '0;
            fu_depvals[i]  = '{default: '0};
            
            for (int j = 0; j < RS_DEPTH; j++) begin
                fu_operands[i] |= operandouts[i][j];
                fu_wbs[i]      |= wbsouts[i][j];
                fu_flags[i]    |= flagouts[i][j];
                fu_robids[i]   |= robidouts[i][j];
                fu_depvals[i][0] |= depvalsouts[i][j][0];
                fu_depvals[i][1] |= depvalsouts[i][j][1];
            end
        end
    end
    
    genvar i;
    genvar j;
    for (j = 0; j < FU_COUNT; j += 1) begin
        for (i = 0; i < RS_DEPTH; i += 1) begin
            rs station(
                .clk(clk),
                .rst(rst),
                .operandin(operand),
                .wbsin(wbs),
                .flagin(flags),
                .robidin(robid),
                // dep ids in
                .depidsin({readregs[0][3:0], readregs[1][3:0]}),
                // cdb ins
                .depins(cdbid),
                // cdb in val
                .depinval(cdbval),
                // buses
                .camtransmit(camtransmit[j][i]),
                .camtransmitout(camtransmit[j][i+1]),
                .fuclaimed(fubus_claimed[i][j]),
                .fuclaimedout(fubus_claimed[i+1][j]),
                // outputs
                .operandout(operandouts[j][i]),
                .wbsout(wbsouts[j][i]),
                .flagout(flagouts[j][i]),
                .robidout(robidouts[j][i]),
                .depvalsout(depvalsouts[j][i]),
                .rs_full(rs_full_signals[j][i])
            );
        end
    end
    
    genvar l;
    for (l = 0; l < FU_COUNT; l += 1) begin
        assign camtransmit[l][0] = (l == fuid) && issue_instr;
    end


    always_comb begin
        fu_issuing = rst ? 0 : fubus_claimed[RS_DEPTH] & ~fubus_claimed[0];  // TODO: tidy this

        stall_for_rs = issue_instr;
        for (integer k=0; k<FU_COUNT; k+=1) begin
            if (k == fuid && issue_instr) begin
                for (integer j=0; j<RS_DEPTH; j+=1) begin
                    if (!rs_full_signals[k][j]) begin
                        stall_for_rs = 0;
                    end
                end
            end
        end

        stall_for_deps = |deps_pending_request;
    end


endmodule
