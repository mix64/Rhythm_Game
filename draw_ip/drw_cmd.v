// 描画コマンド解析回路

module drw_cmd
(
    /* System signals */
    input               ACLK,
    input               ARST,

    /* regctrl wire */
    input               EXE,
    input               RST,
    output              DRAW_FINISH,
    output reg  [15:0]  ERRNO,

    /* command buffer fifo wire */
    output              FIFO_RD,
    input               FIFO_VALID,
    input       [31:0]  FIFO_DOUT,
    input       [10:0]  FIFO_DATA_CNT,

    /* wait block transfer */
    output              BLT_WAIT,
    input               BLT_FINISH,

    /* draw style */
    output reg          BLEND_ALPHA,    /* 0:OFF, 1:ON */
    output reg          BLT_CMD,        /* 0:PAT, 1:BIT */

    /* draw parameter -> drw_vramctrl_rd */
    output reg          TEXTURE_FMT,    /* 0:ARGB, 1:RGB */

    /* draw parameter -> drw_pixel */
    output reg  [31:0]  FRAME_COLOR,
    output reg          STEALTH_MODE,
    output reg   [3:0]  STEALTH_MASK,
    output reg  [31:0]  STEALTH_COLOR_L,
    output reg  [31:0]  STEALTH_COLOR_H,
    output reg   [2:0]  BLEND_A,
    output reg   [2:0]  BLEND_B,
    output reg   [2:0]  BLEND_C,
    output reg   [2:0]  BLEND_D,
    output reg   [2:0]  BLEND_E,
    output reg   [7:0]  BLEND_SRCCA,
    output reg  [31:0]  BLEND_COEF0,
    output reg  [31:0]  BLEND_COEF1,

    /* draw parameter -> drw_mkaddr */
    output reg  [28:0]  FRAME_ADDR,
    output reg  [10:0]  FRAME_WIDTH,
    output reg  [10:0]  FRAME_HEIGHT,
    output reg  [10:0]  AREA_POSX,
    output reg  [10:0]  AREA_POSY,
    output reg  [10:0]  AREA_SIZX,
    output reg  [10:0]  AREA_SIZY,
    output reg  [28:0]  TEXTURE_ADDR,
    output reg  [11:0]  BLT_DPOSX,
    output reg  [11:0]  BLT_DPOSY,
    output reg  [10:0]  BLT_DSIZX,
    output reg  [10:0]  BLT_DSIZY,
    output reg  [11:0]  BLT_SPOSX,
    output reg  [11:0]  BLT_SPOSY
);

`include "drw_param.vh"

/* State patameter */
localparam S_IDLE   = 3'b000;
localparam S_SETCMD = 3'b001;
localparam S_READCMD= 3'b010;
localparam S_WAIT   = 3'b011;
localparam S_FINISH = 3'b100;
localparam S_ERROR  = 3'b111;
reg [2:0] State = 3'b000;
reg [2:0] nextState = 3'b000;

/* register */                  
reg [31:0] NOW_CMD_reg = 32'h0000_0000;
reg        FIN_CMD = 1'b0;
reg  [1:0] rd_cnt = 2'b00;

wire [31:0] NOW_CMD;

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
        if (EXE)
            nextState <= S_SETCMD;
        else
            nextState <= State;

    S_SETCMD:
        if (FIFO_VALID) begin
            if (FIFO_DOUT[31:24] == C_SETSTMODE || FIFO_DOUT[31:24] == C_SETBLENDOFF)
                nextState <= S_SETCMD;
            else 
                nextState <= S_READCMD;
        end
        else
            nextState <= State;

    S_READCMD:
        if (NOW_CMD[31:24] == C_EODL)
            nextState <= S_FINISH;
        else if (FIN_CMD) begin
            if (NOW_CMD[31]) /* block transfer command */
                nextState <= S_WAIT;
            else /* set draw parameter command */
                nextState <=S_SETCMD;
        end
        else
            nextState <= State;

    S_WAIT:
        if (BLT_FINISH)
            nextState <= S_SETCMD;
        else
            nextState <= State;

    S_FINISH: nextState <= State; /* wait RST */

    S_ERROR: nextState <= State; /* wait RST*/

    default: nextState <= S_IDLE;

    endcase
end

/* ERRNO */
always @ ( posedge ACLK ) begin
    if (ARST || RST)
        ERRNO <= 16'h0000;
end

/* NOW_CMD */
always @ ( posedge ACLK ) begin
    if (ARST || RST)
        NOW_CMD_reg <= 32'h0000_0000;
    else if (State == S_SETCMD && FIFO_VALID)
        NOW_CMD_reg <= FIFO_DOUT[31:0];
end

assign NOW_CMD = (State == S_SETCMD && FIFO_VALID) ? FIFO_DOUT[31:0] : NOW_CMD_reg;

/* rd_cnt */
always @ ( posedge ACLK ) begin
    if (ARST || RST || FIN_CMD)
        rd_cnt <= 2'b00;
    else if (FIFO_VALID)
        rd_cnt <= rd_cnt + 1'b1;
end

/* FIN_CMD */
always @ ( * ) begin
    if (ARST || RST)
        FIN_CMD <= 1'b0;
    else begin
        case(NOW_CMD[31:24])
        C_NOP:           FIN_CMD <= 1'b0;
        C_SETFRAME:      FIN_CMD <= (rd_cnt == N_SETFRAME);
        C_SETDRAWAREA:   FIN_CMD <= (rd_cnt == N_SETDRAWAREA);
        C_SETTEXTURE:    FIN_CMD <= (rd_cnt == N_SETTEXTURE);
        C_SETFCOLOR:     FIN_CMD <= (rd_cnt == N_SETFCOLOR);
        C_SETSTMODE:     FIN_CMD <= (rd_cnt == N_SETSTMODE);
        C_SETSCOLOR:     FIN_CMD <= (rd_cnt == N_SETSCOLOR);
        C_SETBLENDOFF:   FIN_CMD <= (rd_cnt == N_SETBLENDOFF);
        C_SETBLENDALPHA: FIN_CMD <= (rd_cnt == N_SETBLENDALPHA);
        C_PATBLT:        FIN_CMD <= (rd_cnt == N_PATBLT);
        C_BITBLT:        FIN_CMD <= (rd_cnt == N_BITBLT);
        default:         FIN_CMD <= 1'b1;
        endcase
    end
end

/* SETFRAME */
always @ ( posedge ACLK ) begin
    if (ARST || RST) begin
        FRAME_ADDR <= 29'h0;
        FRAME_WIDTH <= 11'h0;
        FRAME_HEIGHT <= 11'h0;
    end
    else if (NOW_CMD[31:24] == C_SETFRAME) begin
        if (rd_cnt == 2'b01 && FIFO_VALID)
            FRAME_ADDR <= { FIFO_DOUT[28:2], 2'b00 };
        else if (rd_cnt == 2'b10 && FIFO_VALID) begin
            FRAME_WIDTH <= FIFO_DOUT[26:16];
            FRAME_HEIGHT <= FIFO_DOUT[10:0];
        end
    end
end

/* SETDRAWAREA */
always @ ( posedge ACLK ) begin
    if (ARST || RST) begin
        AREA_POSX <= 11'h0;
        AREA_POSY <= 11'h0;
        AREA_SIZX <= 11'h0;
        AREA_SIZY <= 11'h0;
    end
    else if (NOW_CMD[31:24] == C_SETDRAWAREA) begin
        if (rd_cnt == 2'b01 && FIFO_VALID) begin
            AREA_POSX <= FIFO_DOUT[26:16];
            AREA_POSY <= FIFO_DOUT[10:0];
        end
        else if (rd_cnt == 2'b10 && FIFO_VALID) begin
            AREA_SIZX <= FIFO_DOUT[26:16];
            AREA_SIZY <= FIFO_DOUT[10:0];
        end
    end
end

/* SETTEXTURE */
always @ ( posedge ACLK ) begin
    if (ARST || RST) begin
        TEXTURE_ADDR <= 29'h0;
        TEXTURE_FMT <= 1'b0;
    end
    else if (NOW_CMD[31:24] == C_SETTEXTURE) begin
        TEXTURE_FMT <= NOW_CMD[0];
        if (rd_cnt == 2'b01 && FIFO_VALID)
            TEXTURE_ADDR <= { FIFO_DOUT[28:2], 2'b00 };
    end
end

/* SETFCOLOR */
always @ ( posedge ACLK ) begin
    if (ARST || RST)
        FRAME_COLOR[31:0] <= 32'h0000_0000;
    else if (NOW_CMD[31:24] == C_SETFCOLOR) begin
        if (rd_cnt == 2'b01 && FIFO_VALID)
            FRAME_COLOR <= FIFO_DOUT[31:0];
    end
end

/* SETSTMODE */
always @ ( posedge ACLK ) begin
    if (ARST || RST)
        STEALTH_MODE <= 1'b0;
    else if (NOW_CMD[31:24] == C_SETSTMODE)
        STEALTH_MODE <= NOW_CMD[0];
end

/* SETSCOLOR */
always @ ( posedge ACLK ) begin
    if (ARST || RST) begin
        STEALTH_MASK <= 4'b1000;
        STEALTH_COLOR_L <= 32'h0000_0000;
        STEALTH_COLOR_H <= 32'h0000_0000;
    end
    else if (NOW_CMD[31:24] == C_SETSCOLOR) begin
        if (TEXTURE_FMT)
            STEALTH_MASK[2:0] <= NOW_CMD[2:0];
        else
            STEALTH_MASK[3:0] <= NOW_CMD[3:0];
        if (rd_cnt == 2'b01 && FIFO_VALID)
            STEALTH_COLOR_L <= FIFO_DOUT[31:0];
        else if (rd_cnt == 2'b10 && FIFO_VALID)
            STEALTH_COLOR_H <= FIFO_DOUT[31:0];
    end
end

/* SETBLENDOFF, SETBLENDALPHA */
always @ ( posedge ACLK ) begin
    if (ARST || RST) begin
        BLEND_ALPHA <= 1'b0;
        BLEND_A <= 3'b000;
        BLEND_B <= 3'b000;
        BLEND_C <= 3'b000;
        BLEND_D <= 3'b000;
        BLEND_E <= 3'b000;
        BLEND_SRCCA <= 8'h00;
        BLEND_COEF0 <= 32'h0000_0000;
        BLEND_COEF1 <= 32'h0000_0000;
    end
    else if (NOW_CMD[31:24] == C_SETBLENDOFF)
        BLEND_ALPHA <= 1'b0;
    else if (NOW_CMD[31:24] == C_SETBLENDALPHA) begin
        BLEND_ALPHA <= 1'b1;
        BLEND_A <= NOW_CMD[22:20];
        BLEND_B <= NOW_CMD[19:17];
        BLEND_C <= NOW_CMD[16:14];
        BLEND_D <= NOW_CMD[13:11];
        BLEND_E <= NOW_CMD[10:8];
        BLEND_SRCCA <= NOW_CMD[7:0];
        if (rd_cnt == 2'b01 && FIFO_VALID)
            BLEND_COEF0 <= FIFO_DOUT[31:0];
        else if (rd_cnt == 2'b10 && FIFO_VALID)
            BLEND_COEF1 <= FIFO_DOUT[31:0];
    end
end

/* PATBLT, BITBLT */
always @ ( posedge ACLK ) begin
    if (ARST || RST) begin
        BLT_CMD <= 1'b0;
        BLT_DPOSX <= 12'h0;
        BLT_DPOSY <= 12'h0;
        BLT_DSIZX <= 11'h0;
        BLT_DSIZY <= 11'h0;
        BLT_SPOSX <= 12'h0;
        BLT_SPOSY <= 12'h0;
    end
    else if (NOW_CMD[31:24] == C_PATBLT) begin
        BLT_CMD <= 1'b0;
        if (rd_cnt == 2'b01 && FIFO_VALID) begin
            BLT_DPOSX <= FIFO_DOUT[27:16];
            BLT_DPOSY <= FIFO_DOUT[11:0];
        end
        else if (rd_cnt == 2'b10 && FIFO_VALID) begin
            BLT_DSIZX <= FIFO_DOUT[26:16];
            BLT_DSIZY <= FIFO_DOUT[10:0];
        end
    end
    else if (NOW_CMD[31:24] == C_BITBLT) begin
        BLT_CMD <= 1'b1;
        if (rd_cnt == 2'b01 && FIFO_VALID) begin
            BLT_DPOSX <= FIFO_DOUT[27:16];
            BLT_DPOSY <= FIFO_DOUT[11:0];
        end
        else if (rd_cnt == 2'b10 && FIFO_VALID) begin
            BLT_DSIZX <= FIFO_DOUT[26:16];
            BLT_DSIZY <= FIFO_DOUT[10:0];
        end
        else if (rd_cnt == 2'b11 && FIFO_VALID) begin
            BLT_SPOSX <= FIFO_DOUT[27:16];
            BLT_SPOSY <= FIFO_DOUT[11:0];
        end
    end
end

assign BLT_WAIT = (State == S_WAIT);
assign FIFO_RD = ((State == S_SETCMD || State == S_READCMD) && (nextState != S_WAIT));
assign DRAW_FINISH = (State == S_FINISH || State == S_ERROR);

endmodule // drw_cmd
