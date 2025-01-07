library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.video_package.all;

entity video_generator is
    generic(
        C_TIMING : video_timing_t := TIMING_480p
    );
    port(
        clk        : in  std_logic;
        rst        : in  std_logic;
        active     : out std_logic;
        hsync      : out std_logic;
        vsync      : out std_logic;
        pos_x      : out unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);
        pos_y      : out unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);
        frame      : out unsigned(FRAME_CNT_WIDTH - 1 downto 0);
        active_end : out std_logic;
        frame_end  : out std_logic
    );
end entity video_generator;

architecture RTL of video_generator is

    -- declare two counters - horizontal and vertical
    signal hcnt, vcnt : unsigned(pos_x'range);

    signal frame_cnt : unsigned(frame'range);

begin

    -- create process
    -- create nested timers counting up to video_get_hline_length and (nested) video_get_vline_length

    xy : process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                hcnt <= (others => '0');
                vcnt <= (others => '0');
                frame_cnt <= (others => '0');
            else
                if hcnt < video_get_hline_length(C_TIMING) - 1 then
                    hcnt <= hcnt + 1;
                else
                    hcnt <= (others => '0');
                    if vcnt < video_get_vline_length(C_TIMING) - 1 then
                        vcnt <= vcnt + 1;
                    else
                        vcnt <= (others => '0');
                        frame_cnt <= frame_cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process xy;

    frame <= frame_cnt;

    -- create process(es)
    -- create registers on pos_x, pos_y
    -- feed hsync,vsync (watch out for timing.polarity) and active. 
    -- generate single clock pulses @active_end and @frame_end
    name : process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                pos_x      <= (others => '0');
                pos_x      <= (others => '0');
                hsync      <= not C_TIMING.H_POLARITY;
                vsync      <= not C_TIMING.V_POLARITY;
                active     <= '0';
                frame_end  <= '0';
                active_end <= '0';
            else
                pos_x      <= hcnt;
                pos_y      <= vcnt;
                hsync      <= not C_TIMING.H_POLARITY;
                vsync      <= not C_TIMING.V_POLARITY;
                active     <= '0';
                frame_end  <= '0';
                active_end <= '0';
                if hcnt < C_TIMING.H_ACTIVE and vcnt < C_TIMING.V_ACTIVE then
                    active <= '1';
                end if;
                if hcnt = C_TIMING.H_ACTIVE - 1 and vcnt = C_TIMING.V_ACTIVE - 1 then
                    active_end <= '1';
                end if;
                if hcnt = video_get_hline_length(C_TIMING) - 1 and vcnt = video_get_vline_length(C_TIMING) - 1 then
                    frame_end <= '1';
                end if;
                if hcnt >= (C_TIMING.H_ACTIVE + C_TIMING.H_FPORCH) and hcnt < (C_TIMING.H_ACTIVE + C_TIMING.H_FPORCH + C_TIMING.H_SYNC) then
                    hsync <= C_TIMING.H_POLARITY;
                end if;
                if vcnt >= (C_TIMING.V_ACTIVE + C_TIMING.V_FPORCH) and vcnt < (C_TIMING.V_ACTIVE + C_TIMING.V_FPORCH + C_TIMING.V_SYNC) then
                    vsync <= C_TIMING.V_POLARITY;
                end if;
            end if;
        end if;
    end process name;

end architecture RTL;

