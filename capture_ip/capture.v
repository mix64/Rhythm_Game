// キャプチャ回路のトップモジュール
// カメラからの入力をデコードしVRAMに書き込む

module capture #
  (
    parameter integer C_M_AXI_THREAD_ID_WIDTH       = 1,
    parameter integer C_M_AXI_ADDR_WIDTH            = 32,
    parameter integer C_M_AXI_DATA_WIDTH            = 64,
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

    /* 割り込み */
    output              CAP_IRQ,

    /* 解像度切り替え */
    input   [1:0]       RESOL,

    /* カメラ信号 */
    input               PCLK, HREF, VSYNC,
    input   [7:0]       CAMDATA,

    /* レジスタバス */
    input   [15:0]      WRADDR,
    input   [3:0]       BYTEEN,
    input               WREN,
    input   [31:0]      WDATA,
    input   [15:0]      RDADDR,
    input               RDEN,
    output  [31:0]      RDATA,

    /* FIFOフラグ（LED[3]、LED[2]にそれぞれ接続している */
    output              CAP_FIFO_OVER, CAP_FIFO_UNDER
    );

    // Write Address (AW)
    assign M_AXI_AWLEN    = 8'h1F;  // 32word
    assign M_AXI_AWSIZE   = 3'b011; // 64bit (8Byte)
    assign M_AXI_AWBURST  = 2'b01;
    assign M_AXI_AWLOCK   = 2'b00;
    assign M_AXI_AWCACHE  = 4'b0011;
    assign M_AXI_AWPROT   = 3'b000;
    assign M_AXI_AWID     = 1'b0;
    assign M_AXI_AWQOS    = 4'b0000;
    // assign M_AXI_AWREGION = 4'b0000;
    assign M_AXI_AWUSER   = 1'b0;

    // Write Data (W)
    assign M_AXI_WSTRB    = 8'b1111_1111; // Byte Enable
    assign M_AXI_WUSER    = 1'b0;

    // Read Adress (AR)
    assign M_AXI_ARVALID   = 0;
    assign M_AXI_ARADDR    = 0;
    assign M_AXI_ARLEN     = 0;
    assign M_AXI_ARSIZE    = 0;
    assign M_AXI_ARBURST   = 2'b01;
    assign M_AXI_ARLOCK    = 2'b00;
    assign M_AXI_ARCACHE   = 4'b0011;
    assign M_AXI_ARPROT    = 3'b000;
    assign M_AXI_ARID      = 1'b0;
    assign M_AXI_ARQOS     = 4'b0000;
    // assign M_AXI_ARREGION  = 4'b0000;
    assign M_AXI_ARUSER    = 1'b0;

    // Read Data (R)
    assign M_AXI_RREADY = 0;

/* VRAM制御部のAWADDRにVRAMCTRL_AWADDRを接続することで */
/* アクセス範囲を0x20000000〜0x3FFFFFFFに限定する      */
wire    [31:0] VRAMCTRL_AWADDR;
assign M_AXI_AWADDR = {3'b001, VRAMCTRL_AWADDR[28:0]};

// /* とりあえず0固定しておくが、自由に使っていい */
// assign CAP_FIFO_OVER  = 1'b0;   // LED[3]
// assign CAP_FIFO_UNDER = 1'b0;   // LED[2]

// FIFO用ワイヤー
wire        FIFO_WR;
wire        FIFO_RD;
wire        FIFO_VALID;
wire [47:0] FIFO_DIN;
wire [47:0] FIFO_DOUT;
wire [10:0] RD_DATA_CNT;

// ACLKで同期化したリセット信号ARSTの作成
reg [1:0]   arst_ff = 2'b00;
always @( posedge ACLK ) begin
    arst_ff[1:0] <= { arst_ff[0], ~ARESETN };
end
wire ARST = arst_ff[1];

reg [1:0]   vsync_ff = 2'b00;
always @( posedge ACLK ) begin
    vsync_ff[1:0] <= { vsync_ff[0], VSYNC };
end
wire PRST = vsync_ff[1];

// CAPレジスタ用ワイヤ
wire        CAP_ON;
wire [28:0] CAP_ADDR;


// デコーダー
cap_decoder cap_decoder (
    .PCLK               (PCLK),
    .CAMDATA            (CAMDATA),
    .HREF               (HREF),
    .VSYNC              (VSYNC),
    .RESOL              (RESOL),
    .FIFO_WR            (FIFO_WR),
    .FIFO_DIN           (FIFO_DIN)
);

// FIFO
fifo_48in48out_2048depth fifo_48in48out_2048depth (
    .rst                (VSYNC|ARST),
    .wr_clk             (PCLK),
    .rd_clk             (ACLK),
    .din                (FIFO_DIN),
    .wr_en              (FIFO_WR && CAP_ON),
    .rd_en              (FIFO_RD),
    .dout               (FIFO_DOUT),
    .valid              (FIFO_VALID),
    .overflow           (CAP_FIFO_OVER),
    .underflow          (CAP_FIFO_UNDER),
    .rd_data_count      (RD_DATA_CNT)
);

// レジスタ回路
cap_regctrl cap_regctrl (
    .ACLK               (ACLK),
    .ARST               (ARST),
    .VSYNC              (VSYNC),
    .HREF               (HREF),
    .WRADDR             (WRADDR),
    .BYTEEN             (BYTEEN),
    .WREN               (WREN),
    .WDATA              (WDATA),
    .RDADDR             (RDADDR),
    .RDEN               (RDEN),
    .RDATA              (RDATA),
    .CAP_IRQ            (CAP_IRQ),
    .FIFO_UNDER         (CAP_FIFO_UNDER),
    .FIFO_OVER          (CAP_FIFO_OVER),
    .CAP_ON             (CAP_ON),
    .CAP_ADDR           (CAP_ADDR)
);

// VRAM制御
cap_vramctrl cap_vramctrl (
    .ACLK               (ACLK),
    .ARST               (ARST),
    .PRST               (PRST),
    .AWADDR             (VRAMCTRL_AWADDR),
    .AWVALID            (M_AXI_AWVALID),
    .AWREADY            (M_AXI_AWREADY),
    .AWLEN              (M_AXI_AWLEN),
    .WDATA              (M_AXI_WDATA),
    .WVALID             (M_AXI_WVALID),
    .WLAST              (M_AXI_WLAST),
    .WREADY             (M_AXI_WREADY),
    .BRESP              (M_AXI_BRESP),
    .BVALID             (M_AXI_BVALID),
    .BREADY             (M_AXI_BREADY),
    .RESOL              (RESOL),
    .RD_DATA_CNT        (RD_DATA_CNT),
    .FIFO_VALID         (FIFO_VALID),
    .FIFO_DOUT          (FIFO_DOUT),
    .FIFO_RD            (FIFO_RD),
    .CAP_ADDR           (CAP_ADDR)
);

endmodule
