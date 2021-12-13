	component daodao is
		port (
			reset_reset_n   : in  std_logic := 'X'; -- reset_n
			altpll_100k_clk : out std_logic;        -- clk
			altpll_12m_clk  : out std_logic;        -- clk
			clk_clk         : in  std_logic := 'X'  -- clk
		);
	end component daodao;

	u0 : component daodao
		port map (
			reset_reset_n   => CONNECTED_TO_reset_reset_n,   --       reset.reset_n
			altpll_100k_clk => CONNECTED_TO_altpll_100k_clk, -- altpll_100k.clk
			altpll_12m_clk  => CONNECTED_TO_altpll_12m_clk,  --  altpll_12m.clk
			clk_clk         => CONNECTED_TO_clk_clk          --         clk.clk
		);

