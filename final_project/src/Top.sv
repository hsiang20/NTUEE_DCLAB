module Top (
    input i_clk, 
    input i_rst_n, 
    input i_key2, 
    input i_key3, 
    input i_sw0, 
    input i_sw1, 

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
	output [2:0] state
);
    // display sync signals and coordinates
    localparam CORDW = 16; // screen coordinate width
    parameter COLR_BITS = 4;
    parameter H_RES = 640;
    logic [5:0] cnt_anim_r, cnt_anim_w;
    logic signed [CORDW-1:0] sx, sy;
    logic de, line, frame;
    assign VGA_R = r_r;
    assign VGA_G = g_r;
    assign VGA_B = b_r;
	assign VGA_CLK = i_clk_25;
    assign state = state_r;

    // game FSM
    localparam INIT = 3'd0;
    localparam JUMP = 3'd1;
    localparam NORMAL = 3'd2;
    localparam DEAD = 3'd3;
    localparam OPEN = 3'd4;
    logic [2:0] state_r, state_w;
    logic [19:0] screen_height_r, screen_height_w; // doodle height: spry_r, speed: y_motion_r
    always_comb begin
        if (frame) begin
            case (state_r)
                OPEN: begin
                    screen_height_w = screen_height_r;
                    if (i_sw0) state_w = INIT;
                    else state_w = OPEN;
                end
                INIT: begin
                    screen_height_w = screen_height_r;
                    if ((spry_r+SPR_HEIGHT) <= platey_r && (spry_r+SPR_HEIGHT+10) > platey_r && y_motion_r > 0 && (sprx_r+SPR_WIDTH) > platex_r && sprx_r < (platex_r+PLATE_WIDTH)) begin
                        state_w = JUMP;
                    end
                    else state_w = INIT;
                end 
                JUMP: begin
                    if (platey_r >= 420) begin
                        screen_height_w = 87; 
                        state_w = NORMAL;
                    end
                    else begin
                        screen_height_w = screen_height_r + y_motion_r;
                        state_w = JUMP;
                    end
                end
                NORMAL: begin
                    // screen_height_w = screen_height_r;
                    screen_height_w = 87;
                    state_w = state_r;
                end
                DEAD: begin
                    screen_height_w = screen_height_r;
                    state_w = INIT;
                end
                default: begin
                    screen_height_w = screen_height_r;
                    state_w = state_r;
                end
            endcase
        end
        else begin
            screen_height_w = screen_height_r;
            state_w = state_r;
            if (i_sw0 && state_r == OPEN) state_w = INIT;
        end
    end
    always_ff begin
        if (!i_rst_n) begin
            state_r <= OPEN;
            screen_height_r <= 20'b0;
        end
        else begin
            state_r <= state_w;
            screen_height_r <= screen_height_w;
        end
    end
	 

    // background color
    logic [7:0] bg_r_r, bg_r_w, bg_g_r, bg_g_w, bg_b_r, bg_b_w;
    always_comb begin
        bg_r_w = bg_r_r;
        bg_g_w = bg_g_r;
        bg_b_w = bg_b_r;
        if (line) begin
            case (sy)
                469 : {bg_r_w, bg_g_w, bg_b_w} = 24'h87CEFF;
                (440 + screen_height_r) : {bg_r_w, bg_g_w, bg_b_w} = 24'h7CFC00;
            endcase
        end
    end
	always_ff @(posedge i_clk_25 or negedge i_rst_n) begin
		if (!i_rst_n) begin
            bg_r_r <= 8'h00;
            bg_g_r <= 8'h00;
            bg_b_r <= 8'h00;
        end
        else begin
            bg_r_r <= bg_r_w;
            bg_g_r <= bg_g_w;
            bg_b_r <= bg_b_w;
        end
    end

    // display color
    parameter SPR_TRANS = 0;
    parameter PLATE_TRANS = 0;
    parameter TITLE_TRANS = 0;
    logic [7:0] r_r, r_w, g_r, g_w, b_r, b_w;
    always_comb begin
        case (state_r) 
            OPEN: begin
                r_w = (title_drawing_r && !(title_pix == TITLE_TRANS) && de) ? {title_colr[11:8], 4'b0} : 
                      (spr_drawing_r && !(spr_pix == SPR_TRANS) && de)       ? {spr_colr[11:8], 4'b0}   : 
                      (plate_drawing_r && !(plate_pix == PLATE_TRANS) && de) ? {plate_colr[11:8], 4'b0} : bg_r_r;
                g_w = (title_drawing_r && !(title_pix == TITLE_TRANS) && de) ? {title_colr[7:4], 4'b0}  :
                      (spr_drawing_r && !(spr_pix == SPR_TRANS) && de)       ? {spr_colr[7:4], 4'b0}    : 
                      (plate_drawing_r && !(plate_pix == PLATE_TRANS) && de) ? {plate_colr[7:4], 4'b0}  : bg_g_r;
                b_w = (title_drawing_r && !(title_pix == TITLE_TRANS) && de) ? {title_colr[3:0], 4'b0}  :
                      (spr_drawing_r && !(spr_pix == SPR_TRANS) && de)       ? {spr_colr[3:0], 4'b0}    : 
                      (plate_drawing_r && !(plate_pix == PLATE_TRANS) && de) ? {plate_colr[3:0], 4'b0}  : bg_b_r;
            end
            default: begin
                r_w = (spr_drawing_r && !(spr_pix == SPR_TRANS) && de) ? {spr_colr[11:8], 4'b0} : 
                    (plate_drawing_r && !(plate_pix == PLATE_TRANS) && de) ? {plate_colr[11:8], 4'b0} : bg_r_r;
                g_w = (spr_drawing_r && !(spr_pix == SPR_TRANS) && de) ? {spr_colr[7:4], 4'b0} : 
                    (plate_drawing_r && !(plate_pix == PLATE_TRANS) && de) ? {plate_colr[7:4], 4'b0} : bg_g_r;
                b_w = (spr_drawing_r && !(spr_pix == SPR_TRANS) && de) ? {spr_colr[3:0], 4'b0} : 
                    (plate_drawing_r && !(plate_pix == PLATE_TRANS) && de) ? {plate_colr[3:0], 4'b0} : bg_b_r;
            end
        endcase
    end
	always_ff @(posedge i_clk_25 or negedge i_rst_n) begin
		if (!i_rst_n) begin
            r_r <= 8'b0;
            g_r <= 8'b0;
            b_r <= 8'b0;
        end
		else begin
            r_r <= r_w;
            g_r <= g_w;
            b_r <= b_w;
        end
    end


    // doodle
    parameter SPR_FILE = "doodle.mem";
    localparam SPR_WIDTH = 64;
    localparam SPR_HEIGHT = 64;
    localparam SPR_FRAMES = 1;
    localparam SPR_PIXELS = SPR_WIDTH * SPR_HEIGHT;
    localparam SPR_DEPTH = SPR_PIXELS * SPR_FRAMES;
    localparam SPR_ADDRW = $clog2(SPR_DEPTH);
    logic [COLR_BITS-1:0] spr_rom_data;
    logic [SPR_ADDRW-1:0] spr_rom_addr;
    logic [SPR_ADDRW-1:0] spr_base_addr_r, spr_base_addr_w;
    rom_sync #(
        .WIDTH(COLR_BITS), 
        .DEPTH(SPR_DEPTH), 
        .INIT_F(SPR_FILE)
    ) spr_rom (
        .clk(i_clk_25), 
        .addr(spr_base_addr_r + spr_rom_addr), 
        .data(spr_rom_data)
    );
    parameter SPR_PALETTE = "doodle_palette.mem";
    logic [COLR_BITS-1:0] spr_pix;
    logic [11:0] spr_colr;
	rom_async #(
		.WIDTH(12), 
		.DEPTH(16), 
		.INIT_F(SPR_PALETTE), 
        .ADDRW(4)
    ) doodle_clut(
        .addr(spr_pix), 
        .data(spr_colr)
    );
    parameter SCALE_X = 1;
    parameter SCALE_Y = 1;
    logic signed [CORDW-1:0] sprx_r, sprx_w, spry_r, spry_w;
    logic spr_start, spr_drawing, spr_drawing_w, spr_drawing_r;
    sprite_1 #(
        .WIDTH(SPR_WIDTH), 
        .HEIGHT(SPR_HEIGHT), 
        .COLR_BITS(COLR_BITS), 
        .SCALE_X(SCALE_X), 
        .SCALE_Y(SCALE_Y), 
        .ADDRW(SPR_ADDRW)
    ) doodle(
        .clk(i_clk_25), 
        .rst(i_rst_n), 
        .start(spr_start), 
        .sx(sx), 
        .sprx(sprx_r),
        .data_in(spr_rom_data), 
        .pos(spr_rom_addr),  
        .pix(spr_pix), 
        .drawing(spr_drawing), 
        .done()
    );
    logic spr_trans_r, spr_trans_w;
    logic signed [10:0] y_motion_r, y_motion_w;
    always_comb begin
        spr_start = (line && sy == spry_r);
        cnt_anim_w = cnt_anim_r;
        spr_base_addr_w = 0;
        sprx_w = sprx_r;
        spry_w = spry_r;
        y_motion_w = y_motion_r;
        spr_drawing_w = spr_drawing;
        if (frame) begin
            if (!i_key2) begin
                sprx_w = (sprx_r < H_RES) ? sprx_r + 3 : -SPR_WIDTH * SCALE_X;
                cnt_anim_w = cnt_anim_r + 1;
            end
            else if (!i_key3) begin
                sprx_w = (sprx_r > -SPR_WIDTH*SCALE_X) ? sprx_r - 3 : H_RES;
                cnt_anim_w = cnt_anim_r + 1;
            end
            if (i_sw0) begin
                if (state_r == JUMP) begin
                    if (y_motion_r == 0) y_motion_w = 1;
                    else y_motion_w = ((spry_r - platey_r) >> 3) + 1;
                end
                else begin
                    if (spry_r >= 376) y_motion_w = -1;
                    else if (spry_r <= 250) y_motion_w = 1;
                    else if (y_motion_r < 0) y_motion_w = -(((spry_r - 250) >> 3) + 1);
                    else if (y_motion_r > 0) y_motion_w = ((spry_r - 250) >> 3) + 1;
                    else if (y_motion_r == 0) y_motion_w = 1;
                end
            end
            else begin
                y_motion_w = 0;
            end
            spry_w = ((spry_r + y_motion_r) >= 376) ?    376 : 
                                     (spry_r > 376) ?    376 :
                                     (spry_r < 250) ?    250 :
                                  (state_r == JUMP) ? spry_r : (spry_r + y_motion_r);
        end
    end
	always_ff @(posedge i_clk_25 or negedge i_rst_n) begin
		if (!i_rst_n) begin
            sprx_r <= 300;
            spry_r <= 376;
            y_motion_r <= 11'b0;
            spr_base_addr_r <= 0;
        end
		else begin
            spr_trans_r <= spr_trans_w;
            cnt_anim_r <= cnt_anim_w;
            spr_base_addr_r <= spr_base_addr_w;
            sprx_r <= sprx_w;
            spry_r <= spry_w;
            y_motion_r <= y_motion_w;
            spr_drawing_r <= spr_drawing_w;
        end
	end


    // plate
    parameter PLATE_FILE = "plate.mem";
    localparam PLATE_WIDTH = 64;
    localparam PLATE_HEIGHT = 16;
    localparam PLATE_FRAMES = 1;
    localparam PLATE_PIXELS = PLATE_WIDTH * PLATE_HEIGHT;
    localparam PLATE_DEPTH = PLATE_PIXELS * PLATE_FRAMES;
    localparam PLATE_ADDRW = $clog2(PLATE_DEPTH);
    logic [COLR_BITS-1:0] plate_rom_data;
    logic [PLATE_ADDRW-1:0] plate_rom_addr;
    logic [PLATE_ADDRW-1:0] plate_base_addr_r, plate_base_addr_w;
    rom_sync #(
        .WIDTH(COLR_BITS), 
        .DEPTH(PLATE_DEPTH), 
        .INIT_F(PLATE_FILE)
    ) plate_rom (
        .clk(i_clk_25), 
        .addr(plate_base_addr_r + plate_rom_addr), 
        .data(plate_rom_data)
    );
    parameter PLATE_PALETTE = "plate_palette.mem";
    logic [COLR_BITS-1:0] plate_pix;
    logic [11:0] plate_colr;
	rom_async #(
		.WIDTH(12), 
		.DEPTH(16), 
		.INIT_F(PLATE_PALETTE), 
        .ADDRW(4)
    ) plate_clut(
        .addr(plate_pix), 
        .data(plate_colr)
    );
    parameter PLATE_SCALE_X = 1;
    parameter PLATE_SCALE_Y = 1;
    logic signed [CORDW-1:0] platex_r, platex_w, platey_r, platey_w;
    logic plate_start, plate_drawing, plate_drawing_w, plate_drawing_r;
    sprite_1 #(
        .WIDTH(PLATE_WIDTH), 
        .HEIGHT(PLATE_HEIGHT), 
        .COLR_BITS(COLR_BITS), 
        .SCALE_X(PLATE_SCALE_X), 
        .SCALE_Y(PLATE_SCALE_Y), 
        .ADDRW(PLATE_ADDRW)
    ) plate(
        .clk(i_clk_25), 
        .rst(i_rst_n), 
        .start(plate_start), 
        .sx(sx), 
        .sprx(platex_r),
        .data_in(plate_rom_data), 
        .pos(plate_rom_addr),  
        .pix(plate_pix), 
        .drawing(plate_drawing), 
        .done()
    );
    localparam PLATE_BG_HEIGHT = 100;
    logic plate_trans_r, plate_trans_w;
    always_comb begin
        plate_trans_w = (plate_pix == PLATE_TRANS);
        plate_start = (line && sy == platey_r);
        platex_w = platex_r;
        platey_w = 469 - 16 - (PLATE_BG_HEIGHT - screen_height_r);
        plate_base_addr_w = 0;
        plate_drawing_w = plate_drawing;
    end
	always_ff @(posedge i_clk_25 or negedge i_rst_n) begin
		if (!i_rst_n) begin
            platex_r <= 250;
            platey_r <= 469 - 16 - 100; // 353
        end
		else begin
            plate_trans_r <= plate_trans_w;
            plate_base_addr_r <= plate_base_addr_w;
            platex_r <= platex_w;
            platey_r <= platey_w;
            plate_drawing_r <= plate_drawing_w;
        end
	end


    // title
    parameter TITLE_FILE = "title.mem";
    localparam TITLE_WIDTH = 512;
    localparam TITLE_HEIGHT = 128;
    localparam TITLE_FRAMES = 1;
    localparam TITLE_PIXELS = TITLE_WIDTH * TITLE_HEIGHT;
    localparam TITLE_DEPTH = TITLE_PIXELS * TITLE_FRAMES;
    localparam TITLE_ADDRW = $clog2(TITLE_DEPTH);
    logic [COLR_BITS-1:0] title_rom_data;
    logic [TITLE_ADDRW-1:0] title_rom_addr;
    rom_sync #(
        .WIDTH(COLR_BITS), 
        .DEPTH(TITLE_DEPTH), 
        .INIT_F(TITLE_FILE)
    ) title_rom (
        .clk(i_clk_25), 
        .addr(title_rom_addr), 
        .data(title_rom_data)
    );
    parameter TITLE_PALETTE = "title_palette.mem";
    logic [COLR_BITS-1:0] title_pix;
    logic [11:0] title_colr;
	rom_async #(
		.WIDTH(12), 
		.DEPTH(16), 
		.INIT_F(TITLE_PALETTE), 
        .ADDRW(4)
    ) title_clut(
        .addr(title_pix), 
        .data(title_colr)
    );
    parameter TITLE_SCALE_X = 1;
    parameter TITLE_SCALE_Y = 1;
    logic signed [CORDW-1:0] titlex_r, titlex_w, titley_r, titley_w;
    logic title_start, title_drawing, title_drawing_w, title_drawing_r;
    sprite_1 #(
        .WIDTH(TITLE_WIDTH), 
        .HEIGHT(TITLE_HEIGHT), 
        .COLR_BITS(COLR_BITS), 
        .SCALE_X(TITLE_SCALE_X), 
        .SCALE_Y(TITLE_SCALE_Y), 
        .ADDRW(TITLE_ADDRW)
    ) title(
        .clk(i_clk_25), 
        .rst(i_rst_n), 
        .start(title_start), 
        .sx(sx), 
        .sprx(titlex_r),
        .data_in(title_rom_data), 
        .pos(title_rom_addr),  
        .pix(title_pix), 
        .drawing(title_drawing), 
        .done()
    );
    logic title_trans_r, title_trans_w;
    always_comb begin
        title_trans_w = (title_pix == TITLE_TRANS);
        title_start = (line && sy == titley_r);
        titlex_w = titlex_r;
        titley_w = titley_r;
        title_drawing_w = title_drawing;
    end
	always_ff @(posedge i_clk_25 or negedge i_rst_n) begin
		if (!i_rst_n) begin
            titlex_r <= 60;
            titley_r <= 100;
        end
		else begin
            title_trans_r <= title_trans_w;
            titlex_r <= titlex_w;
            titley_r <= titley_w;
            title_drawing_r <= title_drawing_w;
        end
	end



    // monitor
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