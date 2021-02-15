// 描画回路のトップモジュール

module draw #
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
    parameter integer C_M_AXI_SUPPORTS_READ              = 1,
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

    /* 解像度切り替え */
    input   [1:0]       RESOL,
    /* 割り込み */
    output              DRW_IRQ,

    /* レジスタバス */
    input   [15:0]      WRADDR,
    input   [3:0]       BYTEEN,
    input               WREN,
    input   [31:0]      WDATA,
    input   [15:0]      RDADDR,
    input               RDEN,
    output  [31:0]      RDATA
    );

/* AXI */
assign M_AXI_AWID       = 1'b0;
assign M_AXI_AWBURST    = 2'b01;
assign M_AXI_AWLOCK     = 2'b00;
assign M_AXI_AWCACHE    = 4'b0011;
assign M_AXI_AWPROT     = 3'b000;
assign M_AXI_AWQOS      = 4'b0000;
assign M_AXI_AWUSER     = 1'b0;
assign M_AXI_WUSER      = 1'b0;
assign M_AXI_ARID       = 1'b0;
assign M_AXI_ARBURST    = 2'b01;
assign M_AXI_ARLOCK     = 2'b00;
assign M_AXI_ARCACHE    = 4'b0011;
assign M_AXI_ARPROT     = 3'b000;
assign M_AXI_ARQOS      = 4'b0000;
assign M_AXI_ARUSER     = 1'b0;

/* VRAM制御部のAWADDRやARADDRに接続することで、     */
/* アクセス範囲を0x20000000〜0x3FFFFFFFに限定できる */
wire    [31:0] VRAMCTRL_ARADDR;
wire    [31:0] VRAMCTRL_AWADDR;
assign M_AXI_ARADDR = {3'b001, VRAMCTRL_ARADDR[28:0]};
assign M_AXI_AWADDR = {3'b001, VRAMCTRL_AWADDR[28:0]};

// ACLKで同期化したリセット信号ARSTの作成
reg [1:0]   arst_ff = 2'b00;
always @( posedge ACLK ) begin
    arst_ff[1:0] <= { arst_ff[0], ~ARESETN };
end
wire ARST = arst_ff[1];

/* regctrl wire */
wire        RST;
wire        EXE;

/* drw_cmd wire */
wire        DRAW_FINISH;
wire [15:0] ERRNO;
wire        BLT_WAIT;

/* drw_mkaddr wire */
wire        BLT_FINISH;
wire [28:0] SRC_ADDR;
wire  [7:0] SRC_LEN;
wire        SRC_FIN;
wire        SRC_COMMIT;
wire [28:0] DST_ADDR;
wire  [7:0] DST_LEN;
wire        DST_FIN;
wire        DST_COMMIT;
wire [28:0] WRT_ADDR;
wire  [7:0] WRT_LEN;
wire        WRT_FIN;
wire        WRT_COMMIT;

/* FIFOs wire */
wire [31:0] CMD_FIFO_DIN;
wire        CMD_FIFO_WR;
wire        CMD_FIFO_RD;
wire [31:0] CMD_FIFO_DOUT;
wire        CMD_FIFO_VALID;
wire        CMD_FIFO_FULL;
wire        CMD_FIFO_EMPTY;
wire [10:0] CMD_FIFO_DATA_CNT;

wire [31:0] SRC_FIFO_DIN;
wire [31:0] SRC_FIFO_DOUT;
wire        SRC_FIFO_WR;
wire        SRC_FIFO_RD;
wire        SRC_FIFO_almostFULL;
wire        SRC_FIFO_FULL;
wire        SRC_FIFO_almostEMPTY;
wire        SRC_FIFO_EMPTY;
wire        SRC_FIFO_VALID;
wire [8:0]  SRC_FIFO_DATA_CNT;

wire [31:0] DST_FIFO_DIN;
wire [31:0] DST_FIFO_DOUT;
wire        DST_FIFO_WR;
wire        DST_FIFO_RD;
wire        DST_FIFO_almostFULL;
wire        DST_FIFO_FULL;
wire        DST_FIFO_almostEMPTY;
wire        DST_FIFO_EMPTY;
wire        DST_FIFO_VALID;
wire [8:0]  DST_FIFO_DATA_CNT;

wire [31:0] WRT_FIFO_DIN;
wire [31:0] WRT_FIFO_DOUT;
wire        WRT_FIFO_WR;
wire        WRT_FIFO_RD;
wire        WRT_FIFO_almostFULL;
wire        WRT_FIFO_FULL;
wire        WRT_FIFO_almostEMPTY;
wire        WRT_FIFO_EMPTY;
wire        WRT_FIFO_VALID;
wire [8:0]  WRT_FIFO_DATA_CNT;

/* draw parameter */
wire [31:0] FRAME_COLOR;
wire        STEALTH_MODE;
wire  [3:0] STEALTH_MASK;
wire [31:0] STEALTH_COLOR_L;
wire [31:0] STEALTH_COLOR_H;
wire        BLEND_ALPHA;    /* 0:OFF, 1:ON */
wire  [2:0] BLEND_A;
wire  [2:0] BLEND_B;
wire  [2:0] BLEND_C;
wire  [2:0] BLEND_D;
wire  [2:0] BLEND_E;
wire  [7:0] BLEND_SRCCA;
wire [31:0] BLEND_COEF0;
wire [31:0] BLEND_COEF1;
wire [28:0] FRAME_ADDR;
wire [10:0] FRAME_WIDTH;
wire [10:0] FRAME_HEIGHT;
wire [10:0] AREA_POSX;
wire [10:0] AREA_POSY;
wire [10:0] AREA_SIZX;
wire [10:0] AREA_SIZY;
wire [28:0] TEXTURE_ADDR;
wire        TEXTURE_FMT;    /* 0:ARGB, 1:RGB */
wire        BLT_CMD;        /* 0:PAT, 1:BIT */
wire [11:0] BLT_DPOSX;
wire [11:0] BLT_DPOSY;
wire [10:0] BLT_DSIZX;
wire [10:0] BLT_DSIZY;
wire [11:0] BLT_SPOSX;
wire [11:0] BLT_SPOSY;


drw_cmd drw_cmd (
    .ACLK               (ACLK),
    .ARST               (ARST),
    .EXE                (EXE),
    .RST                (RST),
    .DRAW_FINISH        (DRAW_FINISH),
    .ERRNO              (ERRNO),
    .FIFO_RD            (CMD_FIFO_RD),
    .FIFO_VALID         (CMD_FIFO_VALID),
    .FIFO_DOUT          (CMD_FIFO_DOUT),
    .FIFO_DATA_CNT      (CMD_FIFO_DATA_CNT),
    .BLT_WAIT           (BLT_WAIT),
    .BLT_FINISH         (BLT_FINISH),
    .FRAME_COLOR        (FRAME_COLOR),
    .STEALTH_MODE       (STEALTH_MODE),
    .STEALTH_MASK       (STEALTH_MASK),
    .STEALTH_COLOR_L    (STEALTH_COLOR_L),
    .STEALTH_COLOR_H    (STEALTH_COLOR_H),
    .BLEND_ALPHA        (BLEND_ALPHA),
    .BLEND_A            (BLEND_A),
    .BLEND_B            (BLEND_B),
    .BLEND_C            (BLEND_C),
    .BLEND_D            (BLEND_D),
    .BLEND_E            (BLEND_E),
    .BLEND_SRCCA        (BLEND_SRCCA),
    .BLEND_COEF0        (BLEND_COEF0),
    .BLEND_COEF1        (BLEND_COEF1),
    .FRAME_ADDR         (FRAME_ADDR),
    .FRAME_WIDTH        (FRAME_WIDTH),
    .FRAME_HEIGHT       (FRAME_HEIGHT),
    .AREA_POSX          (AREA_POSX),
    .AREA_POSY          (AREA_POSY),
    .AREA_SIZX          (AREA_SIZX),
    .AREA_SIZY          (AREA_SIZY),
    .TEXTURE_ADDR       (TEXTURE_ADDR),
    .TEXTURE_FMT        (TEXTURE_FMT),
    .BLT_CMD            (BLT_CMD),
    .BLT_DPOSX          (BLT_DPOSX),
    .BLT_DPOSY          (BLT_DPOSY),
    .BLT_DSIZX          (BLT_DSIZX),
    .BLT_DSIZY          (BLT_DSIZY),
    .BLT_SPOSX          (BLT_SPOSX),
    .BLT_SPOSY          (BLT_SPOSY)
);

drw_mkaddr drw_mkaddr (
    .ACLK               (ACLK),
    .ARST               (ARST),
    .RST                (RST),
    .BLT_WAIT           (BLT_WAIT),
    .BLT_FINISH         (BLT_FINISH),
    .ADDR_VALID         (ADDR_VALID),
    .SRC_ADDR           (SRC_ADDR),
    .SRC_LEN            (SRC_LEN),
    .SRC_FIN            (SRC_FIN),
    .SRC_COMMIT         (SRC_COMMIT),
    .DST_ADDR           (DST_ADDR),
    .DST_LEN            (DST_LEN),
    .DST_FIN            (DST_FIN),
    .DST_COMMIT         (DST_COMMIT),
    .WRT_ADDR           (WRT_ADDR),
    .WRT_LEN            (WRT_LEN),
    .WRT_FIN            (WRT_FIN),
    .WRT_COMMIT         (WRT_COMMIT),
    .AXI_BVALID         (M_AXI_BVALID),
    .FRAME_ADDR         (FRAME_ADDR),
    .FRAME_WIDTH        (FRAME_WIDTH),
    .FRAME_HEIGHT       (FRAME_HEIGHT),
    .AREA_POSX          (AREA_POSX),
    .AREA_POSY          (AREA_POSY),
    .AREA_SIZX          (AREA_SIZX),
    .AREA_SIZY          (AREA_SIZY),
    .TEXTURE_ADDR       (TEXTURE_ADDR),
    .BLEND_ALPHA        (BLEND_ALPHA),
    .BLT_CMD            (BLT_CMD),
    .BLT_DPOSX          (BLT_DPOSX),
    .BLT_DPOSY          (BLT_DPOSY),
    .BLT_DSIZX          (BLT_DSIZX),
    .BLT_DSIZY          (BLT_DSIZY),
    .BLT_SPOSX          (BLT_SPOSX),
    .BLT_SPOSY          (BLT_SPOSY)
);

drw_pixel drw_pixel (
    .ACLK                   (ACLK),
    .ARST                   (ARST),
    .RST                    (RST),
    .BLEND_ALPHA            (BLEND_ALPHA),
    .BLT_CMD                (BLT_CMD),
    .ADDR_VALID             (ADDR_VALID),
    .SRC_FIFO_almostEMPTY   (SRC_FIFO_almostEMPTY),
    .SRC_FIFO_EMPTY         (SRC_FIFO_EMPTY),
    .SRC_FIFO_RD            (SRC_FIFO_RD),
    .SRC_FIFO_VALID         (SRC_FIFO_VALID),
    .SRC_FIFO_DOUT          (SRC_FIFO_DOUT),
    .DST_FIFO_almostEMPTY   (DST_FIFO_almostEMPTY),
    .DST_FIFO_EMPTY         (DST_FIFO_EMPTY),
    .DST_FIFO_RD            (DST_FIFO_RD),
    .DST_FIFO_VALID         (DST_FIFO_VALID),
    .DST_FIFO_DOUT          (DST_FIFO_DOUT),
    .WRT_FIFO_DATA_CNT      (WRT_FIFO_DATA_CNT),
    .WRT_FIFO_WR            (WRT_FIFO_WR),
    .WRT_FIFO_DIN           (WRT_FIFO_DIN),
    .FRAME_COLOR            (FRAME_COLOR),
    .STEALTH_MODE           (STEALTH_MODE),
    .STEALTH_MASK           (STEALTH_MASK),
    .STEALTH_COLOR_L        (STEALTH_COLOR_L),
    .STEALTH_COLOR_H        (STEALTH_COLOR_H),
    .BLEND_A                (BLEND_A),
    .BLEND_B                (BLEND_B),
    .BLEND_C                (BLEND_C),
    .BLEND_D                (BLEND_D),
    .BLEND_E                (BLEND_E),
    .BLEND_SRCCA            (BLEND_SRCCA),
    .BLEND_COEF0            (BLEND_COEF0),
    .BLEND_COEF1            (BLEND_COEF1)
);

drw_regctrl drw_regctrl (
    .ACLK               (ACLK),
    .ARST               (ARST),
    .WRADDR             (WRADDR),
    .BYTEEN             (BYTEEN),
    .WREN               (WREN),
    .WDATA              (WDATA),
    .RDADDR             (RDADDR),
    .RDEN               (RDEN),
    .RDATA              (RDATA),
    .DATA_CNT           (CMD_FIFO_DATA_CNT),
    .FIFO_WR            (CMD_FIFO_WR),
    .FIFO_DIN           (CMD_FIFO_DIN),
    .FIFO_EMPTY         (CMD_FIFO_EMPTY),
    .FIFO_FULL          (CMD_FIFO_FULL),
    .DRW_IRQ            (DRW_IRQ),
    .RST                (RST),
    .EXE                (EXE),
    .DRAW_FINISH        (DRAW_FINISH),
    .ERRNO              (ERRNO)
);

drw_vramctrl_rd drw_vramctrl_rd (
    .ACLK               (ACLK),
    .ARST               (ARST),
    .RST                (RST),
    .SRC_FIFO_almostFULL(SRC_FIFO_almostFULL),
    .SRC_FIFO_FULL      (SRC_FIFO_FULL),
    .SRC_FIFO_WR        (SRC_FIFO_WR),
    .SRC_FIFO_DIN       (SRC_FIFO_DIN),
    .DST_FIFO_almostFULL(DST_FIFO_almostFULL),
    .DST_FIFO_FULL      (DST_FIFO_FULL),
    .DST_FIFO_WR        (DST_FIFO_WR),
    .DST_FIFO_DIN       (DST_FIFO_DIN),
    .ADDR_VALID         (ADDR_VALID),
    .SRC_ADDR           (SRC_ADDR),
    .SRC_LEN            (SRC_LEN),
    .SRC_FIN            (SRC_FIN),
    .SRC_COMMIT         (SRC_COMMIT),
    .DST_ADDR           (DST_ADDR),
    .DST_LEN            (DST_LEN),
    .DST_FIN            (DST_FIN),
    .DST_COMMIT         (DST_COMMIT),
    .BLEND_ALPHA        (BLEND_ALPHA),
    .BLT_CMD            (BLT_CMD),
    .TEXTURE_FMT        (TEXTURE_FMT),
    .ARREADY            (M_AXI_ARREADY),
    .ARVALID            (M_AXI_ARVALID),
    .ARADDR             (VRAMCTRL_ARADDR),
    .ARLEN              (M_AXI_ARLEN),
    .ARSIZE             (M_AXI_ARSIZE),
    .RREADY             (M_AXI_RREADY),
    .RVALID             (M_AXI_RVALID),
    .RLAST              (M_AXI_RLAST),
    .RDATA              (M_AXI_RDATA),
    .RRESP              (M_AXI_RRESP)
);

drw_vramctrl_wr drw_vramctrl_wr (
    .ACLK                   (ACLK),
    .ARST                   (ARST),
    .RST                    (RST),
    .WRT_FIFO_almostEMPTY   (WRT_FIFO_almostEMPTY),
    .WRT_FIFO_EMPTY         (WRT_FIFO_EMPTY),
    .WRT_FIFO_RD            (WRT_FIFO_RD),
    .WRT_FIFO_VALID         (WRT_FIFO_VALID),
    .WRT_FIFO_DOUT          (WRT_FIFO_DOUT),
    .ADDR_VALID             (ADDR_VALID),
    .WRT_ADDR               (WRT_ADDR),
    .WRT_LEN                (WRT_LEN),
    .WRT_FIN                (WRT_FIN),
    .WRT_COMMIT             (WRT_COMMIT),
    .BLEND_ALPHA            (BLEND_ALPHA),
    .BLT_CMD                (BLT_CMD),
    .STEALTH_MODE           (STEALTH_MODE),
    .STEALTH_MASK           (STEALTH_MASK),
    .STEALTH_COLOR_L        (STEALTH_COLOR_L),
    .STEALTH_COLOR_H        (STEALTH_COLOR_H),
    .AWREADY                (M_AXI_AWREADY),
    .AWVALID                (M_AXI_AWVALID),
    .AWADDR                 (VRAMCTRL_AWADDR),
    .AWLEN                  (M_AXI_AWLEN),
    .AWSIZE                 (M_AXI_AWSIZE),
    .WREADY                 (M_AXI_WREADY),
    .WVALID                 (M_AXI_WVALID),
    .WLAST                  (M_AXI_WLAST),
    .WDATA                  (M_AXI_WDATA),
    .WSTRB                  (M_AXI_WSTRB),
    .BREADY                 (M_AXI_BREADY),
    .BVALID                 (M_AXI_BVALID),
    .BRESP                  (M_AXI_BRESP)
);

cmd_fifo_32in32out_2048depth cmd_fifo_32in32out_2048depth (
    .srst               (ARST|RST),
    .clk                (ACLK),
    .din                (CMD_FIFO_DIN),
    .wr_en              (CMD_FIFO_WR),
    .rd_en              (CMD_FIFO_RD),
    .dout               (CMD_FIFO_DOUT),
    .valid              (CMD_FIFO_VALID),
    .full               (CMD_FIFO_FULL),
    .empty              (CMD_FIFO_EMPTY),
    .data_count         (CMD_FIFO_DATA_CNT)
);

wire fifo_rst = !ADDR_VALID;

fifo_32in32out_256depth src_fifo_32in32out_256depth (
    .srst               (ARST|RST|fifo_rst),
    .clk                (ACLK),
    .din                (SRC_FIFO_DIN),
    .wr_en              (SRC_FIFO_WR),
    .rd_en              (SRC_FIFO_RD),
    .dout               (SRC_FIFO_DOUT),
    .valid              (SRC_FIFO_VALID),
    .almost_full        (SRC_FIFO_almostFULL),
    .full               (SRC_FIFO_FULL),
    .almost_empty       (SRC_FIFO_almostEMPTY),
    .empty              (SRC_FIFO_EMPTY),
    .data_count         (SRC_FIFO_DATA_CNT)
);

fifo_32in32out_256depth dst_fifo_32in32out_256depth (
    .srst               (ARST|RST|fifo_rst),
    .clk                (ACLK),
    .din                (DST_FIFO_DIN),
    .wr_en              (DST_FIFO_WR),
    .rd_en              (DST_FIFO_RD),
    .dout               (DST_FIFO_DOUT),
    .valid              (DST_FIFO_VALID),
    .almost_full        (DST_FIFO_almostFULL),
    .full               (DST_FIFO_FULL),
    .almost_empty       (DST_FIFO_almostEMPTY),
    .empty              (DST_FIFO_EMPTY),
    .data_count         (DST_FIFO_DATA_CNT)
);

fifo_32in32out_256depth wrt_fifo_32in32out_256depth (
    .srst               (ARST|RST|fifo_rst),
    .clk                (ACLK),
    .din                (WRT_FIFO_DIN),
    .wr_en              (WRT_FIFO_WR),
    .rd_en              (WRT_FIFO_RD),
    .dout               (WRT_FIFO_DOUT),
    .valid              (WRT_FIFO_VALID), 
    .almost_full        (WRT_FIFO_almostFULL),
    .full               (WRT_FIFO_FULL),
    .almost_empty       (WRT_FIFO_almostEMPTY),
    .empty              (WRT_FIFO_EMPTY),
    .data_count         (WRT_FIFO_DATA_CNT)
);

endmodule
