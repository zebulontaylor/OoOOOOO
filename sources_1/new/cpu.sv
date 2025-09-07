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


module cpu(
    input clk,
    input rst
);
    // ROM STAGE
    reg[5:0] pc;
    reg[3:0] robid;
    
    wire[15:0] irom_instr;
    
    reg[15:0] decoder_instr;
    
    rom irom(pc, irom_instr);
    
    always @(posedge clk) begin
        decoder_instr <= irom_instr;
        pc <= pc+1;
        robid <= robid+1;
    end
    
    // DECODER STAGE
    
    wire[1:0][4:0] reads;
    wire[4:0] writes;
    wire[4:0] flags;
    wire[3:0] fuid;
    
    reg[1:0][4:0] renamer_reads;
    reg[4:0] renamer_writes;
    reg[4:0] renamer_flags;
    reg[3:0] renamer_fuid;
    reg[7:0] renamer_operand;
    
    decoder instrdecoder(
        .instr(decoder_instr),
        .readregs(reads),
        .writereg(writes),
        .flagouts(flags),
        .fuid(fuid)
    );
    
    always @(posedge clk) begin
        renamer_reads <= reads;
        renamer_writes <= writes;
        renamer_flags <= flags;
        renamer_fuid <= fuid;
        renamer_operand <= decoder_instr[7:0];  // MAKE SURE THIS IS THE RIGHT WORD
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
        issuer_reads <= renamed_reads;
        issuer_wbs <= renamed_wbs;
        issuer_flags <= renamer_flags;
        issuer_fuid <= renamer_fuid;
        issuer_operand <= renamer_operand;
    end
    
    // ISSUING STAGE
    
    issuer issuer_instance(
        .clk(clk),
        .rst(rst),
        .readyregs(16'b0),  // ADD THIS WHEN PRF READY
        .readregs(issuer_reads),
        .flags(issuer_flags),
        .wbs(issuer_wbs),
        .operand(issuer_operand)
    );
endmodule
