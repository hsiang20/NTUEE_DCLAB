module AudRecorder(

	input i_rst_n, 
	input i_clk,
	input i_lrc,
	input i_start,
	input i_pause,
	input i_stop,
	input i_data,
	output [19:0] o_address,
	output [15:0] o_data

);

logic [2:0] state_r, state_w;
logic [19:0] address_r, address_w;
logic [15:0] data_r, data_w;
logic [3:0] det_16_r, det_16_w; //detect 16 bits
logic lrc_r, lrc_w; 

localparam S_IDLE  = 0;
localparam S_PROC  = 1;
localparam S_DATA  = 2;
//localparam S_LRC1 = 3; //
localparam S_LRC0 = 3; //

assign o_address = address_r;
assign o_data = data_r ;




always_comb begin

	state_w = state_r;
	address_w = address_r;
	data_w = data_r;
	det_16_w = det_16_r;
	lrc_w = i_lrc;

	case(state_r) 
		S_IDLE: begin
			state_w = (i_start) ? S_LRC0 : state_r; 
			
			data_w = 16'b0;
		end
		S_PROC: begin
			data_w = {data_r[14:0], i_data};
			det_16_w = (det_16_r == 4'd15)? 4'b0 : det_16_r+1;
			state_w =  (det_16_r == 4'd15)? S_DATA : state_r;
		end
		S_DATA: begin
			address_w = address_r+1;
			state_w = S_LRC0;
		end
		
		S_LRC0: begin
			state_w = (!lrc_r && lrc_w) ? S_PROC : state_r ;
			det_16_w = 4'b0;
		end
	endcase
	if(i_stop) begin
		address_w = 20'b0;
		state_w = S_IDLE;
		
	end
	if(i_pause) begin
		state_w = S_IDLE;
	end
end

always_ff @ ( posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		state_r <= S_IDLE;
		address_r <= 20'b0;
		data_r <= 16'b0;
		det_16_r <= 4'b0;
		lrc_r <= 0;
	end else begin
		state_r <= state_w;
		address_r <= address_w;
		data_r <= data_w;
		det_16_r <= det_16_w;
		lrc_r <= lrc_w;
	end
end
endmodule
