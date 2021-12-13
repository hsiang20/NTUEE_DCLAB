`timescale 1ns/100ps

module tb;
    localparam audio_dat = 16'b1110101010101011;
    localparam audio_dat2 = 16'b1011101110101001;


    localparam CLK = 10;
    localparam HCLK = CLK/2;

    logic rst, clk, start, pause, stop, fin;

    initial clk = 0;
    always #HCLK clk = ~clk;
    
    logic i_ADCLRCK;
    logic i_ADCDAT;
    logic [19:0] addr;
    logic [15:0] data_record;

    AudRecorder audrecorder_0(
        .i_rst_n(rst), 
        .i_clk(clk),
        .i_lrc(i_ADCLRCK),
        .i_start(start),
        .i_pause(pause),
        .i_stop(stop),
        .i_data(i_ADCDAT),
        .o_address(addr),
        .o_data(data_record)
    );

    initial begin
        $fsdbDumpfile("AudRecorder.fsdb");
		$fsdbDumpvars;
        rst = 1;

        #(2*CLK)
        rst = 0;
        $display("reset~");
        #(2*CLK)

        rst = 1;
        $display("start~");
        start = 1;
        stop = 0;
        i_ADCLRCK = 1'b0;

        #CLK
        start = 0;
        #(5*CLK)
        i_ADCLRCK = 1'b1;
        #(1*CLK)
        for (int i = 0; i < 16; i = i + 1) begin
            i_ADCDAT = audio_dat[i];
            $display("%1d, audio_dat[i] = %1d, i_ADCDAT = %1d", i, audio_dat[i], i_ADCDAT);
        end

        #CLK
        i_ADCDAT = 16'bx;
        #(5*CLK)
        i_ADCLRCK = 1'b0;
        #(20*CLK)

        i_ADCLRCK = 1'b1;
        #CLK
        for (int i = 0; i < 16; i = i + 1) begin
            @(posedge clk)
            i_ADCDAT = audio_dat2[i];
        end
        #CLK
        i_ADCDAT = 16'bx;
        #(5*CLK)
        i_ADCLRCK = 1'b0;
        #(2*CLK)
        
        stop = 1;
        #(CLK)
        i_ADCLRCK = 1'b1;
        #(20*CLK)

        $display("finish");
        $finish;

    end

    initial begin
        #(600000*CLK)
		$display("Too slow, abort.");
		$finish;
    end

endmodule