// data load extend

module dle (
    input wire [31:0] i_rdata,
    input wire [1:0] i_byte_offset,
    input wire [2:0] i_funct3,
    output reg [31:0] o_ldata
);
    reg [7:0] b;
    reg [15:0] h;

    always @(*) begin
        case (i_byte_offset)
            2'd0: b = i_rdata[7:0];
            2'd1: b = i_rdata[15:8];
            2'd2: b = i_rdata[23:16];
            default: b = i_rdata[31:24];
        endcase
        h = i_byte_offset[1] ? i_rdata[31:16] : i_rdata[15:0];

        case (i_funct3)
            3'd0: o_ldata = {{24{b[7]}}, b}; // lb
            3'd1: o_ldata = {{16{h[15]}}, h}; // lh
            3'd2: o_ldata = i_rdata; // lw
            3'd4: o_ldata = {24'b0, b}; // lbu
            3'd5: o_ldata = {16'b0, h}; // lhu
            default: o_ldata = 32'b0;
        endcase
     end
endmodule