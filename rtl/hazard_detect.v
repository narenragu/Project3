module hazard_detect (
    input wire i_id_valid,
    input wire [31:0] i_id_inst,
    input wire i_id_branch,
    input wire i_id_jal,
    input wire i_id_jalr,

    input wire i_ex_valid,
    input wire i_ex_rf_wen,
    input wire [31:0] i_ex_inst,
    input wire i_ex_branch,
    input wire i_ex_jal,
    input wire i_ex_jalr,

    input wire i_mem_rf_wen,
    input wire [31:0] i_mem_inst,

    input wire [1:0] i_pc_sel,

    output wire o_data_stall,
    output wire o_control_wait,
    output wire o_pc_stall
);

    wire [4:0] id_rs1;
    wire [4:0] id_rs2;
    wire [4:0] ex_rd;
    wire [4:0] mem_rd;

    wire [6:0] id_opcode;
    wire id_uses_rs1;
    wire id_uses_rs2;

    assign id_opcode = i_id_inst[6:0];

    assign id_uses_rs1 =
        (id_opcode == 7'b0110011) || // R-type ALU
        (id_opcode == 7'b0010011) || // Immediate ALU
        (id_opcode == 7'b0000011) || // Load
        (id_opcode == 7'b0100011) || // Store
        (id_opcode == 7'b1100011) || // Branch
        (id_opcode == 7'b1100111); // JALR

    assign id_uses_rs2 =
        (id_opcode == 7'b0110011) || // R-type ALU
        (id_opcode == 7'b0100011) || // Store
        (id_opcode == 7'b1100011); // Branch

    wire hazard_ex;
    wire hazard_mem;
    wire raw_hazard;

    wire id_control;
    wire ex_control_pending;
    wire ex_redirect;

    assign id_rs1 = i_id_inst[19:15];
    assign id_rs2 = i_id_inst[24:20];

    assign ex_rd = i_ex_inst[11:7];
    assign mem_rd = i_mem_inst[11:7];

    assign hazard_ex = i_ex_rf_wen && (ex_rd != 5'd0) && ((id_uses_rs1 && (id_rs1 == ex_rd)) || (id_uses_rs2 && (id_rs2 == ex_rd)));
    assign hazard_mem = i_mem_rf_wen && (mem_rd != 5'd0) && ((id_uses_rs1 && (id_rs1 == mem_rd)) || (id_uses_rs2 && (id_rs2 == mem_rd)));

    assign raw_hazard = hazard_ex || hazard_mem;

    //stall/flush control
    assign o_data_stall = i_id_valid && raw_hazard;                                 //keep instruction in ID stage if there is a raw hazard
    assign id_control = i_id_valid && (i_id_branch || i_id_jal || i_id_jalr);       //if the instruction in ID stage is a control instruction
    assign ex_control_pending = i_ex_valid && (i_ex_branch || i_ex_jal || i_ex_jalr);
    assign o_control_wait = id_control || ex_control_pending;                       //prevent younger instructions from proceeding to ID while a control instruction is pending
    assign ex_redirect = i_pc_sel == 2'b01 || i_pc_sel == 2'b10;                    //allow pc to be redirected for taken branch or jump instructions
    assign o_pc_stall = (o_data_stall || o_control_wait) && !ex_redirect;           //stall PC if there is a data hazard or control instruction is pending and no redirect is happening

endmodule