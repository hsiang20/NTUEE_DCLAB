module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
);

// operations for RSA256 decryption
// namely, the Montgomery algorithm
// ===== States =====
parameter PREP = 2'b00;
parameter MONT = 2'b01;
parameter CALC = 2'b10;
parameter IDLE = 2'b11;

// ===== Output Buffers =====
logic [255:0] o_a_pow_d_r, o_a_pow_d_w;
logic         o_finished_r, o_finished_w;

// ===== Registers and Wires =====
logic [1:0]   state_r, state_w;
logic [255:0] t_r, t_w;
logic         is_second_mont_r, is_second_mont_w;
logic [8:0]   cycle_r, cycle_w;
logic [255:0] d_bitwise_r, d_bitwise_w;
logic         prep_start_r, prep_start_w;
logic         first_mont_start_r, first_mont_start_w;
logic         second_mont_start_r, second_mont_start_w;
logic         mont1_is_processing_r, mont1_is_processing_w;
logic         mont2_is_processing_r, mont2_is_processing_w;
logic [255:0] a;

// ===== Module Ouputs =====
logic [255:0] o_prep;
logic         o_prep_finished;
logic [255:0] o_mont1, o_mont2;
logic         o_first_mont_finished;
logic         o_second_mont_finished;

// ===== Modules =====
RsaPrep rsa_prep(
	.i_clk(i_clk),
	.i_rst(i_rst),
	.i_start(prep_start_r),
	.i_a(a),
	.i_n(i_n),
	.o_a_mult(o_prep),
	.o_prep_finished(o_prep_finished)
);

RsaMont rsa_mont1(
	.i_clk(i_clk),
	.i_rst(i_rst),
	.i_start(first_mont_start_r),
	.i_a(o_a_pow_d_r),
	.i_b(t_r),
	.i_n(i_n),
	.o_a_mont(o_mont1),
	.o_mont_finished(o_first_mont_finished)
);

RsaMont rsa_mont2(
	.i_clk(i_clk),
	.i_rst(i_rst),
	.i_start(second_mont_start_r),
	.i_a(t_r),
	.i_b(t_r),
	.i_n(i_n),
	.o_a_mont(o_mont2),
	.o_mont_finished(o_second_mont_finished)
);
// ===== Output Assignments =====
assign o_a_pow_d  = o_a_pow_d_r;
assign o_finished = o_finished_r;

// ===== Combinational Circuits =====
always_comb begin
	// Default Values
	a 						 = 0;
	state_w                  = state_r;
	o_a_pow_d_w				 = o_a_pow_d_r;
	o_finished_w             = o_finished_r;
	t_w                      = t_r;
	is_second_mont_w         = is_second_mont_r;
	cycle_w                  = cycle_r;
	d_bitwise_w              = d_bitwise_r;
	prep_start_w             = prep_start_r;
	first_mont_start_w       = first_mont_start_r;
	second_mont_start_w      = second_mont_start_r;
	mont1_is_processing_w    = mont1_is_processing_r;
	mont2_is_processing_w    = mont2_is_processing_r;
	//FSM
	case (state_r)
	IDLE: begin
		// $display("IDLE");
		o_finished_w     = 1'b0;
		o_a_pow_d_w      = 256'b1;
		if (i_start) begin
			a            = i_a;
			state_w      = PREP;
			prep_start_w = 1'b1;
			cycle_w      = 9'b0;
			t_w          = 256'b0;
		end
	end
	PREP: begin
		// $display("PREP");
		if (prep_start_r == 1'b1) begin
			prep_start_w = 1'b0;
		end
		if (o_prep_finished == 1'b1) begin
			state_w           = MONT;
			t_w               = o_prep;
			d_bitwise_w       = i_d;
		end
	end
	MONT: begin
		// $display("MONT");
		if (d_bitwise_r[0] == 1'b1 & mont1_is_processing_r == 1'b0) begin
			// $display("dao1");
			mont1_is_processing_w = 1'b1;
			first_mont_start_w    = 1'b1;
		end
		else if (d_bitwise_r[0] == 1'b0) begin
			mont2_is_processing_w = 1'b1;
			second_mont_start_w   = 1'b1;
			// $display("d_no");
		end
		if (o_first_mont_finished == 1'b1) begin
			o_a_pow_d_w           = o_mont1;
			mont2_is_processing_w = 1'b1;
			second_mont_start_w   = 1'b1;
			// $display("d_yes");
		end
		else if (o_second_mont_finished == 1'b1) begin
			mont1_is_processing_w = 1'b0;
			t_w = o_mont2;
			state_w = CALC;
		end
		// close start1 and start2
		if (mont1_is_processing_r == 1'b1) begin
			first_mont_start_w = 1'b0;
		end
		if (mont2_is_processing_r == 1'b1) begin
			second_mont_start_w = 1'b0;
		end
	end
	CALC: begin
		// $display("CALC");
		mont1_is_processing_w = 1'b0;
		mont2_is_processing_w = 1'b0;
		if (cycle_r == 9'b1_0000_0000) begin
			state_w      = IDLE;
			o_finished_w = 1'b1;
		end
		else begin
			state_w      = MONT;
			cycle_w      = cycle_r + 1;
			d_bitwise_w  = d_bitwise_r >> 1;
		end
	end
	endcase
end

// ===== Sequential Circuits =====
always_ff @( posedge i_clk or posedge i_rst ) begin
	// reset 
	if (i_rst) begin
		state_r                  <= IDLE;
		o_a_pow_d_r              <= 256'b1;
		o_finished_r             <= 1'b0;
		t_r                      <= 256'b0;
		is_second_mont_r         <= 1'b0;
		cycle_r                  <= 9'b0;
		d_bitwise_r              <= 256'b0;
		prep_start_r             <= 1'b0;
		first_mont_start_r       <= 1'b0;
		second_mont_start_r      <= 1'b0;
		mont1_is_processing_r    <= 1'b0;
		mont2_is_processing_r    <= 1'b0;
	end
	else begin
		state_r                  <= state_w;
		o_a_pow_d_r              <= o_a_pow_d_w;
		o_finished_r             <= o_finished_w;
		t_r                      <= t_w;
		is_second_mont_r         <= is_second_mont_w;
		cycle_r                  <= cycle_w;
		d_bitwise_r              <= d_bitwise_w;
		prep_start_r             <= prep_start_w;
		first_mont_start_r       <= first_mont_start_w;
		second_mont_start_r      <= second_mont_start_w;
		mont1_is_processing_r    <= mont1_is_processing_w;
		mont2_is_processing_r    <= mont2_is_processing_w;
	end
end
endmodule
