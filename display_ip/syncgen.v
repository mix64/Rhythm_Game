// 表示同期用回路

module syncgen(
    input               DCLK,
    input               DRST,
    input       [1:0]   RESOL,
    output  reg         DSP_HSYNC_X,
    output  reg         DSP_VSYNC_X,
    output  reg         DSP_preDE,
    output  reg         VRSTART
);

`include "syncgen_param.vh"

reg [10:0] HCNT;
reg [10:0] VCNT;

// DSP_HSYNC_X
always @ (posedge DCLK) begin
    if (HCNT >= HFP-1 && HCNT < HFP+HPW-1) begin
        DSP_HSYNC_X <= 1'b0;
    end
    else begin
        DSP_HSYNC_X <= 1'b1;
    end
end

// DSP_VSYNC_X
always @ (posedge DCLK) begin
    if (VCNT == VFP && HCNT >= HFP-1) begin
        DSP_VSYNC_X <= 1'b0;
    end
    else if (VCNT > VFP && VCNT < VFP+VPW) begin
        DSP_VSYNC_X <= 1'b0;
    end
    else if (VCNT == VFP+VPW && HCNT < HFP-1) begin
        DSP_VSYNC_X <= 1'b0;
    end
    else begin
        DSP_VSYNC_X <= 1'b1;
    end
end

// DSP_preDE @ 2CLK before
always @ (posedge DCLK) begin
    if ((HCNT >= HFP+HPW+HBP-3 && HCNT < HSC-3) && (VCNT >= VFP+VPW+VBP && VCNT < VSC)) begin
        DSP_preDE <= 1'b1;
    end
    else begin
        DSP_preDE <= 1'b0;
    end
end

// VRSTART
always @ ( posedge DCLK ) begin
    if ((HCNT == HFP+HPW+HBP-1) && (VCNT == VFP+VPW+VBP-1)) begin
        VRSTART <= 1'b1;
    end
    else begin
        VRSTART <= 1'b0;
    end
end

// HCNT
always @ ( posedge DCLK ) begin
    if (DRST || HCNT == (HSC-1)) begin
        HCNT <= 0;
    end
    else begin
        HCNT <= HCNT + 1'b1;
    end
end

// VCNT
always @ ( posedge DCLK ) begin
    if (DRST) begin
        VCNT <= 0;
    end
    else if (HCNT == (HSC-1)) begin
        if (VCNT == (VSC-1)) begin
            VCNT <= 0;
        end
        else begin
            VCNT <= VCNT + 1'b1;
        end
    end
    else begin
        VCNT <= VCNT;
    end
end

endmodule
