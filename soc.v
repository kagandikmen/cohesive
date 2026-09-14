// Top SoC module
// Created:     2026-07-04
// Modified:    2026-09-14
// Author:      Kagan Dikmen

module soc
    #(
    parameter DMEM_ADDR_WIDTH  = 16,
    parameter DMEM_DATA_WIDTH  = 32,
    parameter OP_LENGTH = 32,
    parameter PC_WIDTH = 16,
    parameter MEM_INIT_FILE = "",
    parameter RESET_ADDR = 32'h00000000
    )(
    input rst,
    input sysclk,
    input ext_irq_i,
    output wire led     // dummy signal to prevent overoptimization
    );

    wire [31:0] instr;
    wire [31:0] rdata;
    wire rdata_valid, wdata_valid;
    wire if_en;
    wire mem_enb;
    wire [3:0] wr_mode;
    wire [DMEM_ADDR_WIDTH-1:0] mem_addra;
    wire [DMEM_ADDR_WIDTH-1:0] mem_addrb;
    wire [OP_LENGTH-1:0] mem_dinb;

    cpu #(
        .DMEM_ADDR_WIDTH(DMEM_ADDR_WIDTH),
        .DMEM_DATA_WIDTH(DMEM_DATA_WIDTH),
        .OP_LENGTH(OP_LENGTH),
        .PC_WIDTH(PC_WIDTH),
        .RESET_ADDR(RESET_ADDR)
    ) cpu (
        .rst(rst),
        .sysclk(sysclk),
        .mem_instr_i(instr),
        .mem_rdata_i(rdata),
        .mem_rdata_valid_i(rdata_valid),
        .mem_wdata_valid_i(wdata_valid),
        .mem_if_en_o(if_en),
        .mem_enb_o(mem_enb),
        .mem_wr_mode_o(wr_mode),
        .mem_addra_o(mem_addra),
        .mem_addrb_o(mem_addrb),
        .mem_dinb_o(mem_dinb),
        .timer_irq_i(1'b0),     // future work
        .ext_irq_i(ext_irq_i)
    );

    // NOTE: a for program memory, b for data memory
    bram_dual #(
        .NB_COL(4),
        .COL_WIDTH(8),
        .RAM_DEPTH(65536),      // 128 KiB for program memory, 128 KiB for data memory
        .RAM_PERFORMANCE("LOW_LATENCY"),
        .INIT_FILE(MEM_INIT_FILE)
    ) mem (
        .addra(mem_addra),
        .addrb(mem_addrb),
        .dina(),
        .dinb(mem_dinb),
        .clka(sysclk),
        .clkb(sysclk),
        .wea(),
        .web(wr_mode),
        .ena(if_en),
        .enb(mem_enb),
        .rsta(),
        .rstb(),
        .regcea(),
        .regceb(),
        .douta(instr),
        .doutb(rdata)
    );

    assign rdata_valid = mem_enb;
    assign wdata_valid = mem_enb && |wr_mode;

    assign led = |wr_mode;

endmodule
