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
    parameter FU_COUNT = 7,
    parameter RS_DEPTH = 4
)(
    input clk,
    input rst,
    
    // SWITCH INPUT
    input [15:0] sw,

    // LED PORT
    output reg[7:0] led
);

    // ============================================================================
    // ALL SIGNAL DECLARATIONS
    // ============================================================================
    
    // ROM STAGE SIGNALS
    reg halt;
    reg[5:0] pc;
    reg[3:0] robid;
    wire[15:0] irom_instr;
    reg[15:0] decoder_instr;
    reg stall_fetching;
    reg stall_decoding;
    reg[3:0] decoder_robid;
    
    // DECODER STAGE SIGNALS
    wire[1:0][3:0] decoder_reads;
    wire[1:0] decoder_read_ena;
    wire[3:0] decoder_writes;
    wire decoder_write_ena;
    wire[4:0] decoder_flags;
    wire[3:0] decoder_fuid;
    wire decoder_halt;
    
    // RENAMING STAGE SIGNALS
    reg[1:0][3:0] renamer_reads;
    reg[1:0] renamer_read_ena;
    reg[3:0] renamer_writes;
    reg renamer_write_ena;
    reg[4:0] renamer_flags;
    reg[3:0] renamer_fuid;
    reg[7:0] renamer_operand;
    reg[3:0] renamer_robid;
    wire[1:0][3:0] renamed_reads;
    wire[1:0] renamed_read_ena;
    wire[7:0] renamed_wbs;
    reg stall_renaming;
    
    // ISSUING STAGE SIGNALS
    reg[1:0][3:0] issuer_reads;
    reg[1:0] issuer_read_ena;
    reg[7:0] issuer_wbs;
    reg[7:0] issuer_flags;
    reg[7:0] issuer_operand;
    reg[3:0] issuer_fuid;
    reg[3:0] issuer_robid;
    reg issue_instr;
    wire[7:0] fu_operands [FU_COUNT];
    wire[7:0] fu_wbs [FU_COUNT];
    wire[7:0] fu_flags [FU_COUNT];
    wire[3:0] fu_robids [FU_COUNT];
    wire[1:0][7:0] fu_depvals [FU_COUNT];
    wire[FU_COUNT-1:0] fu_issuing;
    wire[FU_COUNT-1:0] fus_busy;
    wire issuer_stall;
    wire prf_requesting;
    wire[3:0] prf_requested_id;
    
    // FU OUTPUT SIGNALS
    wire[3:0] fu_robids_out [FU_COUNT];
    wire[7:0] fu_flags_out [FU_COUNT];
    wire[7:0] fu_wbs_out [FU_COUNT];
    wire[7:0] fu_value_out [FU_COUNT];
    wire fu_rob_transmit [FU_COUNT+1];
    wire fu_cdb_transmit [FU_COUNT+1];
    wire[3:0] fu_cdb_id [FU_COUNT];
    wire[7:0] fu_cdb_val [FU_COUNT];
    reg final_rob_transmit;
    reg[3:0] final_robids_out;
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
    
    // Shared CDB signals (final arbitrated output)
    wire shared_cdb_transmit;
    wire[3:0] shared_cdb_id;
    wire[7:0] shared_cdb_val;
    
    // ROB STAGE SIGNALS
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
    
    // PRF SIGNALS
    wire[15:0] prf_ready_regs;
    wire prf_cdb_transmit;
    wire[3:0] prf_cdb_id;
    wire[7:0] prf_cdb_val;
    
    // ============================================================================
    // MODULE INSTANTIATIONS AND LOGIC
    // ============================================================================
    
    // ROM STAGE
    
    rom irom(pc, irom_instr);
    
    always @(posedge clk) begin
        if ((!stall_fetching | branch_transmit) & !halt & !issuer_stall) begin
            stall_fetching <= 0;

            if (!branch_transmit) begin
                robid <= robid+1;
            end else begin
                robid <= robid-1;
            end

            if (branch_transmit) begin
                pc <= branch_not_taken ? pc-1 : new_pc;
            end else begin
                pc <= pc+1;
            end

            stall_decoding <= stall_fetching;
            decoder_instr <= irom_instr;
            decoder_robid <= robid;
        end

        if (halt) begin
            decoder_instr <= 0;
        end
    end
    
    // DECODER STAGE
    
    initial halt = 0;
    
    decoder instrdecoder(
        .instr(decoder_instr),
        .readregs(decoder_reads),
        .read_ena(decoder_read_ena),
        .writereg(decoder_writes),
        .write_ena(decoder_write_ena),
        .flagouts(decoder_flags),
        .fuid(decoder_fuid),
        .halt(decoder_halt)
    );
    
    always @(posedge clk) begin
        if (!stall_decoding & !halt & !issuer_stall) begin
            renamer_reads <= decoder_reads;
            renamer_read_ena <= decoder_read_ena;
            renamer_writes <= decoder_writes;
            renamer_write_ena <= decoder_write_ena;
            renamer_flags <= decoder_flags;
            renamer_fuid <= decoder_fuid;
            renamer_operand <= decoder_instr[15:8];  // MAKE SURE THIS IS THE RIGHT WORD
            renamer_robid <= decoder_robid;

            if (decoder_flags[0]) begin
                stall_fetching <= 1; // probably a multiple drivers violation
                stall_decoding <= 1;
            end

            if (decoder_halt) begin
                halt <= 1;
            end
        end

        if (halt) begin
            renamer_reads <= 0;
            renamer_read_ena <= 0;
            renamer_writes <= 0;
            renamer_write_ena <= 0;
            renamer_flags <= 0;
            renamer_fuid <= 0;
            renamer_operand <= 0;
        end
    end
    
    // RENAMING STAGE
    
    //assign retire_in = retire_id;
    //assign retire_ena_in = retire_transmit;

    renamer renamer_instance(
        .clk(clk),
        .rst(rst),
        .read1in(renamer_reads[0]),
        .read2in(renamer_reads[1]),
        .read_ena_in(renamer_read_ena),
        .writein(renamer_writes),
        .write_ena_in(renamer_write_ena),
        .ena(!stall_renaming & !issuer_stall),
        .retirein(retire_id),
        .retire_ena_in(retire_transmit),
        .read1out(renamed_reads[0]),
        .read2out(renamed_reads[1]),
        .read_ena_out(renamed_read_ena),
        .wbsout(renamed_wbs)
    );
    
    always @(posedge clk) begin
        issue_instr <= !stall_renaming & !issuer_stall & !stall_renaming;
        
        if (!issuer_stall) begin
            stall_renaming <= stall_decoding;

            if (!stall_renaming) begin
                issuer_reads <= renamed_reads;
                issuer_read_ena <= renamed_read_ena;
                issuer_wbs <= renamed_wbs;
                issuer_flags <= renamer_flags;
                issuer_fuid <= renamer_fuid;
                issuer_operand <= renamer_operand;
                issuer_robid <= renamer_robid;
            end
        end
    end
    
    // ISSUING STAGE

    issuer #(
        .FU_COUNT(FU_COUNT),
        .RS_DEPTH(RS_DEPTH)
    ) issuer_instance(
        .clk(clk),
        .rst(rst),
        .readyregs(prf_ready_regs),
        .readregs(issuer_reads),
        .read_ena(issuer_read_ena),
        .flags(issuer_flags),
        .wbs(issuer_wbs),
        .operand(issuer_operand),
        .robid(issuer_robid),
        .fuid(issuer_fuid),
        .fus_busy(fus_busy),
        .issue_instr(issue_instr),
        .cdbval(shared_cdb_val),
        .cdbid(shared_cdb_id),
        .cdbtransmit(shared_cdb_transmit),
        .stall(issuer_stall),
        .fu_operands(fu_operands),
        .fu_wbs(fu_wbs),
        .fu_flags(fu_flags),
        .fu_robids(fu_robids),
        .fu_depvals(fu_depvals),
        .fu_issuing(fu_issuing),
        .prf_requesting(prf_requesting),
        .prf_id(prf_requested_id)
    );


    // FUS

    // Initialize CDB chain - first FU gets PRF CDB output
    assign fu_cdb_transmit[0] = prf_cdb_transmit;
    assign fu_rob_transmit[0] = 1'b0;

    alufu alufu_instance(
        .clk(clk),
        .rst(rst),
        .input_transmit(fu_issuing[0]),
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
        .input_transmit(fu_issuing[1]),
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
        .input_transmit(fu_issuing[2]),
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
        .input_transmit(fu_issuing[3]),
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
        .input_transmit(fu_issuing[4]),
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
        .input_transmit(fu_issuing[5]),
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

    ramfu ramfu_instance(
        .clk(clk),
        .rst(rst),
        .input_transmit(fu_issuing[6]),
        .operand(fu_operands[6]),
        .depvals(fu_depvals[6]),
        .wbs(fu_wbs[6]),
        .flags(fu_flags[6]),
        .robid(fu_robids[6]),
        .cdb_transmit(fu_cdb_transmit[6]),
        .cdb_transmit_out(fu_cdb_transmit[7]),
        .cdb_id(fu_cdb_id[6]),
        .cdb_val(fu_cdb_val[6]),
        .rob_transmit(fu_rob_transmit[6]),
        .rob_transmit_out(fu_rob_transmit[7]),
        .robid_out(fu_robids_out[6]),
        .flags_out(fu_flags_out[6]),
        .wbs_out(fu_wbs_out[6]),
        .value_out(fu_value_out[6]),
        .busy(fus_busy[6]),
        .sw(sw),
        .led(led)
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
            final_cdb_transmit |= fu_cdb_transmit[i+1];
            final_cdb_id |= fu_cdb_id[i];
            final_cdb_val |= fu_cdb_val[i];
            final_rob_transmit |= fu_rob_transmit[i+1];
        end
    end
    
    assign shared_cdb_transmit = prf_cdb_transmit | final_cdb_transmit;
    assign shared_cdb_id = prf_cdb_transmit ? prf_cdb_id : final_cdb_id;
    assign shared_cdb_val = prf_cdb_transmit ? prf_cdb_val : final_cdb_val;

    always @(posedge clk) begin
        rob_transmit <= final_rob_transmit;
        rob_flags <= final_flags_out;
        rob_wbs <= final_wbs_out;
        rob_value <= final_value_out;
        rob_id <= final_robids_out;
    end


    // ROB STAGE

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
        .new_pc_out(rob_new_pc),
        .branch_not_taken(rob_branch_not_taken),
        .retire_transmit(rob_retire_transmit),
        .retire_id(rob_retire_id)
    );

    always @(posedge clk) begin
        prf_wb_val <= rob_prf_value;
        prf_wb_id <= rob_prf_id;
        prf_old_wb <= retire_id;
        prf_wb_ena <= rob_prf_transmit;
        new_pc <= rob_new_pc;
        branch_transmit <= rob_branch_transmit;
        branch_not_taken <= rob_branch_not_taken;
        retire_transmit <= rob_retire_transmit;
        retire_id <= rob_retire_id;
    end

    // PRF STUFF

    prf prf_instance(
        .clk(clk),
        .rst(rst),
        .shared_cdb_transmit(shared_cdb_transmit),
        .shared_cdb_id(shared_cdb_id),
        .shared_cdb_val(shared_cdb_val),
        .requested_id(prf_requested_id),
        .requesting(prf_requesting),
        .retire_ena(retire_transmit),
        .old_wb(retire_id),
        .ready_regs(prf_ready_regs),
        .cdb_transmit(prf_cdb_transmit),
        .cdb_id(prf_cdb_id),
        .cdb_val(prf_cdb_val)
    );

    // RESET STUFF

    always @(posedge clk) begin
        if (rst) begin
            halt <= 0;
            pc <= 0;
            robid <= 0;
            decoder_instr <= 0;
            stall_fetching <= 0;
            stall_decoding <= 0;
            renamer_reads <= 0;
            renamer_read_ena <= 0;
            renamer_writes <= 0;
            renamer_write_ena <= 0;
            renamer_flags <= 0;
            renamer_fuid <= 0;
            renamer_operand <= 0;
            stall_renaming <= 0;
            issue_instr <= 0;
            prf_wb_val <= 0;
            prf_wb_id <= 0;
            prf_old_wb <= 0;
            prf_wb_ena <= 0;
            new_pc <= 0;
            branch_transmit <= 0;
            branch_not_taken <= 0;
            retire_transmit <= 0;
            retire_id <= 0;
            rob_transmit <= 0;
            rob_flags <= 0;
            rob_wbs <= 0;
            rob_value <= 0;
            rob_id <= 0;
        end
    end
endmodule
