// サウンド回路のトップモジュール

module sound #
  (
    parameter integer C_M_AXI_THREAD_ID_WIDTH       = 1,
    parameter integer C_M_AXI_ADDR_WIDTH            = 32,
    parameter integer C_M_AXI_DATA_WIDTH            = 32,
    parameter integer C_M_AXI_AWUSER_WIDTH          = 1,
    parameter integer C_M_AXI_ARUSER_WIDTH          = 1,
    parameter integer C_M_AXI_WUSER_WIDTH           = 1,
    parameter integer C_M_AXI_RUSER_WIDTH           = 1,
    parameter integer C_M_AXI_BUSER_WIDTH           = 1,

    /* 以下は未対応だけどコンパイルエラー回避のため付加しておく */
    parameter integer C_INTERCONNECT_M_AXI_WRITE_ISSUING = 0,
    parameter integer C_M_AXI_SUPPORTS_READ              = 0,
    parameter integer C_M_AXI_SUPPORTS_WRITE             = 1,
    parameter integer C_M_AXI_TARGET                     = 0,
    parameter integer C_M_AXI_BURST_LEN                  = 0,
    parameter integer C_OFFSET_WIDTH                     = 0
   )
  (
    // System Signals
    input wire        ACLK,
    input wire        ARESETN,

    // Master Interface Write Address
    output wire [C_M_AXI_THREAD_ID_WIDTH-1:0]    M_AXI_AWID,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]         M_AXI_AWADDR,
    output wire [8-1:0]                          M_AXI_AWLEN,
    output wire [3-1:0]                          M_AXI_AWSIZE,
    output wire [2-1:0]                          M_AXI_AWBURST,
    output wire [2-1:0]                          M_AXI_AWLOCK,
    output wire [4-1:0]                          M_AXI_AWCACHE,
    output wire [3-1:0]                          M_AXI_AWPROT,
    // AXI3 output wire [4-1:0]                  M_AXI_AWREGION,
    output wire [4-1:0]                          M_AXI_AWQOS,
    output wire [C_M_AXI_AWUSER_WIDTH-1:0]       M_AXI_AWUSER,
    output wire                                  M_AXI_AWVALID,
    input  wire                                  M_AXI_AWREADY,

    // Master Interface Write Data
    // AXI3 output wire [C_M_AXI_THREAD_ID_WIDTH-1:0]     M_AXI_WID,
    output wire [C_M_AXI_DATA_WIDTH-1:0]         M_AXI_WDATA,
    output wire [C_M_AXI_DATA_WIDTH/8-1:0]       M_AXI_WSTRB,
    output wire                                  M_AXI_WLAST,
    output wire [C_M_AXI_WUSER_WIDTH-1:0]        M_AXI_WUSER,
    output wire                                  M_AXI_WVALID,
    input  wire                                  M_AXI_WREADY,

    // Master Interface Write Response
    input  wire [C_M_AXI_THREAD_ID_WIDTH-1:0]    M_AXI_BID,
    input  wire [2-1:0]                          M_AXI_BRESP,
    input  wire [C_M_AXI_BUSER_WIDTH-1:0]        M_AXI_BUSER,
    input  wire                                  M_AXI_BVALID,
    output wire                                  M_AXI_BREADY,

    // Master Interface Read Address
    output wire [C_M_AXI_THREAD_ID_WIDTH-1:0]    M_AXI_ARID,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]         M_AXI_ARADDR,
    output wire [8-1:0]                          M_AXI_ARLEN,
    output wire [3-1:0]                          M_AXI_ARSIZE,
    output wire [2-1:0]                          M_AXI_ARBURST,
    output wire [2-1:0]                          M_AXI_ARLOCK,
    output wire [4-1:0]                          M_AXI_ARCACHE,
    output wire [3-1:0]                          M_AXI_ARPROT,
    // AXI3 output wire [4-1:0]                  M_AXI_ARREGION,
    output wire [4-1:0]                          M_AXI_ARQOS,
    output wire [C_M_AXI_ARUSER_WIDTH-1:0]       M_AXI_ARUSER,
    output wire                                  M_AXI_ARVALID,
    input  wire                                  M_AXI_ARREADY,

    // Master Interface Read Data
    input  wire [C_M_AXI_THREAD_ID_WIDTH-1:0]    M_AXI_RID,
    input  wire [C_M_AXI_DATA_WIDTH-1:0]         M_AXI_RDATA,
    input  wire [2-1:0]                          M_AXI_RRESP,
    input  wire                                  M_AXI_RLAST,
    input  wire [C_M_AXI_RUSER_WIDTH-1:0]        M_AXI_RUSER,
    input  wire                                  M_AXI_RVALID,
    output wire                                  M_AXI_RREADY,

    /* 音声関連信号 */
    input               CLK40,
    output              SND_MCLK, SND_BCLK, SND_LRCLK, SND_DOUT,

    /* レジスタバス */
    input   [15:0]      WRADDR,
    input   [3:0]       BYTEEN,
    input               WREN,
    input   [31:0]      WDATA,
    input   [15:0]      RDADDR,
    input               RDEN,
    output  [31:0]      RDATA,

    /* FIFOフラグ（LED[4]、LED[5]にそれぞれ接続している）*/
    output              SND_FIFO_UNDER, SND_FIFO_OVER
);

assign SND_FIFO_UNDER = 1'b0;
assign SND_FIFO_OVER = 1'b0;

// Write Address (AW)
assign M_AXI_AWID    = 'b0;
assign M_AXI_AWADDR  = 0;
assign M_AXI_AWLEN   = 0;
assign M_AXI_AWSIZE  = 0;
assign M_AXI_AWBURST = 2'b01;
assign M_AXI_AWLOCK  = 2'b00;
assign M_AXI_AWCACHE = 4'b0010;
assign M_AXI_AWPROT  = 3'h0;
assign M_AXI_AWQOS   = 4'h0;
assign M_AXI_AWUSER  = 'b0;
assign M_AXI_AWVALID = 0;

// Write Data(W)
assign M_AXI_WDATA  = 0;
assign M_AXI_WSTRB  = 0;
assign M_AXI_WLAST  = 0;
assign M_AXI_WUSER  = 'b0;
assign M_AXI_WVALID = 0;

// Write Response (B)
assign M_AXI_BREADY = 0;

// Read Address (AR)
assign M_AXI_ARID    = 'b0;
// assign M_AXI_ARLEN   = 8'h1F; // 32 word
assign M_AXI_ARSIZE  = 3'b010; // 32bit (4Byte)
assign M_AXI_ARBURST = 2'b01;
assign M_AXI_ARLOCK  = 1'b0;
assign M_AXI_ARCACHE = 4'b0010;
assign M_AXI_ARPROT  = 3'h0;
assign M_AXI_ARQOS   = 4'h0;
assign M_AXI_ARUSER  = 'b0;

/* VRAM制御部のARADDRにVRAMCTRL_ARADDRを接続することで */
/* アクセス範囲を0x20000000〜0x3FFFFFFFに限定する      */
wire    [31:0] VRAMCTRL_ARADDR;
assign M_AXI_ARADDR = {3'b001, VRAMCTRL_ARADDR[28:0]};

/* MCLK生成部を接続 */
snd_mclkgen snd_mclkgen (
    .CLK40      (CLK40),
    .SND_MCLK   (SND_MCLK)
);

// FIFO wire
wire        BGM_FIFO_WR;
wire        BGM_FIFO_RD;
wire        BGM_FIFO_VALID;
wire [31:0] BGM_FIFO_DIN;
wire [31:0] BGM_FIFO_DOUT;
wire  [9:0] BGM_WR_DATA_CNT;
wire [31:0] BGM_ADDR;
wire  [7:0] BGM_LEN;

wire        SE1_FIFO_WR;
wire        SE1_FIFO_RD;
wire        SE1_FIFO_VALID;
wire [31:0] SE1_FIFO_DIN;
wire [31:0] SE1_FIFO_DOUT;
wire  [9:0] SE1_WR_DATA_CNT;
wire [31:0] SE1_ADDR;
wire  [7:0] SE1_LEN;

wire        SE2_FIFO_WR;
wire        SE2_FIFO_RD;
wire        SE2_FIFO_VALID;
wire [31:0] SE2_FIFO_DIN;
wire [31:0] SE2_FIFO_DOUT;
wire  [9:0] SE2_WR_DATA_CNT;
wire [31:0] SE2_ADDR;
wire  [7:0] SE2_LEN;

wire        SE3_FIFO_WR;
wire        SE3_FIFO_RD;
wire        SE3_FIFO_VALID;
wire [31:0] SE3_FIFO_DIN;
wire [31:0] SE3_FIFO_DOUT;
wire  [9:0] SE3_WR_DATA_CNT;
wire [31:0] SE3_ADDR;
wire  [7:0] SE3_LEN;

wire        SE4_FIFO_WR;
wire        SE4_FIFO_RD;
wire        SE4_FIFO_VALID;
wire [31:0] SE4_FIFO_DIN;
wire [31:0] SE4_FIFO_DOUT;
wire  [9:0] SE4_WR_DATA_CNT;
wire [31:0] SE4_ADDR;
wire  [7:0] SE4_LEN;

// buffer
wire        FIFO_RD;
wire        FIFO_VALID;
wire [31:0] FIFO_DOUT;

// regctrl wire
wire        BGM_FIN;
wire        SE1_FIN;
wire        SE2_FIN;
wire        SE3_FIN;
wire        SE4_FIN;
wire        RST;
wire [31:0] BGM_BASEADDR;
wire [31:0] BGM_SIZE;
wire  [7:0] BGM_VOLUME;
wire        BGM_PLAY;
wire [31:0] SE_ADDR;
wire [31:0] SE_SIZE;
wire  [7:0] SE_VOLUME;
wire  [3:0] SE_SELECT;

// other wire
wire [5:0] serial_cnt; // BCLKとLRCLKのタイミング

// ARST
reg [1:0] arst_ff = 2'b00;
always @( posedge ACLK ) begin
    arst_ff[1:0] <= { arst_ff[0], ~ARESETN };
end
wire ARST = arst_ff[1];

// MCLK
reg [15:0] bgm_vol_ff;
reg [15:0] se_vol_ff;
reg [7:0] se_select_ff;
reg [1:0] bgm_play_ff;

always @( posedge SND_MCLK ) begin
    bgm_vol_ff[15:0] <= { bgm_vol_ff[7:0], BGM_VOLUME };
    se_vol_ff[15:0] <= { se_vol_ff[7:0], SE_VOLUME };
    se_select_ff[7:0] <= { se_select_ff[3:0], SE_SELECT };
    bgm_play_ff[1:0] <= { bgm_play_ff[0], BGM_PLAY };
end
wire [7:0] M_BGM_VOLUME = bgm_vol_ff[15:8];
wire [7:0] M_SE_VOLUME = se_vol_ff[15:8];
wire [3:0] M_SE_SELECT = se_select_ff[7:4];
wire M_BGM_PLAY = bgm_play_ff[1];


// 分周回路
snd_freq snd_freq (
    .SND_MCLK           (SND_MCLK),
    .SND_BCLK           (SND_BCLK),
    .SND_LRCLK          (SND_LRCLK),
    .serial_cnt         (serial_cnt)
);

// 音量調節, FIFO読み出し制御, シリアル変換
snd_buffer snd_buffer (
    .SND_MCLK           (SND_MCLK),
    .serial_cnt         (serial_cnt),
    .FIFO_VALID         (FIFO_VALID),
    .FIFO_DOUT          (FIFO_DOUT),
    .FIFO_RD            (FIFO_RD),
    .M_BGM_PLAY         (M_BGM_PLAY),
    .SND_DOUT           (SND_DOUT)
);

snd_mix snd_mix (
    .FIFO_RD            (FIFO_RD),
    .FIFO_VALID         (FIFO_VALID),
    .FIFO_DOUT          (FIFO_DOUT),
    .BGM_FIFO_VALID     (BGM_FIFO_VALID),
    .BGM_FIFO_DOUT      (BGM_FIFO_DOUT),
    .BGM_FIFO_RD        (BGM_FIFO_RD),
    .SE1_FIFO_VALID     (SE1_FIFO_VALID),
    .SE1_FIFO_DOUT      (SE1_FIFO_DOUT),
    .SE1_FIFO_RD        (SE1_FIFO_RD),
    .SE2_FIFO_VALID     (SE2_FIFO_VALID),
    .SE2_FIFO_DOUT      (SE2_FIFO_DOUT),
    .SE2_FIFO_RD        (SE2_FIFO_RD),
    .SE3_FIFO_VALID     (SE3_FIFO_VALID),
    .SE3_FIFO_DOUT      (SE3_FIFO_DOUT),
    .SE3_FIFO_RD        (SE3_FIFO_RD),
    .SE4_FIFO_VALID     (SE4_FIFO_VALID),
    .SE4_FIFO_DOUT      (SE4_FIFO_DOUT),
    .SE4_FIFO_RD        (SE4_FIFO_RD),
    .M_SE_SELECT        (M_SE_SELECT),
    .M_BGM_VOLUME       (M_BGM_VOLUME),
    .M_SE_VOLUME        (M_SE_VOLUME)
);

// レジスタ回路
snd_regctrl snd_regctrl (
    .ACLK               (ACLK),
    .ARST               (ARST),
    .WRADDR             (WRADDR),
    .BYTEEN             (BYTEEN),
    .WREN               (WREN),
    .WDATA              (WDATA),
    .RDADDR             (RDADDR),
    .RDEN               (RDEN),
    .RDATA              (RDATA),
    .BGM_FIN            (BGM_FIN),
    .SE1_FIN            (SE1_FIN),
    .SE2_FIN            (SE2_FIN),
    .SE3_FIN            (SE3_FIN),
    .SE4_FIN            (SE4_FIN),
    .RST                (RST),
    .BGM_ADDR           (BGM_BASEADDR),
    .BGM_SIZE           (BGM_SIZE),
    .BGM_VOLUME         (BGM_VOLUME),
    .BGM_PLAY           (BGM_PLAY),
    .SE_ADDR            (SE_ADDR),
    .SE_SIZE            (SE_SIZE),
    .SE_VOLUME          (SE_VOLUME),
    .SE_SELECT          (SE_SELECT)
);

snd_vramctrl snd_vramctrl (
    .ACLK               (ACLK),
    .ARST               (ARST),
    .RST                (RST),
    .ARLEN              (M_AXI_ARLEN),
    .ARADDR             (VRAMCTRL_ARADDR),
    .ARVALID            (M_AXI_ARVALID),
    .ARREADY            (M_AXI_ARREADY),
    .RLAST              (M_AXI_RLAST),
    .RVALID             (M_AXI_RVALID),
    .RDATA              (M_AXI_RDATA),
    .RREADY             (M_AXI_RREADY),
    .BGM_FIFO_DIN       (BGM_FIFO_DIN),
    .BGM_FIFO_WR        (BGM_FIFO_WR),
    .BGM_WR_DATA_CNT    (BGM_WR_DATA_CNT),
    .BGM_ADDR           (BGM_ADDR),  
    .BGM_LEN            (BGM_LEN),
    .SE1_FIFO_DIN       (SE1_FIFO_DIN),
    .SE1_FIFO_WR        (SE1_FIFO_WR),
    .SE1_WR_DATA_CNT    (SE1_WR_DATA_CNT),
    .SE1_ADDR           (SE1_ADDR),
    .SE1_LEN            (SE1_LEN),
    .SE2_FIFO_DIN       (SE2_FIFO_DIN),
    .SE2_FIFO_WR        (SE2_FIFO_WR),
    .SE2_WR_DATA_CNT    (SE2_WR_DATA_CNT),
    .SE2_ADDR           (SE2_ADDR),
    .SE2_LEN            (SE2_LEN),
    .SE3_FIFO_DIN       (SE3_FIFO_DIN),
    .SE3_FIFO_WR        (SE3_FIFO_WR),   
    .SE3_WR_DATA_CNT    (SE3_WR_DATA_CNT),
    .SE3_ADDR           (SE3_ADDR),
    .SE3_LEN            (SE3_LEN),
    .SE4_FIFO_DIN       (SE4_FIFO_DIN),
    .SE4_FIFO_WR        (SE4_FIFO_WR),
    .SE4_WR_DATA_CNT    (SE4_WR_DATA_CNT),
    .SE4_ADDR           (SE4_ADDR),
    .SE4_LEN            (SE4_LEN)
);

// FIFOs
snd_fifo_wrap bgm_fifo (
    .ACLK               (ACLK),
    .ARST               (ARST),
    .RST                (RST),
    .SND_MCLK           (SND_MCLK),
    .FIFO_RD            (BGM_FIFO_RD),
    .FIFO_VALID         (BGM_FIFO_VALID),
    .FIFO_DOUT          (BGM_FIFO_DOUT),
    .FIFO_WR            (BGM_FIFO_WR),
    .FIFO_DIN           (BGM_FIFO_DIN),
    .WR_DATA_CNT        (BGM_WR_DATA_CNT),
    .ADDR               (BGM_ADDR),
    .LEN                (BGM_LEN),
    .FIFO_FIN           (BGM_FIN),
    .BASEADDR           (BGM_BASEADDR),
    .SIZE               (BGM_SIZE)
);

snd_fifo_wrap se1_fifo (
    .ACLK               (ACLK),
    .ARST               (ARST),
    .RST                (RST),
    .SND_MCLK           (SND_MCLK),
    .FIFO_RD            (SE1_FIFO_RD),
    .FIFO_VALID         (SE1_FIFO_VALID),
    .FIFO_DOUT          (SE1_FIFO_DOUT),
    .FIFO_WR            (SE1_FIFO_WR),
    .FIFO_DIN           (SE1_FIFO_DIN),
    .WR_DATA_CNT        (SE1_WR_DATA_CNT),
    .ADDR               (SE1_ADDR),
    .LEN                (SE1_LEN),
    .FIFO_FIN           (SE1_FIN),
    .BASEADDR           (SE_ADDR),
    .SIZE               (SE_SIZE)
);

snd_fifo_wrap se2_fifo (
    .ACLK               (ACLK),
    .ARST               (ARST),
    .RST                (RST),
    .SND_MCLK           (SND_MCLK),
    .FIFO_RD            (SE2_FIFO_RD),
    .FIFO_VALID         (SE2_FIFO_VALID),
    .FIFO_DOUT          (SE2_FIFO_DOUT),
    .FIFO_WR            (SE2_FIFO_WR),
    .FIFO_DIN           (SE2_FIFO_DIN),
    .WR_DATA_CNT        (SE2_WR_DATA_CNT),
    .ADDR               (SE2_ADDR),
    .LEN                (SE2_LEN),
    .FIFO_FIN           (SE2_FIN),
    .BASEADDR           (SE_ADDR),
    .SIZE               (SE_SIZE)
);

snd_fifo_wrap se3_fifo (
    .ACLK               (ACLK),
    .ARST               (ARST),
    .RST                (RST),
    .SND_MCLK           (SND_MCLK),
    .FIFO_RD            (SE3_FIFO_RD),
    .FIFO_VALID         (SE3_FIFO_VALID),
    .FIFO_DOUT          (SE3_FIFO_DOUT),
    .FIFO_WR            (SE3_FIFO_WR),
    .FIFO_DIN           (SE3_FIFO_DIN),
    .WR_DATA_CNT        (SE3_WR_DATA_CNT),
    .ADDR               (SE3_ADDR),
    .LEN                (SE3_LEN),
    .FIFO_FIN           (SE3_FIN),
    .BASEADDR           (SE_ADDR),
    .SIZE               (SE_SIZE)
);

snd_fifo_wrap se4_fifo (
    .ACLK               (ACLK),
    .ARST               (ARST),
    .RST                (RST),
    .SND_MCLK           (SND_MCLK),
    .FIFO_RD            (SE4_FIFO_RD),
    .FIFO_VALID         (SE4_FIFO_VALID),
    .FIFO_DOUT          (SE4_FIFO_DOUT),
    .FIFO_WR            (SE4_FIFO_WR),
    .FIFO_DIN           (SE4_FIFO_DIN),
    .WR_DATA_CNT        (SE4_WR_DATA_CNT),
    .ADDR               (SE4_ADDR),
    .LEN                (SE4_LEN),
    .FIFO_FIN           (SE4_FIN),
    .BASEADDR           (SE_ADDR),
    .SIZE               (SE_SIZE)
);

endmodule
