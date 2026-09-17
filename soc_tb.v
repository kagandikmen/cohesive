// Testbench for the top SoC module
// Created:     2026-07-05
// Modified:    2026-09-17
// Author:      Kagan Dikmen

`timescale 1ns/1ns

module soc_tb
    #(
        parameter MEM_INIT_FILE = "",
        parameter TOHOST_ADDR   = 16384,
        parameter RESET_ADDR    = 32'h00000000
    )(
    );

    reg rst, sysclk_t, ext_irq_i_t;
    wire led_t;

    localparam DMEM_ADDR_WIDTH = 16;

    soc #(.DMEM_ADDR_WIDTH(DMEM_ADDR_WIDTH), .DMEM_DATA_WIDTH(32), .OP_LENGTH(32), .PC_WIDTH(16), .MEM_INIT_FILE(MEM_INIT_FILE), .RESET_ADDR(RESET_ADDR)) 
        soc_ut 
        (
            .rst(rst),
            .sysclk(sysclk_t),
            .ext_irq_i(ext_irq_i_t),
            .led(led_t)
        );
    
    always #5 sysclk_t = ~sysclk_t;
    
    initial
    begin
        rst = 1'b0;
        sysclk_t = 1'b0;
        ext_irq_i_t = 1'b0;
        
        #4;
        rst = ~rst;

        #20;
        rst = ~rst;

`ifdef UT

        wait (^soc_ut.mem.BRAM[TOHOST_ADDR[DMEM_ADDR_WIDTH-1+2:2]] !== 1'bx);

        wait (|soc_ut.mem.BRAM[TOHOST_ADDR[DMEM_ADDR_WIDTH-1+2:2]] !== 1'b0);
        
        if (soc_ut.mem.BRAM[TOHOST_ADDR[DMEM_ADDR_WIDTH-1+2:2]] == 32'd1)
            $display("Note: Success!");
        else
            $display("Note: Failure!");
        
        #100;
        $finish;

`endif
        
    end

endmodule