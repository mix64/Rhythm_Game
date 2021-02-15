// 描画回路用VRAM読み込みモジュール

/*
vramctrl側でFIFOを見るので、EMPTYを監視しながら、
EMPTYになったらmkaddrから必要なアドレスを取得する。(READYも出す)
監視:src_fifo.EMPTY,dst_fifo.EMPTY,wrt_fifo.FULL
ソースアドレス発行->SRC_READY->ソース読み->背景読みアドレス発行->背景読み->
    ->(wrt_fifo.FULL待つ)->背景書きアドレス発行->DST_READY->背景書き込み
*/
/*
どのパターンでもFIFOに書き込むことで、Pixel作成は脳死で取り出して書き込むことができるのでは。
こっちもいろいろ区別化する必要がないので順番通りにステートマシンを進めていくことができるのでは
ブレンドアルファのあるなしで区別、PATBLTはsrcFIFOへ突っ込む。
ただでさえブレンドアルファで複雑になるのでPixelの簡略化をしたい。
*/

module drw_vramctrl_rd
(
    /* System signals */
    input               ACLK,
    input               ARST,
    input               RST,

    /* FIFO buffer wire */
    input               SRC_FIFO_almostFULL,
    input               SRC_FIFO_FULL,
    output              SRC_FIFO_WR,
    output      [31:0]  SRC_FIFO_DIN,
    input               DST_FIFO_almostFULL,
    input               DST_FIFO_FULL,
    output              DST_FIFO_WR,
    output      [31:0]  DST_FIFO_DIN,

    /* address from mkaddr */
    input               ADDR_VALID,
    input       [28:0]  SRC_ADDR,
    input        [7:0]  SRC_LEN,
    input               SRC_FIN,
    output              SRC_COMMIT,
    input       [28:0]  DST_ADDR,
    input        [7:0]  DST_LEN,
    input               DST_FIN,
    output              DST_COMMIT,

    /* draw style from drw_cmd */
    input               BLEND_ALPHA,    /* 0:OFF, 1:ON */
    input               BLT_CMD,        /* 0:PAT, 1:BIT */
    input               TEXTURE_FMT,    /* 0:ARGB, 1:RGB */

    /* AXI: Address Read Channel */
    input               ARREADY,
    output              ARVALID,
    output      [31:0]  ARADDR,
    output       [7:0]  ARLEN,
    output       [2:0]  ARSIZE,

    /* AXI: Read Channel */
    output              RREADY,
    input               RVALID,
    input               RLAST,
    input       [31:0]  RDATA,
    input        [1:0]  RRESP  /* 読み出し応答, 2'b00:OK, 2'b10:Error */
);

/* draw command status */
wire [1:0] draw_cmd = {BLT_CMD, BLEND_ALPHA};
localparam PAT_OFF   = 2'b00;
localparam PAT_ALPHA = 2'b01;
localparam BIT_OFF   = 2'b10;
localparam BIT_ALPHA = 2'b11;

/* State parameter */
localparam S_IDLE          = 4'b0000;
localparam S_PAT_ALPHA_S   = 4'b0001;
localparam S_PAT_ALPHA_R   = 4'b0010;
localparam S_BIT_OFF_S     = 4'b0011;
localparam S_BIT_OFF_R     = 4'b0100;
localparam S_BIT_ALPHA_SS  = 4'b0101; /* set src */
localparam S_BIT_ALPHA_RS  = 4'b0110; /* read src */
localparam S_BIT_ALPHA_SD  = 4'b0111; /* set dst */
localparam S_BIT_ALPHA_RD  = 4'b1000; /* read dst */
localparam S_WAIT           = 4'b1111;

/* State register */
reg [3:0] State     = 4'b0000;
reg [3:0] nextState = 4'b0000;

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
            if (ADDR_VALID) begin
                if (draw_cmd == PAT_OFF) /* PATBLT (BLEND OFF) don't used this module */
                    nextState <= State;
                else if (draw_cmd == PAT_ALPHA) /* PATBLT (BLEND ON) */
                    nextState <= S_PAT_ALPHA_S;
                else if (draw_cmd == BIT_OFF) /* BITBLT(BLEND OFF) */
                    nextState <= S_BIT_OFF_S;
                else /* BITBLT(BLEND ON) */
                    nextState <= S_BIT_ALPHA_SS;
            end
            else
                nextState <= State;

/*
 *  PATBLT (BLEND ON)
 */
        S_PAT_ALPHA_S:
            if (ARVALID && ARREADY)
                nextState <= S_PAT_ALPHA_R;
            else
                nextState <= State;

        S_PAT_ALPHA_R:
            if (RVALID && RREADY && RLAST) begin
                if (DST_FIN)
                    nextState <= S_WAIT;
                else
                    nextState <= S_PAT_ALPHA_S;
            end
            else
                nextState <= State;

/*
 *  BITBLT (BLEND OFF)
 */

    S_BIT_OFF_S:
            if (ARVALID && ARREADY)
                nextState <= S_BIT_OFF_R;
            else
                nextState <= State;

    S_BIT_OFF_R:
            if (RVALID && RREADY && RLAST) begin
                if (SRC_FIN)
                    nextState <= S_WAIT;
                else
                    nextState <= S_BIT_OFF_S;
            end
            else
                nextState <= State;

/*
 *  BITBLT (BLEND ON)
 */
        S_BIT_ALPHA_SS:
            if (ARVALID && ARREADY)
                nextState <= S_BIT_ALPHA_RS;
            else
                nextState <= State;

        S_BIT_ALPHA_RS:
            if (RVALID && RREADY && RLAST)
                nextState <= S_BIT_ALPHA_SD;
            else
                nextState <= State;

        S_BIT_ALPHA_SD:
            if (ARVALID && ARREADY)
                nextState <= S_BIT_ALPHA_RD;
            else
                nextState <= State;

        S_BIT_ALPHA_RD:
            if (RVALID && RREADY && RLAST) begin
                if (DST_FIN)
                    nextState <= S_WAIT;
                else
                    nextState <= S_BIT_ALPHA_SS;
            end
            else
                nextState <= State;

        S_WAIT:
            if (ADDR_VALID)
                nextState <= State;
            else
                nextState <= S_IDLE;

        default: nextState <= S_IDLE;
    endcase
end

// wire setsrc, setdst, readsrc, readdst;
wire setsrc = ((State == S_BIT_ALPHA_SS) || (State == S_BIT_OFF_S));
wire setdst = ((State == S_BIT_ALPHA_SD) || (State == S_PAT_ALPHA_S));
wire readsrc = ((State == S_BIT_ALPHA_RS) || (State == S_BIT_OFF_R));
wire readdst = ((State == S_BIT_ALPHA_RD) || (State == S_PAT_ALPHA_R));

assign SRC_COMMIT = (setsrc && ARVALID && ARREADY);
assign DST_COMMIT = (setdst && ARVALID && ARREADY);

/* AXI */
assign ARVALID = (setsrc || setdst);
assign ARADDR = (setsrc) ? SRC_ADDR[28:0]:
                (setdst) ? DST_ADDR[28:0]: 29'h0;
assign ARLEN =  (setsrc) ? SRC_LEN[7:0]:
                (setdst) ? DST_LEN[7:0]: 8'h0;
assign ARSIZE = 3'b010; /* 4Byte (32bit) */
assign RREADY = (readsrc) ? !SRC_FIFO_almostFULL:
                (readdst) ? !DST_FIFO_almostFULL: 1'b0;

/* FIFOs */
assign SRC_FIFO_WR = (readsrc && RREADY && RVALID);
assign DST_FIFO_WR = (readdst && RREADY && RVALID);
assign SRC_FIFO_DIN = (readsrc) ? (TEXTURE_FMT) ? {8'hFF, RDATA[23:0]}: RDATA[31:0]: 32'h0;
assign DST_FIFO_DIN = (readdst) ? RDATA[31:0]: 32'h0;

reg [31:0] debug_src;
always @ ( posedge ACLK ) begin
    if (ARST|RST) begin
        debug_src <= 32'h0;
    end
    else begin
        if (SRC_FIFO_WR)
            debug_src <= debug_src + 1'b1;
    end
end

endmodule // drw_vramctrl_rd
