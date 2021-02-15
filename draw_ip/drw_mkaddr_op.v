// 描画管理回路の補助モジュール
// 座標を入力に取りアドレスを出力する

module drw_mkaddr_op 
(
    /* System signals */
    input               ACLK,
    input               ARST,
    input               RST,

    /* mkaddr.State == S_SET */
    input               SET,
    output              FIN,

    input       [28:0]  BASE_ADDR,
    input       [10:0]  FRAME_WIDTH,
    input       [10:0]  POSX,
    input       [10:0]  POSY,
    input       [10:0]  SIZX,
    input       [10:0]  SIZY,

    output reg  [28:0]  ADDR,
    input               COMMIT,
    output       [7:0]  AXLEN
);

reg [10:0] hcnt;
reg [10:0] vcnt;
reg [28:0] next_line;
reg [15:0] cmtcnt;

wire [8:0] LEN = (SIZX > 11'hFF) ? (SIZX <= hcnt+11'h100) ? SIZX-hcnt : 9'h100 : SIZX[7:0];
wire nextFlag = (SIZX[10:0] == LEN[8:0] + hcnt[10:0]);
assign AXLEN = LEN[8:0] - 1'b1; /* 0x100 -1 = 0xFF */
assign FIN = (cmtcnt == 16'h0);

/* ADDR */
always @ (posedge ACLK ) begin
    if (ARST | RST)
        ADDR <= 29'h0;
    else if (SET)
        ADDR <= BASE_ADDR + ((POSY * FRAME_WIDTH + POSX) << 2);
    else if (COMMIT) begin
        if (nextFlag)
            ADDR <= next_line;
        else
            ADDR <= ADDR + {LEN[8:0], 2'b00}; /* LENx4 */
    end
end

/* next_line */
always @ ( posedge ACLK ) begin
    if (ARST || RST)
        next_line <= 29'h0;
    else if (SET)
        next_line <= BASE_ADDR + (((POSY+1'b1) * FRAME_WIDTH + POSX) << 2);
    else if (COMMIT && nextFlag)
        next_line <= next_line + (FRAME_WIDTH << 2);
end

/* vcnt, hcnt */
always @ ( posedge ACLK ) begin
    if (ARST || RST || SET) begin
        hcnt <= 11'h0;
        vcnt <= 11'h0;
    end
    else if (COMMIT) begin
        if (nextFlag) begin
            hcnt <= 11'h0;
            vcnt <= vcnt + 1'b1;
        end
        else
            hcnt <= hcnt + 11'h100;
    end
end

/* cmtcnt */
always @ ( posedge ACLK ) begin
    if (ARST || RST)
        cmtcnt <= 16'h0;
    else if (SET)
        cmtcnt <= (SIZX[10:8]+1'b1)*SIZY[10:0];
    else if (COMMIT)
        cmtcnt <= cmtcnt - 1'b1;
end

endmodule // drw_mkaddr_op 