// サウンド用FIFOのラッパーモジュール

module snd_fifo_wrap
(
    // system 
    input               ACLK,
    input               ARST,
    input               RST,
    input               SND_MCLK,

    // snd_mix
    input               FIFO_RD,
    output              FIFO_VALID,
    output      [31:0]  FIFO_DOUT,

    // vramctrl
    input               FIFO_WR,
    input       [31:0]  FIFO_DIN,
    output       [9:0]  WR_DATA_CNT,
    output      [31:0]  ADDR,
    output       [7:0]  LEN,

    // regctrl
    output              FIFO_FIN,
    input       [31:0]  BASEADDR,
    input       [31:0]  SIZE
);

reg [31:0]  offset;

fifo_32in32out_1024depth fifo_32in32out_1024depth (
    .rst                (ARST || RST),
    .wr_clk             (ACLK),
    .rd_clk             (SND_MCLK),
    .din                (FIFO_DIN),
    .wr_en              (FIFO_WR),
    .rd_en              (FIFO_RD),
    .dout               (FIFO_DOUT),
    .valid              (FIFO_VALID),
    .wr_data_count      (WR_DATA_CNT)
);

always @ ( posedge ACLK ) begin
    if (ARST || RST || FIFO_FIN)
        offset <= 32'h0;
    else if (FIFO_WR)
        offset <= offset + 32'h4;
end

assign FIFO_FIN = (LEN == 8'h0 && WR_DATA_CNT == 10'b0);
assign ADDR = BASEADDR + offset;
wire [31:0] rem_size = (SIZE - offset);
assign LEN = (rem_size == 32'h0) ? 8'h00: (rem_size < 32'h80) ? rem_size[9:2]-1'b1 : 8'h1F;

endmodule // snd_fifo_wrap