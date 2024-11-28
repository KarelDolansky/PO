library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity pwm_tb is
end pwm_tb;

architecture Behavioral of pwm_tb is
    constant C_SAMPLE_WIDTH : integer := 8;

    constant CLK_P   : time                               := 10 ns;
    signal clk       : std_logic                          := '0';
    signal rst       : std_logic                          := '0';
    signal pwm_value : unsigned(C_SAMPLE_WIDTH - 1 downto 0) := (others => '0');
    signal pwm       : std_logic;

begin

    clk <= not clk after CLK_P / 2;

    DUT : entity work.pwm
        generic map(
            C_SAMPLE_WIDTH => C_SAMPLE_WIDTH
        )
        port map(
            clk       => clk,
            rst       => rst,
            pwm_value => pwm_value,
            pwm       => pwm
        );

    tb : process is
    begin
        rst <= '1';
        wait for CLK_P * 10;
        rst <= '0';
        pwm_value <= (others => '0');
        wait for (2**C_SAMPLE_WIDTH)*CLK_P*2;
        pwm_value <= (others => '1');
        wait for (2**C_SAMPLE_WIDTH)*CLK_P*2;
        pwm_value <= "00011000";
        wait for (2**C_SAMPLE_WIDTH)*CLK_P*2;
        
        -- test other values
        
      wait;  
    end process tb;
    

end Behavioral;
