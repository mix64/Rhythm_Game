// 音量管理モジュール

module snd_vol
(
    input           USED,
    input    [7:0]  VOLUME,
    input   [31:0]  FIFO_DOUT,
    output  [15:0]  L_BUFF,
    output  [15:0]  R_BUFF
);

wire [23:0] lbuff = (VOLUME == 8'hFF) ? {FIFO_DOUT[15:0], 8'h00} :
                    (VOLUME == 8'h00) ? { 24'h00 } :
                    (FIFO_DOUT[15]) ? {8'hFF, FIFO_DOUT[15:0] } * (VOLUME + 1'b1) :
                    {8'h00, FIFO_DOUT[15:0] } * (VOLUME + 1'b1); 

wire [23:0] rbuff = (VOLUME == 8'hFF) ? {FIFO_DOUT[31:16], 8'h00} :
                    (VOLUME == 8'h00) ? { 24'h00 } :
                    (FIFO_DOUT[31]) ? {8'hFF, FIFO_DOUT[31:16] } * (VOLUME + 1'b1) :
                    {8'h00, FIFO_DOUT[31:16] } * (VOLUME + 1'b1); 

assign L_BUFF = USED ? lbuff[23:8] : 16'h0000;
assign R_BUFF = USED ? rbuff[23:8] : 16'h0000;

endmodule // snd_vol