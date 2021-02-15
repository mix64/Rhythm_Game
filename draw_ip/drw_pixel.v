// ピクセル管理回路
// 読み込んだ画像やコマンドに応じて描画内容をピクセル単位で管理し、書き込み回路にわたす。

module drw_pixel
(
    /* System signals */
    input               ACLK,
    input               ARST,
    input               RST,

    /* draw style from drw_cmd */
    input               BLEND_ALPHA,    /* 0:OFF, 1:ON */
    input               BLT_CMD,        /* 0:PAT, 1:BIT */
    input               ADDR_VALID,

    /* FIFO buffer wire */
    input               SRC_FIFO_almostEMPTY,
    input               SRC_FIFO_EMPTY,
    output              SRC_FIFO_RD,
    input               SRC_FIFO_VALID,
    input       [31:0]  SRC_FIFO_DOUT,
    input               DST_FIFO_almostEMPTY,
    input               DST_FIFO_EMPTY,
    output              DST_FIFO_RD,
    input               DST_FIFO_VALID,
    input       [31:0]  DST_FIFO_DOUT,
    input       [8:0]   WRT_FIFO_DATA_CNT,
    output              WRT_FIFO_WR,
    output      [31:0]  WRT_FIFO_DIN,

    /* draw parameter */
    input       [31:0]  FRAME_COLOR,
    input               STEALTH_MODE,
    input        [3:0]  STEALTH_MASK,
    input       [31:0]  STEALTH_COLOR_L,
    input       [31:0]  STEALTH_COLOR_H,
    input        [2:0]  BLEND_A,
    input        [2:0]  BLEND_B,
    input        [2:0]  BLEND_C,
    input        [2:0]  BLEND_D,
    input        [2:0]  BLEND_E,
    input        [7:0]  BLEND_SRCCA,
    input       [31:0]  BLEND_COEF0,
    input       [31:0]  BLEND_COEF1
);

wire WRT_FIFO_available = (WRT_FIFO_DATA_CNT[8:0] < 9'hFF);

wire [1:0] DRW_CMD = {BLT_CMD, BLEND_ALPHA};
localparam PAT_OFF   = 2'b00;
localparam PAT_ALPHA = 2'b01;
localparam BIT_OFF   = 2'b10;
localparam BIT_ALPHA = 2'b11;

/* State register */
reg [3:0] State = 4'b0000;
reg [3:0] nextState = 4'b0000;

/* State parameter */
localparam S_IDLE = 4'b0000;
localparam S_CONV_00_WAIT = 4'b0001;
localparam S_CONV_00_RUNN = 4'b0010;
localparam S_CONV_01_WAIT = 4'b0101;
localparam S_CONV_01_RUNN = 4'b0110;
localparam S_CONV_10_WAIT = 4'b1001;
localparam S_CONV_10_RUNN = 4'b1010;
localparam S_CONV_11_WAIT = 4'b1101;
localparam S_CONV_11_RUNN = 4'b1110;

/* wire for Blend alpha execute*/
reg [31:0] A;
reg [31:0] B;
reg [31:0] C;
reg [31:0] D;
reg [31:0] E;
reg blend_ready = 1'b0;
wire [3:0] st_flag1;
reg st_flag;
reg [4:0] wr_cnt = 5'h0;

drw_pixel_blend drw_pixel_blend (
    .ACLK       (ACLK),
    .ARST       (ARST),
    .RST        (RST),
    .A          (A),
    .B          (B),
    .C          (C),
    .D          (D),
    .E          (E),
    .READY      (blend_ready),
    .IGNORE     (!BLEND_ALPHA || st_flag),
    .VALID      (WRT_FIFO_WR),
    .Z          (WRT_FIFO_DIN)
);

always @ ( posedge ACLK ) begin
    if (ARST || RST || !ADDR_VALID)
        State <= S_IDLE;
    else
        State <= nextState;
end

always @ ( * ) begin
    case (State)

        S_IDLE:
            if (ADDR_VALID) begin
                if (DRW_CMD == PAT_OFF)
                    nextState <= S_CONV_00_WAIT;
                else if (DRW_CMD == PAT_ALPHA)
                    nextState <= S_CONV_01_WAIT;
                else if (DRW_CMD == BIT_OFF)
                    nextState <= S_CONV_10_WAIT;
                else /* (DRW_CMD == BIT_ALPHA) */
                    nextState <= S_CONV_11_WAIT;
            end
            else
                nextState <= State;

/* 
 * PATBLT (BLEND OFF) 
 */
        S_CONV_00_WAIT:
            if (WRT_FIFO_available)
                nextState <= S_CONV_00_RUNN;
            else
                nextState <= State;

        S_CONV_00_RUNN:
            if (WRT_FIFO_available)
                nextState <= State;
            else
                nextState <= S_CONV_00_WAIT;

/*
 * PATBLT (BLEND ON)
 */
        S_CONV_01_WAIT:
            if (WRT_FIFO_available) 
                nextState <= S_CONV_01_RUNN;
            else
                nextState <= State;

        S_CONV_01_RUNN:
            if (WRT_FIFO_available)
                nextState <= State;
            else
                nextState <= S_CONV_01_WAIT;

/*
 * BITBLT (BLEND OFF)
 */
        S_CONV_10_WAIT:
            if (WRT_FIFO_available && !SRC_FIFO_EMPTY) 
                nextState <= S_CONV_10_RUNN;
            else
                nextState <= State;

        S_CONV_10_RUNN:
            if (WRT_FIFO_available && !SRC_FIFO_almostEMPTY)
                nextState <= State;
            else
                nextState <= S_CONV_10_WAIT;

/*
 * BITBLT (BLEND ON)
 */
        S_CONV_11_WAIT:
            if (WRT_FIFO_available && !SRC_FIFO_EMPTY && !DST_FIFO_EMPTY) 
                nextState <= S_CONV_11_RUNN;
            else
                nextState <= State;

        S_CONV_11_RUNN:
            if (WRT_FIFO_available && !SRC_FIFO_almostEMPTY && !DST_FIFO_almostEMPTY) 
                nextState <= State;
            else
                nextState <= S_CONV_11_WAIT;

        default: nextState <= S_IDLE;
    endcase
end

/* blend_ready */
always @ ( posedge ACLK ) begin
    if (ARST || RST)
        blend_ready <= 1'b0;
    else if (State == S_CONV_00_RUNN)
        blend_ready <= 1'b1;
    else if (State == S_CONV_01_RUNN)
        blend_ready <= DST_FIFO_VALID;
    else if (State == S_CONV_10_RUNN)
        blend_ready <= SRC_FIFO_VALID;
    else if (State == S_CONV_11_RUNN)
        blend_ready <= DST_FIFO_VALID;
    else 
        blend_ready <= 1'b0;
end

/* A */
always @ ( posedge ACLK ) begin
    case(BLEND_A)
    3'b000: 
        if (BLT_CMD)
            A <= SRC_FIFO_DOUT[31:0];
        else
            A <= FRAME_COLOR[31:0];
    3'b001: A <= DST_FIFO_DOUT[31:0];
    3'b010: A <= {BLEND_SRCCA[7:0], BLEND_SRCCA[7:0], BLEND_SRCCA[7:0], BLEND_SRCCA[7:0]};
    3'b011:
        if (BLT_CMD)
            A <= {SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24]};
        else
            A <= {FRAME_COLOR[31:24], FRAME_COLOR[31:24], FRAME_COLOR[31:24], FRAME_COLOR[31:24]};
    3'b100: A <= {DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24]};
    3'b101: A <= BLEND_COEF0[31:0];
    3'b110: A <= BLEND_COEF1[31:0];
    default: 
        if (BLT_CMD)
            A <= SRC_FIFO_DOUT[31:0];
        else
            A <= FRAME_COLOR[31:0];
    endcase
end

/* B */
always @ ( posedge ACLK ) begin
    case(BLEND_B)
    3'b000: 
        if (BLT_CMD)
            B <= SRC_FIFO_DOUT[31:0];
        else
            B <= FRAME_COLOR[31:0];
    3'b001: B <= DST_FIFO_DOUT[31:0];
    3'b010: B <= {BLEND_SRCCA[7:0], BLEND_SRCCA[7:0], BLEND_SRCCA[7:0], BLEND_SRCCA[7:0]};
    3'b011:
        if (BLT_CMD)
            B <= {SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24]};
        else
            B <= {FRAME_COLOR[31:24], FRAME_COLOR[31:24], FRAME_COLOR[31:24], FRAME_COLOR[31:24]};
    3'b100: B <= {DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24]};
    3'b101: B <= BLEND_COEF0[31:0];
    3'b110: B <= BLEND_COEF1[31:0];
    default: 
        if (BLT_CMD)
            B <= SRC_FIFO_DOUT[31:0];
        else
            B <= FRAME_COLOR[31:0];
    endcase
end

/* C */
always @ ( posedge ACLK ) begin
    case(BLEND_C)
    3'b000: 
        if (BLT_CMD)
            C <= SRC_FIFO_DOUT[31:0];
        else
            C <= FRAME_COLOR[31:0];
    3'b001: C <= DST_FIFO_DOUT[31:0];
    3'b010: C <= {BLEND_SRCCA[7:0], BLEND_SRCCA[7:0], BLEND_SRCCA[7:0], BLEND_SRCCA[7:0]};
    3'b011:
        if (BLT_CMD)
            C <= {SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24]};
        else
            C <= {FRAME_COLOR[31:24], FRAME_COLOR[31:24], FRAME_COLOR[31:24], FRAME_COLOR[31:24]};
    3'b100: C <= {DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24]};
    3'b101: C <= BLEND_COEF0[31:0];
    3'b110: C <= BLEND_COEF1[31:0];
    default: 
        if (BLT_CMD)
            C <= SRC_FIFO_DOUT[31:0];
        else
            C <= FRAME_COLOR[31:0];
    endcase
end

/* D */
always @ ( posedge ACLK ) begin
    if (BLEND_ALPHA && !(&st_flag1 && STEALTH_MODE)) begin
        case(BLEND_D)
        3'b000: 
            if (BLT_CMD)
                D <= SRC_FIFO_DOUT[31:0];
            else
                D <= FRAME_COLOR[31:0];
        3'b001: D <= DST_FIFO_DOUT[31:0];
        3'b010: D <= {BLEND_SRCCA[7:0], BLEND_SRCCA[7:0], BLEND_SRCCA[7:0], BLEND_SRCCA[7:0]};
        3'b011:
            if (BLT_CMD)
                D <= {SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24]};
            else
                D <= {FRAME_COLOR[31:24], FRAME_COLOR[31:24], FRAME_COLOR[31:24], FRAME_COLOR[31:24]};
        3'b100: D <= {DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24]};
        3'b101: D <= BLEND_COEF0[31:0];
        3'b110: D <= BLEND_COEF1[31:0];
        default: 
            if (BLT_CMD)
                D <= SRC_FIFO_DOUT[31:0];
            else
                D <= FRAME_COLOR[31:0];
        endcase
    end
    else begin
        if (BLT_CMD)
            D <= SRC_FIFO_DOUT[31:0];
        else 
            D <= FRAME_COLOR[31:0];
    end
end

/* E */
always @ ( posedge ACLK ) begin
    case(BLEND_E)
    3'b000: 
        if (BLT_CMD)
            E <= SRC_FIFO_DOUT[31:0];
        else
            E <= FRAME_COLOR[31:0];
    3'b001: E <= DST_FIFO_DOUT[31:0];
    3'b010: E <= {BLEND_SRCCA[7:0], BLEND_SRCCA[7:0], BLEND_SRCCA[7:0], BLEND_SRCCA[7:0]};
    3'b011:
        if (BLT_CMD)
            E <= {SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24], SRC_FIFO_DOUT[31:24]};
        else
            E <= {FRAME_COLOR[31:24], FRAME_COLOR[31:24], FRAME_COLOR[31:24], FRAME_COLOR[31:24]};
    3'b100: E <= {DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24], DST_FIFO_DOUT[31:24]};
    3'b101: E <= BLEND_COEF0[31:0];
    3'b110: E <= BLEND_COEF1[31:0];
    default: 
        if (BLT_CMD)
            E <= SRC_FIFO_DOUT[31:0];
        else
            E <= FRAME_COLOR[31:0];
    endcase
end

assign st_flag1[0] = (STEALTH_MASK[0] || (SRC_FIFO_DOUT[7:0] >= STEALTH_COLOR_L[7:0] && SRC_FIFO_DOUT[7:0] <= STEALTH_COLOR_H[7:0]));
assign st_flag1[1] = (STEALTH_MASK[1] || (SRC_FIFO_DOUT[15:8] >= STEALTH_COLOR_L[15:8] && SRC_FIFO_DOUT[15:8] <= STEALTH_COLOR_H[15:8]));       
assign st_flag1[2] = (STEALTH_MASK[2] || (SRC_FIFO_DOUT[23:16] >= STEALTH_COLOR_L[23:16] && SRC_FIFO_DOUT[23:16] <= STEALTH_COLOR_H[23:16]));
assign st_flag1[3] = (STEALTH_MASK[3] || (SRC_FIFO_DOUT[31:24] >= STEALTH_COLOR_L[31:24] && SRC_FIFO_DOUT[31:24] <= STEALTH_COLOR_H[31:24]));

always @ ( posedge ACLK ) begin
    st_flag <= (&st_flag1 && STEALTH_MODE); /* 1なら透過 */
end

assign SRC_FIFO_RD = nextState[3] && nextState[1];
assign DST_FIFO_RD = nextState[2] && nextState[1];

reg [31:0] debug_src;
reg [31:0] debug_wrt;

always @ ( posedge ACLK ) begin
    if (ARST|RST) begin
        debug_src <= 32'h0;
        debug_wrt <= 32'h0;
    end
    else begin
        if (SRC_FIFO_RD)
            debug_src <= debug_src + 1'b1;
        if (WRT_FIFO_WR)
            debug_wrt <= debug_wrt + 1'b1;
    end
end

endmodule // drw_pixel
