// キャプチャ回路のコントロールレジスタ

module cap_regctrl
  (
    // System Signals
    input                  ACLK,
    input                  ARST,

    /* VSYNC */
    input                  VSYNC,
    input                  HREF,

    /* レジスタバス */
    input          [15:0]  WRADDR,
    input          [3:0]   BYTEEN,
    input                  WREN,
    input          [31:0]  WDATA,
    input          [15:0]  RDADDR,
    input                  RDEN,
    output  reg    [31:0]  RDATA,

    /* 割り込み、FIFOフラグ */
    output  reg            CAP_IRQ,
    input                  FIFO_UNDER,
    input                  FIFO_OVER,

    output         [28:0]  CAP_ADDR,
    output                 CAP_ON
    );


reg [31:0] CAPADDR;
reg [31:0] CAPCTRL;
reg [31:0] CAPINT;
reg [31:0] CAPFIFO;
reg [2:0]  regVSYNC;
reg [1:0]  href_ff;
reg is_valid_frame;

// href_ff HERF同期化
always @ ( posedge ACLK ) begin
    if (ARST || regVSYNC[1])
        href_ff <= 2'b00;
    else
        href_ff <= { href_ff[0], HREF };
end

// is_valid_frame
always @ ( posedge ACLK ) begin
    if (ARST || regVSYNC[1])
        is_valid_frame <= 1'b0;
    else if (href_ff)
        is_valid_frame <= 1'b1;
end

// sync VSYNC
always @ ( posedge ACLK ) begin
    if (ARST)
        regVSYNC[2:0] <= 3'b000;
    else
        regVSYNC[2:0] <= {regVSYNC[1:0], VSYNC};
end

// CAPADDR
always @ ( posedge ACLK ) begin
    if (ARST) begin
        CAPADDR[31:0] <= 32'h0000_0000;
    end
    else if (WREN && (WRADDR == 16'h1000)) begin
        if (BYTEEN[3])
            CAPADDR[31:24] <= {3'b000, WDATA[28:24]};
        if (BYTEEN[2])
            CAPADDR[23:16] <= WDATA[23:16];
        if (BYTEEN[1])
            CAPADDR[15:8] <= WDATA[15:8];
        if (BYTEEN[0])
            CAPADDR[7:0] <= {WDATA[7:2], 2'b00};
    end
end

// CAPCTRL
always @ ( posedge ACLK ) begin
    if (ARST)
        CAPCTRL[31:0] <= 32'h0000_0000;
    else begin
        // CAP_ON (R/W)
        if (WREN && (WRADDR == 16'h1004) && BYTEEN[0]) begin
            if (WDATA[0])
                CAPCTRL[0] <= 1'b1;
            else
                CAPCTRL[0] <= 1'b0;
        end
        // CBLANK (TOW)
        if (WREN && (WRADDR == 16'h1004) && BYTEEN[0] && WDATA[1])
            CAPCTRL[1] <= 1'b0;
        else if (regVSYNC[1] && ~regVSYNC[2] && is_valid_frame)
            CAPCTRL[1] <= 1'b1;
    end
end

// CAPINT
always @ ( posedge ACLK ) begin
    if (ARST)
        CAPINT[31:0] <= 32'h0000_0000;
    else if (WREN && (WRADDR == 16'h1008) && BYTEEN[0]) begin
        if (WDATA[0]) // INTENBL (R/W)
            CAPINT[0] <= 1'b1;
        else
            CAPINT[0] <= 1'b0;
    end
end

// CAPFIFO
always @ ( posedge ACLK ) begin
    if (ARST)
        CAPFIFO[31:0] <= 32'h0000_0000;
    else if (WREN && (WRADDR == 16'h100C) && BYTEEN[0]) begin
        if (WDATA[1])
            CAPFIFO[1] <= 1'b0;
        if (WDATA[0])
            CAPFIFO[0] <= 1'b0;
    end
    else begin
        if (FIFO_OVER)
            CAPFIFO[1] <= 1'b1;
        if (FIFO_UNDER)
            CAPFIFO[0] <= 1'b1;
    end
end

// read
always @ ( posedge ACLK ) begin
    if (ARST)
        RDATA[31:0] <= 32'd0;
    else if (RDEN) begin
        case (RDADDR)
            16'h1000: RDATA[31:0] <= CAPADDR[31:0];
            16'h1004: RDATA[31:0] <= CAPCTRL[31:0];
            16'h1008: RDATA[31:0] <= CAPINT [31:0];
            16'h100C: RDATA[31:0] <= CAPFIFO[31:0];
            default:  RDATA[31:0] <= 32'hDEADFACE;
        endcase
    end
end

// CAP_IRQ
always @ ( posedge ACLK ) begin
    if (ARST)
        CAP_IRQ <= 1'b0;
    else if (regVSYNC[1] && ~regVSYNC[2])
        CAP_IRQ <= 1'b1;
    else if (WDATA[1] && WREN && (WRADDR == 16'h1008) && BYTEEN[0])
        CAP_IRQ <= 1'b0;
end

assign CAP_ADDR = CAPADDR[28:0];
assign CAP_ON = CAPCTRL[0];

endmodule
