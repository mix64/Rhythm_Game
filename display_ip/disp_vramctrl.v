// 表示回路からVRAMを読み書きするためのモジュール

module disp_vramctrl
  (
    // System Signals
    input           ACLK,
    input           ARST,

    // Read Address
    output  [31:0]  ARADDR,
    output          ARVALID,
    input           ARREADY,
    // Read Data
    input           RLAST,
    input           RVALID,
    output          RREADY,

    input   [1:0]   RESOL,

    input           VRSTART,
    input           DISPON,
    input   [28:0]  DISPADDR,
    input           BUF_WREADY
);

reg [28:0] ADDR_END;
reg [3:0]  N_OVERLAP;

reg [1:0] vr_start;
reg [1:0] state, nextState;
reg [28:0] addr_cnt = 0;
reg [3:0] lap_cnt = 0;
reg [3:0] rd_cnt = 0;

localparam  S_IDLE      = 2'b00;
localparam  S_SETADDR   = 2'b01;
localparam  S_READ      = 2'b10;
localparam  S_WAIT      = 2'b11;

always @ ( posedge ACLK ) begin
    if (nextState == S_IDLE) begin
        if (RESOL == 2'b10) begin // SXGA
            ADDR_END <= 29'h500000; // 1280 x 1024 x4
            N_OVERLAP <= 4'ha; // 64word *10 = 640word (1280 dot)
        end
        else if (RESOL == 2'b01) begin // XGA
            ADDR_END <= 29'h300000; // 1024 x  768 x4
            N_OVERLAP <= 4'h8; // 64word * 8 = 512word (1024 dot)
        end
        else begin // VGA
            ADDR_END <= 29'h12c000; // 640  x  480 x4
            N_OVERLAP <= 4'h5; // 64word * 5 = 320word ( 640 dot)
        end
    end
    else begin
        ADDR_END <= ADDR_END;
        N_OVERLAP <= N_OVERLAP;
    end
end

// state FF
always @( posedge ACLK ) begin
   if( ARST )
       state <= S_IDLE;
   else
       state <= nextState;
end

always @* begin
    case (state)
    S_IDLE:
        if (~DISPON || ARST) begin
            nextState <= S_IDLE;
        end
        else if (vr_start[1]) begin
            nextState <= S_SETADDR;
        end
        else begin
            nextState <= state;
        end

    S_SETADDR:
        if (~DISPON || ARST) begin
            nextState <= S_IDLE;
        end
        else if (lap_cnt == N_OVERLAP) begin
            nextState <= S_READ;
        end
        else begin
            nextState <= state;
        end

    S_READ :
        if (~DISPON || ARST) begin
            nextState <= S_IDLE;
        end
        else if (rd_cnt == N_OVERLAP) begin
            nextState <= S_WAIT;
        end
        else begin
            nextState <= state;
        end

    S_WAIT :
        if (~DISPON || ARST) begin
            nextState <= S_IDLE;
        end
        else if (addr_cnt == 29'h0) begin
            nextState <= S_IDLE;
        end
        else if (BUF_WREADY) begin
            nextState <= S_SETADDR;
        end
        else begin
            nextState <= state;
        end

    default :
       nextState <= S_IDLE;
    endcase
end

// VRSTART
always @ ( posedge ACLK ) begin
    if (ARST || ~DISPON) begin
        vr_start[1:0] <= 2'b00;
    end
    else begin
        vr_start[1] = vr_start[0];
        vr_start[0] = VRSTART;
    end
end

// rd_cnt
always @ ( posedge ACLK ) begin
    if (ARST || ~DISPON) begin
        rd_cnt <= 4'b0;
    end
    else if (RLAST && RVALID)begin
        rd_cnt <= rd_cnt + 1'b1;
    end
    else if (nextState == S_WAIT) begin
        rd_cnt <= 4'b0;
    end
end

// lap_cnt
always @ ( posedge ACLK ) begin
    if (ARST || ~DISPON) begin
        lap_cnt <= 4'b0;
    end
    else if ((nextState == S_SETADDR) && ARREADY)begin
        lap_cnt <= lap_cnt + 1'b1;
    end
    else if (nextState != S_SETADDR) begin
        lap_cnt <= 4'b0;
    end
end

// addr_cnt
always @ ( posedge ACLK ) begin
    if (ARST || ~DISPON) begin
        addr_cnt <= 0;
    end
    else if (addr_cnt == ADDR_END) begin
            addr_cnt <= 0;
        end
    else if ((nextState == S_SETADDR) && ARREADY) begin
        addr_cnt <= addr_cnt + 29'h200; // 64x2x4 = 512
    end
end

assign ARVALID = ((nextState == S_SETADDR) && DISPON);
assign ARADDR = {3'b000, (DISPADDR+addr_cnt)};
assign RREADY = DISPON;
endmodule
