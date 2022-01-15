module Top (
    input i_clk, 
    input i_rst_n,
    input i_key0,  
    input i_key2, 
    input i_key3, 
    input i_sw0, 
    input i_start, 
    input i_burst, 
    input [2:0] i_speed, 
    input [7:0] i_base, 

    // VGA
    input i_clk_25, 
    output [7:0] VGA_R, 
    output [7:0] VGA_G, 
    output [7:0] VGA_B, 
    output VGA_CLK, 
    output VGA_BLANK_N, 
    output VGA_HS, 
    output VGA_VS, 
    output VGA_SYNC_N, 
	output [2:0] state, 
    output [3:0] test
);
    // display sync signals and coordinates
    localparam CORDW = 16; // screen coordinate width
    parameter COLR_BITS = 4;
    parameter H_RES = 640;
    logic [5:0] cnt_anim_r, cnt_anim_w;
    logic [19:0] count_r, count_w;
    logic signed [CORDW-1:0] sx, sy;
    logic de, line, frame;
    logic start;
    logic [7:0] base;
    assign VGA_R = r_r;
    assign VGA_G = g_r;
    assign VGA_B = b_r;
	assign VGA_CLK = i_clk_25;
    assign state = state_r;
    assign test = !(bullet_y_r+12 > monster_y[0] && bullet_y_r < monster_y[0]+MONSTER_HEIGHT && (bullet_x_r+12) > monster_x[0] && bullet_x_r < (monster_x[0]+MONSTER_WIDTH));
    assign start = i_sw0 && i_start;
    assign base = i_base;

    // game FSM
    localparam OPEN = 3'd0;
    localparam INIT = 3'd1;
    localparam JUMP = 3'd2;
    localparam NORMAL = 3'd3;
    localparam DEAD = 3'd4;
    localparam FINAL = 3'd5;
    logic [2:0] state_r, state_w;
    logic [19:0] screen_height_r, screen_height_w; // doodle height: spry_r, speed: y_motion_r
    logic [19:0] now_plate_left_r, now_plate_left_w, now_plate_right_r, now_plate_right_w, now_plate_bg_height_r, now_plate_bg_height_w; // which plate the doodle is on
    logic [10:0] now_plate_index_r, now_plate_index_w;
    logic [PLATE_NUM-1:0] jump_pos_r, jump_pos_w;
    logic [PLATE_NUM-1:0] jump_on_plate;
    genvar k;
    generate
        for (k=0; k<PLATE_NUM; k=k+1) begin: which_plate_is_jumping
            assign jump_on_plate[k] = (state_r != JUMP) && frame && jump_pos_r[k] && (spry_r+SPR_HEIGHT) > plate_y[k] && (sprx_r+SPR_WIDTH) > plate_x[k] && sprx_r < (plate_x[k]+PLATE_WIDTH);
            assign jump_pos_w[k] = (frame)? (spry_r+SPR_HEIGHT) <= plate_y[k] : jump_pos_r[k];
        end
    endgenerate
    always_comb begin
        count_w = count_r + 1;
        if (frame) begin
            case (state_r)
                OPEN: begin
                    now_plate_index_w = now_plate_index_r;
                    now_plate_right_w = now_plate_right_r;
                    now_plate_left_w = now_plate_left_r;
                    screen_height_w = screen_height_r;
                    if (start) state_w = INIT;
                    else state_w = OPEN;
                end
                INIT: begin
                    now_plate_right_w = now_plate_right_r;
                    now_plate_left_w = now_plate_left_r;
                    screen_height_w = screen_height_r;
                    if (jump_on_plate != 0) begin
                        now_plate_index_w = now_plate_index_r;
                        for (integer n=0; n<PLATE_NUM; n=n+1) begin
                            if (jump_on_plate[n]) begin
                                now_plate_index_w = n;
                            end
                        end
                        state_w = JUMP;
                    end
                    else begin
                        state_w = INIT;
                        now_plate_index_w = now_plate_index_r;
                    end
                    for (integer i=0; i<MONSTER_NUM; i=i+1) begin
                        if (monster_valid_r[i] && spry_r+SPR_HEIGHT > monster_y[i] && spry_r < monster_y[i]+MONSTER_HEIGHT && (sprx_r+SPR_WIDTH) > monster_x[i] && sprx_r < (monster_x[i]+MONSTER_WIDTH)) begin
                            state_w = DEAD;
                        end
                    end
                    for (integer i=0; i<MONSTER2_NUM; i=i+1) begin
                        if (monster2_valid_r[i] && spry_r+SPR_HEIGHT > monster2_y[i] && spry_r < monster2_y[i]+MONSTER2_HEIGHT && (sprx_r+SPR_WIDTH) > monster2_x[i] && sprx_r < (monster2_x[i]+MONSTER2_WIDTH)) begin
                            state_w = DEAD;
                        end
                    end
                end 
                JUMP: begin
                    now_plate_index_w = now_plate_index_r;
                    now_plate_right_w = plate_x[now_plate_index_r] + PLATE_WIDTH;
                    now_plate_left_w = plate_x[now_plate_index_r];
                    if (plate_y[now_plate_index_r] >= 420) begin
                        screen_height_w = plate_y_init[now_plate_index_r] - 13; 
                        state_w = NORMAL;
                    end
                    else begin
                        screen_height_w = screen_height_r + 12;
                        state_w = JUMP;
                    end
                end
                NORMAL: begin
                    now_plate_right_w = now_plate_right_r;
                    now_plate_left_w = now_plate_left_r;
                    screen_height_w = plate_y_init[now_plate_index_r] - 13;
                    if ((spry_r+SPR_HEIGHT) >= 430 && (sprx_r>now_plate_right_r || (sprx_r+SPR_WIDTH)<now_plate_left_r)) begin
                        now_plate_index_w = now_plate_index_r;
                        state_w = DEAD;
                    end
                    else if (jump_on_plate != 0) begin
                        now_plate_index_w = now_plate_index_r;
                        for (integer n=0; n<PLATE_NUM; n=n+1) begin
                            if (jump_on_plate[n]) begin
                                now_plate_index_w = n;
                            end
                        end
                        state_w = JUMP;
                    end
                    else begin
                        now_plate_index_w = now_plate_index_r;
                        state_w = state_r;
                    end
                    for (integer i=0; i<MONSTER_NUM; i=i+1) begin
                        if (monster_valid_r[i] && spry_r+SPR_HEIGHT > monster_y[i] && spry_r < monster_y[i]+MONSTER_HEIGHT && (sprx_r+SPR_WIDTH) > monster_x[i] && sprx_r < (monster_x[i]+MONSTER_WIDTH)) begin
                            state_w = DEAD;
                        end
                    end
                    for (integer i=0; i<MONSTER2_NUM; i=i+1) begin
                        if (monster2_valid_r[i] && spry_r+SPR_HEIGHT > monster2_y[i] && spry_r < monster2_y[i]+MONSTER2_HEIGHT && (sprx_r+SPR_WIDTH) > monster2_x[i] && sprx_r < (monster2_x[i]+MONSTER2_WIDTH)) begin
                            state_w = DEAD;
                        end
                    end
                end
                DEAD: begin
                    now_plate_index_w = now_plate_index_r;
                    now_plate_right_w = now_plate_right_r;
                    now_plate_left_w = now_plate_left_r;
                    screen_height_w = screen_height_r;
                    if (spry_r == 480) state_w = FINAL;
                    else state_w = state_r;
                end
                FINAL: begin
                    now_plate_index_w = now_plate_index_r;
                    now_plate_right_w = now_plate_right_r;
                    now_plate_left_w = now_plate_left_r;
                    screen_height_w = screen_height_r;
                    state_w = state_r;
                end
                default: begin
                    now_plate_index_w = now_plate_index_r;
                    now_plate_right_w = now_plate_right_r;
                    now_plate_left_w = now_plate_left_r;
                    screen_height_w = screen_height_r;
                    state_w = state_r;
                end
            endcase
        end
        else begin
            now_plate_index_w = now_plate_index_r;
            now_plate_right_w = now_plate_right_r;
            now_plate_left_w = now_plate_left_r;
            screen_height_w = screen_height_r;
            state_w = state_r;
            if (start && state_r == OPEN) state_w = INIT;
        end
    end
	always_ff @(posedge i_clk_25 or negedge i_rst_n) begin
        if (!i_rst_n) begin
            count_r <= base;
            state_r <= OPEN;
            screen_height_r <= count_r[12:0] + (base<<4);
            now_plate_left_r <= 0;
            now_plate_right_r <= 640;
            jump_pos_r <= 8'b0;
            now_plate_index_r <= 11'b0; 
        end
        else begin
            count_r <= count_w;
            state_r <= state_w;
            screen_height_r <= screen_height_w;
            now_plate_left_r <= now_plate_left_w;
            now_plate_right_r <= now_plate_right_w;
            now_plate_index_r <= now_plate_index_w; 
            jump_pos_r <= jump_pos_w;
        end
    end
	 

    // background color
    logic [7:0] bg_r_r, bg_r_w, bg_g_r, bg_g_w, bg_b_r, bg_b_w;
    always_comb begin
        bg_r_w = bg_r_r;
        bg_g_w = bg_g_r;
        bg_b_w = bg_b_r;
        if (line) begin
            if (state_r == OPEN || state_r == INIT) begin
                case (sy)
                    469 : {bg_r_w, bg_g_w, bg_b_w} = 24'h87CEFF;
                    440 : {bg_r_w, bg_g_w, bg_b_w} = 24'h7CFC00;
                endcase
            end
            else begin
                if (sy == 469) {bg_r_w, bg_g_w, bg_b_w} = 24'h87CEFF;
            end
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
    parameter MONSTER_TRANS = 0;
    parameter MONSTER2_TRANS = 0;
    parameter GAMEOVER_TRANS = 0;
    parameter PLAYAGAIN_TRANS = 0;
    parameter BULLET_TRANS = 0;
    logic [7:0] r_r, r_w, g_r, g_w, b_r, b_w;
    
    logic [PLATE_NUM-1:0] plate_draw;
    logic plate_draw_display;
    logic [11:0] plate_color_draw [PLATE_NUM];
    logic [11:0] plate_color_display;
    logic [MONSTER_NUM-1:0] monster_draw;
    logic monster_draw_display;
    logic [11:0] monster_color_draw [MONSTER_NUM];
    logic [11:0] monster_color_display;
    logic [MONSTER2_NUM-1:0] monster2_draw;
    logic monster2_draw_display;
    logic [11:0] monster2_color_draw [MONSTER2_NUM];
    logic [11:0] monster2_color_display;
    assign plate_draw_display = !(plate_draw == 0);
    assign monster_draw_display = !(monster_draw == 0) && monster_valid_r[0] && monster_valid_r[1] && monster_valid_r[2] && monster_valid_r[3] && monster_valid_r[4] && monster_valid_r[5] && monster_valid_r[6] && monster_valid_r[7] && monster_valid_r[8] && monster_valid_r[9];
    assign monster2_draw_display = !(monster2_draw == 0)&& monster2_valid_r[0] && monster2_valid_r[1] && monster2_valid_r[2] && monster2_valid_r[3] && monster2_valid_r[4] && monster2_valid_r[5] && monster2_valid_r[6] && monster2_valid_r[7] && monster2_valid_r[8] && monster2_valid_r[9];
    genvar j, q, r;
    generate
        for (j=0; j<PLATE_NUM; j=j+1) begin : plate_color
            assign plate_draw[j] = (plate_drawing_r[j] && !(plate_pix[j]==PLATE_TRANS) && de);
            assign plate_color_draw[j] = (plate_draw[j])? plate_colr[j] : 12'b0;
        end
        for (q=0; q<MONSTER_NUM; q=q+1) begin : monster_color
            assign monster_draw[q] = (monster_drawing_r[q] && !(monster_pix[q]==MONSTER_TRANS) && de);
            assign monster_color_draw[q] = (monster_draw[q] && monster_valid_r[q])? monster_colr[q] : 12'b0;
        end
        for (r=0; r<MONSTER2_NUM; r=r+1) begin : monster2_color
            assign monster2_draw[r] = (monster2_drawing_r[r] && !(monster2_pix[r]==MONSTER2_TRANS) && de);
            assign monster2_color_draw[r] = (monster2_draw[r] && monster2_valid_r[r])? monster2_colr[r] : 12'b0;
        end
    endgenerate

    always_comb begin
        plate_color_display = plate_color_draw[0];
        monster_color_display = monster_color_draw[0];
        monster2_color_display = monster2_color_draw[0];
        for (integer m=0; m<PLATE_NUM; m=m+1) begin
            if (plate_color_draw[m]) begin
                plate_color_display = plate_color_draw[m];
            end
        end
        for (integer o=0; o<MONSTER_NUM; o=o+1) begin
            if (monster_color_draw[o]) begin
                monster_color_display = monster_color_draw[o];
            end
        end
        for (integer m=0; m<MONSTER2_NUM; m=m+1) begin
            if (monster2_color_draw[m]) begin
                monster2_color_display = monster2_color_draw[m];
            end
        end
        case (state_r) 
            OPEN: begin
                r_w = (title_drawing_r && !(title_pix == TITLE_TRANS) && de) ? {title_colr[11:8], 4'b0} : 
                      (spr_drawing_r && !(spr_pix == SPR_TRANS) && de)       ? {spr_colr[11:8], 4'b0}   : 
                      (monster_draw_display)                                 ? {monster_color_display[11:8], 4'b0} :
                      (monster2_draw_display)                                ? {monster2_color_display[11:8], 4'b0} :
                      (plate_draw_display)                                   ? {plate_color_display[11:8], 4'b0} : bg_r_r;   
                g_w = (title_drawing_r && !(title_pix == TITLE_TRANS) && de) ? {title_colr[7:4], 4'b0}  :
                      (spr_drawing_r && !(spr_pix == SPR_TRANS) && de)       ? {spr_colr[7:4], 4'b0}    : 
                      (monster_draw_display)                                 ? {monster_color_display[7:4], 4'b0} :
                      (monster2_draw_display)                                ? {monster2_color_display[7:4], 4'b0} :
                      (plate_draw_display)                                   ? {plate_color_display[7:4], 4'b0} : bg_g_r;   
                b_w = (title_drawing_r && !(title_pix == TITLE_TRANS) && de) ? {title_colr[3:0], 4'b0}  :
                      (spr_drawing_r && !(spr_pix == SPR_TRANS) && de)       ? {spr_colr[3:0], 4'b0}    : 
                      (monster_draw_display)                                 ? {monster_color_display[3:0], 4'b0} :
                      (monster2_draw_display)                                ? {monster2_color_display[3:0], 4'b0} :
                      (plate_draw_display)                                   ? {plate_color_display[3:0], 4'b0} : bg_b_r;   
            end
            FINAL: begin
                r_w = (spr_drawing_r && !(spr_pix == SPR_TRANS) && de)                   ? {spr_colr[11:8], 4'b0}       : 
                      (gameover_drawing_r && !(gameover_pix == GAMEOVER_TRANS) && de)    ? {gameover_colr[11:8], 4'b0}  : 
                      (playagain_drawing_r && !(playagain_pix == PLAYAGAIN_TRANS) && de) ? {playagain_colr[11:8], 4'b0} : bg_r_r;
                g_w = (spr_drawing_r && !(spr_pix == SPR_TRANS) && de)                   ? {spr_colr[7:4], 4'b0}        : 
                      (gameover_drawing_r && !(gameover_pix == GAMEOVER_TRANS) && de)    ? {gameover_colr[7:4], 4'b0}   : 
                      (playagain_drawing_r && !(playagain_pix == PLAYAGAIN_TRANS) && de) ? {playagain_colr[7:4], 4'b0}  : bg_g_r;
                b_w = (spr_drawing_r && !(spr_pix == SPR_TRANS) && de)                   ? {spr_colr[3:0], 4'b0}        : 
                      (gameover_drawing_r && !(gameover_pix == GAMEOVER_TRANS) && de)    ? {gameover_colr[3:0], 4'b0}   : 
                      (playagain_drawing_r && !(playagain_pix == PLAYAGAIN_TRANS) && de) ? {playagain_colr[3:0], 4'b0}  : bg_b_r;
            end
            default: begin
                r_w = (spr_drawing_r && !(spr_pix == SPR_TRANS) && de) ? {spr_colr[11:8], 4'b0} :
                      (bullet_drawing_r && (bullet_pix == BULLET_TRANS) && de && bullet_opa_r)    ? {bullet_colr[11:8], 4'b0}   : 
                      (monster_draw_display)                                 ? {monster_color_display[11:8], 4'b0} :
                      (monster2_draw_display)                                ? {monster2_color_display[11:8], 4'b0} :
                      (plate_draw_display)                                   ? {plate_color_display[11:8], 4'b0} : bg_r_r;   
                g_w = (spr_drawing_r && !(spr_pix == SPR_TRANS) && de) ? {spr_colr[7:4], 4'b0} : 
                      (bullet_drawing_r && (bullet_pix == BULLET_TRANS) && de && bullet_opa_r)    ? {bullet_colr[7:4], 4'b0}   : 
                      (monster_draw_display)                                 ? {monster_color_display[7:4], 4'b0} :
                      (monster2_draw_display)                                ? {monster2_color_display[7:4], 4'b0} :
                      (plate_draw_display)                                   ? {plate_color_display[7:4], 4'b0} : bg_g_r;   
                b_w = (spr_drawing_r && !(spr_pix == SPR_TRANS) && de) ? {spr_colr[3:0], 4'b0} : 
                      (bullet_drawing_r && (bullet_pix == BULLET_TRANS) && de && bullet_opa_r)    ? {bullet_colr[3:0], 4'b0}   : 
                      (monster_draw_display)                                 ? {monster_color_display[3:0], 4'b0} :
                      (monster2_draw_display)                                ? {monster2_color_display[3:0], 4'b0} :
                      (plate_draw_display)                                   ? {plate_color_display[3:0], 4'b0} : bg_b_r;   
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
    logic [2:0] speed;
    logic direction;
    assign direction = i_speed > 3'd3; // negative: left, positive: right
    assign speed = (direction)? i_speed - 3'd3 : 3'd3 - i_speed;
    always_comb begin
        spr_start = (line && sy == spry_r);
        spr_base_addr_w = 0;
        sprx_w = sprx_r;
        spry_w = spry_r;
        y_motion_w = y_motion_r;
        spr_drawing_w = spr_drawing;
        if (frame) begin
            if (!i_key2) begin
                sprx_w = (sprx_r < H_RES) ? sprx_r + 5 : -SPR_WIDTH * SCALE_X;
            end
            else if (!i_key3) begin
                sprx_w = (sprx_r > -SPR_WIDTH*SCALE_X) ? sprx_r - 5 : H_RES;
            end
            else if (speed == 0) begin
                sprx_w = sprx_r;
            end
            else if (direction) begin
                sprx_w = (sprx_r < H_RES) ? sprx_r + (speed<<1) - 1 : -SPR_WIDTH * SCALE_X;
            end
            else if (!direction) begin
                sprx_w = (sprx_r > -SPR_WIDTH*SCALE_X) ? sprx_r - (speed<<1) - 1 : H_RES;
            end
            if (start) begin
                if (state_r == JUMP) begin
                    if (y_motion_r == 0) y_motion_w = 1;
                    else y_motion_w = ((spry_r - plate_y[now_plate_index_r]) >> 3) + 1;
                end
                else begin
                    if (spry_r >= 376) y_motion_w = -1;
                    else if (spry_r <= 220) y_motion_w = 1;
                    else if (y_motion_r < 0) y_motion_w = -(((spry_r - 220) >> 3) + 1);
                    else if (y_motion_r > 0) y_motion_w = ((spry_r - 220) >> 3) + 1;
                    else if (y_motion_r == 0) y_motion_w = 1;
                end
            end
            else begin
                y_motion_w = 0;
            end
            if (state == FINAL) begin
                if (spry_r == 480) spry_w = 0;
                else if (spry_r != 400) spry_w = spry_r + 10;
                else spry_w = spry_r;
            end
            else if (state == DEAD) begin
                if (spry_r < 445) spry_w = spry_r + 10;
                else spry_w = 480;
            end
            else begin
                spry_w = ((spry_r + y_motion_r) >= 376) ?    376 : 
                         ((spry_r + y_motion_r) <  220) ?    220 :
                                    (state_r == JUMP)   ? spry_r : (spry_r + y_motion_r);
            end
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
            spr_base_addr_r <= spr_base_addr_w;
            sprx_r <= sprx_w;
            spry_r <= spry_w;
            y_motion_r <= y_motion_w;
            spr_drawing_r <= spr_drawing_w;
        end
	end


    // plate
    localparam TOTAL_PLATE = 1000;
    localparam PLATE_NUM = 100;
    logic [19:0] plate_x_init [TOTAL_PLATE];
    logic [19:0] plate_y_init [TOTAL_PLATE]; // bg_height
    logic [COLR_BITS-1:0] plate_pix [PLATE_NUM];
    logic [11:0] plate_colr [PLATE_NUM];
    logic plate_drawing_r [PLATE_NUM];
    logic signed [15:0] plate_x [PLATE_NUM];
    logic signed [15:0] plate_y [PLATE_NUM];
    localparam PLATE_POS_X_FILE = "plate_pos_x.mem";
    localparam PLATE_POS_Y_FILE = "plate_pos_y.mem";
    initial begin
        $readmemh(PLATE_POS_X_FILE, plate_x_init);
        $readmemh(PLATE_POS_Y_FILE, plate_y_init);
    end
    localparam PLATE_WIDTH = 64;
    localparam PLATE_HEIGHT = 16;
    localparam PLATE_FRAMES = 1;
    localparam PLATE_PIXELS = PLATE_WIDTH * PLATE_HEIGHT;
    localparam PLATE_DEPTH = PLATE_PIXELS * PLATE_FRAMES;
    localparam PLATE_ADDRW = $clog2(PLATE_DEPTH);
    genvar i;
    generate
        for (i=0; i<PLATE_NUM; i=i+1) begin : plate_generator
            logic [19:0] a, b;
            assign a = plate_x_init[i];
            assign b = plate_y_init[i];
            plate plate1(
                .clk(i_clk_25), 
                .i_rst_n(i_rst_n), 
                .sx(sx), 
                .sy(sy), 
                .plate_x_init(a), 
                .plate_y_init(b), 
                .line(line), 
                .screen_height(screen_height_r), 
                .plate_pix(plate_pix[i]), 
                .plate_colr(plate_colr[i]), 
                .plate_drawing_r(plate_drawing_r[i]), 
                .plate_x(plate_x[i]), 
                .plate_y(plate_y[i])
            );
        end
    endgenerate


    // bullet
    logic [3:0] bullet_pix;
    logic [11:0] bullet_colr;
    logic bullet_drawing_r;
    logic [15:0] bullet_x_r, bullet_x_w, bullet_y_r, bullet_y_w, bullet_opa_r, bullet_opa_w;
    logic burst;
    assign burst = !i_key0 || i_burst;
    item #(
        .FILE("bullet.mem"), 
        .PALETTE_FILE("bullet_palette.mem"), 
        .WIDTH(4), 
        .HEIGHT(4), 
        .SCALE_X(3), 
        .SCALE_Y(3)
    ) bullet (
        .i_clk_25(i_clk_25), 
        .i_rst_n(i_rst_n), 
        .sx(sx), 
        .sy(sy), 
        .x_init(bullet_x_r), 
        .y_init(bullet_y_r), 
        .line(line), 
        .pix(bullet_pix), 
        .colr(bullet_colr), 
        .drawing_r(bullet_drawing_r)
    );
    always_comb begin
        if (bullet_y_r <= 1) bullet_opa_w = 1'b0;
        else if (bullet_y_r > 469) bullet_opa_w = 1'b0;
        else if (burst) bullet_opa_w = 1'b1;
        else bullet_opa_w = bullet_opa_r;
        if (bullet_opa_r) begin
            if (frame) bullet_y_w = bullet_y_r - 10;
            else bullet_y_w = bullet_y_r;
            bullet_x_w = bullet_x_r;
        end
        else begin
            bullet_x_w = sprx_r + 32;
            bullet_y_w = spry_r + 30;
        end
    end
	always_ff @(posedge i_clk_25 or negedge i_rst_n) begin
		if (!i_rst_n) begin
            bullet_opa_r <= 1'b0;
            bullet_x_r <= sprx_r + 32;
            bullet_y_r <= spry_r + 30;
        end
		else begin
            bullet_opa_r <= bullet_opa_w;
            bullet_x_r <= bullet_x_w;
            bullet_y_r <= bullet_y_w;
        end
	end



    // monster
    localparam MONSTER_NUM = 10;
    logic [19:0] monster_x_init [MONSTER_NUM];
    logic [19:0] monster_y_init [MONSTER_NUM]; // bg_height
    logic monster_valid_r [MONSTER_NUM], monster_valid_w [MONSTER_NUM];
    logic [COLR_BITS-1:0] monster_pix [MONSTER_NUM];
    logic [11:0] monster_colr [MONSTER_NUM];
    logic monster_drawing_r [MONSTER_NUM];
    logic signed [15:0] monster_x [MONSTER_NUM];
    logic signed [15:0] monster_y [MONSTER_NUM];
    localparam MONSTER_POS_X_FILE = "monster_pos_x.mem";
    localparam MONSTER_POS_Y_FILE = "monster_pos_y.mem";
    initial begin
        $readmemh(MONSTER_POS_X_FILE, monster_x_init);
        $readmemh(MONSTER_POS_Y_FILE, monster_y_init);
    end
    localparam MONSTER_WIDTH = 64;
    localparam MONSTER_HEIGHT = 64;
    localparam MONSTER_FRAMES = 1;
    localparam MONSTER_PIXELS = MONSTER_WIDTH * MONSTER_HEIGHT;
    localparam MONSTER_DEPTH = MONSTER_PIXELS * MONSTER_FRAMES;
    localparam MONSTER_ADDRW = $clog2(MONSTER_DEPTH);
    genvar p2;
    generate
        for (p2=0; p2<MONSTER_NUM; p2=p2+1) begin : monster_generator
            logic [19:0] c, d;
            assign c = monster_x_init[p2];
            assign d = monster_y_init[p2];
            monster monster1(
                .clk(i_clk_25), 
                .i_rst_n(i_rst_n), 
                .sx(sx), 
                .sy(sy), 
                .monster_x_init(c), 
                .monster_y_init(d), 
                .line(line), 
                .screen_height(screen_height_r), 
                .monster_pix(monster_pix[p2]), 
                .monster_colr(monster_colr[p2]), 
                .monster_drawing_r(monster_drawing_r[p2]), 
                .monster_x(monster_x[p2]), 
                .monster_y(monster_y[p2])
            );
        end
    endgenerate
    genvar p3;
    generate
        for (p3=0; p3<MONSTER_NUM; p3=p3+1) begin: dao
            assign monster_valid_w[p3] = !(state_r != OPEN && bullet_y_r+12 > monster_y[p3] && bullet_y_r < monster_y[p3]+MONSTER_HEIGHT && (bullet_x_r+12) > monster_x[p3] && bullet_x_r < (monster_x[p3]+MONSTER_WIDTH));
            assign monster_valid_r[p3] = (state_r == OPEN)? 1'b1 : (monster_valid_r[p3])? monster_valid_w[p3] : 1'b0;
        end
    endgenerate
            

    // monster2
    localparam MONSTER2_NUM = 10;
    logic [19:0] monster2_x_init [MONSTER2_NUM];
    logic [19:0] monster2_y_init [MONSTER2_NUM]; // bg_height
    logic monster2_valid_r [MONSTER2_NUM], monster2_valid_w [MONSTER2_NUM];
    logic [COLR_BITS-1:0] monster2_pix [MONSTER2_NUM];
    logic [11:0] monster2_colr [MONSTER2_NUM];
    logic monster2_drawing_r [MONSTER2_NUM];
    logic signed [15:0] monster2_x [MONSTER2_NUM];
    logic signed [15:0] monster2_y [MONSTER2_NUM];
    localparam MONSTER2_POS_X_FILE = "monster2_pos_x.mem";
    localparam MONSTER2_POS_Y_FILE = "monster2_pos_y.mem";
    initial begin
        $readmemh(MONSTER2_POS_X_FILE, monster2_x_init);
        $readmemh(MONSTER2_POS_Y_FILE, monster2_y_init);
    end
    localparam MONSTER2_WIDTH = 64;
    localparam MONSTER2_HEIGHT = 64;
    localparam MONSTER2_FRAMES = 1;
    localparam MONSTER2_PIXELS = MONSTER2_WIDTH * MONSTER2_HEIGHT;
    localparam MONSTER2_DEPTH = MONSTER2_PIXELS * MONSTER2_FRAMES;
    localparam MONSTER2_ADDRW = $clog2(MONSTER2_DEPTH);
    genvar p;
    generate
        for (p=0; p<MONSTER2_NUM; p=p+1) begin : monster2_generator
            logic [19:0] c, d;
            assign c = monster2_x_init[p];
            assign d = monster2_y_init[p];
            monster2 monster21(
                .clk(i_clk_25), 
                .i_rst_n(i_rst_n), 
                .sx(sx), 
                .sy(sy), 
                .monster2_x_init(c), 
                .monster2_y_init(d), 
                .line(line), 
                .screen_height(screen_height_r), 
                .monster2_pix(monster2_pix[p]), 
                .monster2_colr(monster2_colr[p]), 
                .monster2_drawing_r(monster2_drawing_r[p]), 
                .monster2_x(monster2_x[p]), 
                .monster2_y(monster2_y[p])
            );
        end
    endgenerate
    genvar p4;
    generate
        for (p4=0; p4<MONSTER2_NUM; p4=p4+1) begin: dao2
            assign monster2_valid_w[p4] = !(state_r != OPEN && bullet_y_r+12 > monster2_y[p4] && bullet_y_r < monster2_y[p4]+MONSTER2_HEIGHT && (bullet_x_r+12) > monster2_x[p4] && bullet_x_r < (monster2_x[p4]+MONSTER2_WIDTH));
            assign monster2_valid_r[p4] = (state_r == OPEN)? 1'b1 : (monster2_valid_r[p4])? monster2_valid_w[p4] : 1'b0;
        end
    endgenerate


    // title
    logic [3:0] title_pix;
    logic [11:0] title_colr;
    logic title_drawing_r;
    item #(
        .FILE("title.mem"), 
        .PALETTE_FILE("title_palette.mem")
    ) title (
        .i_clk_25(i_clk_25), 
        .i_rst_n(i_rst_n), 
        .sx(sx), 
        .sy(sy), 
        .x_init(60), 
        .y_init(100), 
        .line(line), 
        .pix(title_pix), 
        .colr(title_colr), 
        .drawing_r(title_drawing_r)
    );

    // gameover
    logic [3:0] gameover_pix;
    logic [11:0] gameover_colr;
    logic gameover_drawing_r;
    item #(
        .FILE("gameover.mem"), 
        .PALETTE_FILE("gameover_palette.mem"), 
        .HEIGHT(177)
    ) gameover (
        .i_clk_25(i_clk_25), 
        .i_rst_n(i_rst_n), 
        .sx(sx), 
        .sy(sy), 
        .x_init(60), 
        .y_init(50), 
        .line(line), 
        .pix(gameover_pix), 
        .colr(gameover_colr), 
        .drawing_r(gameover_drawing_r)
    );

    // playagain
    logic [3:0] playagain_pix;
    logic [11:0] playagain_colr;
    logic playagain_drawing_r;
    item #(
        .FILE("playagain.mem"), 
        .PALETTE_FILE("playagain_palette.mem"), 
        .WIDTH(256), 
        .HEIGHT(100)
    ) playagain (
        .i_clk_25(i_clk_25), 
        .i_rst_n(i_rst_n), 
        .sx(sx), 
        .sy(sy), 
        .x_init(60), 
        .y_init(280), 
        .line(line), 
        .pix(playagain_pix), 
        .colr(playagain_colr), 
        .drawing_r(playagain_drawing_r)
    );


    // monitor
    logic monitor_start_r, monitor_start_w;
    assign monitor_start_w = monitor_start_r;
	always_ff @(posedge i_clk_25 or negedge i_rst_n) begin
		if (!i_rst_n) begin
            monitor_start_r <= 1'b1;
        end
        else begin
            monitor_start_r <= monitor_start_w;       
        end
    end
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
        .i_start_display(monitor_start_r)
    );
endmodule