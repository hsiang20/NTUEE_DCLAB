module plate (
    input 
)
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
    // localparam PLATE_BG_HEIGHT = 100;
    logic plate_trans_r, plate_trans_w;
    always_comb begin
        plate_trans_w = (plate_pix == PLATE_TRANS);
        plate_start = (line && sy == platey_r);
        platex_w = platex_r;
        platey_w = 469 - 16 - (plate_y[0] - screen_height_r);
        plate_base_addr_w = 0;
        plate_drawing_w = plate_drawing;
    end
	always_ff @(posedge i_clk_25 or negedge i_rst_n) begin
		if (!i_rst_n) begin
            platex_r <= 250;
            platey_r <= 469 - 16 - plate_y[0]; // 353
        end
		else begin
            plate_trans_r <= plate_trans_w;
            plate_base_addr_r <= plate_base_addr_w;
            platex_r <= platex_w;
            platey_r <= platey_w;
            plate_drawing_r <= plate_drawing_w;
        end
	end

endmodule