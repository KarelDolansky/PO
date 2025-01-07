library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.video_package.all;


-- sprite outputs its color depending on the SPRITE dimensions, active position, and sprite position
entity sprite is
    generic(
        C_TIMING : video_timing_t := TIMING_768p;
        C_SPRITE : sprite_t       := (ROM_FILE    => "c:\work\2024\PO\lab08\python\anim.mem",
                                      WIDTH       => 16,
                                      HEIGHT      => 16,
                                      FRAMES      => 4,
                                      TRANSPARENT => COLOR_TRANSPARENT)
    );
    port(
        clk          : in  std_logic;
        rst          : in  std_logic;
        video_pos_x  : in  unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);
        video_pos_y  : in  unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);
        video_frame  : in  unsigned(FRAME_CNT_WIDTH - 1 downto 0);
        active       : in  std_logic;
        sprite_pos_x : in  unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);
        sprite_pos_y : in  unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);
        RGB          : out color_t;
        transparent  : out std_logic
    );
end entity sprite;

architecture RTL of sprite is

    constant C_ADDRESS_WIDTH : integer := sprite_get_address_width(C_SPRITE);
    constant C_DATA_WIDTH    : integer := COLOR_WIDTH * 3;

    signal rom_address : std_logic_vector(C_ADDRESS_WIDTH - 1 downto 0);
    signal rom_data    : std_logic_vector(C_DATA_WIDTH - 1 downto 0);

    signal pos_delta_x, pos_delta_y : unsigned(sprite_pos_x'range);
    signal active_d : std_logic;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            pos_delta_x <= video_pos_x - sprite_pos_x;
            pos_delta_y <= video_pos_y - sprite_pos_y;
            active_d <= active;
        end if;
    end process;
    render : process(clk) is
    begin
        if rising_edge(clk) then
            RGB         <= COLOR_BLACK;
            transparent <= '1';
            if active_d then
                if (video_pos_x >= sprite_pos_x) and (pos_delta_x < C_SPRITE.WIDTH) and (video_pos_y >= sprite_pos_y) and (pos_delta_y < C_SPRITE.HEIGHT) then
                    RGB <= vec2color(rom_data);
                    if vec2color(rom_data) /= C_SPRITE.TRANSPARENT then
                        transparent <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process render;

    raddr : process(all)
        variable f : unsigned(sprite_get_address_width(C_SPRITE) - 1 downto 0);
        variable x : unsigned(sprite_get_address_width(C_SPRITE) - 1 downto 0);
        variable y : unsigned(sprite_get_address_width(C_SPRITE) - 1 downto 0);
    begin
        -- the address should be sthing like (frame offset*width*height) + (line_offset * width) + x pos
        x           := resize(pos_delta_x, x'length);
        y           := resize(shift_left(pos_delta_y, log2i(C_SPRITE.WIDTH)), y'length);
        f           := shift_left(resize(video_frame(video_frame'high downto video_frame'high - log2i(C_SPRITE.FRAMES) + 1), sprite_get_address_width(C_SPRITE)), log2i(C_SPRITE.WIDTH * C_SPRITE.HEIGHT));
        rom_address <= std_logic_vector(f + y + x);
    end process;

    xmp_rom_wrapper_inst : entity work.xmp_rom_wrapper
        generic map(
            C_ADDRESS_WIDTH => sprite_get_address_width(C_SPRITE),
            C_DATA_WIDTH    => C_DATA_WIDTH,
            C_MEM_FILE      => C_SPRITE.ROM_FILE
        )
        port map(
            clk     => clk,
            rst     => rst,
            address => rom_address,
            data    => rom_data
        );

end architecture RTL;
