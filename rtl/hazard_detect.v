module hazard_detect (
    input wire [31:0] i_id_inst,

    input wire i_ex_rf_wen,
    input wire [31:0] i_ex_inst,

    input wire i_mem_rf_wen,
    input wire [31:0] i_mem_inst,

    output wire o_hazard
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

    assign id_rs1 = i_id_inst[19:15];
    assign id_rs2 = i_id_inst[24:20];

    assign ex_rd = i_ex_inst[11:7];
    assign mem_rd = i_mem_inst[11:7];

    assign hazard_ex = i_ex_rf_wen && (ex_rd != 5'd0) && ((id_uses_rs1 && (id_rs1 == ex_rd)) || (id_uses_rs2 && (id_rs2 == ex_rd)));
    assign hazard_mem = i_mem_rf_wen && (mem_rd != 5'd0) && ((id_uses_rs1 && (id_rs1 == mem_rd)) || (id_uses_rs2 && (id_rs2 == mem_rd)));

    assign o_hazard = hazard_ex || hazard_mem;

endmodule