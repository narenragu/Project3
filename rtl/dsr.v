//replicate store data for byte/halfword/word stores

module dsr (
    input wire [31:0] i_rs2,
    input wire [2:0] i_funct3,
    output reg [31:0] o_wdata
);

always @(*) begin
    case (i_funct3)
        3'b000: o_wdata = {4{i_rs2[7:0]}};   // SB
        3'b001: o_wdata = {2{i_rs2[15:0]}};  // SH
        3'b010: o_wdata = i_rs2;             // SW
        default: o_wdata = 32'b0;
    endcase
end
    
endmodule
