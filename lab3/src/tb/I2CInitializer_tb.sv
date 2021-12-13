`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic clk, start_I2c, fin, rst_n, sclk, sdat, oen, err;
	initial clk = 0;
	always #HCLK clk = ~clk;
    logic [23: 0] setting_init[6:0] = '{
    24'b00110100_000_1001_0_0000_0001,
    24'b00110100_000_1000_0_0001_1001,
    24'b00110100_000_0111_0_0100_0010,
    24'b00110100_000_0110_0_0000_0000,
    24'b00110100_000_0101_0_0000_0000,
    24'b00110100_000_0100_0_0001_0101,
	24'b00110100_000_1111_0_0000_0000
    };

    I2cInitializer init0(
	.i_rst_n(rst_n),
	.i_clk(clk),
	.i_start(start_I2c),
	.o_finished(fin),
	.o_sclk(sclk),
	.o_sdat(sdat),
	.o_oen(oen) // you are outputing (you are not outputing only when you are "ack"ing.)
    );

	initial begin
		$fsdbDumpfile("I2CInitializer.fsdb");
		$fsdbDumpvars;
		rst_n = 1;
        err = 0;
		#(2*CLK)
		rst_n = 0;
		#(2*CLK)
        
        $display("=========");
        $display("Start Evaluation");
        $display("=========");
        rst_n = 1;
        start_I2c <= 1;
        @(posedge clk)
        start_I2c <= 0;
        // start

        // message sending
        // for (int i = 0; i < 7; i++) begin
        //     for (int j = 0; j < 24; j++)begin
        //         @(posedge sclk);
        //         err = (sdat != setting_init[6-i][23-j]) ? err + 1: err;
        //         if (j % 8 == 7) begin
        //             @(posedge sclk);
        //             err = (sdat != 1'bz) ? err + 1: err;
        //         end 
        //     end
        // end
            
        
        // end
        @(posedge fin)
        $display("=========");
        $display("error count : %10d", err);
        $display("=========");
		
		$finish;
	end

	initial begin
		#(600000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
