`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2025 11:03:33 AM
// Design Name: 
// Module Name: cpu
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


module cpu #(
    parameter FU_COUNT = 8,
    parameter RS_DEPTH = 4
)(
    input clk,
    input rst
);
    // ROM STAGE
    reg halt;
    reg[5:0] pc;
    reg[3:0] robid;
    
    wire[15:0] irom_instr;
    
    reg[15:0] decoder_instr;

    reg stall_fetching;
    reg stall_decoding;
    
    rom irom(pc, irom_instr);
    
    always @(posedge clk) begin
        if ((!stall_fetching | branch_transmit) & !halt) begin
            stall_fetching <= 0;
            robid <= robid+1;

            if (branch_transmit & !branch_not_taken) begin
                pc <= new_pc;
            end else begin
                pc <= pc+1;
            end

            stall_decoding <= stall_fetching;
            decoder_instr <= irom_instr;
        end

        if (halt) begin
            decoder_instr <= 0;
        end
    end
    
    // DECODER STAGE
    
    wire[1:0][4:0] decoder_reads;
    wire[4:0] decoder_writes;
    wire[4:0] decoder_flags;
    wire[3:0] decoder_fuid;
    wire decoder_halt;

    initial halt = 0;

    reg[1:0][4:0] renamer_reads;
    reg[4:0] renamer_writes;
    reg[4:0] renamer_flags;
    reg[3:0] renamer_fuid;
    reg[7:0] renamer_operand;
    reg stall_renaming;
    
    decoder instrdecoder(
        .instr(decoder_instr),
        .readregs(decoder_reads),
        .writereg(decoder_writes),
        .flagouts(decoder_flags),
        .fuid(decoder_fuid),
        .halt(decoder_halt)
    );
    
    always @(posedge clk) begin
        if (!stall_decoding & !halt) begin
            renamer_reads <= decoder_reads;
            renamer_writes <= decoder_writes;
            renamer_flags <= decoder_flags;
            renamer_fuid <= decoder_fuid;
            renamer_operand <= decoder_instr[7:0];  // MAKE SURE THIS IS THE RIGHT WORD

            stall_renaming <= stall_decoding;

            if (decoder_flags[0]) begin
                stall_fetching <= 1;
                stall_decoding <= 1;
            end

            if (decoder_halt) begin
                halt <= 1;
            end
        end

        if (halt) begin
            renamer_reads <= 0;
            renamer_writes <= 0;
            renamer_flags <= 0;
            renamer_fuid <= 0;
            renamer_operand <= 0;
        end
    end
    
    // RENAMING STAGE
    
    wire[4:0] retire_in;
    wire[1:0][4:0] renamed_reads;
    wire[7:0] renamed_wbs;
    
    reg[1:0][4:0] issuer_reads;
    reg[7:0] issuer_wbs;
    reg[7:0] issuer_flags;
    reg[7:0] issuer_operand;
    reg[3:0] issuer_fuid;
    reg issue_instr;
    
    renamer renamer_instance(
        .clk(clk),
        .rst(rst),
        .read1in(renamer_reads[0][3:0]),
        .read2in(renamer_reads[1][3:0]),
        .writein(renamer_writes[3:0]),
        .retirein(retire_in),
        .read1out(renamed_reads[0]),
        .read2out(renamed_reads[1]),
        .writeout(renamed_wbs[3:0]),
        .oldwrite(renamed_wbs[7:4])
    );
    
    always @(posedge clk) begin
        issue_instr <= !stall_renaming;

        if (!stall_renaming) begin
            issuer_reads <= renamed_reads;
            issuer_wbs <= renamed_wbs;
            issuer_flags <= renamer_flags;
            issuer_fuid <= renamer_fuid;
            issuer_operand <= renamer_operand;
        end
    end
    
    // ISSUING STAGE
    
    wire[7:0] fu_operands [FU_COUNT];
    wire[7:0] fu_wbs [FU_COUNT];
    wire[7:0] fu_flags [FU_COUNT];
    wire[7:0] fu_robids [FU_COUNT];
    wire[1:0][7:0] fu_depvals [FU_COUNT];
    
    wire[FU_COUNT-1:0] fus_busy;
    wire issuer_stall;
    wire prf_requesting;
    wire[3:0] prf_requested_id;

    issuer issuer_instance(
        .clk(clk),
        .rst(rst),
        .readyregs(prf_ready_regs),
        .readregs(issuer_reads),
        .flags(issuer_flags),
        .wbs(issuer_wbs),
        .operand(issuer_operand),
        .robid(issuer_robid),
        .fuid(issuer_fuid),
        .fus_busy(fus_busy),
        .issue_instr(issue_instr),
        .cdbval(prf_cdb_val),
        .cdbid(prf_cdb_id),
        .cdbtransmit(prf_cdb_transmit),
        .stall(issuer_stall),
        .fu_operands(fu_operands),
        .fu_wbs(fu_wbs),
        .fu_flags(fu_flags),
        .fu_robids(fu_robids),
        .fu_depvals(fu_depvals),
        .prf_requesting(prf_requesting),
        .prf_id(prf_requested_id)
    );


    // FUS

    wire[7:0] fu_robids_out [FU_COUNT];
    wire[7:0] fu_flags_out [FU_COUNT];
    wire[7:0] fu_wbs_out [FU_COUNT];
    wire[7:0] fu_value_out [FU_COUNT];
    wire fu_rob_transmit [FU_COUNT+1];
    wire fu_cdb_transmit [FU_COUNT+1];
    wire[3:0] fu_cdb_id [FU_COUNT];
    wire[7:0] fu_cdb_val [FU_COUNT];
    wire[FU_COUNT-1:0] fus_busy;

    reg final_rob_transmit;
    reg[7:0] final_robids_out;
    reg[7:0] final_flags_out;
    reg[7:0] final_wbs_out;
    reg[7:0] final_value_out;
    reg final_cdb_transmit;
    reg[3:0] final_cdb_id;
    reg[7:0] final_cdb_val;

    reg rob_transmit;
    reg[7:0] rob_flags;
    reg[7:0] rob_wbs;
    reg[7:0] rob_value;
    reg[3:0] rob_id;
    reg cdb_transmit;
    reg[3:0] cdb_id;
    reg[7:0] cdb_val;

    alufu alufu_instance(
        .clk(clk),
        .rst(rst),
        .input_transmit(issue_instr),
        .operand(fu_operands[0]),
        .depvals(fu_depvals[0]),
        .wbs(fu_wbs[0]),
        .flags(fu_flags[0]),
        .robid(fu_robids[0]),
        .cdb_transmit(fu_cdb_transmit[0]),
        .cdb_transmit_out(fu_cdb_transmit[1]),
        .cdb_id(fu_cdb_id[0]),
        .cdb_val(fu_cdb_val[0]),
        .rob_transmit(fu_rob_transmit[0]),
        .rob_transmit_out(fu_rob_transmit[1]),
        .robid_out(fu_robids_out[0]),
        .flags_out(fu_flags_out[0]),
        .wbs_out(fu_wbs_out[0]),
        .value_out(fu_value_out[0]),
        .busy(fus_busy[0])
    );

    selfu selfu_instance(
        .clk(clk),
        .rst(rst),
        .input_transmit(issue_instr),
        .operand(fu_operands[1]),
        .depvals(fu_depvals[1]),
        .wbs(fu_wbs[1]),
        .flags(fu_flags[1]),
        .robid(fu_robids[1]),
        .cdb_transmit(fu_cdb_transmit[1]),
        .cdb_transmit_out(fu_cdb_transmit[2]),
        .cdb_id(fu_cdb_id[1]),
        .cdb_val(fu_cdb_val[1]),
        .rob_transmit(fu_rob_transmit[1]),
        .rob_transmit_out(fu_rob_transmit[2]),
        .robid_out(fu_robids_out[1]),
        .flags_out(fu_flags_out[1]),
        .wbs_out(fu_wbs_out[1]),
        .value_out(fu_value_out[1]),
        .busy(fus_busy[1])
    );

    multfu multfu_instance(
        .clk(clk),
        .rst(rst),
        .input_transmit(issue_instr),
        .operand(fu_operands[2]),
        .depvals(fu_depvals[2]),
        .wbs(fu_wbs[2]),
        .flags(fu_flags[2]),
        .robid(fu_robids[2]),
        .cdb_transmit(fu_cdb_transmit[2]),
        .cdb_transmit_out(fu_cdb_transmit[3]),
        .cdb_id(fu_cdb_id[2]),
        .cdb_val(fu_cdb_val[2]),
        .rob_transmit(fu_rob_transmit[2]),
        .rob_transmit_out(fu_rob_transmit[3]),
        .robid_out(fu_robids_out[2]),
        .flags_out(fu_flags_out[2]),
        .wbs_out(fu_wbs_out[2]),
        .value_out(fu_value_out[2]),
        .busy(fus_busy[2])
    );

    hashfu hashfu_instance(
        .clk(clk),
        .rst(rst),
        .input_transmit(issue_instr),
        .operand(fu_operands[3]),
        .depvals(fu_depvals[3]),
        .wbs(fu_wbs[3]),
        .flags(fu_flags[3]),
        .robid(fu_robids[3]),
        .cdb_transmit(fu_cdb_transmit[3]),
        .cdb_transmit_out(fu_cdb_transmit[4]),
        .cdb_id(fu_cdb_id[3]),
        .cdb_val(fu_cdb_val[3]),
        .rob_transmit(fu_rob_transmit[3]),
        .rob_transmit_out(fu_rob_transmit[4]),
        .robid_out(fu_robids_out[3]),
        .flags_out(fu_flags_out[3]),
        .wbs_out(fu_wbs_out[3]),
        .value_out(fu_value_out[3]),
        .busy(fus_busy[3])
    );

    cjumpfu cjumpfu_instance(
        .clk(clk),
        .rst(rst),
        .input_transmit(issue_instr),
        .operand(fu_operands[4]),
        .depvals(fu_depvals[4]),
        .wbs(fu_wbs[4]),
        .flags(fu_flags[4]),
        .robid(fu_robids[4]),
        .cdb_transmit(fu_cdb_transmit[4]),
        .cdb_transmit_out(fu_cdb_transmit[5]),
        .cdb_id(fu_cdb_id[4]),
        .cdb_val(fu_cdb_val[4]),
        .rob_transmit(fu_rob_transmit[4]),
        .rob_transmit_out(fu_rob_transmit[5]),
        .robid_out(fu_robids_out[4]),
        .flags_out(fu_flags_out[4]),
        .wbs_out(fu_wbs_out[4]),
        .value_out(fu_value_out[4]),
        .busy(fus_busy[4])
    );

    shiftfu shiftfu_instance(
        .clk(clk),
        .rst(rst),
        .input_transmit(issue_instr),
        .operand(fu_operands[5]),
        .depvals(fu_depvals[5]),
        .wbs(fu_wbs[5]),
        .flags(fu_flags[5]),
        .robid(fu_robids[5]),
        .cdb_transmit(fu_cdb_transmit[5]),
        .cdb_transmit_out(fu_cdb_transmit[6]),
        .cdb_id(fu_cdb_id[5]),
        .cdb_val(fu_cdb_val[5]),
        .rob_transmit(fu_rob_transmit[5]),
        .rob_transmit_out(fu_rob_transmit[6]),
        .robid_out(fu_robids_out[5]),
        .flags_out(fu_flags_out[5]),
        .wbs_out(fu_wbs_out[5]),
        .value_out(fu_value_out[5]),
        .busy(fus_busy[5])
    );

    always_comb begin
        final_robids_out = '0;
        final_wbs_out      = '0;
        final_flags_out    = '0;
        final_value_out  = '0;
        final_cdb_transmit  = '0;
        final_cdb_id  = '0;
        final_cdb_val  = '0;
        final_rob_transmit  = '0;

        for (int i = 0; i < FU_COUNT; i++) begin
            final_robids_out |= fu_robids_out[i];
            final_wbs_out |= fu_wbs_out[i];
            final_flags_out |= fu_flags_out[i];
            final_value_out |= fu_value_out[i];
            final_cdb_transmit |= fu_cdb_transmit[i];
            final_cdb_id |= fu_cdb_id[i];
            final_cdb_val |= fu_cdb_val[i];
            final_rob_transmit |= fu_rob_transmit[i];
        end
    end

    always @(posedge clk) begin
        rob_transmit <= final_rob_transmit;
        rob_flags <= final_flags_out;
        rob_wbs <= final_wbs_out;
        rob_value <= final_value_out;
        rob_id <= final_robids_out;
        cdb_transmit <= final_cdb_transmit;
        cdb_id <= final_cdb_id;
        cdb_val <= final_cdb_val;
    end


    // ROB STAGE

    wire rob_prf_transmit;
    wire[3:0] rob_prf_id;
    wire[7:0] rob_prf_value;
    wire rob_branch_transmit;
    wire[7:0] rob_new_pc;
    wire rob_branch_not_taken;
    wire rob_retire_transmit;
    wire[3:0] rob_retire_id;

    reg[7:0] prf_wb_val;
    reg[3:0] prf_wb_id;
    reg[3:0] prf_old_wb;
    reg prf_wb_ena;

    reg[7:0] new_pc;
    reg branch_transmit;
    reg branch_not_taken;
    reg retire_transmit;
    reg[3:0] retire_id;

    rob rob_instance(
        .clk(clk),
        .rst(rst),
        .rob_transmit(rob_transmit),
        .robid(rob_id),
        .flags(rob_flags),
        .wbs(rob_wbs),
        .value(rob_value),
        .prf_transmit(rob_prf_transmit),
        .prf_id(rob_prf_id),
        .prf_value(rob_prf_value),
        .branch_transmit(rob_branch_transmit),
        .new_pc(rob_new_pc),
        .branch_not_taken(rob_branch_not_taken),
        .retire_transmit(rob_retire_transmit),
        .retire_id(rob_retire_id)
    );

    always @(posedge clk) begin
        prf_wb_val <= rob_prf_value;
        prf_wb_id <= rob_prf_id;
        prf_old_wb <= rob_prf_id;
        prf_wb_ena <= rob_prf_transmit;
        new_pc <= rob_new_pc;
        branch_transmit <= rob_branch_transmit;
        branch_not_taken <= rob_branch_not_taken;
        retire_transmit <= rob_retire_transmit;
        retire_id <= rob_retire_id;
    end

    // PRF STUFF

    wire[15:0] prf_ready_regs;
    wire prf_cdb_transmit;
    wire[3:0] prf_cdb_id;
    wire[7:0] prf_cdb_val;

    prf prf_instance(
        .clk(clk),
        .rst(rst),
        .requested_id(prf_requested_id),
        .requesting(prf_requesting),
        .wb_val(prf_wb_val),
        .wb_id(prf_wb_id),
        .old_wb(prf_old_wb),
        .wb_ena(prf_wb_ena),
        .ready_regs(prf_ready_regs),
        .cdb_transmit(prf_cdb_transmit),
        .cdb_id(prf_cdb_id),
        .cdb_val(prf_cdb_val)
    );
endmodule
