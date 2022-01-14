
module monster (
    input clk, 
    input i_rst_n, 
    input signed [15:0] sx, 
    input signed [15:0] sy, 
    input [19:0] monster_x_init, 
    input [19:0] monster_y_init, // bg_height
    input line, 
    input [19:0] screen_height, 
    output [3:0] monster_pix, 
    output [11:0] monster_colr, 
    output monster_drawing_r, 
    output signed [15:0] monster_x, 
    output signed [15:0] monster_y
);
    
    assign monster_x = monster_x_r;
    assign monster_y = monster_y_r;
    localparam MONSTER_FILE = "monster.mem";
    localparam COLR_BITS = 4;
    localparam CORDW = 16; // screen coordinate width
    localparam MONSTER_WIDTH = 64;
    localparam MONSTER_HEIGHT = 64;
    localparam MONSTER_FRAMES = 1;
    localparam MONSTER_PIXELS = MONSTER_WIDTH * MONSTER_HEIGHT;
    localparam MONSTER_DEPTH = MONSTER_PIXELS * MONSTER_FRAMES;
    localparam MONSTER_ADDRW = $clog2(MONSTER_DEPTH);
    logic [COLR_BITS-1:0] monster_rom_data;
    logic [MONSTER_ADDRW-1:0] monster_rom_addr;
    rom_sync #(
        .WIDTH(COLR_BITS), 
        .DEPTH(MONSTER_DEPTH), 
        .INIT_F(MONSTER_FILE)
    ) monster_rom (
        .clk(clk), 
        .addr(monster_rom_addr), 
        .data(monster_rom_data)
    );
    parameter MONSTER_PALETTE = "monster_palette.mem";
	rom_async #(
		.WIDTH(12), 
		.DEPTH(16), 
		.INIT_F(MONSTER_PALETTE), 
        .ADDRW(4)
    ) monster_clut(
        .addr(monster_pix), 
        .data(monster_colr)
    );
    parameter MONSTER_SCALE_X = 1;
    parameter MONSTER_SCALE_Y = 1;
    logic signed [CORDW-1:0] monster_x_r, monster_x_w, monster_y_r, monster_y_w;
    logic monster_start, monster_drawing, monster_drawing_w;
    sprite_1 #(
        .WIDTH(MONSTER_WIDTH), 
        .HEIGHT(MONSTER_HEIGHT), 
        .COLR_BITS(COLR_BITS), 
        .SCALE_X(MONSTER_SCALE_X), 
        .SCALE_Y(MONSTER_SCALE_Y), 
        .ADDRW(MONSTER_ADDRW)
    ) monster(
        .clk(clk), 
        .rst(i_rst_n), 
        .start(monster_start), 
        .sx(sx), 
        .sprx(monster_x_r),
        .data_in(monster_rom_data), 
        .pos(monster_rom_addr),  
        .pix(monster_pix), 
        .drawing(monster_drawing), 
        .done()
    );
    always_comb begin
        monster_start = (line && sy == monster_y_r);
        monster_x_w = monster_x_r;
        monster_y_w = 469 - 64 - (monster_y_init - screen_height);
        monster_drawing_w = monster_drawing;
    end
	always_ff @(posedge clk or negedge i_rst_n) begin
		if (!i_rst_n) begin
            monster_x_r <= monster_x_init;
            monster_y_r <= 469 - 64 - monster_y_init;
        end
		else begin
            monster_x_r <= monster_x_w;
            monster_y_r <= monster_y_w;
            monster_drawing_r <= monster_drawing_w;
        end
	end

endmodule