`default_nettype none

module hart #(
    // After reset, the program counter (PC) should be initialized to this
    // address and start executing instructions from there.
    parameter RESET_ADDR = 32'h00000000
) (
    // Global clock.
    input  wire        i_clk,
    // Synchronous active-high reset.
    input  wire        i_rst,
    // Instruction fetch goes through a read only instruction memory (imem)
    // port. The port accepts a 32-bit address (e.g. from the program counter)
    // per cycle and combinationally returns a 32-bit instruction word. This
    // is not representative of a realistic memory interface; it has been
    // modeled as more similar to a DFF or SRAM to simplify phase 3. In
    // later phases, you will replace this with a more realistic memory.
    //
    // 32-bit read address for the instruction memory. This is expected to be
    // 4 byte aligned - that is, the two LSBs should be zero.
    output wire [31:0] o_imem_raddr,
    // Instruction word fetched from memory, available on the same cycle.
    input  wire [31:0] i_imem_rdata,
    // Data memory accesses go through a separate read/write data memory (dmem)
    // that is shared between read (load) and write (stored). The port accepts
    // a 32-bit address, read or write enable, and mask (explained below) each
    // cycle. Reads are combinational - values are available immediately after
    // updating the address and asserting read enable. Writes occur on (and
    // are visible at) the next clock edge.
    //
    // Read/write address for the data memory. This should be 32-bit aligned
    // (i.e. the two LSB should be zero). See `o_dmem_mask` for how to perform
    // half-word and byte accesses at unaligned addresses.
    output wire [31:0] o_dmem_addr,
    // When asserted, the memory will perform a read at the aligned address
    // specified by `i_addr` and return the 32-bit word at that address
    // immediately (i.e. combinationally). It is illegal to assert this and
    // `o_dmem_wen` on the same cycle.
    output wire        o_dmem_ren,
    // When asserted, the memory will perform a write to the aligned address
    // `o_dmem_addr`. When asserted, the memory will write the bytes in
    // `o_dmem_wdata` (specified by the mask) to memory at the specified
    // address on the next rising clock edge. It is illegal to assert this and
    // `o_dmem_ren` on the same cycle.
    output wire        o_dmem_wen,
    // The 32-bit word to write to memory when `o_dmem_wen` is asserted. When
    // write enable is asserted, the byte lanes specified by the mask will be
    // written to the memory word at the aligned address at the next rising
    // clock edge. The other byte lanes of the word will be unaffected.
    output wire [31:0] o_dmem_wdata,
    // The dmem interface expects word (32 bit) aligned addresses. However,
    // the processor supports byte and half-word loads and stores at unaligned and
    // 16-bit aligned addresses, respectively. To support this, the access
    // mask specifies which bytes within the 32-bit word are actually read
    // from or written to memory.
    //
    // To perform a half-word read at address 0x00001002, align `o_dmem_addr`
    // to 0x00001000, assert `o_dmem_ren`, and set the mask to 0b1100 to
    // indicate that only the upper two bytes should be read. Only the upper
    // two bytes of `i_dmem_rdata` can be assumed to have valid data; to
    // calculate the final value of the `lh[u]` instruction, shift the rdata
    // word right by 16 bits and sign/zero extend as appropriate.
    //
    // To perform a byte write at address 0x00002003, align `o_dmem_addr` to
    // `0x00002000`, assert `o_dmem_wen`, and set the mask to 0b1000 to
    // indicate that only the upper byte should be written. On the next clock
    // cycle, the upper byte of `o_dmem_wdata` will be written to memory, with
    // the other three bytes of the aligned word unaffected. Remember to shift
    // the value of the `sb` instruction left by 24 bits to place it in the
    // appropriate byte lane.
    output wire [ 3:0] o_dmem_mask,
    // The 32-bit word read from data memory. When `o_dmem_ren` is asserted,
    // this will immediately reflect the contents of memory at the specified
    // address, for the bytes enabled by the mask. When read enable is not
    // asserted, or for bytes not set in the mask, the value is undefined.
    input  wire [31:0] i_dmem_rdata,
	// The output `retire` interface is used to signal to the testbench that
    // the CPU has completed and retired an instruction. A single cycle
    // implementation will assert this every cycle; however, a pipelined
    // implementation that needs to stall (due to internal hazards or waiting
    // on memory accesses) will not assert the signal on cycles where the
    // instruction in the writeback stage is not retiring.
    //
    // Asserted when an instruction is being retired this cycle. If this is
    // not asserted, the other retire signals are ignored and may be left invalid.
    output wire        o_retire_valid,
    // The 32 bit instruction word of the instrution being retired. This
    // should be the unmodified instruction word fetched from instruction
    // memory.
    output wire [31:0] o_retire_inst,
    // Asserted if the instruction produced a trap, due to an illegal
    // instruction, unaligned data memory access, or unaligned instruction
    // address on a taken branch or jump.
    output wire        o_retire_trap,
    // Asserted if the instruction is an `ebreak` instruction used to halt the
    // processor. This is used for debugging and testing purposes to end
    // a program.
    output wire        o_retire_halt,
    // The first register address read by the instruction being retired. If
    // the instruction does not read from a register (like `lui`), this is
    // don't-care -- the grading testbench doesn't look at it in that case.
    output wire [ 4:0] o_retire_rs1_raddr,
    // The second register address read by the instruction being retired. If
    // the instruction does not read from a second register (like `addi`),
    // this is don't-care -- the grading testbench doesn't look at it in that
    // case.
    output wire [ 4:0] o_retire_rs2_raddr,
    // The first source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs1 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs1_rdata,
    // The second source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs2 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs2_rdata,
    // The destination register address written by the instruction being
    // retired. If the instruction does not write to a register (like `sw`),
    // this should be 5'd0.
    output wire [ 4:0] o_retire_rd_waddr,
    // The destination register data written to the register file in the
    // writeback stage by this instruction. If rd is 5'd0, this field is
    // ignored and can be treated as a don't care.
    output wire [31:0] o_retire_rd_wdata,
    // The current program counter of the instruction being retired - i.e.
    // the instruction memory address that the instruction was fetched from.
    output wire [31:0] o_retire_pc,
    // the next program counter after the instruction is retired. For most
    // instructions, this is `o_retire_pc + 4`, but must be the branch or jump
    // target for *taken* branches and jumps.
    output wire [31:0] o_retire_next_pc

`ifdef RISCV_FORMAL
    ,`RVFI_OUTPUTS,
`endif
);
    // signal instantiation

        // pc
        wire [31:0] pc;
        wire [31:0] instr;
        wire [31:0] pc_nxt;
        reg [31:0] pc_target;

        // alu
        wire [2:0] alu_opsel;
        wire alu_sub;
        wire alu_unsigned;
        wire alu_arith;
        reg [31:0] alu_op1;
        reg [31:0] alu_op2;
        wire [31:0] alu_result;
        wire alu_eq;
        wire alu_slt;

        // control
        wire [5:0] format;
        wire dmem_ren;
        wire dmem_wen;
        wire rf_wen;
        wire [1:0] rd_wsel;
        wire [1:0] op1_sel;
        wire op2_sel;
        wire [1:0] pc_sel;
        wire illegal;
        wire halt;

        wire [2:0] funct3 = instr[14:12];

        // immediate generator
        wire [31:0] immediate;

        // register file
        wire [31:0] rs1;
        wire [31:0] rs2;

        // data memory
        wire [31:0] dmem_wdata;
        wire [3:0] dmem_mask;

        // data load extend
        wire [31:0] dmem_ldata;

        // extra
        reg [31:0] rd_wdata;
        wire data_misaligned;
        wire target_misaligned;
        wire trap;
        wire commit;

    // module instantiation
        alu iALU(
            .i_opsel(alu_opsel), .i_sub(alu_sub), .i_unsigned(alu_unsigned), .i_arith(alu_arith), .i_op1(alu_op1), .i_op2(alu_op2),
            .o_result(alu_result), .o_eq(alu_eq), .o_slt(alu_slt)
        );

        control iControlUnit(
            .i_instr(instr), .i_alu_eq(alu_eq), .i_alu_slt(alu_slt),
            .o_format(format), .o_op1_sel(op1_sel), .o_op2_sel(op2_sel),
            .o_alu_opsel(alu_opsel), .o_alu_sub(alu_sub), .o_alu_arith(alu_arith),
            .o_alu_unsigned(alu_unsigned), .o_rf_wen(rf_wen), .o_rd_wsel(rd_wsel),
            .o_dmem_ren(dmem_ren), .o_dmem_wen(dmem_wen), .o_pc_sel(pc_sel),
            .o_halt(halt), .o_illegal(illegal)
        );

        pc #(.RESET_ADDR(RESET_ADDR)) iProgramCounter(
            .i_clk(i_clk), .i_rst(i_rst), .i_pc_nxt(pc_nxt),
            .o_pc(pc)
        );

        rf #(.BYPASS_EN(0)) iRegisterFile(
            .i_clk(i_clk), .i_rst(i_rst),
            .i_rs1_raddr(instr[19:15]), .o_rs1_rdata(rs1),
            .i_rs2_raddr(instr[24:20]), .o_rs2_rdata(rs2),
            .i_rd_wen(rf_wen && commit), .i_rd_waddr(instr[11:7]), .i_rd_wdata(rd_wdata)
        );

        imm iImmediateGenerator(
            .i_inst(instr), .i_format(format), .o_immediate(immediate)
        );

        dsr iDataStoreAlign(
            .i_rs2(rs2), .i_byte_offset(alu_result[1:0]),
            .i_funct3(funct3), .o_wdata(dmem_wdata)
        );

        maskgen iMaskGenerator(
            .i_byte_offset(alu_result[1:0]), .i_funct3(funct3), .o_mask(dmem_mask)
        );

        dle iDataLoadExtend(
            .i_rdata(i_dmem_rdata), .i_byte_offset(alu_result[1:0]),
            .i_funct3(funct3), .o_ldata(dmem_ldata)
        );

    // wiring
        always @(*) begin
            // op1
            case (op1_sel)
                2'b00 : alu_op1 = rs1;
                2'b01 : alu_op1 = pc;
                2'b10 : alu_op1 = 32'd0;
                default : alu_op1 = 32'bx;
            endcase

            // op2
            alu_op2 = (op2_sel) ? immediate : rs2;

            // pc_nxt (TODO: pull out adder and mux inputs)
            case (pc_sel)
                2'b00 : pc_target = pc + 32'd4;
                2'b01 : pc_target = pc + immediate;
                2'b10 : pc_target = {alu_result[31:1], 1'b0};
                default : pc_target = 32'bx;
            endcase

            // rd_wdata
            case (rd_wsel)
                2'b00 : rd_wdata = alu_result;
                2'b01 : rd_wdata = dmem_ldata;
                2'b10 : rd_wdata = pc + 32'd4;
                default : rd_wdata = 32'bx;
            endcase
        end

        assign instr = i_imem_rdata;
        assign o_imem_raddr = pc;
        assign o_dmem_addr = {alu_result[31:2], 2'b00};
        assign o_dmem_wdata = dmem_wdata;
        assign o_dmem_mask = dmem_mask;
        assign o_dmem_ren = dmem_ren && commit;
        assign o_dmem_wen = dmem_wen && commit;

        assign data_misaligned = (dmem_ren || dmem_wen) &&
            (((funct3 == 3'b001 || funct3 == 3'b101) && alu_result[0]) ||
             ((funct3 == 3'b010) && (|alu_result[1:0])));

        assign target_misaligned =
            ((pc_sel == 2'b01) || (pc_sel == 2'b10)) && (|pc_target[1:0]);
        assign trap = illegal || data_misaligned || target_misaligned;
        assign commit = !i_rst && !trap;
        assign pc_nxt = pc_target;

        assign o_retire_valid = !i_rst;
        assign o_retire_inst = instr;
        assign o_retire_trap = trap;
        assign o_retire_halt = halt;
        assign o_retire_rs1_raddr = instr[19:15];
        assign o_retire_rs2_raddr = instr[24:20];
        assign o_retire_rs1_rdata = rs1;
        assign o_retire_rs2_rdata = rs2;
        assign o_retire_rd_waddr = (rf_wen && commit) ? instr[11:7] : 5'd0;
        assign o_retire_rd_wdata = rd_wdata;
        assign o_retire_pc = pc;
        assign o_retire_next_pc = pc_nxt;
endmodule

`default_nettype wire
