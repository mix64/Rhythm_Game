// サウンド合成回路
// 複数の音を同時に鳴らす際に出力する音を生成する部分

module snd_mix
(
    // connect to snd_buffer
    input               FIFO_RD,
    output              FIFO_VALID,
    output     [31:0]   FIFO_DOUT,

    // connect to snd_fifo_wrap
    input               BGM_FIFO_VALID,
    input      [31:0]   BGM_FIFO_DOUT,
    output              BGM_FIFO_RD,
    input               SE1_FIFO_VALID,
    input      [31:0]   SE1_FIFO_DOUT,
    output              SE1_FIFO_RD,
    input               SE2_FIFO_VALID,
    input      [31:0]   SE2_FIFO_DOUT,
    output              SE2_FIFO_RD,
    input               SE3_FIFO_VALID,
    input      [31:0]   SE3_FIFO_DOUT,
    output              SE3_FIFO_RD,
    input               SE4_FIFO_VALID,
    input      [31:0]   SE4_FIFO_DOUT,
    output              SE4_FIFO_RD,

    // connect to snd_regctrl
    input       [3:0]   M_SE_SELECT,
    input       [7:0]   M_BGM_VOLUME,
    input       [7:0]   M_SE_VOLUME
);

wire [15:0] BGM_L;
wire [15:0] BGM_R;
wire [15:0] SE1_L;
wire [15:0] SE1_R;
wire [15:0] SE2_L;
wire [15:0] SE2_R;
wire [15:0] SE3_L;
wire [15:0] SE3_R;
wire [15:0] SE4_L;
wire [15:0] SE4_R;

snd_vol snd_vol_bgm (
    .USED       (BGM_FIFO_VALID),
    .VOLUME     (M_BGM_VOLUME),
    .FIFO_DOUT  (BGM_FIFO_DOUT),
    .L_BUFF     (BGM_L),
    .R_BUFF     (BGM_R)
);
snd_vol snd_vol_se1 (
    .USED       (SE1_FIFO_VALID),
    .VOLUME     (M_SE_VOLUME),
    .FIFO_DOUT  (SE1_FIFO_DOUT),
    .L_BUFF     (SE1_L),
    .R_BUFF     (SE1_R)
);
snd_vol snd_vol_se2 (
    .USED       (SE2_FIFO_VALID),
    .VOLUME     (M_SE_VOLUME),
    .FIFO_DOUT  (SE2_FIFO_DOUT),
    .L_BUFF     (SE2_L),
    .R_BUFF     (SE2_R)
);
snd_vol snd_vol_se3 (
    .USED       (SE3_FIFO_VALID),
    .VOLUME     (M_SE_VOLUME),
    .FIFO_DOUT  (SE3_FIFO_DOUT),
    .L_BUFF     (SE3_L),
    .R_BUFF     (SE3_R)
);
snd_vol snd_vol_se4 (
    .USED       (SE4_FIFO_VALID),
    .VOLUME     (M_SE_VOLUME),
    .FIFO_DOUT  (SE4_FIFO_DOUT),
    .L_BUFF     (SE4_L),
    .R_BUFF     (SE4_R)
);

wire [15:0] SE12_L;
wire [15:0] SE12_R;
wire [15:0] SE34_L;
wire [15:0] SE34_R;
wire [15:0] SE1234_L;
wire [15:0] SE1234_R;
wire [15:0] BUFF_L;
wire [15:0] BUFF_R;

snd_mix2 se12_l (
    .IN1    (SE1_L),
    .IN2    (SE2_L),
    .OUT    (SE12_L)
);
snd_mix2 se12_r (
    .IN1    (SE1_R),
    .IN2    (SE2_R),
    .OUT    (SE12_R)
);
snd_mix2 se34_l (
    .IN1    (SE3_L),
    .IN2    (SE4_L),
    .OUT    (SE34_L)
);
snd_mix2 se34_r (
    .IN1    (SE3_R),
    .IN2    (SE4_R),
    .OUT    (SE34_R)
);
snd_mix2 se1234_l (
    .IN1    (SE12_L),
    .IN2    (SE34_L),
    .OUT    (SE1234_L)
);
snd_mix2 se1234_r (
    .IN1    (SE12_R),
    .IN2    (SE34_R),
    .OUT    (SE1234_R)
);
snd_mix2 buff_l (
    .IN1    (BGM_L),
    .IN2    (SE1234_L),
    .OUT    (BUFF_L)
);
snd_mix2 buff_r (
    .IN1    (BGM_R),
    .IN2    (SE1234_R),
    .OUT    (BUFF_R)
);

assign BGM_FIFO_RD = FIFO_RD;
assign SE1_FIFO_RD = FIFO_RD & M_SE_SELECT[0];
assign SE2_FIFO_RD = FIFO_RD & M_SE_SELECT[1];
assign SE3_FIFO_RD = FIFO_RD & M_SE_SELECT[2];
assign SE4_FIFO_RD = FIFO_RD & M_SE_SELECT[3];
assign FIFO_VALID = BGM_FIFO_VALID;
assign FIFO_DOUT = { BUFF_R[15:0], BUFF_L[15:0] };

endmodule // snd_mix
