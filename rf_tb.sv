`default_nettype none

module rf_tb();

    // PORTS
    reg clk, rst;
    // Register read port 1
    reg [4:0] i_rs1_raddr;
    // Register read port 2
    reg [4:0] i_rs2_raddr;
    // Register write port (with enable)
    reg i_rd_wen;
    reg [4:0] i_rd_waddr;
    reg [31:0] i_rd_wdata;

    // Outputs from each DUT
    wire [31:0] o_rs1_rdata_nobypass;
    wire [31:0] o_rs2_rdata_nobypass;
    wire [31:0] o_rs1_rdata_bypass;
    wire [31:0] o_rs2_rdata_bypass;

    // CLOCK GENERATION
    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    // INSTANTIATION
    rf #(.BYPASS_EN(0)) iDUT_nobypass(
        .i_clk(clk), .i_rst(rst),
        .i_rs1_raddr(i_rs1_raddr), .o_rs1_rdata(o_rs1_rdata_nobypass),
        .i_rs2_raddr(i_rs2_raddr), .o_rs2_rdata(o_rs2_rdata_nobypass),
        .i_rd_wen(i_rd_wen), .i_rd_waddr(i_rd_waddr), .i_rd_wdata(i_rd_wdata));

    rf #(.BYPASS_EN(1)) iDUT_bypass(
        .i_clk(clk), .i_rst(rst),
        .i_rs1_raddr(i_rs1_raddr), .o_rs1_rdata(o_rs1_rdata_bypass),
        .i_rs2_raddr(i_rs2_raddr), .o_rs2_rdata(o_rs2_rdata_bypass),
        .i_rd_wen(i_rd_wen), .i_rd_waddr(i_rd_waddr), .i_rd_wdata(i_rd_wdata));

    // TASKS

    task reset;
        rst = 1;
        @(negedge clk);
        rst = 0;
    endtask

    // TEST
    initial begin
        reset();
        repeat(2) @(negedge clk);

        // no bypass tests

        // test 1: write nonzero to x0, read zero
        i_rd_wen = 1;
        i_rd_waddr = 5'd0;
        i_rd_wdata = 32'hDEADBEEF;
        @(negedge clk);
        i_rd_wen = 0;
        i_rs1_raddr = 5'd0;
        @(negedge clk);
        if (o_rs1_rdata_nobypass !== 32'd0) begin
            $display("TEST FAILED: x0 readback is not zero, got %h\n", o_rs1_rdata_nobypass);
            $finish();
        end
        $display("TEST PASSED: x0 readback is zero\n");

        // test 2: write to x1-31, verify value by reading
        for (int i = 1; i < 32; i++) begin
            i_rd_wen = 1;
            i_rd_waddr = i;
            i_rd_wdata = {i, 27'd0};
            @(negedge clk);
            i_rd_wen = 0;
            i_rs1_raddr = i;
            @(negedge clk);
            if (o_rs1_rdata_nobypass !== {i, 27'd0}) begin
                $display("TEST FAILED: x%d readback is not %h, got %h\n", i, {i, 27'd0}, o_rs1_rdata_nobypass);
                $finish();
            end
        end
        $display("TEST PASSED: x1-31 readback is correct\n");

        // test 3: read two registers at once
        i_rs1_raddr = 5'd1;
        i_rs2_raddr = 5'd2;
        @(negedge clk);
        if (o_rs1_rdata_nobypass !== {5'd1, 27'd0} || o_rs2_rdata_nobypass !== {5'd2, 27'd0}) begin
            $display("TEST FAILED: x1 readback is %h, x2 readback is %h\n", o_rs1_rdata_nobypass, o_rs2_rdata_nobypass);
            $finish();
        end
        $display("TEST PASSED: x1 and x2 readback is correct\n");

        // bypass tests

        // test 4: write to x1, read x1 same cycle -> bypass DUT should
        // forward the new value combinationally; no-bypass DUT should
        // still show the old value until after the clock edge.
        @(negedge clk);
        i_rd_wen = 1;
        i_rd_waddr = 5'd1;
        i_rd_wdata = 32'hCAFEBABE;
        i_rs1_raddr = 5'd1;
        #1; // let combinational logic settle, still before next posedge

        if (o_rs1_rdata_bypass !== 32'hCAFEBABE) begin
            $display("TEST FAILED: bypass DUT x1 readback is not bypassed value, got %h\n", o_rs1_rdata_bypass);
            $finish();
        end
        if (o_rs1_rdata_nobypass === 32'hCAFEBABE) begin
            $display("TEST FAILED: no-bypass DUT x1 readback should not reflect same-cycle write yet, got %h\n", o_rs1_rdata_nobypass);
            $finish();
        end
        $display("TEST PASSED: bypass DUT forwards same-cycle write, no-bypass DUT does not\n");

        @(negedge clk);
        i_rd_wen = 0;
        if (o_rs1_rdata_nobypass !== 32'hCAFEBABE) begin
            $display("TEST FAILED: no-bypass DUT x1 readback after clock edge should be %h, got %h\n", 32'hCAFEBABE, o_rs1_rdata_nobypass);
            $finish();
        end
        $display("TEST PASSED: no-bypass DUT x1 readback correct after clock edge\n");

        $finish();
    end
endmodule



`default_nettype wire