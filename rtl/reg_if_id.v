`default_nettype none

module reg_if_id (
    input wire i_clk, i_rst,
    input wire if_valid,
    input wire [31:0] if_inst,
    input wire [31:0] if_pc,
    input wire i_stall,
    
    output reg id_valid,
    output reg [31:0] id_inst,
    output reg [31:0] id_pc
);
    always @(posedge i_clk) begin
        if(i_rst) begin
            id_valid <= 1'b0;
            id_inst <= 32'b0;       //maybe should be 32'h0013?
            id_pc <= 32'b0;     
        end else if(!i_stall) begin
            id_valid <= if_valid;
            id_inst <= if_inst;
            id_pc <= if_pc;
        end
    end

endmodule   

`default_nettype wire