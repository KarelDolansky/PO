library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.video_package.all;

entity timing_tb is
end entity timing_tb;

architecture RTL of timing_tb is
    constant C_TIMING : video_timing_t := TIMING_test;

    constant CLK_P : time := sec / C_TIMING.C_REQ_FREQ_HZ;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal active     : std_logic;
    signal hsync      : std_logic;
    signal vsync      : std_logic;
    signal pos_x      : unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);
    signal pos_y      : unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);
    signal active_end : std_logic;
    signal frame_end  : std_logic;

begin

    clk <= not clk after CLK_P / 2;

    dut : entity work.video_generator
        generic map(
            C_TIMING => C_TIMING
        )
        port map(
            clk        => clk,
            rst        => rst,
            active     => active,
            hsync      => hsync,
            vsync      => vsync,
            pos_x      => pos_x,
            pos_y      => pos_y,
            active_end => active_end,
            frame_end  => frame_end
        );

    tb : process
    begin
        rst <= '1';
        wait for CLK_P * 10;
        rst <= '0';
        wait;
    end process;

end architecture RTL;
