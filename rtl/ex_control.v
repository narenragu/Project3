`default_nettype none
//EX stage control logic
//PC Source and Trap Control Logic

//does NOT send out rf_wen and dmem control signals
//USE TRAP SIGNAL to gate all access to rf and dmem in hart probably
module ex_control (
    input wire i_valid,
    input wire [1:0] i_pc_plus_imm,
    input wire i_illegal,
    input wire i_dmem_ren,
    input wire i_dmem_wen,
    input wire [2:0] i_funct3,
    input wire i_slt,
    input wire i_eq,
    input wire [1:0] i_alu_res,
    input wire i_branch,
    input wire i_jal,
    input wire i_jalr,

    output wire [1:0] o_pc_sel,
    output wire o_trap
);
    wire data_misaligned;
    wire target_misaligned;

    assign data_misaligned = (i_dmem_ren || i_dmem_wen) &&
            (((i_funct3 == 3'b001 || i_funct3 == 3'b101) && i_alu_res[0]) ||
             ((i_funct3 == 3'b010) && (|i_alu_res[1:0])));

    //for jal and branch, check if pc+imm is word-aligned
    assign target_misaligned = ((i_jal || branch_cond_met) && (|i_pc_plus_imm)) ||
            (i_jalr && i_alu_res[1]);

    //trap must disable dmem reads/writes, rf writes, supress branch/jump redirects, and carry to wb for retire
    assign o_trap = i_illegal | data_misaligned | target_misaligned;

    //in b-type instruction, funct3 determines the type of branch
    //branches are split into BEQ, BLT, BLTU, and their inverses (BNE, BGE, BGEU)
    //the unsigned comparison decision for the ALU is already determined by o_alu_unsigned
    //therefore the comparison can be chosen simply from funct3[2](0 = equality, 1 = less than), and funct3[0] to invert
    wire branch_cond_met = i_branch && ((i_funct3[2] ? i_slt : i_eq) ^ i_funct3[0]);
    assign o_pc_sel = (!i_valid || o_trap) ? 2'b00 :
                       i_jalr ? 2'b10 :   // JALR instruction
                       (i_jal | branch_cond_met) ? 2'b01 :  //PC+imm
                       2'b00;  //PC+4 for all other cases
endmodule

`default_nettype wire