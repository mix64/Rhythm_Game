// サウンド回路のコントロールレジスタ

module snd_regctrl
(
    // System Signals
    input                  ACLK,
    input                  ARST,

    /* regbus */
    input          [15:0]  WRADDR,
    input          [3:0]   BYTEEN,
    input                  WREN,
    input          [31:0]  WDATA,
    input          [15:0]  RDADDR,
    input                  RDEN,
    output  reg    [31:0]  RDATA,

    // fifos
    input                  BGM_FIN,
    input                  SE1_FIN,
    input                  SE2_FIN,
    input                  SE3_FIN,
    input                  SE4_FIN,

    /* param */
    output                 RST,
    output  reg    [31:0]  BGM_ADDR,
    output  reg    [31:0]  BGM_SIZE,
    output          [7:0]  BGM_VOLUME,
    output                 BGM_PLAY,
    output  reg    [31:0]  SE_ADDR,
    output  reg    [31:0]  SE_SIZE,
    output          [7:0]  SE_VOLUME,
    output  reg     [3:0]  SE_SELECT
);

/*
 *  0x3000 - BGM_ADDR - R/W
 *  0x3004 - BGM_SIZE - R/W
 *  0x3008 - SE_ADDR  - R/W
 *  0x300C - SE_SIZE  - R/W
 *  0x3010 - SND_VOL  - R/W  - (BGMVOL[7:0], SEVOL[15:8]) 
 *  0x3014 - SND_CTRL - W    - 0:RST, 1:BGMPlay, 2:SEPlay(one shot)
 */

reg [31:0] SND_VOL;
reg [31:0] SND_CTRL;

// BGM_ADDR
always @ ( posedge ACLK ) begin
    if (ARST)
        BGM_ADDR[31:0] <= 32'h0000_0000;
    else if (WREN && (WRADDR == 16'h3000)) begin
        if (BYTEEN[3])
            BGM_ADDR[31:24] <= {3'b000, WDATA[28:24]};
        if (BYTEEN[2])
            BGM_ADDR[23:16] <= WDATA[23:16];
        if (BYTEEN[1])
            BGM_ADDR[15:8] <= WDATA[15:8];
        if (BYTEEN[0])
            BGM_ADDR[7:0] <= {WDATA[7:2], 2'b00};
    end
end

// BGM_SIZE
always @ ( posedge ACLK ) begin
    if (ARST)
        BGM_SIZE[31:0] <= 32'h0000_0000;
    else if (WREN && (WRADDR == 16'h3004)) begin
        if (BYTEEN[3])
            BGM_SIZE[31:24] <= {3'b000, WDATA[28:24]};
        if (BYTEEN[2])
            BGM_SIZE[23:16] <= WDATA[23:16];
        if (BYTEEN[1])
            BGM_SIZE[15:8] <= WDATA[15:8];
        if (BYTEEN[0])
            BGM_SIZE[7:0] <= WDATA[7:0];
    end
end

// SE_ADDR
always @ ( posedge ACLK ) begin
    if (ARST)
        SE_ADDR[31:0] <= 32'h0000_0000;
    else if (WREN && (WRADDR == 16'h3008)) begin
        if (BYTEEN[3])
            SE_ADDR[31:24] <= {3'b000, WDATA[28:24]};
        if (BYTEEN[2])
            SE_ADDR[23:16] <= WDATA[23:16];
        if (BYTEEN[1])
            SE_ADDR[15:8] <= WDATA[15:8];
        if (BYTEEN[0])
            SE_ADDR[7:0] <= {WDATA[7:2], 2'b00};
    end
end

// SE_SIZE
always @ ( posedge ACLK ) begin
    if (ARST)
        SE_SIZE[31:0] <= 32'h0000_0000;
    else if (WREN && (WRADDR == 16'h300C)) begin
        if (BYTEEN[3])
            SE_SIZE[31:24] <= {3'b000, WDATA[28:24]};
        if (BYTEEN[2])
            SE_SIZE[23:16] <= WDATA[23:16];
        if (BYTEEN[1])
            SE_SIZE[15:8] <= WDATA[15:8];
        if (BYTEEN[0])
            SE_SIZE[7:0] <= WDATA[7:0];
    end
end


// SND_VOL
always @ ( posedge ACLK ) begin
    if (ARST)
        SND_VOL[31:0] <= 32'h0000_0000;
    else if (WREN && (WRADDR == 16'h3010)) begin
        if (BYTEEN[1])
            SND_VOL[15:8] <= WDATA[15:8];
        if (BYTEEN[0])
            SND_VOL[7:0] <= WDATA[7:0];
    end
end

// SND_CTRL
always @ ( posedge ACLK ) begin
    if (ARST)
        SND_CTRL[31:0] <= 32'h0000_0000;
    else if (WREN && (WRADDR == 16'h3014) && BYTEEN[0])
        SND_CTRL[1] <= WDATA[1];
    else if (BGM_FIN) // 再生終了時
        SND_CTRL[1] <= 1'b0; // BGM, SE
end

wire SE_PLAY = (WREN && (WRADDR == 16'h3014) && BYTEEN[0] && WDATA[2]);
// SE_SELECT
always @ ( posedge ACLK ) begin
    if (ARST)
        SE_SELECT[3:0] <= 4'h0;
    else if (SE1_FIN | SE2_FIN | SE3_FIN | SE4_FIN) begin
        if (SE1_FIN)
            SE_SELECT[0] <= 1'b0;
        if (SE2_FIN)
            SE_SELECT[1] <= 1'b0;
        if (SE3_FIN)
            SE_SELECT[2] <= 1'b0;
        if (SE4_FIN)
            SE_SELECT[3] <= 1'b0;
    end
    else if (SE_PLAY) begin
        if (!SE_SELECT[0])
            SE_SELECT[0] <= 1'b1;
        else if (!SE_SELECT[1])
            SE_SELECT[1] <= 1'b1;
        else if (!SE_SELECT[2])
            SE_SELECT[2] <= 1'b1;
        else if (!SE_SELECT[3])
            SE_SELECT[3] <= 1'b1;
    end
end

// read
always @ ( posedge ACLK ) begin
    if (ARST)
        RDATA[31:0] <= 32'd0;
    else if (RDEN) begin
        case (RDADDR)
            16'h3000: RDATA[31:0] <= BGM_ADDR[31:0];
            16'h3004: RDATA[31:0] <= BGM_SIZE[31:0];
            16'h3008: RDATA[31:0] <= SE_ADDR[31:0];
            16'h300C: RDATA[31:0] <= SE_SIZE[31:0];
            16'h3010: RDATA[31:0] <= SND_VOL [31:0];
            16'h3014: RDATA[31:0] <= SND_CTRL[31:0];
            default:  RDATA[31:0] <= 32'hDEADFACE;
        endcase
    end
end

assign BGM_VOLUME = SND_VOL[7:0];
assign BGM_PLAY = SND_CTRL[1];
assign SE_VOLUME = SND_VOL[15:8];
assign RST = (WREN && (WRADDR == 16'h3014) && BYTEEN[0] && WDATA[0]);


endmodule
