// サウンド回路からVRAMを読み書きするためのモジュール

module snd_vramctrl
(
    // System Signals
    input               ACLK,
    input               ARST,
    input               RST,

    // Read Address
    output      [7:0]   ARLEN,
    output     [31:0]   ARADDR,
    output              ARVALID,
    input               ARREADY,

    // Read Data
    input               RLAST,
    input               RVALID,
    input      [31:0]   RDATA,
    output              RREADY,

    // fifos  
    output     [31:0]   BGM_FIFO_DIN,
    output              BGM_FIFO_WR,
    input       [9:0]   BGM_WR_DATA_CNT,
    input      [31:0]   BGM_ADDR,
    input       [7:0]   BGM_LEN,
    output     [31:0]   SE1_FIFO_DIN,
    output              SE1_FIFO_WR,
    input       [9:0]   SE1_WR_DATA_CNT,
    input      [31:0]   SE1_ADDR,
    input       [7:0]   SE1_LEN,
    output     [31:0]   SE2_FIFO_DIN,
    output              SE2_FIFO_WR,
    input       [9:0]   SE2_WR_DATA_CNT,
    input      [31:0]   SE2_ADDR,
    input       [7:0]   SE2_LEN,
    output     [31:0]   SE3_FIFO_DIN,
    output              SE3_FIFO_WR,
    input       [9:0]   SE3_WR_DATA_CNT,
    input      [31:0]   SE3_ADDR,
    input       [7:0]   SE3_LEN,
    output     [31:0]   SE4_FIFO_DIN,
    output              SE4_FIFO_WR,
    input       [9:0]   SE4_WR_DATA_CNT,
    input      [31:0]   SE4_ADDR,
    input       [7:0]   SE4_LEN
);

reg  [2:0] fifo_sel   = 3'b000;
reg  [1:0] State      = 2'b00;
reg  [1:0] nextState  = 2'b00;

localparam S_IDLE    = 2'b00;
localparam S_SETADDR = 2'b01;
localparam S_READ    = 2'b10;
localparam S_WAIT    = 2'b11;

localparam SEL_NONE = 3'b000;
localparam SEL_BGM = 3'b001;
localparam SEL_SE1 = 3'b010;
localparam SEL_SE2 = 3'b011;
localparam SEL_SE3 = 3'b100;
localparam SEL_SE4 = 3'b101;


// state FF
always @ ( posedge ACLK ) begin
   if (ARST || RST)
       State <= S_IDLE;
   else
       State <= nextState;
end

always @ ( * ) begin
    case (State)

    S_IDLE:
        if (fifo_sel != SEL_NONE) 
            nextState <= S_SETADDR;
        else
            nextState <= State;
    
    S_SETADDR:
        if (ARVALID && ARREADY)
            nextState <= S_READ;
        else
            nextState <= State;

    S_READ:
        if (RVALID && RREADY && RLAST)
            nextState <= S_WAIT;
        else
            nextState <= State;

    S_WAIT:
        if (fifo_sel != SEL_NONE) 
            nextState <= S_SETADDR;
        else
            nextState <= State;

    endcase
end

// fifo_sel
always @ ( posedge ACLK ) begin
    if (ARST || RST)
        fifo_sel <= SEL_NONE;
    else if (RVALID && RREADY && RLAST)
        fifo_sel <= SEL_NONE;
    else if (State == S_IDLE || State == S_WAIT) begin
        if (BGM_LEN == 8'h00)
            fifo_sel <= SEL_NONE;
        else if (BGM_WR_DATA_CNT == 10'h000)
            fifo_sel <= SEL_BGM;
        else if (SE1_WR_DATA_CNT == 10'h000)
            fifo_sel <= SEL_SE1;
        else if (SE2_WR_DATA_CNT == 10'h000)
            fifo_sel <= SEL_SE2;
        else if (SE3_WR_DATA_CNT == 10'h000)
            fifo_sel <= SEL_SE3;
        else if (SE4_WR_DATA_CNT == 10'h000)
            fifo_sel <= SEL_SE4;      
    end
end


assign ARLEN =  (fifo_sel == SEL_BGM) ? BGM_LEN :
                (fifo_sel == SEL_SE1) ? SE1_LEN :
                (fifo_sel == SEL_SE2) ? SE2_LEN :
                (fifo_sel == SEL_SE3) ? SE3_LEN :
                (fifo_sel == SEL_SE4) ? SE4_LEN : 8'h0;

// assign ARLEN = 8'h1f;

assign ARADDR = (fifo_sel == SEL_BGM) ? BGM_ADDR :
                (fifo_sel == SEL_SE1) ? SE1_ADDR :
                (fifo_sel == SEL_SE2) ? SE2_ADDR :
                (fifo_sel == SEL_SE3) ? SE3_ADDR :
                (fifo_sel == SEL_SE4) ? SE4_ADDR : 32'h0;
assign ARVALID = (State == S_SETADDR);
assign RREADY = (State == S_READ);

assign BGM_FIFO_WR = (fifo_sel == SEL_BGM) ? (RVALID && RREADY) : 1'b0;
assign BGM_FIFO_DIN = (fifo_sel == SEL_BGM) ? RDATA[31:0] : 32'h0;
assign SE1_FIFO_WR = (fifo_sel == SEL_SE1) ? (RVALID && RREADY) : 1'b0;
assign SE1_FIFO_DIN = (fifo_sel == SEL_SE1) ? RDATA[31:0] : 32'h0;
assign SE2_FIFO_WR = (fifo_sel == SEL_SE2) ? (RVALID && RREADY) : 1'b0;
assign SE2_FIFO_DIN = (fifo_sel == SEL_SE2) ? RDATA[31:0] : 32'h0;
assign SE3_FIFO_WR = (fifo_sel == SEL_SE3) ? (RVALID && RREADY) : 1'b0;
assign SE3_FIFO_DIN = (fifo_sel == SEL_SE3) ? RDATA[31:0] : 32'h0;
assign SE4_FIFO_WR = (fifo_sel == SEL_SE4) ? (RVALID && RREADY) : 1'b0;
assign SE4_FIFO_DIN = (fifo_sel == SEL_SE4) ? RDATA[31:0] : 32'h0;

endmodule // snd_vramctrl
