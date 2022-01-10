module sprite_1(
    input clk, 
    input rst, 
    input start, 
    input signed [15:0] sx, // horizontal screen position
    input signed [15:0] sprx, // horizontal sprite position
    output pix
    );

    localparam WIDTH = 8;
    localparam HEIGHT = 8;
    localparam SPR_FILE = "letter_f.mem";
    localparam CORDW = 16;
    localparam DEPTH = WIDTH * HEIGHT;

    // sprite graphic ROM
    logic [$clog2(DEPTH)-1:0] spr_rom_addr, spr_rom_addr_r, spr_rom_addr_w; // pixel position
    logic spr_rom_data; // pixel color
    logic pix_r, pix_w;
    assign pix = pix_r;
    assign spr_rom_addr = spr_rom_addr_r;
	 
	 rom_async #(
		.WIDTH(1), 
		.DEPTH(DEPTH), 
		.INIT_F(SPR_FILE)
	 )spr_rom(
        .addr(spr_rom_addr), 
        .data(spr_rom_data)
    );

    // position within sprite
    logic [$clog2(WIDTH)-1:0] ox_r, ox_w;
    logic [$clog2(HEIGHT)-1:0] oy_r, oy_w;

    localparam IDLE = 3'd0;
    localparam START = 3'd1;
    localparam AWAIT_POS = 3'd2;
    localparam DRAW = 3'd3;
    localparam NEXT_LINE = 3'd4;
    logic [3:0] state, state_next;
    logic last_pixel, last_line;

    // output pixel color when drawing
    always_comb pix_w = (state == DRAW) ? spr_rom_data : 0;

    // create status signals
    always_comb begin
        last_pixel = (ox_r == WIDTH - 1);
        last_line  = (oy_r == HEIGHT - 1);
    end

    // FSM
    always_comb begin
        case (state)
            IDLE:      state_next = start ? START : IDLE;
            START:     state_next = AWAIT_POS;
            AWAIT_POS: state_next = (sx == sprx-1) ? DRAW : AWAIT_POS;
            DRAW:      state_next = !last_pixel ? DRAW : 
                                    (!last_line) ? NEXT_LINE : IDLE;
            NEXT_LINE: state_next = AWAIT_POS;
            default:   state_next = IDLE;
        endcase
    end

    always_comb begin
        ox_w = ox_r;
        oy_w = oy_r;
        spr_rom_addr_w = spr_rom_addr_r;
        case (state)
            START: begin
                oy_w = 0;
                spr_rom_addr_w <= 0;
            end
            AWAIT_POS: ox_w <= 0;
            DRAW: begin
                ox_w <= ox_r + 1;
                spr_rom_addr_w <= spr_rom_addr_r + 1;
            end
            NEXT_LINE: oy_w <= oy_r + 1;
        endcase
        
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= IDLE;
            pix_r <= 0;
            ox_r <= 0;
            oy_r <= 0;
            spr_rom_addr_r <= 0;
        end
        else begin
            state <= state_next;
            pix_r <= pix_w;
            ox_r <= ox_w;
            oy_r <= oy_w;
            spr_rom_addr_r <= spr_rom_addr_w;
        end
    end


endmodule