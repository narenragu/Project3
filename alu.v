`default_nettype none

// The arithmetic logic unit (ALU) is responsible for performing the core
// calculations of the processor. It takes two 32-bit operands and outputs
// a 32 bit result based on the selection operation - addition, comparison,
// shift, or logical operation. This ALU is a purely combinational block, so
// you should not attempt to add any registers or pipeline it.
module alu (
    // NOTE: Both 3'b010 and 3'b011 are used for set less than operations and
    // your implementation should output the same result for both codes. The
    // reason for this will become clear in project 3.
    //
    // Major operation selection.
    // 3'b000: addition/subtraction if `i_sub` asserted
    // 3'b001: shift left logical
    // 3'b010,
    // 3'b011: set less than/unsigned if `i_unsigned` asserted
    // 3'b100: exclusive or
    // 3'b101: shift right logical/arithmetic if `i_arith` asserted
    // 3'b110: or
    // 3'b111: and
    input  wire [ 2:0] i_opsel,
    // When asserted, addition operations should subtract instead.
    // This is only used for `i_opsel == 3'b000` (addition/subtraction).
    input  wire        i_sub,
    // When asserted, comparison operations should be treated as unsigned.
    // This is used for branch comparisons and set less than unsigned. For
    // branch operations, the ALU result is not used, only the comparison
    // results.
    input  wire        i_unsigned,
    // When asserted, right shifts should be treated as arithmetic instead of
    // logical. This is only used for `i_opsel == 3'b101` (shift right).
    input  wire        i_arith,
    // First 32-bit input operand.
    input  wire [31:0] i_op1,
    // Second 32-bit input operand.
    input  wire [31:0] i_op2,
    // 32-bit output result. Any carry out should be ignored.
    output wire [31:0] o_result,
    // Equality result. This is used externally to determine if a branch
    // should be taken.
    output wire        o_eq,
    // Set less than result. This is used externally to determine if a branch
    // should be taken.
    output wire        o_slt
);
    reg [31:0] result_r;
    reg [31:0] sub_r;
    reg eq_r;
    reg slt_r;

    assign o_result = result_r;
    assign o_eq = eq_r;
    assign o_slt = slt_r;

    always @* begin
        eq_r = i_op1 == i_op2;
        sub_r = i_op1 - i_op2;
        slt_r = i_unsigned ? (i_op1 < i_op2) : ((i_op1[31] != i_op2[31]) ? i_op1[31] : sub_r[31]);
        result_r = 32'b0;

        case (i_opsel)
            3'd0: begin // addition/subtraction if `i_sub` asserted
                result_r = i_sub ? (i_op1 - i_op2) : (i_op1 + i_op2);
            end
            3'd1: begin // shift left logical
                result_r = i_op1;
                result_r = (i_op2[4]) ? {result_r[15:0], 16'b0} : result_r;
                result_r = (i_op2[3]) ? {result_r[23:0], 8'b0} : result_r;
                result_r = (i_op2[2]) ? {result_r[27:0], 4'b0} : result_r;
                result_r = (i_op2[1]) ? {result_r[29:0], 2'b0} : result_r;
                result_r = (i_op2[0]) ? {result_r[30:0], 1'b0} : result_r;
            end
            3'd2, 3'd3: begin // set less than/unsigned if `i_unsigned` asserted
                result_r = {31'b0, slt_r};
            end
            3'd4: begin // exclusive or
                result_r = i_op1 ^ i_op2;
            end
            3'd5: begin // shift right logical/arithmetic if `i_arith` asserted
                result_r = i_op1;
                result_r = i_op2[4] ? (i_arith ? {{16{i_op1[31]}}, result_r[31:16]} : {16'b0, result_r[31:16]}) : result_r;
                result_r = i_op2[3] ? (i_arith ? {{8{i_op1[31]}},  result_r[31:8]}  : {8'b0,  result_r[31:8]})  : result_r;
                result_r = i_op2[2] ? (i_arith ? {{4{i_op1[31]}},  result_r[31:4]}  : {4'b0,  result_r[31:4]})  : result_r;
                result_r = i_op2[1] ? (i_arith ? {{2{i_op1[31]}},  result_r[31:2]}  : {2'b0,  result_r[31:2]})  : result_r;
                result_r = i_op2[0] ? (i_arith ? {{1{i_op1[31]}},  result_r[31:1]}  : {1'b0,  result_r[31:1]})  : result_r;
            end
            3'd6: begin // or
                result_r = i_op1 | i_op2;
            end
            3'd7: begin // and
                result_r = i_op1 & i_op2;
            end
            default: begin
                result_r = 32'b0;
            end
        endcase
    end
endmodule

`default_nettype wire