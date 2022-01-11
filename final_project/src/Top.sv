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
    localparam SPR_WIDTH = 32;
    localparam SPR_HEIGHT = 20;
    localparam SPR_FRAMES = 3;
    localparam SPR_PIXELS = SPR_WIDTH * SPR_HEIGHT;
    localparam SPR_DEPTH = SPR_PIXELS * SPR_FRAMES;
    localparam SPR_ADDRW = $clog2(SPR_DEPTH);
    parameter SCALE_X = 4;
    parameter SCALE_Y = 4;
    parameter COLR_BITS = 4;
    parameter SPR_TRANS = 9;
    parameter SPR_FILE = "hedgehog_walk.mem";
    parameter SPR_PALETTE = "hedgehog_palette.mem";
    parameter H_RES = 640;
    
    logic spr_start, spr_drawing;
    logic [COLR_BITS-1:0] spr_pix;
    logic [COLR_BITS-1:0] spr_rom_data;
    logic [SPR_ADDRW-1:0] spr_rom_addr;
    logic [SPR_ADDRW-1:0] spr_base_addr_r, spr_base_addr_w;
    logic [5:0] cnt_anim_r, cnt_anim_w;
    logic signed [CORDW-1:0] sprx_r, sprx_w, spry;

    logic signed [CORDW-1:0] sx, sy;
    logic de, line, frame;
	logic started_r, started_w;
    logic [7:0] r_r, r_w, g_r, g_w, b_r, b_w;
    logic spr_trans_r, spr_trans_w;
    logic [7:0] red_spr_r, red_spr_w, green_spr_r, green_spr_w, blue_spr_r, blue_spr_w;
    logic [7:0] red_bg, green_bg, blue_bg;
    logic [11:0] clut_colr;
    assign VGA_R = r_r;
    assign VGA_G = g_r;
    assign VGA_B = b_r;
	assign state = started_r;
	assign VGA_CLK = i_clk_25;
	 
    always_comb spr_start = (line && sy == spry);
	// always_comb started_w = started_r ? started_r : spr_start;


	always_ff @(posedge i_clk_25 or negedge i_rst_n) begin
		if (!i_rst_n) begin
            started_r = 1'b0;
            r_r <= 8'b0;
            g_r <= 8'b0;
            b_r <= 8'b0;
            sprx_r <= H_RES;
            spry <= 240;
        end
		else begin
            started_r <= started_w;
            spr_trans_r <= spr_trans_w;
            red_spr_r <= red_spr_w;
            green_spr_r <= green_spr_w;
            blue_spr_r <= blue_spr_w;
            r_r <= r_w;
            g_r <= g_w;
            b_r <= b_w;
            cnt_anim_r <= cnt_anim_w;
            spr_base_addr_r <= spr_base_addr_w;
            sprx_r <= sprx_w;
        end
	end
    always_comb begin
        cnt_anim_w = cnt_anim_r;
        spr_base_addr_w = spr_base_addr_r;
        sprx_w = sprx_r;
        started_w = started_r;
        if (frame) begin
            started_w = 1'b1;
            cnt_anim_w = cnt_anim_r + 1;
            case (cnt_anim_r)
                0: spr_base_addr_w = 0;
                15: spr_base_addr_w = SPR_PIXELS;
                31: spr_base_addr_w = 0;
                47: spr_base_addr_w = 2 * SPR_PIXELS;
            endcase
            sprx_w = (sprx_r > -132) ? sprx_r - 1 : H_RES;
        end
    end
    always_comb begin
        spr_trans_w = (spr_pix == SPR_TRANS);
        red_spr_w = {clut_colr[11:8], 4'b0000};
        green_spr_w = {clut_colr[7:4], 4'b0000};
        blue_spr_w = {clut_colr[3:0], 4'b0000};
        r_w = (spr_drawing && !(spr_pix==SPR_TRANS) && de) ? red_spr_r : 8'b11111111;
	    g_w = (spr_drawing && !(spr_pix==SPR_TRANS) && de) ? green_spr_r : 8'b11111111;
		b_w = (spr_drawing && !(spr_pix==SPR_TRANS) && de) ? blue_spr_r : 8'b11111111;
    end


    rom_sync #(
        .WIDTH(COLR_BITS), 
        .DEPTH(SPR_DEPTH), 
        .INIT_F(SPR_FILE)
    ) spr_rom (
        .clk(i_clk_25), 
        .addr(spr_base_addr_r + spr_rom_addr), 
        .data(spr_rom_data)
    );

	rom_async #(
		.WIDTH(12), 
		.DEPTH(11), 
		.INIT_F(SPR_PALETTE), 
        .ADDRW(4)
	 ) clut(
        .addr(spr_pix), 
        .data(clut_colr)
    );

    sprite_1 #(
        .WIDTH(SPR_WIDTH), 
        .HEIGHT(SPR_HEIGHT), 
        .COLR_BITS(COLR_BITS), 
        .SCALE_X(SCALE_X), 
        .SCALE_Y(SCALE_Y), 
        .ADDRW(SPR_ADDRW)
    ) spr_1(
        .clk(i_clk_25), 
        .rst(i_rst_n), 
        .start(spr_start), 
        .sx(sx), 
        .sprx(sprx_r),
        .data_in(spr_rom_data), 
        .pos(spr_rom_addr),  
        .pix(spr_pix), 
        .drawing(spr_drawing), 
        .done(done)
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