// 画面表示用のバッファー
// バッファーに書き込み終わったら表示する

module disp_buffer
  (
    // System Signals
    input               ACLK,
    input               ARST,

    input               DCLK,
    input               DRST,

    input               DISPON,
    input               FIFORST,
    input   [63:0]      FIFOIN,
    input               FIFOWR,
    input               DSP_preDE,
    output              BUF_WREADY,
    output              BUF_OVER,
    output              BUF_UNDER,

    output  reg [7:0]   DSP_R, DSP_G, DSP_B,
    output  reg         DSP_DE
    );

wire [23:0] dout;
wire [9:0] data_count;
reg dsp_de_flag; // DSP_DEの1クロック前


/* FIFO */
fifo_48in24out_1024depth fifo_48in24out_1024depth(
  .rst          (FIFORST|ARST|DRST),
  .wr_clk       (ACLK),
  .rd_clk       (DCLK),
  .din          ({FIFOIN[23:0], FIFOIN[55:32]}),
  .wr_en        (FIFOWR),
  .rd_en        (DSP_preDE && DISPON),
  .dout         (dout),
  .overflow     (BUF_OVER),
  .underflow    (BUF_UNDER),
  .wr_data_count(data_count)
);

always @ ( * ) begin
    if (DISPON && DSP_DE) begin
        DSP_R <= dout[23:16];
        DSP_G <= dout[15:8];
        DSP_B <= dout[7:0];
    end
    else begin
        DSP_R <= 8'h00;
        DSP_G <= 8'h00;
        DSP_B <= 8'h00;
    end
end

always @ ( posedge DCLK ) begin
    if (DRST) begin
        DSP_DE <= 1'b0;
        dsp_de_flag <= 1'b0;
    end
    else begin
        DSP_DE = dsp_de_flag;
        dsp_de_flag = DSP_preDE;
    end
end

assign BUF_WREADY = (data_count <= 10'd300);


endmodule
