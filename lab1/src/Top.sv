module Top (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	input		 i_back, 
	output [3:0] o_random_out
);

// ===== States =====
parameter S_IDLE = 1'b0;
parameter S_PROC = 1'b1;

// ===== Output Buffers =====
logic [3:0] o_random_out_r, o_random_out_w;

// ===== Registers & Wires =====
logic state_r, state_w;
logic [15:0] lfsr_r, lfsr_w;
logic [27:0] count_r, count_w;
logic [27:0] switch_r, switch_w;
logic [3:0] last_r, last_w;
logic [3:0] now_r, now_w;

// ===== Output Assignments =====
assign o_random_out = o_random_out_r;

// ===== Combinational Circuits =====
always_comb begin
	// Default Values
	o_random_out_w = o_random_out_r;
	state_w        = state_r;
	lfsr_w		   = lfsr_r;
	switch_w	   = switch_r;
	count_w		   = count_r;
	last_w		   = last_r;
	now_w		   = now_r;


	// FSM
	case(state_r)
	S_IDLE: begin
		if (i_start) begin
			state_w 	   = S_PROC;
			count_w		   = 27'b0;
			switch_w	   = 27'b10_0000_0000;
		end
		else if (i_back) begin
			state_w		  = S_IDLE;
			o_random_out_w = last_r;
			count_w		   = 27'b0;
			switch_w	   = 27'b10_0000_0000;
		end	
	end

	S_PROC: begin
		if (i_start) begin // pause
			state_w 		= S_IDLE;
			count_w 		= count_r + 1;
			switch_w		= 27'b10_0000_0000;
		end
		else if (count_r == switch_r) begin
			state_w 		= S_PROC;
			o_random_out_w  = lfsr_r[3:0];
			lfsr_w			= {lfsr_r[8] ^ (lfsr_r[6] ^ (lfsr_r[5] ^ lfsr_r[3])), 
							   lfsr_r[7] ^ (lfsr_r[5] ^ (lfsr_r[4] ^ lfsr_r[2])), 
							   lfsr_r[6] ^ (lfsr_r[4] ^ (lfsr_r[3] ^ lfsr_r[1])), 
							   lfsr_r[5] ^ (lfsr_r[3] ^ (lfsr_r[2] ^ lfsr_r[0])), 
							   lfsr_r[15:4]};
			count_w 		= count_r + 1;
			switch_w		= switch_r << 1;
		end	
		else if (count_r == 28'b1000_0000_0000_0000_0000_0000_0001) begin
			state_w 		= S_IDLE;
			count_w 		= 27'b0;
			switch_w		= 27'b10_0000_0000;
			last_w			= now_r;
			now_w			= o_random_out_r;
		end
		else begin
			state_w 		= S_PROC;
			count_w 		= count_r + 1;
			switch_w		= switch_r;
		end
	end

	endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
	// o_random_out_r <= 4'd0;
	// reset
	if (!i_rst_n) begin
		o_random_out_r <= 4'd0;
		state_r        <= S_IDLE;
		lfsr_r         <= 16'b1011_0100_1001_0011;
		switch_r	   <= 27'b10_0000_0000;
		count_r		   <= 27'b0;
		last_r 		   <= 4'd0;
		now_r		   <= 4'd0;
	end
	else begin
		o_random_out_r <= o_random_out_w;
		state_r        <= state_w;
		lfsr_r 		   <= lfsr_w;
		switch_r	   <= switch_w;
		count_r		   <= count_w;
		last_r		   <= last_w;
		now_r		   <= now_w;
		
	end
end

endmodule