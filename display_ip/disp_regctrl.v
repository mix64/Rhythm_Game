// 表示回路のコントロールレジスタ

module disp_regctrl
  (
    // System Signals
    input               ACLK,
    input               ARST,

    /* VSYNC */
    input               DSP_VSYNC_X,

    /* レジスタバス */
    input       [15:0]  WRADDR,
    input       [3:0]   BYTEEN,
    input               WREN,
    input       [31:0]  WDATA,
    input       [15:0]  RDADDR,
    input               RDEN,
    output  reg [31:0]  RDATA,

    /* レジスタ出力 */
    output              DISPON,
    output      [28:0]  DISPADDR,

    /* 割り込み、FIFOフラグ */
    output  reg         DSP_IRQ,
    input               BUF_UNDER,
    input               BUF_OVER
    );


reg [31:0] regDISPADDR;
reg [31:0] regDISPCTRL;
reg [31:0] regDISPINT;
reg [31:0] regDISPFIFO;
reg [2:0]  regVSYNC;

// sync DSP_VSYNC_X
always @ ( posedge ACLK ) begin
    if (ARST)
        regVSYNC[2:0] <= 3'b111;
    else
        regVSYNC[2:0] <= { regVSYNC[1:0], DSP_VSYNC_X };
end

// DISPADDR
always @ ( posedge ACLK ) begin
    if (ARST)
        regDISPADDR[31:0] <= 32'h0000_0000;
    else if (WREN && (WRADDR == 16'h0000)) begin
        if (BYTEEN[3])
            regDISPADDR[31:24] <= {3'b000, WDATA[28:24]};
        if (BYTEEN[2])
            regDISPADDR[23:16] <= WDATA[23:16];
        if (BYTEEN[1])
            regDISPADDR[15:8] <= WDATA[15:8];
        if (BYTEEN[0])
            regDISPADDR[7:0] <= {WDATA[7:2], 2'b00};
    end
end

// DISPCTRL
always @ ( posedge ACLK ) begin
    if (ARST)
        regDISPCTRL[31:0] <= 32'h0000_0000;
    else begin
        // DISPON (R/W)
        if (WREN && (WRADDR == 16'h0004) && BYTEEN[0]) begin
            if (WDATA[0])
                regDISPCTRL[0] <= 1'b1;
            else
                regDISPCTRL[0] <= 1'b0;
        end
        // VBLANK
        if (WREN && (WRADDR == 16'h0004) && BYTEEN[0] && WDATA[1])
            regDISPCTRL[1] <= 1'b0;
        else if (~regVSYNC[1] && regVSYNC[2])
            regDISPCTRL[1] <= 1'b1;
    end
end

// DISPINT
always @ ( posedge ACLK ) begin
    if (ARST)
        regDISPINT[31:0] <= 32'h0000_0000;
    else if (WREN && (WRADDR == 16'h0008) && BYTEEN[0]) begin
        if (WDATA[0]) // INTENBL (R/W)
            regDISPINT[0] <= 1'b1;
        else
            regDISPINT[0] <= 1'b0;
    end
end

// DISPFIFO
always @ ( posedge ACLK ) begin
    if (ARST)
        regDISPFIFO[31:0] <= 32'h0000_0000;
    else if (WREN && (WRADDR == 16'h000C) && BYTEEN[0]) begin
        if (WDATA[1])
            regDISPFIFO[1] <= 1'b0;
        if (WDATA[0])
            regDISPFIFO[0] <= 1'b0;
    end
    else begin
        if (BUF_OVER)
            regDISPFIFO[1] <= 1'b1;
        if (BUF_UNDER)
            regDISPFIFO[0] <= 1'b1;
    end
end

// read
always @ ( posedge ACLK ) begin
    if (ARST)
        RDATA[31:0] <= 32'd0;
    else if (RDEN) begin
        case (RDADDR)
            16'h0000: RDATA[31:0] <= regDISPADDR[31:0];
            16'h0004: RDATA[31:0] <= regDISPCTRL[31:0];
            16'h0008: RDATA[31:0] <= regDISPINT [31:0];
            16'h000C: RDATA[31:0] <= regDISPFIFO[31:0];
            default:  RDATA[31:0] <= 32'hDEADFACE;
        endcase
    end
end

// DSP_IRQ
always @ ( posedge ACLK ) begin
    if (ARST)
        DSP_IRQ <= 1'b0;
    else if (~regVSYNC[1] && regVSYNC[2])
        DSP_IRQ <= 1'b1;
    else if (WDATA[1] && WREN && (WRADDR == 16'h0008) && BYTEEN[0])
        DSP_IRQ <= 1'b0;
end

assign DISPADDR = regDISPADDR[28:0];
assign DISPON = regDISPCTRL[0];

endmodule
