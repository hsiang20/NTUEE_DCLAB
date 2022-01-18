module I2C (
    input	i_rst_n,
    input	i_clk,      
    input	i_start,            // control if start
    input   [6:0] i_addr,       // chip address (7 bit)
    input   i_rw,               // chip R/W (1'b0 | 1'b1)
    input   [15:0] i_reg_data,  // chip reg and data (7 + 9 bit)

    output	o_finished,
    output	o_sclk,     // s clock for i2c
    inout	o_sdat,     // data in / out
    output	o_oen       // you are outputing (you are not outputing only when you are "ack"ing.)
);

localparam S_IDLE     = 0;
localparam S_START    = 1;       // a start state for simple delay
localparam S_ADDR     = 2;       // sending slave addr
localparam S_RW       = 3;       // sending R/W
localparam S_REG_DATA_UPPER = 4; // sending register and data bits
localparam S_REG_DATA_LOWER = 5; // sending register and data bits
localparam S_ACK      = 6;       // ack state
localparam S_STOP     = 7;       // stop state

logic [2:0] state_r, state_w;
logic [2:0] prev_state_r, prev_state_w; // previous state for S_ACK to determine where to go next
logic sdat; // data on i2c
logic oen_r, oen_w; // open enable
logic [3:0] counter_r, counter_w; // counter, every 8 bits will jump to ack state and back
logic fin_r, fin_w; // finish

assign o_sclk = (state_r == S_IDLE || state_r == S_START || state_r == S_STOP) ? 1'b1 : ~i_clk; // if not idle, it's the clock, otherwise, should be 1
assign o_oen = oen_r;
assign o_sdat = oen_r ? sdat : 1'bz;
assign o_finished = fin_r;

always_comb begin
    state_w = state_r;
    prev_state_w = prev_state_r;
    oen_w = oen_r;
    counter_w = counter_r;
    fin_w = fin_r;
    sdat = 1'b1;
    case (state_r)
        // idle, not sending or reading from i2c
        S_IDLE: begin
            fin_w = 1'b0;
            sdat = 1'b1;
            if (i_start) begin // pull down o_sdat, pull up oen_r
                state_w = S_START;
                oen_w = 1'b1;
                counter_w = 4'b0;
            end
        end

        S_START: begin
            state_w = S_ADDR;
            sdat = 1'b0;
        end

        // sending address (only 7 bit)
        S_ADDR: begin
            sdat = i_addr[4'd6 - counter_r];
            counter_w = counter_r + 4'b1;
            if (counter_r == 6) state_w = S_RW;
        end

        // sending R/W (only 1 bit) to i2c, will jump to ack
        S_RW: begin
            sdat = i_rw;
            if (counter_r == 7) begin // will always be 7 in this case (S_ADDR send 7 bits)
                state_w = S_ACK;
                prev_state_w = S_RW;
                oen_w = 1'b0; // for ack, output enable is false
            end
        end

        // sending REG and DATA's upper 8 bit
        S_REG_DATA_UPPER: begin
            sdat = i_reg_data[4'd15 - counter_r];
            counter_w = counter_r + 4'b1;
            if (counter_r == 7) begin // go to ack
                state_w = S_ACK;
                prev_state_w = S_REG_DATA_UPPER;
                oen_w = 1'b0;
            end
        end

        // sending REG and DATA's lower 8 bit
        S_REG_DATA_LOWER: begin
            sdat = i_reg_data[4'd7 - counter_r];
            counter_w = counter_r + 4'b1;
            if (counter_r == 7) begin
                state_w = S_ACK;
                prev_state_w = S_REG_DATA_LOWER;
                oen_w = 1'b0;
            end
        end

        // stop, pull sdat from 0 to 1, indicate stop                              
        S_STOP: begin
            sdat = 1'b0; // to stop, make sdat 0 first, will be pulled up by S_STOP
            state_w = S_IDLE;
            fin_w = 1'b1;
        end

        S_ACK: begin
            // TODO: check ACK

            counter_w = 4'b0;
            if (prev_state_r == S_RW) begin
                state_w = S_REG_DATA_UPPER;
                oen_w = 1'b1; // go back to output 
            end
            else if (prev_state_r == S_REG_DATA_UPPER) begin
                state_w = S_REG_DATA_LOWER;
                oen_w = 1'b1;
            end
            else if (prev_state_r == S_REG_DATA_LOWER) begin
                // TODO: Stop, return to IDLE
                state_w = S_STOP;
                oen_w = 1'b1;
            end
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_IDLE;
        prev_state_r <= S_IDLE;
        oen_r <= 1'b1;
        counter_r <= 4'b0;
        fin_r <= 1'b0;
    end
   
    else begin
        state_r <= state_w;
        prev_state_r <= prev_state_w;
        oen_r <= oen_w;
        counter_r <= counter_w;
        fin_r <= fin_w;
    end
end

endmodule

module I2CInitializer(
input	i_rst_n,
input	i_clk,
input 	i_start,
output	o_finished,
output	o_sclk,
output	o_sdat,
output	o_oen  // you are outputing (you are not outputing only when you are "ack"ing.)

//output [1:0] o_state
);

// state
localparam S_IDLE 	 = 0; // idle, initial state
localparam S_START 	 = 1; // start setting
localparam S_SETTING = 2; // setting state, which will send data through i2c to wm8731
localparam S_FINISH  = 3; // finish setup
// address and rw
localparam Address = 7'b0011010; // wm8731 address
localparam RW = 1'b0; // i2c writing (0)
// reg and data
// below four use default instead
// localparam Left_Line_In 				  = 16'b0000000010010111;
// localparam Right_Line_In 				  = 16'b0000001010010111;
// localparam Left_Headphone_Out             = 16'b0000010001111001;
// localparam Right_Headphone_Out            = 16'b0000011001111001;
localparam Reset 						  = 16'b0001111000000000;
localparam Analogue_Audio_Path_Control 	  = 16'b0000100000010101;
localparam Digital_Audio_Path_Control 	  = 16'b0000101000000000;
localparam Power_Down_Control 			  = 16'b0000110000000000;
localparam Digital_Audio_Interface_Format = 16'b0000111001000010;
localparam Sampling_Control 			  = 16'b0001000000011001;
localparam Active_Control 				  = 16'b0001001000000001;

logic [1:0] state_r, state_w; // state
logic [15:0] reg_data_r, reg_data_w; // reg and data
logic [2:0] counter_r, counter_w; // counter from 0 to 6, which is to send reg and data
logic start_r, start_w; // tell i2c module to start
logic fin_r, fin_w;     // tell upper this initialize finished

logic [6:0] addr = Address; // chip Address
logic rw = RW; // chip RW
logic i2c_fin; // get i2c finish or not

assign o_finished = fin_r;

assign o_state = state_r;

I2C i2c(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk),
	.i_start(start_r),
	.i_addr(addr),
	.i_rw(rw),
	.i_reg_data(reg_data_r),

	.o_finished(i2c_fin),
	.o_sclk(o_sclk),
	.o_sdat(o_sdat),
	.o_oen(o_oen)
);

always_comb begin
	state_w = state_r;
	reg_data_w = reg_data_r;
	counter_w = counter_r;
	start_w = start_r;
	fin_w = fin_r;
	case (state_r)

		S_IDLE: begin
			start_w = 1'b0;
			fin_w = 1'b0;
			counter_w = 3'b0;
			if (i_start) begin
				state_w = S_START;
			end
		end

		S_START: begin
			if (counter_r <= 6) begin
				start_w = 1'b1;
				state_w = S_SETTING;
				case (counter_r)
					0: begin reg_data_w = Reset; end
					// below four use default instead
					// 1: begin reg_data_w = Left_Line_In; end
					// 2: begin reg_data_w = Right_Line_In; end
					// 3: begin reg_data_w = Left_Headphone_Out; end
					// 4: begin reg_data_w = Right_Headphone_Out; end  
					1: begin reg_data_w = Analogue_Audio_Path_Control; end
					2: begin reg_data_w = Digital_Audio_Path_Control; end
					3: begin reg_data_w = Power_Down_Control; end
					4: begin reg_data_w = Digital_Audio_Interface_Format; end
					5: begin reg_data_w = Sampling_Control; end
					6: begin reg_data_w = Active_Control; end
					default: begin
						reg_data_w = Reset;
					end
				endcase
			end
			else begin
				state_w = S_FINISH;
			end
		end

		S_SETTING: begin
			start_w = 1'b0; // pull down start for i2c module to work correctly
			if (i2c_fin) begin // i2c will pull this up when finished, then pull this down
				state_w = S_START;
				counter_w = counter_r + 3'b1;
			end
		end
		
		S_FINISH: begin
			fin_w = 1'b1;
			// state_w = S_IDLE; maybe don't need to jump back to idle
		end
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	// design your control here
    if (!i_rst_n) begin
		state_r <= S_IDLE;
		reg_data_r <= 16'b0;
		counter_r <= 3'b0;
		start_r <= 1'b0;
		fin_r <= 1'b0;
	end
	else begin
		state_r <= state_w;
		reg_data_r <= reg_data_w;
		counter_r <= counter_w;
		start_r <= start_w;
		fin_r <= fin_w;
	end
end
endmodule