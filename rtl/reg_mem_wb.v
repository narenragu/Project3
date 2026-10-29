`default_nettype none

module reg_mem_wb (
    input wire i_clk, i_rst,
    input wire mem_valid,
    input wire [31:0] mem_pc,
    input wire [31:0] mem_inst,
    input wire [31:0] mem_next_pc,
    input wire [1:0] mem_rd_wsel,
    input wire mem_rf_wen,
    input wire mem_halt,
    input wire mem_trap,
    input wire [31:0] mem_alu_result,
    input wire [31:0] mem_load_data,
    input wire [31:0] mem_rs1_data,
    input wire [31:0] mem_rs2_data,

    output reg wb_valid,
    output reg [31:0] wb_pc,
    output reg [31:0] wb_inst,
    output reg [31:0] wb_next_pc,
    output reg [1:0]  wb_rd_wsel,
    output reg wb_rf_wen,
    output reg wb_halt,
    output reg wb_trap,
    output reg [31:0] wb_alu_result,
    output reg [31:0] wb_load_data,
    output reg [31:0] wb_rs1_data,
    output reg [31:0] wb_rs2_data
);

    always @(posedge i_clk) begin
        if (i_rst) begin
            wb_valid <= 0;
            wb_pc <= 0;
            wb_inst <= 0;
            wb_next_pc <= 0;
            wb_rd_wsel <= 0;
            wb_rf_wen <= 0;
            wb_halt <= 0;
            wb_trap <= 0;
            wb_alu_result <= 0;
            wb_load_data <= 0;
            wb_rs1_data <= 0;
            wb_rs2_data <= 0;
        end else begin
            wb_valid <= mem_valid;
            wb_pc <= mem_pc;
            wb_inst <= mem_inst;
            wb_next_pc <= mem_next_pc;
            wb_rd_wsel <= mem_rd_wsel;
            wb_rf_wen <= mem_rf_wen;
            wb_halt <= mem_halt;
            wb_trap <= mem_trap;
            wb_alu_result <= mem_alu_result;
            wb_load_data <= mem_load_data;
            wb_rs1_data <= mem_rs1_data;
            wb_rs2_data <= mem_rs2_data;
        end
    end

endmodule

`default_nettype wire