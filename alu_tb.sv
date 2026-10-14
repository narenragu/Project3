`default_nettype none

module alu_tb();
    // PORTS
    reg [2:0] i_opsel;
    reg i_sub;
    reg i_unsigned;
    reg i_arith;
    reg [31:0] i_op1;
    reg [31:0] i_op2;
    wire [31:0] o_result;
    wire o_eq;
    wire o_slt;

    // INSTANTIATION
    alu iDUT(.i_opsel(i_opsel), .i_sub(i_sub), .i_unsigned(i_unsigned), .i_arith(i_arith),
        .i_op1(i_op1), .i_op2(i_op2),
        .o_result(o_result), .o_eq(o_eq), .o_slt(o_slt));
    
    // TASKS
    task reset;
        i_opsel = 3'b000;
        i_sub = 0;
        i_unsigned = 0;
        i_arith = 0;
        i_op1 = 32'b0;
        i_op2 = 32'b0;
    endtask

    // TEST
    initial begin
        reset();
        // test 1: add 1 + 1 = 2
        i_opsel = 3'b000;
        i_op1 = 32'd1;
        i_op2 = 32'd1;
        #1;
        if (o_result !== 32'd2) begin
            $display("TEST FAILED: 1 + 1 != %d", o_result);
            $finish();
        end
        $display("TEST PASSED: 1 + 1 = %d", o_result);

        // test 2: sub 5 - 3 = 2
        reset();
        i_opsel = 3'b000;
        i_sub = 1;
        i_op1 = 32'd5;
        i_op2 = 32'd3;
        #1;
        if (o_result !== 32'd2) begin
            $display("TEST FAILED: 5 - 3 != %d", o_result);
            $finish();
        end
        $display("TEST PASSED: 5 - 3 = %d", o_result);

        // test 3: 16 << 2 = 64
        reset();
        i_opsel = 3'b001;
        i_op1 = 32'd16;
        i_op2 = 32'd2;
        #1;
        if (o_result !== 32'd64) begin
            $display("TEST FAILED: 16 << 2 != %d", o_result);
            $finish();
        end
        $display("TEST PASSED: 16 << 2 = %d", o_result);

        // test 4: slt (unsigned) 5 < 10 = 1
        reset();
        i_opsel = 3'b010;
        i_unsigned = 1;
        i_op1 = 32'd5;
        i_op2 = 32'd10;
        #1;
        if (o_slt !== 1'b1) begin
            $display("TEST FAILED: 5 < 10 (unsigned) != %b", o_slt);
            $finish();
        end
        $display("TEST PASSED: 5 < 10 (unsigned) = %b", o_slt);

        // test 5: slt (signed) -5 < 10 = 1
        reset();
        i_opsel = 3'b010;
        i_unsigned = 0;
        i_op1 = -32'd5;
        i_op2 = 32'd10;
        #1;
        if (o_slt !== 1'b1) begin
            $display("TEST FAILED: -5 < 10 (signed) != %b", o_slt);
            $finish();
        end
        $display("TEST PASSED: -5 < 10 (signed) = %b", o_slt);

        // test 6: or 5 | 3 = 7
        reset();
        i_opsel = 3'b110;
        i_op1 = 32'd5;
        i_op2 = 32'd3;
        #1;
        if (o_result !== 32'd7) begin
            $display("TEST FAILED: 5 | 3 != %d", o_result);
            $finish();
        end
        $display("TEST PASSED: 5 | 3 = %d", o_result);

        // test 7: and 5 & 3 = 1
        reset();
        i_opsel = 3'b111;
        i_op1 = 32'd5;
        i_op2 = 32'd3;
        #1;
        if (o_result !== 32'd1) begin
            $display("TEST FAILED: 5 & 3 != %d", o_result);
            $finish();
        end
        $display("TEST PASSED: 5 & 3 = %d", o_result);
        
        // test 8: eq 5 == 5 = 1
        reset();
        i_opsel = 3'b101;
        i_op1 = 32'd5;
        i_op2 = 32'd5;
        #1;
        if (o_eq !== 1'b1) begin
            $display("TEST FAILED: 5 == 5 != %b", o_eq);
            $finish();
        end
        $display("TEST PASSED: 5 == 5 = %b", o_eq);

        // test 9: shift right logical 16 >> 2 = 4
        reset();
        i_opsel = 3'b101;
        i_op1 = 32'd16;
        i_op2 = 32'd2;
        i_arith = 0;
        #1;
        if (o_result !== 32'd4) begin
            $display("TEST FAILED: 16 >> 2 != %d", o_result);
            $finish();
        end
        $display("TEST PASSED: 16 >> 2 = %d", o_result);

        // test 10: shift right arithmetic -16 >>> 2 = -4
        reset();
        i_opsel = 3'b101;
        i_op1 = -32'd16;
        i_op2 = 32'd2;
        i_arith = 1;
        #1;
        if (o_result !== -32'd4) begin
            $display("TEST FAILED: -16 >>> 2 != %d", o_result);
            $finish();
        end
        $display("TEST PASSED: -16 >>> 2 = %d", o_result);

        $display("All tests passed!");
        $finish();
    end
endmodule



`default_nettype wire