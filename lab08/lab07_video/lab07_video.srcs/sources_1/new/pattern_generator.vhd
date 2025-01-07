library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.video_package.all;

entity pattern_generator is
    generic(
        C_TIMING : video_timing_t := TIMING_768p
    );
    port(
        clk            : in  std_logic;
        rst            : in  std_logic;
        active         : in  std_logic;
        hsync          : in  std_logic;
        vsync          : in  std_logic;
        pos_x          : in  unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);
        pos_y          : in  unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);
        active_end     : in  std_logic;
        frame_end      : in  std_logic;
        bckg_color     : in  color_t;
        bckg_sel       : in  std_logic_vector(1 downto 0);
        VGA_RGB        : out color_t;
        VGA_HS, VGA_VS : out std_logic
    );
end entity pattern_generator;

architecture RTL of pattern_generator is
    constant VROM_IMAGE_WIDTH   : integer := 128;
    constant VROM_ADDRESS_WIDTH : integer := integer(ceil(log2(real(VROM_IMAGE_WIDTH ** 2))));
    constant VROM_DATA_WIDTH    : integer := 12;
    constant VROM_MEM_FILE      : string  := "C:\Users\baron\skola\data\5_semestr\PO\lab08\python\video\tile.mem";
    signal vrom_address         : std_logic_vector(VROM_ADDRESS_WIDTH - 1 downto 0);
    signal vrom_data            : std_logic_vector(VROM_DATA_WIDTH - 1 downto 0);

    signal hsync_d : std_logic_vector(1 downto 0);
    signal vsync_d : std_logic_vector(1 downto 0);

    type color_delay_t is array (1 downto 0) of color_t;
    signal VGA_RGB_D : color_delay_t;

begin

    -- using pos_x, pos_y from video_generator create simple patterns feeding VGA_R,G,B. Feed 0,0,0 when not active.
    -- use SW[15:14] to select pattern
    -- 0) full color screen controlled by SW[11:0] (R[11:8],G[7 ...)
    -- 1) 8 Color bars [black, blue, green, cyan, red, magenta, yellow, white]
    -- 2) Checkered flag with pixsize 16px. Color of "white" fields is determined by SW[11:0]

    process(clk)
        variable bars_cnt : unsigned(2 downto 0);
        variable bars_div : unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);

    begin
        if rising_edge(clk) then
            if rst then
                VGA_RGB  <= COLOR_BLACK;
                VGA_HS   <= '0';
                VGA_VS   <= '0';
                bars_cnt := (others => '0');
                bars_div := (others => '0');
            else
                -- delay due to ROM
                hsync_d   <= hsync_d(hsync_d'high - 1 downto 0) & hsync;
                vsync_d   <= vsync_d(vsync_d'high - 1 downto 0) & vsync;
                VGA_RGB_D <= VGA_RGB_D(VGA_RGB_D'high - 1 downto 0) & COLOR_BLACK;
                -- connect H/Vsync and colors
                VGA_HS    <= hsync_d(hsync_d'high);
                VGA_VS    <= vsync_d(vsync_d'high);
                VGA_RGB   <= VGA_RGB_D(VGA_RGB_D'high);
                -- use active output from video_generator
                if active then
                    -- insert pattern generator here
                    case bckg_sel is
                        when "00" =>
                            VGA_RGB_D(0) <= bckg_color;
                        when "01" =>
                            if bars_div < C_TIMING.H_ACTIVE / 8 - 1 then
                                bars_div := bars_div + 1;
                            else
                                bars_div := (others => '0');
                                bars_cnt := bars_cnt + 1;
                            end if;
                            VGA_RGB_D(0) <= (R => (others => bars_cnt(2)), G => (others => bars_cnt(1)), B => ((others => bars_cnt(0))));
                        when "10" =>
                            if pos_x(4) xor pos_y(4) then
                                VGA_RGB_D(0) <= bckg_color;
                            else
                                VGA_RGB_D(0) <= COLOR_BLACK;
                            end if;
                        when others =>
                            VGA_RGB <= vec2color(vrom_data);
                    end case;
                else
                    bars_div := (others => '0');
                    bars_cnt := (others => '0');
                    VGA_RGB  <= COLOR_BLACK;
                end if;
            end if;
        end if;
    end process;

    vrom_address <= std_logic_vector(pos_y(integer(ceil(log2(real(VROM_IMAGE_WIDTH)))) - 1 downto 0) & pos_x(integer(ceil(log2(real(VROM_IMAGE_WIDTH)))) - 1 downto 0));

    bckg : entity work.xmp_rom_wrapper
        generic map(
            C_ADDRESS_WIDTH => VROM_ADDRESS_WIDTH,
            C_DATA_WIDTH    => VROM_DATA_WIDTH,
            C_MEM_FILE      => VROM_MEM_FILE
        )
        port map(
            clk     => clk,
            rst     => rst,
            address => vrom_address,
            data    => vrom_data
        );

end architecture RTL;
