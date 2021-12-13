`timescale 1ns/100ps

module AudDSP_tb;
    localparam audio_dat0 = 16'b0000000000000000;
    localparam audio_dat1 = 16'b1100000000000011;
    localparam audio_dat2 = 16'b0000000000001100;
    localparam audio_dat3 = 16'b1100000000110000;
    localparam audio_dat4 = 16'b0000000011000000;
    localparam audio_dat5 = 16'b1100001100000000;
    localparam audio_dat6 = 16'b0000110000000000;
    localparam audio_dat7 = 16'b0011000000000000;
    localparam audio_dat8 = 16'b1100000000000000;
    localparam audio_dat9 = 16'b0000000000001111;
    localparam audio_dat10 = 16'b0000000011110000;
    localparam CLK = 10;
    localparam HCLK = CLK/2;

    logic rst, clk, start, pause, stop, fast, slow_0, slow_1, daclrck;
    logic [2:0] speed;
    logic [19:0] addr_out;
    logic [15:0] data_in, data_out;

    initial clk = 0;
    initial daclrck = 0;
    always #HCLK clk = ~clk;

    AudDSP auddsp(
        .i_rst_n(rst), 
        .i_clk(clk),
        .i_start(start),
        .i_pause(pause),
        .i_stop(stop),
        .i_speed(speed), 
        .i_fast(fast), 
        .i_slow_0(slow_0), 
        .i_slow_1(slow_1), 
        .i_daclrck(daclrck), 
        .i_sram_data(data_in), 
        .o_dac_data(data_out), 
        .o_sram_addr(addr_out), 
        .o_audplayer_en(aud_player_en_out)
    );

    assign data_in = (addr_out == 0) ? audio_dat1:
                     (addr_out == 1) ? audio_dat2:
                     (addr_out == 2) ? audio_dat3:
                     (addr_out == 3) ? audio_dat4:
                     (addr_out == 4) ? audio_dat5:
                     (addr_out == 5) ? audio_dat6:
                     (addr_out == 6) ? audio_dat7:
                     (addr_out == 7) ? audio_dat8:
                     (addr_out == 8) ? audio_dat9:
                     (addr_out == 9) ? audio_dat10:
                                       audio_dat0;
 
    initial begin
        $fsdbDumpfile("AudDSP.fsdb");
		$fsdbDumpvars;
        rst = 1;
        start = 0;
        stop = 0;
        pause = 0;
        speed = 0;
        fast = 0;
        slow_0 = 0;
        slow_1 = 0;

        #(2*CLK)
        rst = 0;
        $display("reset~");
        #(2*CLK)
        rst = 1;
        $display("start slow_1");
        start = 1;
        slow_1 = 1;
        speed = 3;
        #(CLK) start = 0;
        #(20*CLK) pause = 1;
        #(CLK) pause = 0;
        #(3*CLK) start = 1;
        #(CLK) start = 0;
        #(20*CLK) stop = 1;
        #(CLK) stop = 0;

        #(2*CLK)
        rst = 0;
        $display("reset~");
        #(2*CLK)
        rst = 1;
        $display("start slow_0");
        start = 1;
        slow_1 = 0;
        slow_0 = 1;
        speed = 4;
        #(CLK) start = 0;
        #(20*CLK) pause = 1;
        #(CLK) pause = 0;
        #(3*CLK) start = 1;
        #(CLK) start = 0;
        #(20*CLK) stop = 1;
        #(CLK) stop = 0;

        #(2*CLK)
        rst = 0;
        $display("reset~");
        #(2*CLK)
        rst = 1;
        $display("start fast");
        start = 1;
        slow_0 = 0;
        fast = 1;
        speed = 2;
        #(CLK) start = 0;
        #(10*CLK) pause = 1;
        #(CLK) pause = 0;
        #(3*CLK) start = 1;
        #(CLK) start = 0;
        #(10*CLK) stop = 1;
        #(CLK) stop = 0;

        #(3*CLK)
        $display("finish");
        $finish;

    end

    always begin
        #(CLK) daclrck = !daclrck;
    end

    initial begin
        #(600000*CLK)
		$display("Too slow, abort.");
		$finish;
    end

endmodule