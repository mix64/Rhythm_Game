// 描画回路のコントロールレジスタ

module drw_regctrl
(
    /* System Signals */
    input                   ACLK,
    input                   ARST,

    /* regbus */
    input          [15:0]   WRADDR,
    input          [3:0]    BYTEEN,
    input                   WREN,
    input          [31:0]   WDATA,
    input          [15:0]   RDADDR,
    input                   RDEN,
    output  reg    [31:0]   RDATA,

    /* command buffer fifo wire */
    input          [10:0]   DATA_CNT,
    output                  FIFO_WR,
    output         [31:0]   FIFO_DIN,
    input                   FIFO_EMPTY,
    input                   FIFO_FULL,

    /* draw finish interrupt */
    output  reg             DRW_IRQ,

    /* Status wire  */
    output                  RST,
    output                  EXE,
    input                   DRAW_FINISH,
    input          [15:0]   ERRNO
);

reg [31:0] DRAWCTRL     = 32'h0000_0000;
reg [31:0] DRAWSTAT     = 32'h0000_0000;
reg [31:0] DRAWINT      = 32'h0000_0000;

/* DRAWCTRL */
always @ ( posedge ACLK ) begin
    if (ARST)
        DRAWCTRL[31:0] <= 32'h0000_0000;
    else if (WREN && (WRADDR == 16'h2000) && BYTEEN[0]) begin
            if (WDATA[0]) /* EXE */
                DRAWCTRL[1:0] <= 2'b01;
            else if (WDATA[1]) /* RST */
                DRAWCTRL[1:0] <= 2'b10;
    end
end

/* DRAWSTAT */
always @ ( posedge ACLK ) begin
    if (ARST)
        DRAWSTAT[31:0] <= 32'h0000_0000;
    else begin
        if (DRAW_FINISH)
            DRAWSTAT[0] <= 1'b0;
        else if (WREN && (WRADDR == 16'h2000) && BYTEEN[0]) begin
            if (WDATA[0]) /* EXE */
                DRAWSTAT[0] <= 1'b1;
            else if (WDATA[1]) /* RST */
                DRAWSTAT[0] <= 1'b0;
        end
        // DRAWSTAT[31:16] <= DRAWSTAT[31:16] | ERRNO[15:0]; /* One-Hot */
    end
end

/* DRAWINT */
always @ ( posedge ACLK ) begin
    if (ARST)
        DRAWINT[31:0] <= 32'h0000_0000;
    else if (WREN && (WRADDR == 16'h2010) && BYTEEN[0]) begin
        if (WDATA[0]) // INTENBL (R/W)
            DRAWINT[0] <= 1'b1;
        else
            DRAWINT[0] <= 1'b0;
    end
end

/* read */
always @ ( posedge ACLK ) begin
    if (ARST)
        RDATA[31:0] <= 32'd0000_0000;
    else if (RDEN) begin
        case (RDADDR)
            16'h2000: RDATA[31:0] <= DRAWCTRL[31:0];
            16'h2004: RDATA[31:0] <= DRAWSTAT[31:0];
            16'h2008: RDATA[31:0] <= {14'h0, FIFO_FULL, FIFO_EMPTY, 5'h0, DATA_CNT[10:0]};
            16'h2010: RDATA[31:0] <= DRAWINT[31:0];
            default:  RDATA[31:0] <= 32'hDEADFACE;
        endcase
    end
end

/* posedge of DRAW_FINISH */
reg [1:0] finish_ff = 2'b00;
always @ ( posedge ACLK ) begin
    finish_ff[1:0] <= {finish_ff[0], DRAW_FINISH};
end

/* DRAW_IRQ */
always @ ( posedge ACLK ) begin
    if (ARST)
        DRW_IRQ <= 1'b0;
    else if (finish_ff[0] && !finish_ff[1] && DRAWINT[0])
        DRW_IRQ <= 1'b1;
    else if (WDATA[1] && WREN && (WRADDR == 16'h2010) && BYTEEN[0])
        DRW_IRQ <= 1'b0;
end

assign RST = (WREN && (WRADDR == 16'h2000) && BYTEEN[0] && WDATA[1]);
assign EXE = DRAWCTRL[0];
assign FIFO_DIN = WDATA[31:0];
assign FIFO_WR = (WREN && (WRADDR == 16'h200C));

endmodule
