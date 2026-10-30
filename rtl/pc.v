`default_nettype none

module pc #(
    parameter RESET_ADDR = 32'b0
)(
    input wire i_clk,
    input wire i_rst,
    input wire [31:0] i_pc_nxt,
    input wire i_stall,
    output reg [31:0] o_pc
);

    always @(posedge i_clk) begin
        if (i_rst) begin
            o_pc <= RESET_ADDR;
        end else if (!i_stall) begin
            o_pc <= i_pc_nxt;
        end
    end

endmodule
