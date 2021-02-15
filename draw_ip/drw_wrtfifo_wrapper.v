// 書き込み用FIFOのラッパーモジュール

module drw_wrtfifo_wrapper 
(
    input               ACLK,
    input               ARST,
    input               RST,

    input               ADDR_VALID,
    input               WRT_FIN,

    input               almostEMPTY,
    input               EMPTY,
    input               VALID,
    output              RD,
    input       [31:0]  DOUT,

    input               WREADY,
    output              WVALID,
    output      [31:0]  WDATA
);

reg [1:0] State, nextState;
reg [31:0] wr_buf;
localparam S_IDLE = 2'b00;
localparam S_SET  = 2'b01;
localparam S_RUN  = 2'b10;
localparam S_WAIT = 2'b11;

/* State */
always @ ( posedge ACLK ) begin
    if (ARST || RST || !ADDR_VALID)
        State <= S_IDLE;
    else
        State <= nextState;
end

/* nextState */
always @ ( * ) begin
    case (State)
        S_IDLE:
            if (!EMPTY)
                nextState <= S_SET;
            else
                nextState <= State;

        S_SET:
            nextState <= S_RUN;

        S_RUN:
            if (almostEMPTY && WVALID && WREADY && !WRT_FIN)
                nextState <= S_WAIT;
            else
                nextState <= State;

        S_WAIT:
            if (!EMPTY)
                nextState <= S_RUN;
            else 
                nextState <= State;

        
    endcase
end

/* wr_buf */
always @ ( posedge ACLK ) begin
    if (ARST || RST)
        wr_buf <= 32'h00;
    else if (VALID)
        wr_buf <= DOUT;
end

assign WVALID = (State == S_RUN);
assign RD = (WVALID && WREADY) || (State == S_SET);
assign WDATA = (VALID) ? DOUT : wr_buf;

endmodule // drw_wrtfifo_wrapper 