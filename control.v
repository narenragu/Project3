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

    //Extract fields from the instruction
    wire [6:0] opcode = i_instr[6:0];
    wire [2:0] funct3 = i_instr[14:12];
    wire [6:0] funct7 = i_instr[31:25];

endmodule
