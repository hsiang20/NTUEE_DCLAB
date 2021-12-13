module I2cInitializer (
	input	i_rst_n,
	input	i_clk,
	input	i_start,
	output	o_finished,
	output	o_sclk,
	inout	o_sdat,
	output	o_oen
);

logic [23: 0] setting_init[6:0] = '{
	24'b001101000001111000000000,
    24'b001101000000100000010101,
    24'b001101000000101000000000,
    24'b001101000000110000000000,
    24'b001101000000111001000010,
    24'b001101000001000000011001,
    24'b001101000001001000000001
};

localparam S_IDLE = 0;
localparam S_START = 1;
localparam S_PROC = 2;
localparam S_ACK = 3;
localparam S_STOP = 4;
localparam S_END = 5;


logic [2:0] state_r, state_w;
logic oen_r, oen_w;
logic sdat_r, sdat_w;
logic sclk_r, sclk_w;
logic finish_r, finish_w;
logic [5:0] det_24_r, det_24_w; // detect 24 bits
logic [3:0] det_7_r, det_7_w; // detect 7 cycles
logic [3:0] det_2_r, det_2_w;
logic get_ack_r, get_ack_w; // if get_ack, then jump to S_ACK when det_24 % 8 == 0
logic stop_cnt_r, stop_cnt_w;
//logic send_start_r, send_start_w;
assign o_finished = finish_r;
//assign o_sclk = sclk_r;
//assign o_sdat = sdat_r;
assign o_sclk = (state_r == S_IDLE || state_r == S_STOP || state_r == S_START || state_r == S_END) ? 1'b1 : ~i_clk;
assign o_sdat = oen_r ? sdat_r : 1'bz;
assign o_oen = oen_r;

always_comb begin
	state_w = state_r;
	sdat_w = sdat_r;
	finish_w = finish_r;
	oen_w = oen_r;
	det_24_w = det_24_r;
	det_7_w = det_7_r;
	det_2_w = det_2_r;
    get_ack_w = get_ack_r;
    stop_cnt_w = stop_cnt_r;
	//send_start_w = send_start_r;
	
	case(state_r)
		S_IDLE: begin
			finish_w = 0;
			oen_w = 1'b1;
			det_24_w = 6'b0;
			det_7_w = 4'b0;
			det_2_w = 4'b0;
			sdat_w = 1;
			if(i_start) begin
				state_w = S_START;
			end
		end

        S_START: begin
            // use stop_cnt as start_cnt
            if (stop_cnt_r == 1'b0) begin
                sdat_w = 1'b0;
                stop_cnt_w = 1'b1;
            end
            else begin
                stop_cnt_w = 1'b0;
                state_w = S_PROC;
                sdat_w = setting_init[6-det_7_r][23-det_24_r];
                det_24_w = det_24_r + 1;
                $display("hihi! current bit: %0d, bit value: %0b", det_24_r, setting_init[6-det_7_r][23-det_24_r]);
            end
        end

		S_PROC: begin
            if (det_24_r % 8 == 0 && get_ack_r == 1'b1) begin
                det_24_w = (det_24_r == 6'd24) ? 6'b0 : (det_24_r);
                det_7_w  = (det_24_r == 6'd24) ? (det_7_r+1) : (det_7_r);
                oen_w = 1'b0;
                state_w = S_ACK;
            end
            else begin
                $display("hehe! current bit: %0d, bit value: %0b", det_24_r, setting_init[6-det_7_r][23-det_24_r]);
                get_ack_w = 1'b1;
                oen_w = 1'b1;
                sdat_w = setting_init[6-det_7_r][23-det_24_r];
                det_24_w = det_24_r + 1;
                // det_7_w = det_7_r;
            end
        end
		S_ACK: begin
            state_w = (det_24_w == 6'b0) ? S_STOP : S_PROC;
            sdat_w  = (det_24_w == 6'b0) ? 1'b0   : setting_init[6-det_7_r][23-det_24_r];
            $display("sent from S_ACK! current bit: %0d, bit value: %0b", det_24_r, setting_init[6-det_7_r][23-det_24_r]);
            det_24_w = det_24_r + 1;
            oen_w = 1'b1;
            get_ack_w = 1'b0;
        end

        S_STOP: begin
            $display("24bit");
            // sdat_w = 1'b1;
            // state_w = (det_7_r == 4'd7) ? S_END : S_START;
            if (stop_cnt_r == 1'b0) begin
                sdat_w = 1'b0;
                stop_cnt_w = 1'b1;
                // $display("phase0");
            end
            else begin
                sdat_w = 1'b1;
                stop_cnt_w = 1'b0;
                state_w = (det_7_r == 4'd7) ? S_END : S_START;
                // $display("phase1");
            end
        end
		
		S_END: begin
			finish_w = 1'b1;
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
		finish_r <= 0;
		oen_r <= 1;
        get_ack_r <= 1'b0;
        stop_cnt_r <= 1'b0;
	end else begin
		state_r <= state_w;
		det_24_r <= det_24_w;
		det_7_r <= det_7_w;
		det_2_r <= det_2_w;
		sdat_r <= sdat_w;
		finish_r <= finish_w;
		oen_r <= oen_w;
        get_ack_r <= get_ack_w;
        stop_cnt_r <= stop_cnt_w;
	end
end

endmodule