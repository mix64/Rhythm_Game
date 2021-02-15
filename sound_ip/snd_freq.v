// サウンド用クロック生成回路

module snd_freq
(
    input        SND_MCLK,
    output       SND_BCLK,
    output       SND_LRCLK,
    output [5:0] serial_cnt
);

reg [7:0] cnt = 8'h00;

always @ ( posedge SND_MCLK ) begin
    cnt <= cnt + 1'b1;
end

assign SND_BCLK = cnt[1];
assign SND_LRCLK = cnt[7];
assign serial_cnt = cnt[7:2];

endmodule // snd_freq
