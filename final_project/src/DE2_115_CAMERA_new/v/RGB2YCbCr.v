module RGB2YCbCr(
    input             iCLK,
    input             iRST_N,
    input      [9:0]  iRed,
    input      [9:0]  iGreen,
    input      [9:0]  iBlue,
    output reg [9:0]  oRed,
    output reg [9:0]  oGreen,
    output reg [9:0]  oBlue
);

reg   [13:0]   tY_r, tCb_r, tCr_r;
wire  [23:0]   tY, tCb, tCr;
reg   [7:0]    Y, Cb, Cr;


// calculate YCbCr
always @(posedge iCLK or negedge iRST_N) begin
    if (!iRST_N) begin
        Y    <= 0;
        Cb   <= 0;
        Cr   <= 0;
    end
    else begin
        // Y
        if (tY_r[13]) begin
            Y  <= 0;
        end
        else if (tY_r[12:0] > 1023) begin
            Y  <= 255;
        end
        else begin
            Y  <= tY_r[9:2];
        end
        // Cb
        if (tCb_r[13]) begin
            Cb <= 0;
        end
        else if (tCb_r[12:0] > 1023) begin
            Cb <= 255;
        end
        else begin
            Cb <= tCb_r[9:2];
        end
        // Cr
        if (tCr_r[13]) begin
            Cr <= 0;
        end
        else if (tCr_r[12:0] > 1023) begin
            Cr <= 255;
        end
        else begin
            Cr <= tCr_r[9:2];
        end
    end
end

// detect skin
always @(posedge iCLK or negedge iRST_N) begin
    if (!iRST_N) begin
        oRed    <= 0;
        oGreen  <= 0;
        oBlue   <= 0;
    end
    else begin
        // Cr >= 133 && Cr <= 173 && Cb >= 77 && Cb <= 127
        if (Cr >= 133 && Cr < 180 && Cb >= 91 && Cb < 112) begin
            oRed    <= (255 << 2);
            oGreen  <= (255 << 2);
            oBlue   <= (255 << 2);
        end
        // else if (Cr >= 173) begin
        //     if (Cr < 177) begin
        //         oRed    <= 0;
        //         oGreen  <= (255 << 2);
        //         oBlue   <= 0;
        //     end
        //     else if (Cr < 182) begin
        //         oRed    <= (255 << 2);
        //         oGreen  <= 0;
        //         oBlue   <= 0;
        //     end
        //     else begin
        //         oRed    <= 0;
        //         oGreen  <= 0;
        //         oBlue   <= (255 << 2);
        //     end
        // end
        else begin
            oRed    <= 0;
            oGreen  <= 0;
            oBlue   <= 0;  
        end
    end
end

// MAC_3 result
always @(posedge iCLK or negedge iRST_N) begin
    if (!iRST_N) begin
        tY_r    <= 0;
        tCb_r   <= 0;
        tCr_r   <= 0;
    end
    else begin
        tY_r    <= (tY  +  ((16384) << 2)) >> 10;
        tCb_r   <= (tCb + ((131072) << 2)) >> 10;
        tCr_r   <= (tCr + ((131072) << 2)) >> 10;
    end
end
// Y
MAC_3   u0(
    .aclr3(!iRST_N),
    .clock0(iCLK),
    .dataa_0(iRed),
    .dataa_1(iGreen),
    .dataa_2(iBlue),
    .datab_0(12'h107),
    .datab_1(12'h204),
    .datab_2(12'h064),
    .result(tY)
);
// Cr
MAC_3   u1(
    .aclr3(!iRST_N),
    .clock0(iCLK),
    .dataa_0(iRed),
    .dataa_1(iGreen),
    .dataa_2(iBlue),
    .datab_0(12'h1C2),
    .datab_1(12'hE87),
    .datab_2(12'hFB7),
    .result(tCr)
);
// Cb
MAC_3   u2(
    .aclr3(!iRST_N),
    .clock0(iCLK),
    .dataa_0(iRed),
    .dataa_1(iGreen),
    .dataa_2(iBlue),
    .datab_0(12'hF68),
    .datab_1(12'hED6),
    .datab_2(12'h1C2),
    .result(tCb)
);

endmodule