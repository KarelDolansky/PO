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
        active_end : out std_logic;
        frame_end  : out std_logic
    );
end entity video_generator;

architecture RTL of video_generator is

    -- declare two counters - horizontal and vertical
    signal c_horizontal : unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);
    signal c_vertical   : unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);
    

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst then
                c_horizontal <= (others => '0');
                c_vertical   <= (others => '0');
                active <= '0';
                active_end <= '0';
                pos_x <= (others => '0');
                pos_y <= (others => '0');
                hsync <= not C_TIMING.C_H_POLARITY;
                vsync <= not C_TIMING.C_V_POLARITY;
                frame_end <= '0';
            else
                active <= '0';
                active_end <= '0';
                pos_x <= c_horizontal;
                pos_y <= c_vertical;
                hsync <= not C_TIMING.C_H_POLARITY;
                vsync <= not C_TIMING.C_V_POLARITY;


                if c_horizontal = C_TIMING.C_H_ACTIVE and c_vertical = C_TIMING.C_V_ACTIVE then
                    active_end <= '1';
                end if;
                if c_horizontal <= C_TIMING.C_H_ACTIVE and c_vertical <= C_TIMING.C_V_ACTIVE then
                    active <= '1';
                end if;

                if c_horizontal > C_TIMING.C_H_ACTIVE + C_TIMING.C_H_FPORCH and c_horizontal < C_TIMING.C_H_ACTIVE+C_TIMING.C_H_FPORCH + C_TIMING.C_H_SYNC then
                    hsync <= C_TIMING.C_H_POLARITY;
                end if;
                if c_vertical >= C_TIMING.C_V_ACTIVE + C_TIMING.C_V_FPORCH and c_vertical < C_TIMING.C_V_ACTIVE+C_TIMING.C_V_FPORCH+C_TIMING.C_V_SYNC then
                    vsync <= C_TIMING.C_V_POLARITY;
                end if;
                
                    
                



                if c_horizontal >= video_get_hline_length(C_TIMING) - 1 then
                    c_horizontal <= (others => '0');
                    if c_vertical = video_get_vline_length(C_TIMING) - 1 then
                        c_vertical <= (others => '0');
                        frame_end <= '1';
                    else
                        c_vertical <= c_vertical + 1;
                    end if;
                else
                    c_horizontal <= c_horizontal + 1;
                end if;
            end if;
        end if;
    end process ;
    
    -- create process
    -- create nested timers counting up to video_get_hline_length and (nested) video_get_vline_length

    -- create process(es)
    -- create registers on pos_x, pos_y
    -- feed hsync,vsync (watch out for timing.polarity) and active. 
    -- generate single clock pulses @active_end and @frame_end

end architecture RTL;

