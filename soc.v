// Top SoC module
// Created:     2026-07-04
// Modified:    2026-10-04
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
    wire [31:0] bram_rdata;
    wire rdata_valid, wdata_valid;
    wire if_en;
    wire mem_enb;
    wire [3:0] wr_mode;
    wire [DMEM_ADDR_WIDTH-1:0] mem_addra;
    wire [DMEM_ADDR_WIDTH-1:0] mem_addrb;
    wire [31:0] mem_addr_full;
    wire [OP_LENGTH-1:0] mem_dinb;

    wire sw_irq, timer_irq, generated_ext_irq, cpu_ext_irq;
    wire [63:0] mtime;

    assign cpu_ext_irq = ext_irq_i | generated_ext_irq;

    wire [31:0] irq_rdata;
    wire irq_rvalid;

    wire ram_selected;
    wire clint_selected;
    wire ext_irq_selected;
    wire irq_selected;

    assign ram_selected = (&mem_addr_full[31:DMEM_ADDR_WIDTH+2]) || (~|mem_addr_full[31:DMEM_ADDR_WIDTH+2]);
    assign clint_selected = mem_addr_full >=32'h0200_0000 && mem_addr_full < 32'h0201_0000;
    assign ext_irq_selected = mem_addr_full == 32'h0c00_0004;
    assign irq_selected = clint_selected || ext_irq_selected;

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
        .mem_addr_full_o(mem_addr_full),
        .mem_addra_o(mem_addra),
        .mem_addrb_o(mem_addrb),
        .mem_dinb_o(mem_dinb),
        .timer_irq_i(timer_irq),
        .ext_irq_i(cpu_ext_irq),
        .sw_irq_i(sw_irq),
        .time_i(mtime)
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
        .web(ram_selected ? wr_mode : 4'b0000),
        .ena(if_en),
        .enb(mem_enb && ram_selected),
        .rsta(),
        .rstb(),
        .regcea(),
        .regceb(),
        .douta(instr),
        .doutb(bram_rdata)
    );

    assign rdata = irq_selected ? irq_rdata : bram_rdata;
    assign rdata_valid = irq_selected ? irq_rvalid : (mem_enb && ram_selected);
    assign wdata_valid = mem_enb && |wr_mode && (ram_selected || irq_selected);

    machine_interrupt_controller interrupt_controller (
        .clk(sysclk),
        .rst(rst),
        .req_i(mem_enb && irq_selected),
        .we_i(wr_mode),
        .addr_i(mem_addr_full),
        .wdata_i(mem_dinb),
        .rdata_o(irq_rdata),
        .rvalid_o(irq_rvalid),
        .sw_irq_o(sw_irq),
        .timer_irq_o(timer_irq),
        .ext_irq_o(generated_ext_irq),
        .mtime_o(mtime)
    );

    assign led = |wr_mode;

endmodule
