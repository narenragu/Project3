`default_nettype none

module reg_id_ex (
    input wire i_clk, i_rst,

    input wire id_valid,
    input wire [31:0] id_inst,
    input wire [31:0] id_pc,
    
    input wire [1:0] id_op1_sel,
    input wire id_op2_sel,
    input wire [2:0] id_alu_opsel,
    input wire id_alu_arith,
    input wire id_alu_sub,
    input wire id_alu_unsigned,
    input wire id_branch,
    input wire id_jal,
    input wire id_jalr,

    input wire id_dmem_ren,
    input wire id_dmem_wen,
    input wire [1:0] id_rd_wsel,
    input wire id_rf_wen,
    input wire id_halt,
    input wire id_illegal,

    input wire [31:0] id_immediate,
    input wire [31:0] id_rs1_rdata,
    input wire [31:0] id_rs2_rdata,

    input wire i_stall,

    output reg ex_valid,
    output reg [31:0] ex_inst,
    output reg [31:0] ex_pc,

    output reg [1:0] ex_op1_sel,
    output reg ex_op2_sel,
    output reg [2:0] ex_alu_opsel,
    output reg ex_alu_arith,
    output reg ex_alu_sub,
    output reg ex_alu_unsigned,
    output reg ex_branch,
    output reg ex_jal,
    output reg ex_jalr,

    output reg ex_dmem_ren,
    output reg ex_dmem_wen,
    output reg [1:0] ex_rd_wsel,
    output reg ex_rf_wen,
    output reg ex_halt,
    output reg ex_illegal,

    output reg [31:0] ex_immediate,
    output reg [31:0] ex_rs1_rdata,
    output reg [31:0] ex_rs2_rdata
);
    always @(posedge i_clk) begin
        if(i_rst) begin
            ex_valid <= 1'b0;
            ex_inst <= 32'b0;
            ex_pc <= 32'b0;
            ex_op1_sel <= 2'b0;
            ex_op2_sel <= 1'b0;
            ex_alu_opsel <= 3'b0;
            ex_alu_arith <= 1'b0;
            ex_alu_sub <= 1'b0;
            ex_alu_unsigned <= 1'b0;
            ex_branch <= 1'b0;
            ex_jal <= 1'b0;
            ex_jalr <= 1'b0;
            ex_dmem_ren <= 1'b0;
            ex_dmem_wen <= 1'b0;
            ex_rd_wsel <= 2'b0;
            ex_rf_wen <= 1'b0;
            ex_halt <= 1'b0;
            ex_illegal <= 1'b0;
            ex_immediate <= 32'b0;
            ex_rs1_rdata <= 32'b0;
            ex_rs2_rdata <= 32'b0;
        end else if(i_stall) begin      //hold while id waits for operands
            ex_valid <= 1'b0;
            ex_inst <= 32'h13; // addi x0, x0, 0
            ex_pc <= 32'b0;
            ex_op1_sel <= 2'b0;
            ex_op2_sel <= 1'b1; // immediate
            ex_alu_opsel <= 3'b0; // add
            ex_alu_arith <= 1'b0;
            ex_alu_sub <= 1'b0;
            ex_alu_unsigned <= 1'b0;
            ex_branch <= 1'b0;
            ex_jal <= 1'b0;
            ex_jalr <= 1'b0;
            ex_dmem_ren <= 1'b0;
            ex_dmem_wen <= 1'b0;
            ex_rd_wsel <= 2'b0;
            ex_rf_wen <= 1'b1;
            ex_halt <= 1'b0;
            ex_illegal <= 1'b0;
            ex_immediate <= 32'b0; // 0
            ex_rs1_rdata <= 32'b0; // 0
            ex_rs2_rdata <= 32'bx;
        end else begin
            ex_valid <= id_valid;
            ex_inst <= id_inst;
            ex_pc <= id_pc;
            ex_op1_sel <= id_op1_sel;
            ex_op2_sel <= id_op2_sel;
            ex_alu_opsel <= id_alu_opsel;
            ex_alu_arith <= id_alu_arith;
            ex_alu_sub <= id_alu_sub;
            ex_alu_unsigned <= id_alu_unsigned;
            ex_branch <= id_branch;
            ex_jal <= id_jal;
            ex_jalr <= id_jalr;
            ex_dmem_ren <= id_dmem_ren;
            ex_dmem_wen <= id_dmem_wen;
            ex_rd_wsel <= id_rd_wsel;
            ex_rf_wen <= id_rf_wen;
            ex_halt <= id_halt;
            ex_illegal <= id_illegal;
            ex_immediate <= id_immediate;
            ex_rs1_rdata <= id_rs1_rdata;
            ex_rs2_rdata <= id_rs2_rdata;
        end
    end

endmodule

`default_nettype wire