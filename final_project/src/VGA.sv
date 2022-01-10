module vga(
    // DE2-115
    input i_rst_n, 
    input i_clk_25M, 
    output [7:0] VGA_R, 
    output [7:0] VGA_G, 
    output [7:0] VGA_B, 
    output VGA_CLK, 
    output VGA_BLANK_N, 
    output VGA_HS, 
    output VGA_VS, 
    output VGA_SYNC_N, 

    // Top
    input i_start_display
	 
	 // Debug
);
    logic [9:0] x_count_r, x_count_w, y_count_r, y_count_w;
    logic hsync_r, hsync_w, vsync_r, vsync_w;
    logic [7:0] vga_r_r, vga_r_w, vga_g_r, vga_g_w, vga_b_r, vga_b_w;
    logic state_r, state_w;
	logic finish_r, finish_w;

    localparam H_FRONT  =   16;
    localparam H_SYNC   =   96;
    localparam H_BACK   =   48;
    localparam H_ACT    =   640;
    localparam H_BLANK  =   H_FRONT + H_SYNC + H_BACK;
    localparam H_TOTAL  =   H_FRONT + H_SYNC + H_BACK + H_ACT;
    localparam V_FRONT  =   10;
    localparam V_SYNC   =   2;
    localparam V_BACK   =   33;
    localparam V_ACT    =   480;
    localparam V_BLANK  =   V_FRONT + V_SYNC + V_BACK;
    localparam V_TOTAL  =   V_FRONT + V_SYNC + V_BACK + V_ACT;

    localparam S_IDLE    = 1'b0;
    localparam S_DISPLAY = 1'b1;
	 
	localparam bluesquare_x1 = 15 + H_BLANK;
	localparam bluesquare_x2 = 23 + H_BLANK;
	localparam bluesquare_y1 = 15 + V_BLANK;
	localparam bluesquare_y2 = 23 + V_BLANK;

    // output
    assign VGA_CLK = i_clk_25M;
    assign VGA_HS = hsync_r;
    assign VGA_VS = vsync_r;
    assign VGA_R = vga_r_r;
    assign VGA_G = vga_g_r;
    assign VGA_B = vga_b_r;
    assign VGA_SYNC_N = 1'b0;
    assign VGA_BLANK_N = ~((x_count_r < H_BLANK) || (y_count_r < V_BLANK));
	assign finish = finish_r;

    // FSM
    always_comb begin
        if (i_start_display) state_w = S_DISPLAY;
        // else if (y_count_r == 525) state_w = S_IDLE;
        else state_w = state_r;
    end

    // sync
    always_comb begin
        case (state_r)
            S_IDLE: begin
                hsync_w = 1'b1;
                vsync_w = 1'b1;
            end
            S_DISPLAY: begin
                if (x_count_r == 0) hsync_w = 1'b0;
                else if (x_count_r == H_SYNC) hsync_w = 1'b1;
                else hsync_w = hsync_r;
                if (y_count_r == 0) vsync_w = 1'b0;
                else if (y_count_r == V_SYNC) vsync_w = 1'b1;
                else vsync_w = vsync_r;
            end
        endcase 
    end

    // coordinate
    always_comb begin
        case (state_r)
            S_IDLE: begin
                x_count_w = 0;
                y_count_w = 0;
            end
            S_DISPLAY: begin
                if (x_count_r == 800) x_count_w = 0;
                else x_count_w = x_count_r + 1;
                if (y_count_r == 525) y_count_w = 0;
                else if (x_count_r == 800) y_count_w = y_count_r + 1;
                else y_count_w = y_count_r;
            end
        endcase
    end

    // rgb
    always_comb begin
        case (state_r)
            S_IDLE: begin
                vga_r_w = 8'b0;
                vga_g_w = 8'b0;
                vga_b_w = 8'b0;
					 finish_w = 1'b0;
            end
            S_DISPLAY: begin
                if (y_count_r == 0 && x_count_r == 0) begin
                    vga_r_w = 8'b0;
                    vga_g_w = 8'b0;
                    vga_b_w = 8'b0;
						  finish_w = 1'b1;
                end
                else if (x_count_r < (H_BLANK-1) || x_count_r > (H_TOTAL-2) || y_count_r < V_BLANK || y_count_r >= V_TOTAL) begin
                    vga_r_w = 8'b0;
                    vga_g_w = 8'b0;
                    vga_b_w = 8'b0;
						  finish_w = 1'b0;
                end
					 else if (bluesquare_x1 < x_count_r &&
								 x_count_r < bluesquare_x2 && 
								 bluesquare_y1 < y_count_r &&
								 y_count_r < bluesquare_y2) begin
							vga_r_w = 8'b0;
							vga_g_w = 8'b0;
							vga_b_w = 8'b1111_1111;
							finish_w = 1'b0;
					 end
                else begin
                    vga_r_w = 8'b0;
                    vga_g_w = 8'b0;
                    vga_b_w = 8'b0;
						  finish_w = 1'b0;
                end
            end
        endcase
    end


    always_ff @(posedge i_clk_25M or negedge i_rst_n) begin
        if (!i_rst_n) begin
            x_count_r <= 0;
            y_count_r <= 0;
            hsync_r   <= 1'b1;
            vsync_r   <= 1'b1;
            vga_r_r   <= 8'b0;
            vga_g_r   <= 8'b0;
            vga_b_r   <= 8'b0;
            state_r   <= S_IDLE;
			finish_r    <= 1'b0;
        end
        else begin
            x_count_r <= x_count_w;
            y_count_r <= y_count_w;
            hsync_r   <= hsync_w;
            vsync_r   <= vsync_w;
            vga_r_r   <= vga_r_w;
            vga_g_r   <= vga_g_w;
            vga_b_r   <= vga_b_w;
            state_r   <= state_w;
			finish_r  <= finish_w;
        end
    end
endmodule