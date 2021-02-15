// キャプチャ回路からVRAMを読み書きするためのモジュール

module cap_vramctrl
    (
    // System Signals
    input               ACLK,
    input               ARST,

    // Camera reset
    input               PRST,

    // Write Address
    output [31:0]       AWADDR,
    output              AWVALID,
    input               AWREADY,
    input   [7:0]       AWLEN, // == 31 (32word)

    // Write Data
    output reg [63:0]   WDATA,
    output reg          WVALID,
    output              WLAST,
    input               WREADY,

    // B Channel
    input  [1:0]        BRESP, // 2'b00:OK, 2'b10:NG
    input               BVALID,
    output              BREADY,

    input  [1:0]        RESOL,

    // Read FIFO
    input [10:0]        RD_DATA_CNT,
    input               FIFO_VALID,
    input [47:0]        FIFO_DOUT,
    output reg          FIFO_RD,

    // Capture Register
    input [28:0]        CAP_ADDR
    );

reg [28:0] ADDR_END;

reg [1:0] State, nextState;
reg [28:0] addr_cnt = 29'h0;
reg [28:0] wr_cnt = 29'h0;

localparam  S_IDLE     = 2'b00;
localparam  S_SETADDR  = 2'b01;
localparam  S_WRITE    = 2'b10;
localparam  S_WAIT     = 2'b11;

always @ ( posedge ACLK ) begin
    if (State == S_IDLE) begin
        if (RESOL == 2'b10) // SXGA
            ADDR_END <= 29'h500000; // 1280 x 1024 x 4
        else if (RESOL == 2'b01) // XGA
            ADDR_END <= 29'h300000; // 1024 x 768 x 4
        else // VGA
            ADDR_END <= 29'h12c000; // 640 x 480 x 4
    end
end

always @ ( posedge ACLK ) begin
    if (ARST)
        State <= S_IDLE;
    else
        State <= nextState;
end

always @ ( * ) begin
    case (State)

    S_IDLE:
        if (RD_DATA_CNT > AWLEN)
            nextState <= S_SETADDR;
        else
            nextState <= State;

    S_SETADDR:
        if (AWVALID && AWREADY)
            nextState <= S_WRITE;
        else
            nextState <= State;

    S_WRITE:
        if (WVALID && WREADY && WLAST)
            nextState <= S_WAIT;
        else
            nextState <= State;

    S_WAIT:
        if (PRST || (addr_cnt == 29'h0))
            nextState <= S_IDLE;
        else if (RD_DATA_CNT > AWLEN)
            nextState <= S_SETADDR;
        else
            nextState <= State;

    endcase
end

// FIFO_RD
always @ ( posedge ACLK ) begin
    if (ARST || PRST)
        FIFO_RD <= 1'b0;
    else if (((State == S_SETADDR) || (State == S_WRITE)) && !WVALID && !FIFO_VALID && !FIFO_RD)
        FIFO_RD <= 1'b1;
    else
        FIFO_RD <= 1'b0;
end

// WDATA
always @ ( posedge ACLK ) begin
    if (ARST || PRST)
        WDATA <= 64'h0;
    else if (FIFO_VALID)
        WDATA <= {8'h00, FIFO_DOUT[47:24], 8'h00, FIFO_DOUT[23:0]};
end

// WVALID
always @ ( posedge ACLK ) begin
    if (ARST)
        WVALID <= 1'b0;
    else if (State == S_WRITE && PRST)
        WVALID <= 1'b1;
    else if (FIFO_VALID)
        WVALID <= 1'b1;
    else if (WREADY && WVALID)
        WVALID <= 1'b0;
end

// addr_cnt
always @ ( posedge ACLK ) begin
    if (ARST || PRST)
        addr_cnt <= 29'h0;
    else if (addr_cnt == ADDR_END)
        addr_cnt <= 29'h0;
    else if (AWREADY && AWVALID)
        addr_cnt <= addr_cnt + 29'h100; // 32x8 = 256
end

// wr_cnt
always @ ( posedge ACLK ) begin
    if (ARST)
        wr_cnt <= 29'h0;
    else if (WVALID && WREADY) begin
        if (WLAST)
            wr_cnt <= 29'h0;
        else
            wr_cnt <= wr_cnt + 1'b1;
    end
end

assign AWADDR = {3'b000, (CAP_ADDR + addr_cnt)};
assign AWVALID = (State == S_SETADDR);

assign WLAST = (wr_cnt == AWLEN);

assign BREADY = 1'b1;

endmodule // cap_vramctrl
