// 描画管理回路
// コマンド解析結果を受け取り、VRAM読み込み/書き出し回路にアドレスを渡す

module drw_mkaddr
(
    /* System signals */
    input               ACLK,
    input               ARST,
    input               RST,

    /* wait block transfer */
    input               BLT_WAIT,
    output              BLT_FINISH,

    /* address -> vramctrl */
    output      [28:0]  SRC_ADDR,
    output       [7:0]  SRC_LEN,
    output              SRC_FIN,
    input               SRC_COMMIT,
    output      [28:0]  DST_ADDR,
    output       [7:0]  DST_LEN,
    output              DST_FIN,
    input               DST_COMMIT,
    output      [28:0]  WRT_ADDR,
    output       [7:0]  WRT_LEN,
    output              WRT_FIN,
    input               WRT_COMMIT,

    output              ADDR_VALID, /* mkaddr is setuped */

    /* sign of vramctrl get address from mkaddr */
    input               AXI_BVALID, /* wrt_len = 0 && BVALID = BLT_FIN */

    /* draw parameter <- drw_cmd */
    input       [28:0]  FRAME_ADDR,
    input       [10:0]  FRAME_WIDTH,
    input       [10:0]  FRAME_HEIGHT,
    input       [10:0]  AREA_POSX,
    input       [10:0]  AREA_POSY,
    input       [10:0]  AREA_SIZX,
    input       [10:0]  AREA_SIZY,
    input       [28:0]  TEXTURE_ADDR,
    input               BLEND_ALPHA,    /* 0:OFF, 1:ON */
    input               BLT_CMD,        /* 0:PAT, 1:BIT */
    input       [11:0]  BLT_DPOSX,
    input       [11:0]  BLT_DPOSY,
    input       [10:0]  BLT_DSIZX,
    input       [10:0]  BLT_DSIZY,
    input       [11:0]  BLT_SPOSX,
    input       [11:0]  BLT_SPOSY
);

/* parameter reg */
reg [10:0] AREA_WIDTH;
reg [10:0] AREA_HEIGHT;
reg [10:0] DPOSX;
reg [10:0] DPOSY;
reg [10:0] DSIZX;
reg [10:0] DSIZY;

/* register */
reg   [2:0] State = 3'b00;
reg   [2:0] nextState = 3'b00;

localparam S_IDLE = 3'b000;
localparam S_WAIT1 = 3'b001;
localparam S_WAIT2 = 3'b010;
localparam S_SET  = 3'b011;
localparam S_RUN  = 3'b100;
localparam S_FIN  = 3'b101;

/* BLT,BLENDで4パターンで考える */
/* 読み出す量を決定すれば書き込む量は決まるので、ここでしっかり読み出し量を把握させてBLT_FINISHを出す */
/* 書き込むデータ量が32(AWLEN:バースト長)の倍数じゃないと無理ゲーでは ->WSTRB (ByteEnable)を使用する？ */
/* FRAME_ADDR -> ベースアドレス */
/* 書き込みバッファと書き込みエリアの論理積の部分が書き込みフレーム */
/* POS+cnt(<SIZ)からアドレスを計算して、書き込みフレーム内かどうか確認？ -> 組み合わせ回路でモジュール化？ */
/* Y=WR_ADDR/WIDTH, X=WR_ADDR-POSY*WIDTH */
/* X>POSX && X<POSX+A_WIDTH && Y>POSY && Y<POSY+A_HEIGHT */
/* 描画エリアとdstの論理積を取ったエリアPOSX,Y, SIZX,YからAREA_WIDTH,HEIGHTを導く事で3つの論理積 */
/* 出力アドレスはsrc_addr,dst_addrのみで良い。vramctrlで管理する。 */

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
            if (BLT_WAIT)
                nextState <= S_WAIT1;
            else
                nextState <= State;
        
        S_WAIT1: nextState <= S_WAIT2;
        S_WAIT2: nextState <= S_SET;

        S_SET: nextState <= S_RUN;
        
        S_RUN:
            if (BLT_FINISH)
                nextState <= S_FIN;
            else 
                nextState <= State;
        
        S_FIN: nextState <= S_IDLE;
        default: nextState <= S_IDLE;
    endcase
end

/* WIDTH, HEIGHT, DPOS */
always @ ( posedge ACLK ) begin
    if (ARST || RST) begin
        AREA_WIDTH <= 11'h0;
        AREA_HEIGHT <= 11'h0;
        DPOSX <= 11'h0;
        DPOSY <= 11'h0;
    end
    else if (nextState == S_WAIT1) begin
        if ((AREA_POSX + AREA_SIZX) > FRAME_WIDTH)
            AREA_WIDTH <= FRAME_WIDTH - AREA_POSX;
        else
            AREA_WIDTH <= AREA_SIZX;
        if ((AREA_POSY + AREA_SIZY) > FRAME_HEIGHT)
            AREA_HEIGHT <= FRAME_HEIGHT - AREA_POSY;
        else
            AREA_HEIGHT <= AREA_SIZY;
        /* TODO: DPOSが負のときにも対応して */
        if (BLT_DPOSX > AREA_POSX)
            DPOSX <= BLT_DPOSX;
        else
            DPOSX <= AREA_POSX;
        if (BLT_DPOSY > AREA_POSY)
            DPOSY <= BLT_DPOSY;
        else
            DPOSY <= AREA_POSY;
    end
end

/* DSIZ */
always @ ( posedge ACLK ) begin
    if (ARST || RST) begin
        DSIZX <= 11'h0;
        DSIZY <= 11'h0;
    end
    else if (nextState == S_WAIT2) begin
        if (AREA_WIDTH > BLT_DSIZX) begin
            if (BLT_DPOSX+BLT_DSIZX > AREA_WIDTH)
                DSIZX <= AREA_WIDTH - BLT_DPOSX;
            else 
                DSIZX <= BLT_DSIZX;
        end
        else
            DSIZX <= AREA_WIDTH;
        if (AREA_HEIGHT > BLT_DSIZY) begin
            if (BLT_DPOSY+BLT_DSIZY > AREA_HEIGHT)
                DSIZY <= AREA_HEIGHT - BLT_DPOSY;
            else 
                DSIZY <= BLT_DSIZY;
        end
        else
            DSIZY <= AREA_HEIGHT;
    end
end

drw_mkaddr_op src_op (
    .ACLK           (ACLK),
    .ARST           (ARST),
    .RST            (RST),
    .SET            (State == S_SET),
    .FIN            (SRC_FIN),
    .BASE_ADDR      (TEXTURE_ADDR),
    .FRAME_WIDTH    (FRAME_WIDTH),
    .POSX           (BLT_SPOSX[10:0]),
    .POSY           (BLT_SPOSY[10:0]),
    .SIZX           (DSIZX),
    .SIZY           (DSIZY),
    .ADDR           (SRC_ADDR),
    .COMMIT         (SRC_COMMIT),
    .AXLEN          (SRC_LEN)
);

drw_mkaddr_op dst_op (
    .ACLK           (ACLK),
    .ARST           (ARST),
    .RST            (RST),
    .SET            (State == S_SET),
    .FIN            (DST_FIN),
    .BASE_ADDR      (FRAME_ADDR),
    .FRAME_WIDTH    (FRAME_WIDTH),
    .POSX           (DPOSX),
    .POSY           (DPOSY),
    .SIZX           (DSIZX),
    .SIZY           (DSIZY),
    .ADDR           (DST_ADDR),
    .COMMIT         (DST_COMMIT),
    .AXLEN          (DST_LEN)
);

drw_mkaddr_op wrt_op (
    .ACLK           (ACLK),
    .ARST           (ARST),
    .RST            (RST),
    .SET            (State == S_SET),
    .FIN            (WRT_FIN),
    .BASE_ADDR      (FRAME_ADDR),
    .FRAME_WIDTH    (FRAME_WIDTH),
    .POSX           (DPOSX),
    .POSY           (DPOSY),
    .SIZX           (DSIZX),
    .SIZY           (DSIZY),
    .ADDR           (WRT_ADDR),
    .COMMIT         (WRT_COMMIT),
    .AXLEN          (WRT_LEN)
);

assign BLT_FINISH = (WRT_FIN && AXI_BVALID);
assign ADDR_VALID = (State == S_RUN);

endmodule // drw_mkaddr
