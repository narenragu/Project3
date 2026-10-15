// data store replicate

module dsr (
    input wire [31:0] i_rs2,
    input wire [2:0] i_funct3,
    output reg [31:0] o_wdata
);

always @(*) begin
    case(i_funct3)
            3'd0: o_wdata = {4{i_rs2[7:0]}}; // sb
            3'd1: o_wdata = {2{i_rs2[15:0]}}; // sh
            3'd2: o_wdata = i_rs2; // sw
            default: o_wdata = 32'b0;
    endcase
end
    
endmodule