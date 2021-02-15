// pixel合成回路
// 描画コマンドに応じて特定のピクセルに書き込む色を決める。
// ex. 透明度, 反転, ...

module drw_pixel_blend 
(
    /* System signals */
    input               ACLK,
    input               ARST,
    input               RST,

    input       [31:0]  A,
    input       [31:0]  B,
    input       [31:0]  C,
    input       [31:0]  D,
    input       [31:0]  E,
    input               READY,
    input               IGNORE,

    output              VALID,
    output      [31:0]  Z
);


/*
掛け算1回で6nsぐらい使ってしまうので、パイプライン処理を行う。
ABCDEを作成する時点でそこそこ時間を使っているので、A-Bで一つのパイプ
(A-B)*CとD*Eで一つのパイプ、最後に２つの足し算でもう一つのパイプ。
ignore-bitが建っていた場合、pipeDを用いて素通りさせる。

A----|
     -
B----|----|
          *
C----|----|----|
               +--
D----|----|----|
          *
E----|----|

     4    2    1     ... pipe num
000  001  010  100   ... valid_bit, ignore_bit
*/

/* for VALID */
reg [2:0] valid_bit;
reg [2:0] ignore_bit;

/* pipe line */
reg [17:0] pipe1AB_A = 17'h0;
reg [17:0] pipe1AB_R = 17'h0;
reg [17:0] pipe1AB_G = 17'h0;
reg [17:0] pipe1AB_B = 17'h0;
reg [31:0] pipe1C = 32'h0;
reg [31:0] pipe1D = 32'h0;
reg [31:0] pipe1E = 32'h0;
reg [17:0] pipe2ABC_A = 17'h0;
reg [17:0] pipe2ABC_R = 17'h0;
reg [17:0] pipe2ABC_G = 17'h0;
reg [17:0] pipe2ABC_B = 17'h0;
reg [15:0] pipe2DE_A = 16'h0;
reg [15:0] pipe2DE_R = 16'h0;
reg [15:0] pipe2DE_G = 16'h0;
reg [15:0] pipe2DE_B = 16'h0;
reg [17:0] pipe3ABCDE_A = 17'h0;
reg [17:0] pipe3ABCDE_R = 17'h0;
reg [17:0] pipe3ABCDE_G = 17'h0;
reg [17:0] pipe3ABCDE_B = 17'h0;

/* valid_bit, ignore_bit */
always @ ( posedge ACLK ) begin
    if (ARST || RST) begin
        valid_bit <= 3'b000;
        ignore_bit <= 3'b000;
    end
    else begin
        valid_bit <= {valid_bit[1:0], READY};
        ignore_bit <= {ignore_bit[1:0], IGNORE};
    end
end

/* pipeline 1 */
always @ ( posedge ACLK ) begin
    if (IGNORE) begin
        pipe1D[31:0] <= D[31:0];
    end
    else begin
        pipe1AB_B[17:0] <= A[7:0] - B[7:0];
        pipe1AB_G[17:0] <= A[15:8] - B[15:8];
        pipe1AB_R[17:0] <= A[23:16] - B[23:16];
        pipe1AB_A[17:0] <= A[31:24] - B[31:24];
        pipe1C[31:0] <= C[31:0];
        pipe1D[31:0] <= D[31:0];
        pipe1E[31:0] <= E[31:0];
    end
end

/* pipeline 2 */
always @ ( posedge ACLK ) begin
    if (ignore_bit[0]) begin
        pipe2DE_B[7:0] <= pipe1D[7:0];
        pipe2DE_G[7:0] <= pipe1D[15:8];
        pipe2DE_R[7:0] <= pipe1D[23:16];
        pipe2DE_A[7:0] <= pipe1D[31:24];
    end
    else begin
        pipe2ABC_B[17:0] <= pipe1AB_B[17:0] * pipe1C[7:0];
        pipe2ABC_G[17:0] <= pipe1AB_G[17:0] * pipe1C[15:8];
        pipe2ABC_R[17:0] <= pipe1AB_R[17:0] * pipe1C[23:16];
        pipe2ABC_A[17:0] <= pipe1AB_A[17:0] * pipe1C[31:24];
        pipe2DE_B[15:0] <= pipe1D[7:0] * pipe1E[7:0];
        pipe2DE_G[15:0] <= pipe1D[15:8] * pipe1E[15:8];
        pipe2DE_R[15:0] <= pipe1D[23:16] * pipe1E[23:16];
        pipe2DE_A[15:0] <= pipe1D[31:24] * pipe1E[31:24];
    end
end

/* pipeline 3 */
always @ ( posedge ACLK ) begin
    if (ignore_bit[1]) begin
        pipe3ABCDE_B[17:0] <= { 2'b00, pipe2DE_B[7:0], 8'h00 };
        pipe3ABCDE_G[17:0] <= { 2'b00, pipe2DE_G[7:0], 8'h00 };
        pipe3ABCDE_R[17:0] <= { 2'b00, pipe2DE_R[7:0], 8'h00 };
        pipe3ABCDE_A[17:0] <= { 2'b00, pipe2DE_A[7:0], 8'h00 };
    end
    else begin /* 0x1FF + 0xFF = 0x2FE, -1 + 255 = 254(0xFE) */
        pipe3ABCDE_B[17:0] <= pipe2ABC_B[17:0] + pipe2DE_B[15:0];
        pipe3ABCDE_G[17:0] <= pipe2ABC_G[17:0] + pipe2DE_G[15:0];
        pipe3ABCDE_R[17:0] <= pipe2ABC_R[17:0] + pipe2DE_R[15:0];
        pipe3ABCDE_A[17:0] <= pipe2ABC_A[17:0] + pipe2DE_A[15:0];
    end
end 


assign VALID = valid_bit[2]; /* 入力から3クロック後 */
assign Z[7:0] = pipe3ABCDE_B[17] ? 16'h0 : pipe3ABCDE_B[16] ? 16'hFF : pipe3ABCDE_B[15:8];
assign Z[15:8] = pipe3ABCDE_G[17] ? 16'h0 : pipe3ABCDE_G[16] ? 16'hFF : pipe3ABCDE_G[15:8];
assign Z[23:16] = pipe3ABCDE_R[17] ? 16'h0 : pipe3ABCDE_R[16] ? 16'hFF : pipe3ABCDE_R[15:8];
assign Z[31:24] = pipe3ABCDE_A[17] ? 16'h0 : pipe3ABCDE_A[16] ? 16'hFF : pipe3ABCDE_A[15:8];

endmodule // drw_pixel_blend 