// カメラからの入力データをデコードする回路

module cap_decoder 
(
    input           PCLK,           // カメラクロック
    input  [7:0]    CAMDATA,        // 画像入力
    input           HREF,           // 画像有効 (High-A)
    input           VSYNC,          // 垂直同期信号 (High-A)
    input  [1:0]    RESOL,          // 解像度

    output          FIFO_WR,        // FIFO書き込み
    output [47:0]   FIFO_DIN        // 書き込みデータ (48bit)
);

reg [1:0] cnt = 2'b00;

reg [7:0]  U  = 8'h00;
reg [7:0]  Y0 = 8'h00;
reg [7:0]  V  = 8'h00;
reg [7:0]  Y1 = 8'h00;

reg        READY = 1'b0;
reg [10:0] HCNT = 11'h0;
reg [10:0] VCNT = 11'h0;

// Save CAMDATA
always @ ( posedge PCLK ) begin
    if (HREF == 1'b1) begin
        case (cnt)
            2'b00: U  <= CAMDATA[7:0];
            2'b01: Y0 <= CAMDATA[7:0];
            2'b10: V  <= CAMDATA[7:0];
            2'b11: Y1 <= CAMDATA[7:0];
        endcase
    end
end

// READY
always @ ( posedge PCLK ) begin
    if (cnt == 2'b11)
        READY <= 1'b1;
    else
        READY <= 1'b0;
end

// cnt
always @ ( posedge PCLK ) begin
    if (HREF == 1'b0)
        cnt <= 2'b00;
    else if (cnt == 2'b11)
        cnt <= 2'b00;
    else
        cnt <= cnt + 1'b1;
end

// HCNT
always @ ( posedge PCLK ) begin
    if (VSYNC)
        HCNT <= 11'h0;
    else if (HCNT == 11'h500) // 1280
        HCNT <= 11'h0;
    else if (cnt == 2'b11)
        HCNT <= HCNT + 2'h2;
end

// VCNT
always @ ( posedge PCLK ) begin
    if (VSYNC)
        VCNT <= 11'h0;
    else if (VCNT == 11'h400) // 1024
        VCNT <= 11'h0;
    else if (HCNT == 11'h500)
        VCNT <= VCNT + 1'b1;
end

assign NO_CAP = (RESOL == 2'b01) ? ((VCNT > 11'h7F) && (VCNT < 11'h380) &&
                                    (HCNT > 11'h7F) && (HCNT < 11'h480)): 1'b1;
yuv2rgb yuv2rgb (
    .PCLK   (PCLK),
    .U      (U),
    .Y0     (Y0),
    .V      (V),
    .Y1     (Y1),
    .READY  (READY && NO_CAP),
    .VALID  (FIFO_WR),
    .RGB    (FIFO_DIN)
);

endmodule //cap_decoder
