`timescale 1ns/100ps
module tb;
    localparam CLK = 10;
    localparam HCLK = CLK/2;
    logic clk, rst, start;
    logic [7:0] r, g, b;
    logic o_clk, o_blank_n, o_hs, o_vs, o_sync_n;
    logic [7:0] v_r, v_g, v_b;
    logic v_clk, v_blank_n, v_hs, v_vs, v_sync_n;
    logic state_1, state_2;

    initial clk=0;
    always #HCLK clk = ~clk;

    Top top0(
        .i_clk(clk), 
        .i_rst_n(rst), 
        .i_clk_25(clk), 
        .i_start(start), 
        .VGA_R(r), 
        .VGA_G(g), 
        .VGA_B(b), 
        .VGA_CLK(o_clk), 
        .VGA_BLANK_N(o_blank_n), 
        .VGA_HS(o_hs), 
        .VGA_VS(o_vs), 
        .VGA_SYNC_N(o_sync_n), 
        .state(state_1)
    );

    vga vga0(
        .i_rst_n(rst), 
        .i_clk_25M(clk), 
        .i_start_display(start), 
        .VGA_R(v_r), 
        .VGA_G(v_g), 
        .VGA_B(v_b), 
        .VGA_CLK(v_clk), 
        .VGA_BLANK_N(v_blank_n), 
        .VGA_HS(v_hs), 
        .VGA_VS(v_vs), 
        .VGA_SYNC_N(v_sync_n)
    );

    initial begin
		$fsdbDumpfile("sprite1.fsdb");
		$fsdbDumpvars;
        rst = 1;
        #(2*CLK)
        rst = 0;
        #CLK
        rst = 1;
        start = 1;
        #CLK
        #(2000000*CLK)
        $finish;
    end

endmodule
