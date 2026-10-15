// UNUSED
`default_nettype none

module dmem (
    input wire i_clk,
    input wire i_rst,
    input wire i_wen,
    input wire i_ren,
    input wire [31:0] i_address,
    input wire [3:0] i_mask,
    input wire [31:0] i_wdata,
    output wire [31:0] o_rdata
);
    reg [31:0] dmem [0:31];
    wire [4:0] idx = i_address[6:2];

    assign o_rdata = i_ren ? dmem[idx] : 32'b0;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_word
            always @(posedge i_clk) begin
                if (i_rst)
                    dmem[i] <= 32'b0;
                else if (i_wen && idx == i) begin
                    if (i_mask[0]) dmem[i][7:0] <= i_wdata[7:0];
                    if (i_mask[1]) dmem[i][15:8] <= i_wdata[15:8];
                    if (i_mask[2]) dmem[i][23:16] <= i_wdata[23:16];
                    if (i_mask[3]) dmem[i][31:24] <= i_wdata[31:24];
                end
            end
        end
    endgenerate
endmodule