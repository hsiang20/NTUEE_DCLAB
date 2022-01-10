module Top (
    input i_clk, 
    input i_rst_n, 

    // VGA
    input i_clk_25, 
    input i_start, 
    output [7:0] VGA_R, 
    output [7:0] VGA_G, 
    output [7:0] VGA_B, 
    output VGA_CLK, 
    output VGA_BLANK_N, 
    output VGA_HS, 
    output VGA_VS, 
    output VGA_SYNC_N, 
	 output state
);
    // display sync signals and coordinates
    localparam CORDW = 16; // screen coordinate width
    localparam SPR_WIDTH = 8;
    localparam SPR_HEIGHT = 8;
    localparam DRAW_X = 16;
    localparam DRAW_Y = 16;

    logic signed [CORDW-1:0] sx, sy;
    logic de;
	 logic line, frame;
    logic spr_start, spr_pix;
	 logic started_r, started_w;
    logic [7:0] r_r, r_w, g_r, g_w, b_r, b_w;
    assign VGA_R = r_r;
    assign VGA_G = g_r;
    assign VGA_B = b_r;
	
	 assign state = started_r;
	 assign VGA_CLK = i_clk_25;
	 
    always_comb spr_start = (line && sy == DRAW_Y);
	 always_comb started_w = started_r ? started_r : spr_start;
	 always_ff @(posedge i_clk_25 or negedge i_rst_n) begin
		if (!i_rst_n) started_r = 1'b0;
		else begin
            started_r <= started_w;
            r_r <= r_w;
            g_r <= g_w;
            b_r <= b_w;
        end
	 end
    always_comb begin
        r_w = (de && spr_pix) ? 8'b1111_1111 : 8'b0;
	    g_w = (de && spr_pix) ? 8'b1111_1111 : 8'b0;
		b_w = (de && spr_pix) ? 8'b0 : 8'b0;
    end
    sprite_1 spr_1(
        .clk(i_clk_25), 
        .rst(i_rst_n), 
        .start(spr_start), 
        .sx(sx), 
        .sprx(DRAW_X), 
        .pix(spr_pix)
    );

    display_1 display0(
        .clk_25M(i_clk_25), 
        .rst(i_rst_n), 
        .VGA_BLANK_N(VGA_BLANK_N), 
        .VGA_HS(VGA_HS), 
        .VGA_VS(VGA_VS), 
        .VGA_SYNC_N(VGA_SYNC_N), 
        .de(de), 
        .frame(frame), 
        .line(line), 
        .sx(sx), 
        .sy(sy), 
        .i_start_display(i_start)
    );
    // vga vga0(
    //     .i_rst_n(i_rst_n), 
    //     .i_clk_25M(i_clk_25), 
    //     .VGA_R(VGA_R), 
    //     .VGA_G(VGA_G), 
    //     .VGA_B(VGA_B), 
    //     .VGA_CLK(VGA_CLK), 
    //     .VGA_BLANK_N(VGA_BLANK_N), 
    //     .VGA_HS(VGA_HS), 
    //     .VGA_VS(VGA_VS), 
    //     .VGA_SYNC_N(VGA_SYNC_N), 
    //     .i_start_display(i_start), 
	// 	.state(state), 
    // );

endmodule