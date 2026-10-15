// UNUSED
`default_nettype none

module imem (
    input wire [31:0] i_addr,
    output reg [31:0] o_instr
);
    reg [31:0] imem [0:31];
    assign o_instr = imem[i_addr];
endmodule