`default_nettype none

// mask generator

module maskgen (
    input wire [1:0] i_byte_offset,
    input wire [2:0] i_funct3,
    output reg [3:0] o_mask
);


always @(*) begin
    case(i_funct3)
            3'd0, 3'd4: o_mask = (i_byte_offset == 2'd0) ? 4'b0001 : (i_byte_offset == 2'd1) ? 4'b0010 : (i_byte_offset == 2'd2) ? 4'b0100 : (i_byte_offset == 2'd3) ? 4'b1000 : 4'b0000;
            3'd1, 3'd5: o_mask = i_byte_offset[1] ? 4'b1100 : 4'b0011;
            3'd2: o_mask = 4'b1111;
            default: o_mask = 4'b0000;
    endcase
end
    
endmodule

`default_nettype wire
