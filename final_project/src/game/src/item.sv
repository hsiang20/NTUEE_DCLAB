module item #(
    parameter FILE = "", 
    parameter PALETTE_FILE = "", 
    parameter WIDTH = 512, 
    parameter HEIGHT = 128, 
    parameter FRAMES = 1, 
    parameter PIXELS = WIDTH * HEIGHT, 
    parameter DEPTH = PIXELS * FRAMES, 
    parameter ADDRW = $clog2(DEPTH), 
    parameter SCALE_X = 1, 
    parameter SCALE_Y = 1, 
    parameter COLR_BITS = 4, 
    parameter CORDW = 16
)(
    input i_clk_25, 
    input i_rst_n, 
    input replay, 
    input signed [15:0] sx, 
    input signed [15:0] sy, 
    input [19:0] x_init, 
    input [19:0] y_init, 
    input line, 
    output [3:0] pix, 
    output [11:0] colr, 
    output drawing_r
);

    logic [COLR_BITS-1:0] rom_data;
    logic [ADDRW-1:0] rom_addr;
    rom_sync #(
        .WIDTH(COLR_BITS), 
        .DEPTH(DEPTH), 
        .INIT_F(FILE)
    ) title_rom (
        .clk(i_clk_25), 
        .addr(rom_addr), 
        .data(rom_data)
    );
	rom_async #(
		.WIDTH(12), 
		.DEPTH(16), 
		.INIT_F(PALETTE_FILE), 
        .ADDRW(4)
    ) title_clut(
        .addr(pix), 
        .data(colr)
    );
    logic start, drawing, drawing_w;
    sprite_1 #(
        .WIDTH(WIDTH), 
        .HEIGHT(HEIGHT), 
        .COLR_BITS(COLR_BITS), 
        .SCALE_X(SCALE_X), 
        .SCALE_Y(SCALE_Y), 
        .ADDRW(ADDRW)
    ) title(
        .clk(i_clk_25), 
        .rst(i_rst_n), 
        .replay(replay), 
        .start(start), 
        .sx(sx), 
        .sprx(x_init),
        .data_in(rom_data), 
        .pos(rom_addr),  
        .pix(pix), 
        .drawing(drawing), 
        .done()
    );
    always_comb begin
        start = (line && sy == y_init);
        drawing_w = drawing;
    end
	always_ff @(posedge i_clk_25 or negedge i_rst_n or posedge replay) begin
        if (!i_rst_n) drawing_r <= 0;
        else if (replay) drawing_r <= 0;
        else drawing_r <= drawing_w;
	end

endmodule