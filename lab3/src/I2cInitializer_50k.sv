module I2cInitializer (
	input	i_rst_n,
	input	i_clk,
	input	i_start,
	output	o_finished,
	output	o_sclk,
	output	o_sdat,
	output	o_oen
);

logic [23: 0] setting_init[6:0] = '{
	24'b00110100_000_1111_0_0000_0000,
    24'b00110100_000_0100_0_0001_0101,
    24'b00110100_000_0101_0_0000_0000,
    24'b00110100_000_0110_0_0000_0000,
    24'b00110100_000_0111_0_0100_0010,
    24'b00110100_000_1000_0_0001_1001,
    24'b00110100_000_1001_0_0000_0001
};

localparam S_IDLE = 0;
localparam S_PROC = 1;
localparam S_ENDING = 2;
localparam S_ENDING1 = 3;
localparam S_STAY = 4;
localparam S_STAY2 = 5;
localparam S_LETSGO = 6;
localparam S_STOP= 7;


logic [2:0] state_r,state_w;
logic oen_r, oen_w;
logic sdat_r, sdat_w;
logic sclk_r, sclk_w;
logic finish_r, finish_w;
logic [5:0] det_24_r, det_24_w; //detect 24 bits
logic [3:0] det_7_r, det_7_w; //detect 7 cycles
logic [3:0] det_2_r, det_2_w;

assign o_finished = finish_r;
assign o_sclk = sclk_r;
assign o_sdat = sdat_r;
assign o_oen = oen_r;

always_comb begin
	state_w = state_r;
	sdat_w = sdat_r;
	sclk_w = sclk_r;
	finish_w = finish_r;
	oen_w = oen_r;
	det_24_w = det_24_r;
	det_7_w = det_7_r;
	det_2_w = det_2_r;
	
	case(state_r)
		S_IDLE: begin
			finish_w = 0;
			oen_w = 1;
			det_24_w = 6'b0;
			det_7_w = 4'b0;
			det_2_w = 4'b0;
			sclk_w = 1;
			sdat_w = 1;
			if(i_start) begin
				state_w = S_PROC;
				sdat_w = 0;
			end
		end

		S_PROC: begin
			sclk_w = ~sclk_r; // switching between Modify and Output
			
			if (sclk_r) begin 
				if (det_24_r % 8 == 0 && det_24_r > 0 && oen_r) begin
					$display("8 bit");
					oen_w = 0;
					sdat_w = 1'bz;
					det_24_w = (det_24_r == 6'd24) ? 6'b0 : (det_24_r);
					det_7_w  = (det_24_r == 6'd24) ? (det_7_r+1) : (det_7_r);
					if(det_24_r == 6'd24) begin
						//sclk_w = 1; //end 
                	 	//sdat_w = 1'bz; //end
          
					 	state_w = S_ENDING;
					end

					
				end
				else begin
					oen_w = 1;
					sdat_w = setting_init[6-det_7_r][23-det_24_r];
					det_24_w = det_24_r + 1;
					det_7_w = det_7_r;
				end
				
			end
		end
		S_ENDING: begin
			oen_w = 0;
			sclk_w = 1'd1;
			sdat_w = 1'bz;
			state_w = S_ENDING1;
			$display("24 bit");
		end	
		S_ENDING1: begin
			oen_w = 1;
			sclk_w = 1'd1;
			sdat_w = 1'b0;
			state_w = S_STAY;
		end
		S_STAY: begin
			
			oen_w = 1;
			sclk_w = 1'd1;
			sdat_w = 1'd1;
			state_w = (det_7_r>6)? S_STOP : S_STAY2;
			//det_2_w = 4'b0;
		end
		S_STAY2: begin
			oen_w = 1;
			sclk_w = 1'd1;
			sdat_w = 1'd1;
			state_w = (det_2_r > 0)? S_LETSGO : state_r;
			det_2_w = (det_2_r > 0)? 4'b0 : (det_2_r+1);

		end

		S_LETSGO: begin
			oen_w = 1;
			sclk_w = 1'd1;
			sdat_w = 1'b0;
			state_w = S_PROC;
		end
		S_STOP: begin
			finish_w = 1;
			oen_w = 1;
			sclk_w = 1'd1;
			sdat_w = 1'd1;
			state_w = state_r;

		
		end	
		
	endcase
end
always_ff @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		state_r <= S_IDLE;
		det_24_r <= 6'b0;
		det_7_r <= 4'b0;
		det_2_r <= 4'b0;
		sdat_r <= 1;
		sclk_r <= 1;
		finish_r <= 0;
		oen_r <= 1;
	end else begin
		state_r <= state_w;
		det_24_r <= det_24_w;
		det_7_r <= det_7_w;
		det_2_r <= det_2_w;
		sdat_r <= sdat_w;
		sclk_r <= sclk_w;
		finish_r <= finish_w;
		oen_r <= oen_w;
	end
end

endmodule