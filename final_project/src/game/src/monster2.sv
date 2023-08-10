
module monster2 (
    input clk, 
    input i_rst_n, 
    input replay, 
    input signed [15:0] sx, 
    input signed [15:0] sy, 
    input [19:0] monster2_x_init, 
    input [19:0] monster2_y_init, // bg_height
    input line, 
    input [19:0] screen_height, 
    output [3:0] monster2_pix, 
    output [11:0] monster2_colr, 
    output monster2_drawing_r, 
    output signed [15:0] monster2_x, 
    output signed [15:0] monster2_y
);
    
    assign monster2_x = monster2_x_r;
    assign monster2_y = monster2_y_r;
    localparam MONSTER2_FILE = "monster2.mem";
    localparam COLR_BITS = 4;
    localparam CORDW = 16; // screen coordinate width
    localparam MONSTER2_WIDTH = 64;
    localparam MONSTER2_HEIGHT = 96;
    localparam MONSTER2_FRAMES = 1;
    localparam MONSTER2_PIXELS = MONSTER2_WIDTH * MONSTER2_HEIGHT;
    localparam MONSTER2_DEPTH = MONSTER2_PIXELS * MONSTER2_FRAMES;
    localparam MONSTER2_ADDRW = $clog2(MONSTER2_DEPTH);
    logic [COLR_BITS-1:0] monster2_rom_data;
    logic [MONSTER2_ADDRW-1:0] monster2_rom_addr;
    rom_sync #(
        .WIDTH(COLR_BITS), 
        .DEPTH(MONSTER2_DEPTH), 
        .INIT_F(MONSTER2_FILE)
    ) monster2_rom (
        .clk(clk), 
        .addr(monster2_rom_addr), 
        .data(monster2_rom_data)
    );
    parameter MONSTER2_PALETTE = "monster2_palette.mem";
	rom_async #(
		.WIDTH(12), 
		.DEPTH(16), 
		.INIT_F(MONSTER2_PALETTE), 
        .ADDRW(4)
    ) monster2_clut(
        .addr(monster2_pix), 
        .data(monster2_colr)
    );
    parameter MONSTER2_SCALE_X = 1;
    parameter MONSTER2_SCALE_Y = 1;
    logic signed [CORDW-1:0] monster2_x_r, monster2_x_w, monster2_y_r, monster2_y_w;
    logic monster2_start, monster2_drawing, monster2_drawing_w;
    sprite_1 #(
        .WIDTH(MONSTER2_WIDTH), 
        .HEIGHT(MONSTER2_HEIGHT), 
        .COLR_BITS(COLR_BITS), 
        .SCALE_X(MONSTER2_SCALE_X), 
        .SCALE_Y(MONSTER2_SCALE_Y), 
        .ADDRW(MONSTER2_ADDRW)
    ) monster2(
        .clk(clk), 
        .rst(i_rst_n), 
        .replay(replay), 
        .start(monster2_start), 
        .sx(sx), 
        .sprx(monster2_x_r),
        .data_in(monster2_rom_data), 
        .pos(monster2_rom_addr),  
        .pix(monster2_pix), 
        .drawing(monster2_drawing), 
        .done()
    );
    always_comb begin
        monster2_start = (line && sy == monster2_y_r);
        monster2_x_w = monster2_x_r;
        monster2_y_w = 469 - MONSTER2_HEIGHT - (monster2_y_init - screen_height);
        monster2_drawing_w = monster2_drawing;
    end
	always_ff @(posedge clk or negedge i_rst_n or posedge replay) begin
		if (!i_rst_n) begin
            monster2_x_r <= monster2_x_init;
            monster2_y_r <= 469 - MONSTER2_HEIGHT - monster2_y_init;
        end
        else if (replay) begin
            monster2_x_r <= monster2_x_init;
            monster2_y_r <= 469 - MONSTER2_HEIGHT - monster2_y_init;
        end
		else begin
            monster2_x_r <= monster2_x_w;
            monster2_y_r <= monster2_y_w;
            monster2_drawing_r <= monster2_drawing_w;
        end
	end
    
endmodule