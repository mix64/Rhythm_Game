// YUVからRGBに変換する回路

module yuv2rgb (
    input             PCLK,
    input       [7:0] U,
    input       [7:0] Y0,
    input       [7:0] V,
    input       [7:0] Y1,
    input             READY,

    output            VALID,
    output     [47:0] RGB
    );

reg [18:0] R0 = 19'h0;
reg [18:0] G0 = 19'h0;
reg [18:0] B0 = 19'h0;
reg [18:0] R1 = 19'h0;
reg [18:0] G1 = 19'h0;
reg [18:0] B1 = 19'h0;

reg state = 1'b0;

always @ ( posedge PCLK ) begin
    if (READY) begin
        R0 <= Y0 * 'h100 + V * 'h164 - 'hb380;
        G0 <= Y0 * 'h100 - V * 'h0b7 - U * 'h058 + 'h8780;
        B0 <= Y0 * 'h100 + U * 'h1c6 - 'he300;
        R1 <= Y1 * 'h100 + V * 'h164 - 'hb380;
        G1 <= Y1 * 'h100 - V * 'h0b7 - U * 'h058 + 'h8780;
        B1 <= Y1 * 'h100 + U * 'h1c6 - 'he300;
    end
end

// state
always @ ( posedge PCLK ) begin
    if (READY) state <= 1'b1;
    else state <= 1'b0;
end

assign VALID = state;
assign RGB[7:0]   = (B0[18]) ? 8'h00: (B0[17] || B0[16]) ? 8'hFF: B0[15:8];
assign RGB[15:8]  = (G0[18]) ? 8'h00: (G0[17] || G0[16]) ? 8'hFF: G0[15:8];
assign RGB[23:16] = (R0[18]) ? 8'h00: (R0[17] || R0[16]) ? 8'hFF: R0[15:8];
assign RGB[31:24] = (B1[18]) ? 8'h00: (B1[17] || B1[16]) ? 8'hFF: B1[15:8];
assign RGB[39:32] = (G1[18]) ? 8'h00: (G1[17] || G1[16]) ? 8'hFF: G1[15:8];
assign RGB[47:40] = (R1[18]) ? 8'h00: (R1[17] || R1[16]) ? 8'hFF: R1[15:8];

endmodule // yuv2rgb
