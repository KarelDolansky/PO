library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm_buttons_tb is
end entity fsm_buttons_tb;

architecture RTL of fsm_buttons_tb is
	constant C_CLK_PERIOD_NS : integer := 10;
	constant C_PUSH_NS : integer := 1_000;
	constant C_REPEAT_NS : integer := 10_000;

	signal clk : std_logic := '0';
	signal rst : std_logic := '0';
	signal d : std_logic := '0';
	signal q : std_logic;
    
begin

    clk <= not clk after 1 ns * C_CLK_PERIOD_NS/2;

    dut : entity work.fsm_button
        generic map(
            C_CLK_PERIOD_NS => C_CLK_PERIOD_NS,
            C_PUSH_NS       => C_PUSH_NS,
            C_REPEAT_NS     => C_REPEAT_NS
        )
        port map(
            clk => clk,
            rst => rst,
            d   => d,
            q   => q
        );
    
    tb: process
    begin
        d <= '0';
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;
        d <= '1';
        wait for 990 ns;
        d <= '0';
        wait for 100 ns;
        d <= '1';
        wait for 1010 ns;
        d <= '0';
        d <= '1';
        wait;
    end process;



end architecture RTL;
