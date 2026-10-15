`default_nettype none

//Instruction Decoder and Control Unit
module control (
    input wire [31:0] i_instr,      //INSTRUCTION from inst memory
    input wire i_alu_eq,            //comparison results from ALU for branch decisions
    input wire i_alu_slt,           //slt is already signed/unsigned from the ALU
    output wire [5:0] o_format,     //one-hot encoded format for imm generator
    output wire [1:0] o_op1_sel,    //ALU op1 select: 0 = rs1, 1 = pc(auipc), 2 = zero(lui)
    output wire o_op2_sel,          //ALU op2 select: 0 = rs2, 1 = imm
    output wire [2:0] o_alu_opsel,  //ALU operation select
    output wire o_alu_sub,          //ALU controls
    output wire o_alu_arith,
    output wire o_alu_unsigned,
    output wire o_rf_wen,           //register file write enable
    output wire [1:0] o_rd_wsel,    //register file write select: 0 = ALU result, 1 = data mem load, 2 = PC+4(jal/jalr)
    output wire o_dmem_ren,         //data memory read enable
    output wire o_dmem_wen,         //data memory write enable
    output wire [1:0] o_pc_sel,     //PC next select: 0 = PC+4, 1 = PC+imm, 2 = jalr target
    output wire o_halt,             //halt signal from ebreak inst
    output wire o_illegal           //illegal instruction signal to feed trap out of processor
);

    //////////////////////////////////////////////////DECODER/////////////////////////////////////////////////////////
    //Extract fields from the instruction
    wire [6:0] opcode = i_instr[6:0];
    wire [2:0] funct3 = i_instr[14:12];
    wire [6:0] funct7 = i_instr[31:25];

    //decode opcode
    wire opcode_r       = (opcode == 7'b0110011); // R-type
    wire opcode_i_alu   = (opcode == 7'b0010011); // I-type ALU operation
    wire opcode_i_load  = (opcode == 7'b0000011); // I-type load
    wire opcode_i_jalr  = (opcode == 7'b1100111); // I-type jalr
    wire opcode_s       = (opcode == 7'b0100011); // S-type
    wire opcode_b       = (opcode == 7'b1100011); // B-type
    wire opcode_u_lui   = (opcode == 7'b0110111); // U-type LUI
    wire opcode_u_auipc = (opcode == 7'b0010111); // U-type AUIPC
    wire opcode_j       = (opcode == 7'b1101111); // J-type jal
    wire opcode_system  = (opcode == 7'b1110011); // ebreak

    //legality check
    wire funct7_zero = (funct7 == 7'b0000000);
    wire funct7_alt = (funct7 == 7'b0100000); //for sub/sra/srai 

    //funct7 is 0 unless sub and sra which use funct7_alt
    wire r_legal = funct7_zero | (funct7_alt & ((funct3 == 3'b000) | (funct3 == 3'b101)));
    //slli needs funct7=0 and srli/srai need zero and alt respectively; otherwise don't care(use immediate)
    wire i_alu_legal = (funct3 == 3'b001) ? funct7_zero : 
                        (funct3 == 3'b101) ? (funct7_zero | funct7_alt) :
                        1'b1;
    wire i_load_legal = (funct3 != 3'b011) & (funct3 != 3'b110) & (funct3 != 3'b111);
    wire i_jalr_legal = (funct3 == 3'b000);
    wire s_legal = (funct3 == 3'b000) | (funct3 == 3'b001) | (funct3 == 3'b010);
    wire b_legal = (funct3 != 3'b010) & (funct3 != 3'b011);
    wire system_legal = (funct3 == 3'b000);
    
    wire legal = (opcode_r & r_legal) |
                 (opcode_i_alu & i_alu_legal) |
                 (opcode_i_load & i_load_legal) |
                 (opcode_i_jalr & i_jalr_legal) |
                 (opcode_s & s_legal) |
                 (opcode_b & b_legal) |
                 (opcode_system & system_legal) |
                 opcode_u_lui |
                 opcode_u_auipc |
                 opcode_j;

    assign o_illegal = ~legal;

    ////////////////////////////////////////////DATAPATH CONTROLS///////////////////////////////////////////////////
    //format for immediate generator
    assign o_format[0] = opcode_r;
    assign o_format[1] = opcode_i_alu | opcode_i_load | opcode_i_jalr;
    assign o_format[2] = opcode_s;
    assign o_format[3] = opcode_b;
    assign o_format[4] = opcode_u_lui | opcode_u_auipc;
    assign o_format[5] = opcode_j;

    //ALU operand selection
    assign o_op1_sel = opcode_u_auipc ? 2'b01 :
                       opcode_u_lui   ? 2'b10 :
                       2'b00;
    assign o_op2_sel = (opcode_r | opcode_b) ? 1'b0 : 1'b1;     //only R-type and B-type use rs2

    //ALU opsel and control signals
    assign o_alu_opsel = (opcode_r | opcode_i_alu) ? funct3 : 3'b000;   //every other instruction beside R and I_imm use add operation
    assign o_alu_sub = (opcode_r & funct7[5]);                          //must ONLY be asserted for R-type sub inst, since other instructions w negative immediates must still add
    assign o_alu_arith = funct7[5];                                     //no need for gating, since it is irrelavent for other instruction types
    assign o_alu_unsigned = opcode_b ? funct3[1] : funct3[0];           //only operations that use this are: branches(bltu,bgeu) use unsigned comparison, r/i-type set-less-than-unsigned; signal ignored for all other operations
    
    //register write
    assign o_rf_wen = (opcode_r | opcode_i_alu | opcode_i_load | opcode_i_jalr | opcode_u_lui | opcode_u_auipc | opcode_j) & legal;
    assign o_rd_wsel = opcode_i_load ? 2'b01 :
                       (opcode_j | opcode_i_jalr) ? 2'b10 :
                       2'b00;

    //data memory
    assign o_dmem_wen = opcode_s & legal;  //only S-type instructions write to data memory
    assign o_dmem_ren = opcode_i_load & legal;  //only I-type load instructions read from data memory

    //BRANCH / NEXT PC
    //in b-type instruction, funct3 determines the type of branch
    //branches are split into BEQ, BLT, BLTU, and their inverses (BNE, BGE, BGEU)
    //the unsigned comparison decision for the ALU is already determined by o_alu_unsigned
    //therefore the comparison can be chosen simply from funct3[2](0 = equality, 1 = less than), and funct3[0] to invert
    wire branch_cond_met = opcode_b & legal & 
                            ((funct3[2] ? i_alu_slt : i_alu_eq) ^ funct3[0]);

    assign o_pc_sel = !legal ? 2'b00 :
                       opcode_i_jalr ? 2'b10 :   // JALR instruction
                       (opcode_j | branch_cond_met) ? 2'b01 :  //PC+imm
                       2'b00;  //PC+4 for all other cases

    assign o_halt = opcode_system & legal;
endmodule

`default_nettype wire