module Volume(

	input i_rst_n, 
	input i_clk,
	input [15:0] i_data,
	input i_recording,
	//output [2:0] o_state,
	//output [17:0] o_led,
	output o_vol,
	output o_volume

);

logic [3:0] state_r, state_w;
logic volume_r, volume_w;
logic vol_w, vol_r;
logic [49:0] count_r, count_w; //detect 16 bits
logic [49:0] cnt_r, cnt_w;

localparam S_IDLE  = 0;
localparam S_PROC0 = 1;
localparam S_PROC0_2 = 2;
//localparam S_PROC0_3 = 3;
localparam S_WAIT1 = 3; 
localparam S_PROC1 = 4; 
localparam S_PROC1_2 = 5;
//localparam S_PROC1_3 = 7;
localparam S_WAIT0 = 6; 



assign o_volume = volume_r;
assign o_vol = vol_r;
//assign o_state = state_r;
//assign o_state = (i_data[15:13]==3'd7)? 3'b1 : 3'b0;



always_comb begin

	state_w  = state_r;
	volume_w = volume_r;
	vol_w = vol_r;
	count_w  = count_r;
	cnt_w = cnt_r;
	//data_w = data_r;
	//det_16_w = det_16_r;
	//o_led = {2'b0,i_data};
	
	


	if(i_recording) begin
		case(state_r)
			S_IDLE: begin
			state_w  = S_PROC0 ; 
			volume_w = 1'b0;
			vol_w = 1'b0;
			count_w  =50'b0;
			cnt_w = 50'b0;
			end
			S_PROC0: begin
				cnt_w = (cnt_r > 15'b10000_00000_00000 || i_data[15:13]==3'd7)? 50'b0 : cnt_r+1;
				state_w =  (cnt_r > 15'b10000_00000_00000)? S_PROC0_2 : state_r;
				vol_w = (cnt_r > 15'b10000_00000_00000)? 1'b1 : vol_r;
				//count_w = 50'b0;
				//volume_w = 1'b1;
				//if (i_data[13]&(i_data[15] ^ i_data[14])) begin
					//volume_w = 1'b1 ;
					//state_w = S_WAIT1 ; 
				//end
				//else begin
					//volume_w = 1'b0;
					//state_w = state_r;
				//end
			end
			S_PROC0_2: begin
				vol_w = 1'b1;
				state_w = S_WAIT1;
			end
			S_WAIT1: begin
				count_w = (count_r > 25'b10000_00000_00000_00000_00000)? 50'b0 : count_r+1;
				state_w =  (count_r > 25'b10000_00000_00000_00000_00000)? S_PROC1 : state_r;
				//cnt_w = 50'b0;
				volume_w = 1'b1;
				vol_w = 1'b0;
			end
			S_PROC1: begin
				cnt_w = (cnt_r > 15'b10000_00000_00000 || i_data[15:13]==3'd7)? 50'b0 : cnt_r+1;
				state_w =  (cnt_r > 15'b10000_00000_00000)? S_PROC1_2 : state_r;
				vol_w = (cnt_r > 15'b10000_00000_00000)? 1'b1 : vol_r;
				//count_w = 50'b0;
			end
			S_PROC1_2: begin
				vol_w = 1'b1;
				state_w = S_WAIT0;
			end
			
			S_WAIT0: begin
				count_w = (count_r > 25'b10000_00000_00000_00000_00000)? 50'b0 : count_r+1;
				state_w =  (count_r > 25'b10000_00000_00000_00000_00000)? S_PROC0 : state_r;
				volume_w = 1'b0;
				vol_w = 1'b0;
			end		
			
		endcase
	end else begin
		volume_w = 1'b0;
		vol_w = 1'b0;
	end
	
end

always_ff @ (posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
 		state_r  <= S_IDLE;
 		volume_r <= 1'b0;
		count_r <= 50'b0;
		cnt_r <= 50'b0;
		vol_r <= 1'b0;

 	end else begin
 		state_r <= state_w;
 		volume_r <= volume_w;
		count_r <= count_w;
		cnt_r <= cnt_w;
		vol_r <= vol_w;
	end
end
endmodule
