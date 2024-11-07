library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity debounce_tb is
end debounce_tb;

architecture Behavioral of debounce_tb is
    constant C_CLK_FREQ_HZ      : integer := 100_000_000;
    constant C_REQ_SCAN_RATE_HZ : integer := 1000000;
    constant C_CLK_PERIOD       : time    := (1000 ms) / C_REQ_SCAN_RATE_HZ;

    signal clk    : std_logic := '0';
    signal rst    : std_logic := '0';
    signal din    : std_logic := '0';

    signal pressed : std_logic;

begin

    clk <= not clk after C_CLK_PERIOD;

    DUT : entity work.debounce
        generic map(
            C_CLK_FREQ_HZ      => C_CLK_FREQ_HZ,
            C_REQ_SCAN_RATE_HZ => C_REQ_SCAN_RATE_HZ
        )
        port map(
            clk     => clk,
            rst     => rst,
            din     => din,
            pressed => pressed
        );

    tb : process
    begin
        rst <= '1';
        wait for C_CLK_PERIOD * 10;
        rst <= '0';

        -- place your test here

        wait;
    end process;

end Behavioral;
