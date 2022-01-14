module plate (
    input clk, 
    input i_rst_n, 
    input signed [15:0] sx, 
    input signed [15:0] sy, 
    input [19:0] plate_x_init, 
    input [19:0] plate_y_init, // bg_height
    input line, 
    input [19:0] screen_height, 
    output [3:0] plate_pix, 
    output [11:0] plate_colr, 
    output plate_drawing_r, 
    output signed [15:0] plate_x, 
    output signed [15:0] plate_y
);
    
    assign plate_x = plate_x_r;
    assign plate_y = plate_y_r;
    localparam PLATE_FILE = "plate.mem";
    localparam COLR_BITS = 4;
    localparam CORDW = 16; // screen coordinate width
    localparam PLATE_WIDTH = 64;
    localparam PLATE_HEIGHT = 16;
    localparam PLATE_FRAMES = 1;
    localparam PLATE_PIXELS = PLATE_WIDTH * PLATE_HEIGHT;
    localparam PLATE_DEPTH = PLATE_PIXELS * PLATE_FRAMES;
    localparam PLATE_ADDRW = $clog2(PLATE_DEPTH);
    logic [COLR_BITS-1:0] plate_rom_data;
    logic [PLATE_ADDRW-1:0] plate_rom_addr;
    rom_sync #(
        .WIDTH(COLR_BITS), 
        .DEPTH(PLATE_DEPTH), 
        .INIT_F(PLATE_FILE)
    ) plate_rom (
        .clk(clk), 
        .addr(plate_rom_addr), 
        .data(plate_rom_data)
    );
    parameter PLATE_PALETTE = "plate_palette.mem";
    // logic [COLR_BITS-1:0] plate_pix;
    // logic [11:0] plate_colr;
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
    logic signed [CORDW-1:0] plate_x_r, plate_x_w, plate_y_r, plate_y_w;
    logic plate_start, plate_drawing, plate_drawing_w;
    sprite_1 #(
        .WIDTH(PLATE_WIDTH), 
        .HEIGHT(PLATE_HEIGHT), 
        .COLR_BITS(COLR_BITS), 
        .SCALE_X(PLATE_SCALE_X), 
        .SCALE_Y(PLATE_SCALE_Y), 
        .ADDRW(PLATE_ADDRW)
    ) plate(
        .clk(clk), 
        .rst(i_rst_n), 
        .start(plate_start), 
        .sx(sx), 
        .sprx(plate_x_r),
        .data_in(plate_rom_data), 
        .pos(plate_rom_addr),  
        .pix(plate_pix), 
        .drawing(plate_drawing), 
        .done()
    );
    // localparam PLATE_BG_HEIGHT = 100;
    always_comb begin
        plate_start = (line && sy == plate_y_r);
        plate_x_w = plate_x_r;
        plate_y_w = 469 - 16 - (plate_y_init - screen_height);
        plate_drawing_w = plate_drawing;
    end
	always_ff @(posedge clk or negedge i_rst_n) begin
		if (!i_rst_n) begin
            plate_x_r <= plate_x_init;
            plate_y_r <= 469 - 16 - plate_y_init;
        end
		else begin
            plate_x_r <= plate_x_w;
            plate_y_r <= plate_y_w;
            plate_drawing_r <= plate_drawing_w;
        end
	end

endmodule