module Sobel(
    input        iCLK,
    input        iRST_N,
    input  [9:0] idata,
    input        iDVAL,
    input  [7:0] iThreshold,// 144
    output [9:0] odata
);

// mask x
parameter X1 = 8'hff, X2 = 8'h00, X3 = 8'h01;
parameter X4 = 8'hfe, X5 = 8'h00, X6 = 8'h02;
parameter X7 = 8'hff, X8 = 8'h00, X9 = 8'h01;

// mask y
parameter Y1 = 8'h00, Y2 = 8'h00, Y3 = 8'h00;
parameter Y4 = 8'h00, Y5 = 8'h00, Y6 = 8'h00;
parameter Y7 = 8'h00, Y8 = 8'h00, Y9 = 8'h00;

wire    [7:0]   Row0, Row1, Row2;

reg     [7:0]   Row0_prev1, Row0_prev2;
reg     [7:0]   Row1_prev1, Row1_prev2;
reg     [7:0]   Row2_prev1, Row2_prev2;

wire   [17:0]   MAC_x0, MAC_x1, MAC_x2, MAC_y0, MAC_y1, MAC_y2;
wire   [19:0]   PA_x, PA_y;

reg    [20:0]   odata_r;

assign odata = (odata_r[7:0] > iThreshold) ? 1023 : 0;

always @(posedge iCLK or negedge iRST_N) begin
    if (!iRST_N) begin
        Row0_prev1  <= 0;
        Row0_prev2  <= 0;
        Row1_prev1  <= 0;
        Row1_prev2  <= 0;
        Row2_prev1  <= 0;
        Row2_prev2  <= 0;
    end
    else begin
        Row0_prev1  <= Row0;
        Row0_prev2  <= Row0_prev1;
        Row1_prev1  <= Row1;
        Row1_prev2  <= Row1_prev1;
        Row2_prev1  <= Row2;
        Row2_prev2  <= Row2_prev1;
    end
end

always @(posedge iCLK or negedge iRST_N) begin
    if (!iRST_N) begin
        odata_r   <= 0;
    end
    else begin
        if (PA_x[19] && PA_y[19]) begin
            odata_r <= - PA_x - PA_y;
        end
        else if (PA_x[19]) begin
            odata_r <= PA_y - PA_x;
        end
        else if (PA_y[19]) begin
            odata_r <= PA_x - PA_y;
        end
        else begin
            odata_r <= PA_x + PA_y;
        end
    end
end

Sobel_buffer_3 buf3_0(
    .iCLK(iCLK),
    .iRST_N(iRST_N),
    .iCLKen(iDVAL),
    .idata(idata[9:2]),
    .oRow0(Row0),
    .oRow1(Row1),
    .oRow2(Row2)
);

Sobel_MAC_3   x0(
    .aclr3(!iRST_N),
    .clock0(iCLK),
    .dataa_0(Row2),
    .dataa_1(Row2_prev1),
    .dataa_2(Row2_prev2),
    .datab_0(X9),
    .datab_1(X8),
    .datab_2(X7),
    .result(MAC_x0)
);

Sobel_MAC_3   x1(
    .aclr3(!iRST_N),
    .clock0(iCLK),
    .dataa_0(Row1),
    .dataa_1(Row1_prev1),
    .dataa_2(Row1_prev2),
    .datab_0(X6),
    .datab_1(X5),
    .datab_2(X4),
    .result(MAC_x1)
);

Sobel_MAC_3   x2(
    .aclr3(!iRST_N),
    .clock0(iCLK),
    .dataa_0(Row0),
    .dataa_1(Row0_prev1),
    .dataa_2(Row0_prev2),
    .datab_0(X3),
    .datab_1(X2),
    .datab_2(X1),
    .result(MAC_x2)
);

Sobel_MAC_3   y0(
    .aclr3(!iRST_N),
    .clock0(iCLK),
    .dataa_0(Row2),
    .dataa_1(Row2_prev1),
    .dataa_2(Row2_prev2),
    .datab_0(Y9),
    .datab_1(Y8),
    .datab_2(Y7),
    .result(MAC_y0)
);

Sobel_MAC_3   y1(
    .aclr3(!iRST_N),
    .clock0(iCLK),
    .dataa_0(Row1),
    .dataa_1(Row1_prev1),
    .dataa_2(Row1_prev2),
    .datab_0(Y6),
    .datab_1(Y5),
    .datab_2(Y4),
    .result(MAC_y1)
);

Sobel_MAC_3   y2(
    .aclr3(!iRST_N),
    .clock0(iCLK),
    .dataa_0(Row0),
    .dataa_1(Row0_prev1),
    .dataa_2(Row0_prev2),
    .datab_0(Y3),
    .datab_1(Y2),
    .datab_2(Y1),
    .result(MAC_y2)
);

PA_3         pa0(
	.clock(iCLK),
	.data0x(MAC_x0),
	.data1x(MAC_x1),
	.data2x(MAC_x2),
	.result(PA_x)
);

PA_3         pa1(
	.clock(iCLK),
	.data0x(MAC_y0),
	.data1x(MAC_y1),
	.data2x(MAC_y2),
	.result(PA_y)
);

endmodule 