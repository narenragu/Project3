`default_nettype none

module reg_ex_mem (
    input wire i_clk, i_rst,
    input wire ex_valid,
    input wire [31:0] ex_pc,
    input wire [31:0] ex_inst,
    input wire ex_dmem_ren,
    input wire ex_dmem_wen,
    input wire [1:0] ex_rd_wsel,
    input wire ex_rf_wen,
    input wire ex_halt, 
    input wire ex_trap,
    input wire [31:0] ex_alu_result,
    input wire [31:0] ex_rs1_data,
    input wire [31:0] ex_rs2_data,
    input wire [31:0] ex_next_pc,

    output reg mem_valid,
    output reg [31:0] mem_pc,
    output reg [31:0] mem_inst,
    output reg mem_dmem_ren,
    output reg mem_dmem_wen,
    output reg [1:0] mem_rd_wsel,
    output reg mem_rf_wen,
    output reg mem_halt,
    output reg mem_trap,
    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_rs1_data,
    output reg [31:0] mem_rs2_data,
    output reg [31:0] mem_next_pc
);
    always @ (posedge i_clk) begin
        if (i_rst) begin
            mem_valid <= 0;
            mem_pc <= 0;
            mem_inst <= 0;
            mem_dmem_ren <= 0;
            mem_dmem_wen <= 0;
            mem_rd_wsel <= 0;
            mem_rf_wen <= 0;
            mem_halt <= 0;
            mem_trap <= 0;
            mem_alu_result <= 0;
            mem_rs1_data <= 0;
            mem_rs2_data <= 0;
            mem_next_pc <= 0;
        end else begin
            mem_valid <= ex_valid;
            mem_pc <= ex_pc;
            mem_inst <= ex_inst;
            mem_dmem_ren <= ex_dmem_ren;
            mem_dmem_wen <= ex_dmem_wen;
            mem_rd_wsel <= ex_rd_wsel;
            mem_rf_wen <= ex_rf_wen;
            mem_halt <= ex_halt;
            mem_trap <= ex_trap;
            mem_alu_result <= ex_alu_result;
            mem_rs1_data <= ex_rs1_data;
            mem_rs2_data <= ex_rs2_data;
            mem_next_pc <= ex_next_pc;
        end
    end
endmodule

`default_nettype wire