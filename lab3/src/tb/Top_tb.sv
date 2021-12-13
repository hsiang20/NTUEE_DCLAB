`timescale 1ns/10ps


module tb;
    localparam CLK = 10;
    localparam HCLK = CLK/2;
    logic clk;
    initial clk = 0;
    always #HCLK clk = ~clk;

    Top top0(
        .i_rst_n(KEY[3]),
        .i_clk(CLK_12M),
        .i_key_0(key0down),
        .i_key_1(key1down),
        .i_key_2(key2down),
        // .i_speed(SW[3:0]), // design how user can decide mode on your own
        .i_speed(1'b0),
        .i_fast(1'b0),
        .i_slow_0(1'b0),
        .i_slow_1(1'b0),
        
        // AudDSP and SRAM
        .o_SRAM_ADDR(SRAM_ADDR), // [19:0]
        .io_SRAM_DQ(SRAM_DQ), // [15:0]
        .o_SRAM_WE_N(SRAM_WE_N),
        .o_SRAM_CE_N(SRAM_CE_N),
        .o_SRAM_OE_N(SRAM_OE_N),
        .o_SRAM_LB_N(SRAM_LB_N),
        .o_SRAM_UB_N(SRAM_UB_N),
        
        // I2C
        .i_clk_100k(CLK_100K),
        .o_I2C_SCLK(I2C_SCLK),
        .io_I2C_SDAT(I2C_SDAT),
        
        // AudPlayer
        .i_AUD_ADCDAT(AUD_ADCDAT),
        .i_AUD_ADCLRCK(AUD_ADCLRCK),
        .i_AUD_BCLK(AUD_BCLK),
        .i_AUD_DACLRCK(AUD_DACLRCK),
        .o_AUD_DACDAT(AUD_DACDAT)

        // SEVENDECODER (optional display)
        // .o_record_time(recd_time),
        // .o_play_time(play_time),

        // LCD (optional display)
        // .i_clk_800k(CLK_800K),
        // .o_LCD_DATA(LCD_DATA), // [7:0]
        // .o_LCD_EN(LCD_EN),
        // .o_LCD_RS(LCD_RS),
        // .o_LCD_RW(LCD_RW),
        // .o_LCD_ON(LCD_ON),
        // .o_LCD_BLON(LCD_BLON),

        // LED
        // .o_ledg(LEDG), // [8:0]
        // .o_ledr(LEDR) // [17:0]
    );