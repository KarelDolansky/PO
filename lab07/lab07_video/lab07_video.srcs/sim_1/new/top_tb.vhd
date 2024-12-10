library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.video_package.all;

entity top_tb is
end entity top_tb;

architecture RTL of top_tb is
    constant C_TIMING : video_timing_t := TIMING_test;

    constant CLK_P : time := sec / C_TIMING.C_REQ_FREQ_HZ;

    signal clk : std_logic := '0';
    signal SW : std_logic_vector(15 downto 0);
    signal VGA_R : std_logic_vector(3 downto 0);
    signal VGA_G : std_logic_vector(3 downto 0);
    signal VGA_B : std_logic_vector(3 downto 0);
    signal VGA_HS : std_logic;
    signal VGA_VS : std_logic;


begin

    clk <= not clk after CLK_P / 2;

    dut : entity work.top
        port map(
            clk      => clk,
            rstn     => '1',
            SW       => SW,
            LED      => open,
            segments => open,
            displays => open,
            LED_RGB  => open,
            btnc     => '0',
            btnu     => '0',
            btnl     => '0',
            btnr     => '0',
            btnd     => '0',
            VGA_R    => VGA_R,
            VGA_G    => VGA_G,
            VGA_B    => VGA_B,
            VGA_HS   => VGA_HS,
            VGA_VS   => VGA_VS
        );

        
    tb : process
    begin
        SW(13 downto 0) <= "11111111111111";
        wait for CLK_P * 1000;
        SW(15 downto 14) <= "00";
        wait for CLK_P * 1000;
        SW(15 downto 14) <= "01";
        wait for CLK_P * 1000;
        SW(15 downto 14) <= "10";
        -- wait for CLK_P * 1000;
        -- SW(15 downto 14) <= "11";
    end process;

end architecture RTL;
