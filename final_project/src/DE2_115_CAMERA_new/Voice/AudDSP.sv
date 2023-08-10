module AudDSP(
	input i_rst_n,
	input i_clk,
	input i_start,
	input i_pause,
	input i_stop,
	input [2:0] i_speed, //i_speed + 1 is the real speed
	input i_fast,
	input i_slow_0, // constant interpolation
	input i_slow_1, // linear interpolation
	input i_reverse,
	input i_daclrck,
	input signed [15:0] i_sram_data,
	input [19:0] i_end_address,
	output[15:0] o_dac_data,
	output[19:0] o_sram_addr,
	output o_audplayer_en
);

logic [3:0] state_r, state_w;
logic audplayer_en_r, audplayer_en_w, play_finish_r, play_finish_w;
logic [19:0] sram_addr_r, sram_addr_w;
logic [15:0] dac_data_r, dac_data_w;
logic signed [15:0] origin_data_r, origin_data_w;
logic [3:0] count_r, count_w;


assign o_audplayer_en = audplayer_en_r;
assign o_sram_addr = sram_addr_r;
assign o_dac_data = dac_data_r;

localparam S_IDLE  = 0;
localparam S_FAST  = 1;
localparam S_SLOW  = 2;
localparam S_LRC1 = 3; //Wait for ending cycles 
localparam S_LRC0 = 4; //Wait for data sending
localparam S_REV = 5;

always_comb begin

	state_w = state_r;
	audplayer_en_w = audplayer_en_r;
	sram_addr_w = sram_addr_r;
	dac_data_w = dac_data_r;
	origin_data_w = origin_data_r;
	count_w = count_r;
	play_finish_w = play_finish_r;

	case(state_r) 
		S_IDLE: begin
			audplayer_en_w = 0;
			dac_data_w =16'b0;
			if(i_start && play_finish_r == 1'b0) begin
				state_w = S_LRC0; //About to fast or slow processing
				if(i_reverse) begin
					sram_addr_w = i_end_address;
				end
			end
		end
		S_FAST: begin
			sram_addr_w = (1+i_speed)+sram_addr_r;
			dac_data_w = i_sram_data;
			origin_data_w = i_sram_data;
			state_w = S_LRC1;
			if (sram_addr_r > i_end_address) begin
				state_w = S_IDLE;
				play_finish_w = 1'b1;
			end
		end
		S_REV: begin
			sram_addr_w = sram_addr_r - (1+i_speed);
			dac_data_w = i_sram_data;
			origin_data_w = i_sram_data;
			state_w = S_LRC1;
			if (sram_addr_r < 20'b1) begin
				state_w = S_IDLE;
				play_finish_w = 1'b1;
			end
		end
		S_SLOW: begin
			if(i_slow_0) begin
				if (count_r < i_speed) begin
					count_w = count_r + 1;
					dac_data_w = origin_data_r;
				end
				else begin
					count_w = 4'b0;
					dac_data_w = i_sram_data;
					origin_data_w = i_sram_data;
					sram_addr_w = 1+sram_addr_r;
					
				end
			end
			else if (i_slow_1) begin
				if (count_r < i_speed) begin
					count_w = count_r + 1;
					dac_data_w = origin_data_r + $signed(i_sram_data - origin_data_r) * (count_r+1) / (i_speed+1);
				end
				else begin
					count_w = 4'b0;
					dac_data_w = i_sram_data;
					origin_data_w = i_sram_data;
					sram_addr_w = 1+sram_addr_r;
					//state_w = S_LRC1;
					//if (sram_addr_r > i_end_address) begin
						//state_w = S_IDLE;
						//play_finish_w = 1'b1;
					//end
				end
			end
			state_w = (sram_addr_r > i_end_address)? S_IDLE : S_LRC1;
			if (sram_addr_r > i_end_address) begin
				//state_w = S_IDLE;
				play_finish_w = 1'b1;
			end
			
		end
		S_LRC1: begin
			audplayer_en_w = (i_daclrck) ? audplayer_en_r : 1;
			state_w = (i_daclrck) ? state_r : S_LRC0;
		end
		S_LRC0: begin
			if(i_daclrck) begin
				state_w = (i_slow_0 || i_slow_1) ? S_SLOW : S_FAST;
				if (i_reverse) begin
					state_w = S_REV;
					//if (play_finish_r == 1'b0) begin
						//sram_addr_w = i_end_address;
					//end
				end
				
			end
		end
	endcase
	if(i_stop) begin
		sram_addr_w = 20'b0;
		state_w = S_IDLE;
		play_finish_w = 1'b0;
	end
	if(i_pause) begin
		state_w = S_IDLE;
	end
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		state_r <= S_IDLE;
		audplayer_en_r <= 0;
		sram_addr_r <= 20'b0;
		dac_data_r <= 16'b0;
		origin_data_r <= 16'b0;
		count_r <= 4'b0;
		play_finish_r <= 1'b0;
	end else begin
		state_r <= state_w;
		audplayer_en_r <= audplayer_en_w;
		sram_addr_r <= sram_addr_w;
		dac_data_r <= dac_data_w;
		origin_data_r <= origin_data_w;
		count_r <= count_w;
		play_finish_r <= play_finish_w;
	end
end

endmodule
