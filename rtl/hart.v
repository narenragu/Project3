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
    /////////////////////////////////////////////////////signal instantiation///////////////////////////////////////////
    //IF:
        // pc
        wire [31:0] pc;
        wire [31:0] instr;
        wire [31:0] pc_plus_4;
        wire [31:0] pc_nxt;
        reg [31:0] pc_target;

        //if/id reg
        wire if_valid;
        wire id_valid;
        wire [31:0] id_pc;
        wire [31:0] id_instr;

    //ID:
        //decoder
        wire [1:0] id_op1_sel;
        wire id_op2_sel;
        wire [2:0] id_alu_opsel;
        wire id_alu_sub;
        wire id_alu_unsigned;
        wire id_alu_arith;
        wire id_branch;
        wire id_jal;
        wire id_jalr;
        wire id_dmem_ren;
        wire id_dmem_wen;
        wire id_rf_wen;
        wire [1:0] id_rd_wsel;
        wire id_halt;
        wire id_illegal;
        wire [5:0] id_format;

        // immediate generator
        wire [31:0] immediate;

        // register file read data
        wire [31:0] id_rf_rs1;
        wire [31:0] id_rf_rs2;

        //hazard detect (later)

        //id/ex reg
        wire ex_valid;
        wire [31:0] ex_pc;
        wire [31:0] ex_instr;
        wire [31:0] ex_rs1_rdata;
        wire [31:0] ex_rs2_rdata;
        wire [31:0] ex_imm;

        wire [2:0] ex_alu_opsel;
        wire [1:0] ex_op1_sel;
        wire ex_op2_sel;
        wire ex_alu_sub;
        wire ex_alu_unsigned;
        wire ex_alu_arith;

        wire ex_dmem_ren;
        wire ex_dmem_wen;
        wire [1:0] ex_rd_wsel;
        wire ex_rf_wen;
        wire ex_branch;
        wire ex_jal;
        wire ex_jalr;
        wire ex_halt;
        wire ex_illegal;
    
    //EX:
        //ex control module
        wire [1:0] pc_sel;
        wire ex_trap;

        //alu
        wire alu_eq;
        wire alu_slt;
        wire [31:0] ex_alu_result;

        //alu op
        reg [31:0] alu_op1;
        reg [31:0] alu_op2;

        //pc + imm (branch/jal)
        wire [31:0] ex_pc_plus_imm;

        //ex/mem reg
        wire mem_valid;
        wire [31:0] mem_pc;
        wire [31:0] mem_instr;
        wire [31:0] mem_alu_result;
        wire [31:0] mem_rs2_rdata;
        wire mem_dmem_ren;
        wire mem_dmem_wen;
        wire [1:0] mem_rd_wsel;
        wire mem_rf_wen;
        wire mem_halt;
        wire mem_trap;

    //MEM:
        //data store replicate
        wire [31:0] mem_wdata;
        
        //mask gen
        wire [3:0] mem_mask;

        //data load extend
        wire [31:0] mem_ldata;

        //mem/wb reg
        wire wb_valid;
        wire [31:0] wb_pc;
        wire [31:0] wb_instr;
        wire wb_trap;
        wire [1:0] wb_rd_wsel;
        wire wb_rf_wen;
        wire [31:0] wb_ldata;
        wire [31:0] wb_alu_result;

    //WB:
        //register file write back data
        reg [31:0] wb_rd_wdata;

    ////////////////////////////////////////////////module instantiation///////////////////////////////////////////////
    //IF:
        pc #(.RESET_ADDR(RESET_ADDR)) iProgramCounter(
            .i_clk(i_clk), .i_rst(i_rst), .i_pc_nxt(pc_nxt),
            .o_pc(pc)
        );

        reg_if_id iRegIFID(
            .i_clk(i_clk), .i_rst(i_rst),
            .if_valid(if_valid), .if_pc(pc), .if_instr(instr),
            .id_valid(id_valid), .id_pc(id_pc), .id_instr(id_instr)
        );

    //ID: 
        decoder iDecoder(
            .i_instr(id_instr),
            .o_op1_sel(id_op1_sel), .o_op2_sel(id_op2_sel),
            .o_alu_opsel(id_alu_opsel), .o_alu_sub(id_alu_sub), .o_alu_unsigned(id_alu_unsigned), .o_alu_arith(id_alu_arith),
            .o_branch(id_branch), .o_jal(id_jal), .o_jalr(id_jalr),
            .o_dmem_ren(id_dmem_ren), .o_dmem_wen(id_dmem_wen),
            .o_rf_wen(id_rf_wen), .o_rd_wsel(id_rd_wsel),
            .o_halt(id_halt), .o_illegal(id_illegal), .o_format(id_format)
        );

        imm iImmediateGenerator(
            .i_inst(id_instr), .i_format(id_format), .o_immediate(immediate)
        );

        rf #(.BYPASS_EN(1)) iRegisterFile(
            .i_clk(i_clk), .i_rst(i_rst),
            .i_rs1_raddr(id_instr[19:15]), .o_rs1_rdata(id_rf_rs1),
            .i_rs2_raddr(id_instr[24:20]), .o_rs2_rdata(id_rf_rs2),
            .i_rd_wen(wb_rf_wen && wb_valid && !wb_trap), .i_rd_waddr(wb_instr[11:7]), .i_rd_wdata(wb_rd_wdata)
        );      //rf write from WB stage

        reg_id_ex iRegIDEX(
            .i_clk(i_clk), .i_rst(i_rst),
            .id_valid(id_valid), .id_pc(id_pc), .id_instr(id_instr),
            .id_op1_sel(id_op1_sel), .id_op2_sel(id_op2_sel),
            .id_alu_opsel(id_alu_opsel), .id_alu_sub(id_alu_sub), .id_alu_unsigned(id_alu_unsigned), .id_alu_arith(id_alu_arith),
            .id_immediate(immediate),
            .id_branch(id_branch), .id_jal(id_jal), .id_jalr(id_jalr),
            .id_dmem_ren(id_dmem_ren), .id_dmem_wen(id_dmem_wen),
            .id_rf_wen(id_rf_wen), .id_rd_wsel(id_rd_wsel),
            .id_rs1_rdata(id_rf_rs1), .id_rs2_rdata(id_rf_rs2),
            .id_halt(id_halt), .id_illegal(id_illegal),
            .ex_valid(ex_valid), .ex_pc(ex_pc), .ex_instr(ex_instr),
            .ex_op1_sel(ex_op1_sel), .ex_op2_sel(ex_op2_sel),
            .ex_alu_opsel(ex_alu_opsel), .ex_alu_sub(ex_alu_sub), .ex_alu_unsigned(ex_alu_unsigned), .ex_alu_arith(ex_alu_arith),
            .ex_immediate(ex_imm),
            .ex_branch(ex_branch), .ex_jal(ex_jal), .ex_jalr(ex_jalr),
            .ex_dmem_ren(ex_dmem_ren), .ex_dmem_wen(ex_dmem_wen),
            .ex_rf_wen(ex_rf_wen), .ex_rd_wsel(ex_rd_wsel),
            .ex_rs1_rdata(ex_rs1_rdata), .ex_rs2_rdata(ex_rs2_rdata),
            .ex_halt(ex_halt), .ex_illegal(ex_illegal)
        );

    //EX:
        ex_control iEXControl(
            .i_valid(ex_valid), .i_pc_plus_imm(ex_pc_plus_imm[1:0]), .i_illegal(ex_illegal),
            .i_dmem_ren(ex_dmem_ren), .i_dmem_wen(ex_dmem_wen),
            .i_funct3(ex_instr[14:12]), .i_slt(alu_slt), .i_eq(alu_eq),
            .i_alu_res(ex_alu_result[1:0]), .i_branch(ex_branch), .i_jal(ex_jal), .i_jalr(ex_jalr),
            .o_pc_sel(pc_sel), .o_trap(ex_trap)
        );

        alu iALU(
            .i_opsel(ex_alu_opsel), .i_sub(ex_alu_sub), .i_unsigned(ex_alu_unsigned), .i_arith(ex_alu_arith), .i_op1(alu_op1), .i_op2(alu_op2),
            .o_result(ex_alu_result), .o_eq(alu_eq), .o_slt(alu_slt)
        );
        
        reg_ex_mem iRegEXMEM(
            .i_clk(i_clk), .i_rst(i_rst),
            .ex_valid(ex_valid), .ex_pc(ex_pc), .ex_instr(ex_instr),
            .ex_alu_result(ex_alu_result), .ex_rs2_rdata(ex_rs2_rdata),
            .ex_dmem_ren(ex_dmem_ren), .ex_dmem_wen(ex_dmem_wen),
            .ex_rf_wen(ex_rf_wen), .ex_rd_wsel(ex_rd_wsel),
            .ex_halt(ex_halt), .ex_trap(ex_trap),
            .mem_valid(mem_valid), .mem_pc(mem_pc), .mem_instr(mem_instr),
            .mem_alu_result(mem_alu_result), .mem_rs2_rdata(mem_rs2_rdata),
            .mem_dmem_ren(mem_dmem_ren), .mem_dmem_wen(mem_dmem_wen),
            .mem_rf_wen(mem_rf_wen), .mem_rd_wsel(mem_rd_wsel),
            .mem_halt(mem_halt), .mem_trap(mem_trap)
        );

    //MEM:
        dsr iDataStoreReplicate(
            .i_rs2(mem_rs2_rdata),
            .i_funct3(mem_instr[14:12]), .o_wdata(mem_wdata)
        );

        maskgen iMaskGenerator(
            .i_byte_offset(mem_alu_result[1:0]), .i_funct3(mem_instr[14:12]), .o_mask(mem_mask)
        );

        dle iDataLoadExtend(
            .i_rdata(i_dmem_rdata), .i_byte_offset(mem_alu_result[1:0]),
            .i_funct3(mem_instr[14:12]), .o_ldata(mem_ldata)
        );

        reg_mem_wb iRegMEMWB(
            .i_clk(i_clk), .i_rst(i_rst),
            .mem_valid(mem_valid), .mem_pc(mem_pc), .mem_instr(mem_instr),
            .mem_alu_result(mem_alu_result), .mem_ldata(mem_ldata),
            .mem_rf_wen(mem_rf_wen), .mem_rd_wsel(mem_rd_wsel),
            .mem_trap(mem_trap),
            .wb_valid(wb_valid), .wb_pc(wb_pc), .wb_instr(wb_instr),
            .wb_alu_result(wb_alu_result), .wb_ldata(wb_ldata),
            .wb_rf_wen(wb_rf_wen), .wb_rd_wsel(wb_rd_wsel),
            .wb_trap(wb_trap)
        );

    ///////////////////////////////////////////////wiring//////////////////////////////////////
        always @(*) begin
            //pc next mux
            case (pc_sel)
                2'b00 : pc_target = pc_plus_4;
                2'b01 : pc_target = ex_pc_plus_imm;
                2'b10 : pc_target = {ex_alu_result[31:1], 1'b0};
                default : pc_target = pc_plus_4;
            endcase
            
            //op1 select
            case (ex_op1_sel)
                2'b00 : alu_op1 = ex_rs1_rdata;
                2'b01 : alu_op1 = ex_pc;
                2'b10 : alu_op1 = 32'd0;
                default : alu_op1 = ex_rs1_rdata;
            endcase

            //op2 select
            alu_op2 = (ex_op2_sel) ? ex_imm : ex_rs2_rdata;

            //wb rd_wdata
            case (wb_rd_wsel)
                2'b00 : wb_rd_wdata = wb_alu_result;
                2'b01 : wb_rd_wdata = wb_ldata;
                2'b10 : wb_rd_wdata = wb_pc + 32'd4;
                default : wb_rd_wdata = 32'bx;
            endcase
        end

        assign if_valid = 1'b1; //always on for 1st hazardless version

        //pc mux
        assign pc_plus_4 = pc + 32'd4;
        assign ex_pc_plus_imm = ex_pc + ex_imm;
        assign pc_nxt = pc_target;

        //imem interface
        assign instr = i_imem_rdata;
        assign o_imem_raddr = pc;

        //dmem interface
        assign o_dmem_addr = {mem_alu_result[31:2], 2'b00};
        assign o_dmem_wdata = mem_wdata;
        assign o_dmem_mask = mem_mask;
        assign o_dmem_ren = mem_dmem_ren && mem_valid && !mem_trap;
        assign o_dmem_wen = mem_dmem_wen && mem_valid && !mem_trap;

        //retire
        assign o_retire_valid = !i_rst;
        assign o_retire_inst = instr;
        assign o_retire_trap = trap;
        assign o_retire_halt = halt;
        assign o_retire_rs1_raddr = instr[19:15];
        assign o_retire_rs2_raddr = instr[24:20];
        assign o_retire_rs1_rdata = rs1;
        assign o_retire_rs2_rdata = rs2;
        assign o_retire_rd_waddr = (wb_rf_wen && wb_valid && !wb_trap) ? wb_instr[11:7] : 5'd0;
        assign o_retire_rd_wdata = wb_rd_wdata;
        assign o_retire_pc = pc;
        assign o_retire_next_pc = pc_nxt;
endmodule

`default_nettype wire
