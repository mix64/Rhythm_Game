// 描画回路用VRAM書き出しモジュール

/*
vramctrl側でFIFOを見るので、EMPTYを監視しながら、
EMPTYになったらmkaddrから必要なアドレスを取得する。(READYも出す)
監視:src_fifo.EMPTY,dst_fifo.EMPTY,wrt_fifo.FULL
ソースアドレス発行->SRC_READY->ソース読み->背景読みアドレス発行->背景読み->
    ->(wrt_fifo.FULL待つ)->背景書きアドレス発行->DST_READY->背景書き込み

    パターンでブレンドアルファがない場合、pixel使わないっていうのもありかも
*/

module drw_vramctrl_wr
(
    /* System signals */
    input               ACLK,
    input               ARST,
    input               RST,

    /* FIFO buffer wire */
    input               WRT_FIFO_almostEMPTY,
    input               WRT_FIFO_EMPTY,
    output              WRT_FIFO_RD,
    input               WRT_FIFO_VALID,
    input       [31:0]  WRT_FIFO_DOUT,

    /* address from mkaddr */
    input               ADDR_VALID,
    input       [28:0]  WRT_ADDR,
    input        [7:0]  WRT_LEN,
    input               WRT_FIN,
    output              WRT_COMMIT,

    /* draw style from drw_cmd */
    input               BLEND_ALPHA,    /* 0:OFF, 1:ON */
    input               BLT_CMD,        /* 0:PAT, 1:BIT */

    /* draw param from drw_cmd (esp:stmode when BIT_OFF) */
    input               STEALTH_MODE,
    input        [3:0]  STEALTH_MASK,
    input       [31:0]  STEALTH_COLOR_L,
    input       [31:0]  STEALTH_COLOR_H,

    /* AXI: Address Write Channel */
    input               AWREADY,
    output              AWVALID,
    output      [31:0]  AWADDR,
    output       [7:0]  AWLEN,
    output       [2:0]  AWSIZE,

    /* AXI: Write Channel */
    input               WREADY,
    output              WVALID,
    output              WLAST,
    output      [31:0]  WDATA,
    output reg   [3:0]  WSTRB,  /* Byte Enable */

    /* AXI: B Channnel */
    output              BREADY,
    input               BVALID,
    input        [1:0]  BRESP   /* 書き込み応答, 2'b00:OK, 2'b10:Error */
);

/* draw command status */
wire [1:0] draw_cmd = {BLT_CMD, BLEND_ALPHA};
localparam PAT_OFF   = 2'b00;
localparam PAT_ALPHA = 2'b01;
localparam BIT_OFF   = 2'b10;
localparam BIT_ALPHA = 2'b11;

/* state parameter */
localparam S_IDLE      = 3'b000;
localparam S_SETADDR   = 3'b001;
localparam S_WRITE     = 3'b010;
localparam S_WAITB     = 3'b011;
localparam S_FIN       = 3'b111;

/* State register */
reg [2:0] State     = 3'b000;
reg [2:0] nextState = 3'b000;

/* register */
reg  [7:0] wr_cnt = 8'h00;          /* write counter */
reg  [7:0] LEN = 8'h00;

drw_wrtfifo_wrapper drw_wrtfifo_wrapper (
    .ACLK           (ACLK),
    .ARST           (ARST),
    .RST            (RST),
    .ADDR_VALID     (ADDR_VALID),
    .WRT_FIN        (WRT_FIN),
    .almostEMPTY    (WRT_FIFO_almostEMPTY),
    .EMPTY          (WRT_FIFO_EMPTY),
    .VALID          (WRT_FIFO_VALID),
    .RD             (WRT_FIFO_RD),
    .DOUT           (WRT_FIFO_DOUT),
    .WREADY         (WREADY && (State == S_WRITE)),
    .WVALID         (WVALID),
    .WDATA          (WDATA)
);

/* State */
always @ ( posedge ACLK ) begin
    if (ARST || RST)
        State <= S_IDLE;
    else
        State <= nextState;
end

/* nextState */
always @ ( * ) begin
    case (State)
        S_IDLE:
            if (ADDR_VALID)
                nextState <= S_SETADDR;
            else
                nextState <= State;

        S_SETADDR:
            if (AWVALID && AWREADY)
                    nextState <= S_WRITE;
            else
                nextState <= State;

        S_WRITE:
            if (WVALID && WREADY && WLAST) begin
                if (WRT_FIN)
                    nextState <= S_FIN;
                else
                    nextState <= S_WAITB;
            end
            else
                nextState <= State;

        S_WAITB:
            if (BVALID)
                nextState <= S_SETADDR;
            else
                nextState <= State;
        
        S_FIN:
            if (ADDR_VALID)
                nextState <= State;
            else
                nextState <= S_IDLE;

        default:
            nextState <= S_IDLE;

    endcase
end

/* LEN (save to localreg) */
always @ ( posedge ACLK ) begin
    if (ARST | RST)
        LEN <= 8'h00;
    else if (WRT_COMMIT)
        LEN <= AWLEN;
end

/* wr_cnt */
always @ ( posedge ACLK ) begin
    if (ARST || RST)
        wr_cnt <= 8'h00;
    else if (WVALID && WREADY) begin
        if (WLAST)
            wr_cnt <= 8'h00;
        else
            wr_cnt <= wr_cnt + 1'b1;
    end
end

wire st0 = (STEALTH_MASK[0] || (WDATA[7:0] >= STEALTH_COLOR_L[7:0] && WDATA[7:0] <= STEALTH_COLOR_H[7:0]));

/* WSTRB */
always @ (*) begin
    if (STEALTH_MODE) begin /* BLEND_OFF && STEALTH */
        /* 不使用なら無条件1, 使用かつ未成立で0, ALL1時に透過 */
        if ((STEALTH_MASK[0] || (WDATA[7:0] >= STEALTH_COLOR_L[7:0] && WDATA[7:0] <= STEALTH_COLOR_H[7:0]))
        &&  (STEALTH_MASK[1] || (WDATA[15:8] >= STEALTH_COLOR_L[15:8] && WDATA[15:8] <= STEALTH_COLOR_H[15:8]))       
        &&  (STEALTH_MASK[2] || (WDATA[23:16] >= STEALTH_COLOR_L[23:16] && WDATA[23:16] <= STEALTH_COLOR_H[23:16]))
        &&  (STEALTH_MASK[3] || (WDATA[31:24] >= STEALTH_COLOR_L[31:24] && WDATA[31:24] <= STEALTH_COLOR_H[31:24]))) 
            WSTRB <= 4'b0000;
        else
            WSTRB <= 4'b1111;
    end
    else
        WSTRB <= 4'b1111;
end

assign WRT_COMMIT = (AWVALID && AWREADY);

/* AXI */
assign AWVALID = (State == S_SETADDR);
assign AWADDR = WRT_ADDR[28:0];
assign AWLEN = WRT_LEN[7:0];
assign AWSIZE = 3'b010; /* 4Byte (32bit) */
assign WLAST = (wr_cnt == LEN);
assign BREADY = 1'b1;


reg [31:0] debug_wrt;
always @ ( posedge ACLK ) begin
    if (ARST|RST) begin
        debug_wrt <= 32'h0;
    end
    else begin
        if (WRT_FIFO_RD)
            debug_wrt <= debug_wrt + 1'b1;
    end
end

endmodule // drw_vramctrl_wr
