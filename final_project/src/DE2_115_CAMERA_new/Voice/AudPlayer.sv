module AudPlayer(

	input i_rst_n,
	input i_bclk,
	input i_daclrck,
	input i_en, // enable AudPlayer only when playing audio, work with AudDSP
	input [15:0] i_dac_data, //dac_data
	output o_aud_dacdat

);

logic [2:0] state_r, state_w;
logic [15:0] data_r, data_w;
logic [3:0] det_16_r, det_16_w; //detect 16 bits

localparam S_IDLE  = 0;
localparam S_PROC  = 1;
localparam S_LRC1 = 2; //
localparam S_LRC0 = 3; //


assign o_aud_dacdat = (state_r == S_PROC)? data_r[15-det_16_r] : 0;




always_comb begin

	state_w = state_r;
	data_w = data_r;
	det_16_w = det_16_r;
	if(i_en) begin
		case(state_r) 
			S_IDLE: begin	
				state_w = (i_daclrck) ? S_LRC1 : S_LRC0; 
			end
			S_PROC: begin
				det_16_w = (det_16_r == 4'd15)? 4'b0 : det_16_r+1;
				state_w =  (det_16_r == 4'd15)? S_LRC1 : state_r;
			end
			S_LRC1: begin
				state_w = (i_daclrck) ? state_r : S_LRC0;
			end
			S_LRC0: begin
				if (i_daclrck) begin
					state_w = S_PROC;
					data_w = i_dac_data;
					det_16_w = 4'b0;
				end
			end
		endcase
	end else begin
		state_w = S_IDLE;
	end
end

always_ff @ ( posedge i_bclk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		state_r <= S_IDLE;
		data_r <= 16'b0;
		det_16_r <= 4'b0;
	end else begin
		state_r <= state_w;
		data_r <= data_w;
		det_16_r <= det_16_w;
	end
end
endmodule
