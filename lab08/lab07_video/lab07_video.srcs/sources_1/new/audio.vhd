library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.video_package.all;

entity audio is
    generic(
        C_SAMPLE_WIDTH : integer := 8;
        C_CLK_FREQ     : integer := 100_000_000;
        C_SAMPLE_FREQ  : integer := 8000
    );
    port(
        clk       : in  std_logic;
        rst       : in  std_logic;
        play_hit  : in  std_logic;
        play_tick : in  std_logic;
        play_tock : in  std_logic;
        PWM       : out std_logic
    );
end entity audio;

architecture RTL of audio is

    signal sample_tick : std_logic_vector(C_SAMPLE_WIDTH - 1 downto 0);
    signal sample_hit  : std_logic_vector(C_SAMPLE_WIDTH - 1 downto 0);
    signal pwm_value   : unsigned(C_SAMPLE_WIDTH - 1 downto 0);
    signal sample_tock : std_logic_vector(C_SAMPLE_WIDTH - 1 downto 0);

begin

    hit_p : entity work.sample
        generic map(
            C_SAMPLE_WIDTH => C_SAMPLE_WIDTH,
            C_CLK_FREQ     => C_CLK_FREQ,
            C_SAMPLE_FREQ  => C_SAMPLE_FREQ,
            C_SAMPLE_PATH  => "c:\work\2024\PO\lab08\python\sound\hit.mem",
            C_NUM_SAMPLES  => 16#17EF#
        )
        port map(
            clk    => clk,
            rst    => rst,
            play   => play_hit,
            sample => sample_hit
        );

    tick_p : entity work.sample
        generic map(
            C_SAMPLE_WIDTH => C_SAMPLE_WIDTH,
            C_CLK_FREQ     => C_CLK_FREQ,
            C_SAMPLE_FREQ  => C_SAMPLE_FREQ,
            C_SAMPLE_PATH  => "c:\work\2024\PO\lab08\python\sound\tick.mem",
            C_NUM_SAMPLES  => 16#4B7#
        )
        port map(
            clk    => clk,
            rst    => rst,
            play   => play_tick,
            sample => sample_tick
        );

    tock_p : entity work.sample
        generic map(
            C_SAMPLE_WIDTH => C_SAMPLE_WIDTH,
            C_CLK_FREQ     => C_CLK_FREQ,
            C_SAMPLE_FREQ  => C_SAMPLE_FREQ,
            C_SAMPLE_PATH  => "c:\work\2024\PO\lab08\python\sound\tock.mem",
            C_NUM_SAMPLES  => 16#659#
        )
        port map(
            clk    => clk,
            rst    => rst,
            play   => play_tock,
            sample => sample_tock
        );

    -- this 
    process(clk) is
    begin
        if rising_edge(clk) then            
            pwm_value <= unsigned(sample_hit or sample_tick or sample_tock);
        end if;
    end process;

    pwm_inst : entity work.pwm
        generic map(
            C_SAMPLE_WIDTH => C_SAMPLE_WIDTH
        )
        port map(
            clk       => clk,
            rst       => rst,
            pwm_value => pwm_value,
            pwm       => pwm
        );

end architecture RTL;
