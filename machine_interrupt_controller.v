// Machine interrupt controller for Cohesive SoC wrapper
// Created:     2026-10-03
// Modified:    2026-10-03
// Author:      Kagan Dikmen

module machine_interrupt_controller
    (
        input   wire        clk,
        input   wire        rst,

        // MMIO request
        input   wire        req_i,      
        input   wire [3:0]  we_i,       // 0 read, 1 write
        input   wire [31:0] addr_i,
        input   wire [31:0] wdata_i,

        output  reg  [31:0] rdata_o,
        output  reg         rvalid_o,

        output  wire        sw_irq_o,
        output  wire        timer_irq_o,
        output  wire        ext_irq_o
    );

    localparam [31:0] MSIP_ADDR             = 32'h0200_0000;
    localparam [31:0] MTIMECMP_LO_ADDR      = 32'h0200_4000;
    localparam [31:0] MTIMECMP_HI_ADDR      = 32'h0200_4004;
    localparam [31:0] MTIME_LO_ADDR         = 32'h0200_bff8;
    localparam [31:0] MTIME_HI_ADDR         = 32'h0200_bffc;
    localparam [31:0] EXT_IRQ_ADDR          = 32'h0c00_0004;

    reg msip, meip;
    reg [63:0] mtime, mtimecmp;

    // output logic
    assign sw_irq_o = msip;
    assign timer_irq_o = (mtime >= mtimecmp);
    assign ext_irq_o = meip;

    always @(posedge clk) begin
        if(rst) begin
            msip <= 1'b0;
            meip <= 1'b0;
            mtime <= 64'b0;
            mtimecmp <= 64'hffff_ffff_ffff_ffff;
        end else begin
            mtime <= mtime + 64'd1;

            if(req_i && |we_i) begin
                case(addr_i)
                    MSIP_ADDR: begin
                        if(we_i[0])
                            msip <= wdata_i[0];
                    end
                    MTIMECMP_LO_ADDR: begin
                        mtimecmp[31:0] <= apply_byte_enables(mtimecmp[31:0], wdata_i, we_i);
                    end
                    MTIMECMP_HI_ADDR: begin
                        mtimecmp[63:32] <= apply_byte_enables(mtimecmp[63:32], wdata_i, we_i);
                    end
                    MTIME_LO_ADDR: begin
                        mtime[31:0] <= apply_byte_enables(mtime[31:0], wdata_i, we_i);
                    end
                    MTIME_HI_ADDR: begin
                        mtime[63:32] <= apply_byte_enables(mtime[63:32], wdata_i, we_i);
                    end
                    EXT_IRQ_ADDR: begin
                        if(we_i[1] && wdata_i[11])
                            meip <= wdata_i[31];
                    end
                endcase
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            rdata_o <= 32'b0;
            rvalid_o <= 1'b0;
        end else begin
            rvalid_o <= req_i && !(|we_i);

            if(req_i && !(|we_i)) begin
                case(addr_i)
                    MSIP_ADDR:
                        rdata_o <= {31'b0, msip};
                    MTIMECMP_LO_ADDR:
                        rdata_o <= mtimecmp[31:0];
                    MTIMECMP_HI_ADDR:
                        rdata_o <= mtimecmp[63:32];
                    MTIME_LO_ADDR:
                        rdata_o <= mtime[31:0];
                    MTIME_HI_ADDR:
                        rdata_o <= mtime[63:32];
                    EXT_IRQ_ADDR:
                        rdata_o <= {20'b0, meip, 11'b0};
                    default:
                        rdata_o <= 32'b0; 
                endcase
            end
        end
    end

    function automatic [31:0] apply_byte_enables;
        input [31:0] old_value;
        input [31:0] new_value;
        input [3:0] byte_en;
        integer i;
        begin
            apply_byte_enables = old_value;

            for(i = 0; i < 4; i = i + 1) begin
                if(byte_en[i]) begin
                    apply_byte_enables[i*8 +: 8] = new_value[i*8 +: 8];
                end
            end
        end
    endfunction

endmodule
