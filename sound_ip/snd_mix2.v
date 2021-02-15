// サウンド合成回路の補助モジュール

module snd_mix2
(
    input   [15:0]  IN1,
    input   [15:0]  IN2, 
    output  [15:0]  OUT
);

wire [15:0] IN12 = IN1 + IN2;

assign OUT = (IN1[15] == IN2[15] && IN12[15] != IN1[15]) ? (IN1[15]) ? 16'h8000 : 16'h7FFF : IN12;

endmodule // snd_mix2