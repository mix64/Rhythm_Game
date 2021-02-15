// サウンド回路用バッファ管理モジュール

module snd_buffer
(
    input               SND_MCLK,
    input       [5:0]   serial_cnt,

    input               FIFO_VALID,
    input      [31:0]   FIFO_DOUT,
    output              FIFO_RD,

    input               M_BGM_PLAY,

    output wire         SND_DOUT
);

reg  [63:0] buff  = 64'h0000_0000_0000_0000;
reg   [5:0] old_serial_cnt = 6'o00;

// buff
always @ ( posedge SND_MCLK ) begin
    if (!M_BGM_PLAY)
        buff <= 64'h0000_0000_0000_0000;
    else if (FIFO_VALID)
        buff <= { 1'b0, FIFO_DOUT[15:0], 16'h0000, FIFO_DOUT[31:16], 15'o0_0000 };
end

always @ ( posedge SND_MCLK ) begin
    old_serial_cnt <= serial_cnt[5:0];
end

assign SND_DOUT = buff[~serial_cnt];
assign FIFO_RD = (M_BGM_PLAY && (serial_cnt == 6'o00) && (old_serial_cnt == 6'o77));


endmodule // snd_buffer
