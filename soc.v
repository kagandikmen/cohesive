// Top SoC module
// Created:     2026-07-04
// Modified:    2026-07-05
// Author:      Kagan Dikmen

module soc
    #(
    parameter DMEM_ADDR_WIDTH  = 13,
    parameter DMEM_DATA_WIDTH  = 32,
    parameter OP_LENGTH = 32,
    parameter PC_WIDTH = 16,
    parameter MEM_INIT_FILE = "",
    parameter RESET_ADDR = 32'h00000000
    )(
    input rst,
    input sysclk,
    output wire led     // dummy signal to prevent overoptimization
    );

    wire [31:0] instr;
    wire [31:0] rdata;
    wire rdata_valid, wdata_valid;
    wire if_en;
    wire mem_enb;
    wire [3:0] wr_mode;
    wire [12:0] mem_addra;
    wire [DMEM_ADDR_WIDTH-1:0] mem_addrb;
    wire [OP_LENGTH-1:0] mem_dinb;

    wire [31:0] rdata_wire;
    reg [31:0] rdata_buf [1:0];
    reg [1:0] rdata_valid_buf, wdata_valid_buf;

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
        .mem_dinb_o(mem_dinb)
    );

    // NOTE: a for program memory, b for data memory
    bram_dual #(
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
        .doutb(rdata_wire)
    );

    integer i;

    // temporary output delay to test CPU-internal stalling
    always @(posedge sysclk) begin
        rdata_buf[1] <= rdata_wire;
        rdata_valid_buf[1] <= mem_enb && !(|wr_mode);
        wdata_valid_buf[1] <= mem_enb && |wr_mode;

        rdata_buf[0] <= rdata_buf[1];
        rdata_valid_buf[0] <= rdata_valid_buf[1];
        wdata_valid_buf[0] <= wdata_valid_buf[1];

        if(rst) begin
            for(i=0; i<2; i=i+1) begin
                rdata_buf[i] <= 'b0;
                rdata_valid_buf[i] <= 'b0;
                wdata_valid_buf[i] <= 'b0;
            end
        end
    end
    assign rdata = rdata_buf[0];
    assign rdata_valid = rdata_valid_buf[0];
    assign wdata_valid = wdata_valid_buf[0];

    assign led = |wr_mode;

endmodule
