library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;


/*
    Contains timing and color related functions and constants
*/
package video_package_generic is
    generic(
        COLOR_WIDTH     : integer := 4; -- width of color component
        FRAME_CNT_WIDTH : integer := 6  -- bit width of max number of counted frames 
    );

    -- simulation redefinition
    constant CLR_WIDTH : integer := COLOR_WIDTH;
    constant FC_WIDTH  : integer := FRAME_CNT_WIDTH;

    -- integer log2
    function log2i(value : integer) return integer;

    /*
    Holds timing constants
    */
    type video_timing_t is record
        H_ACTIVE    : integer;
        H_FPORCH    : integer;
        H_SYNC      : integer;
        H_BPORCH    : integer;
        H_POLARITY  : std_logic;
        V_ACTIVE    : integer;
        V_FPORCH    : integer;
        V_SYNC      : integer;
        V_BPORCH    : integer;
        V_POLARITY  : std_logic;
        REQ_FREQ_HZ : integer;
    end record;

    -- A few pre-defined timings
    constant TIMING_test : video_timing_t := (
        H_ACTIVE    => 8,
        H_FPORCH    => 3,
        H_SYNC      => 2,
        H_BPORCH    => 3,
        H_POLARITY  => '0',
        V_ACTIVE    => 8,
        V_FPORCH    => 3,
        V_SYNC      => 2,
        V_BPORCH    => 3,
        V_POLARITY  => '1',
        REQ_FREQ_HZ => 100_000_000
    );

    constant TIMING_480p : video_timing_t := (
        H_ACTIVE    => 640,
        H_FPORCH    => 16,
        H_SYNC      => 96,
        H_BPORCH    => 48,
        H_POLARITY  => '0',
        V_ACTIVE    => 480,
        V_FPORCH    => 10,
        V_SYNC      => 2,
        V_BPORCH    => 33,
        V_POLARITY  => '0',
        REQ_FREQ_HZ => 25_175_000
    );

    constant TIMING_600p : video_timing_t := (
        H_ACTIVE    => 800,
        H_FPORCH    => 40,
        H_SYNC      => 128,
        H_BPORCH    => 80,
        H_POLARITY  => '1',
        V_ACTIVE    => 600,
        V_FPORCH    => 1,
        V_SYNC      => 4,
        V_BPORCH    => 23,
        V_POLARITY  => '1',
        REQ_FREQ_HZ => 40_000_000
    );

    constant TIMING_768p : video_timing_t := (
        H_ACTIVE    => 1024,
        H_FPORCH    => 24,
        H_SYNC      => 136,
        H_BPORCH    => 160,
        H_POLARITY  => '1',
        V_ACTIVE    => 768,
        V_FPORCH    => 3,
        V_SYNC      => 6,
        V_BPORCH    => 29,
        V_POLARITY  => '1',
        REQ_FREQ_HZ => 65_000_000
    );

    -- for others see http://www.tinyvga.com/vga-timing

    function video_get_hline_length(timing : video_timing_t) return integer;
    function video_get_vline_length(timing : video_timing_t) return integer;
    function video_get_counters_width(timing : video_timing_t) return integer;

    /*
    color_t packs RGB colors
    */
    type color_t is record
        R : std_logic_vector(CLR_WIDTH - 1 downto 0);
        G : std_logic_vector(CLR_WIDTH - 1 downto 0);
        B : std_logic_vector(CLR_WIDTH - 1 downto 0);
    end record;

    -- converts color<->std_logic_vector
    function color2vec(color : color_t) return std_logic_vector;
    function vec2color(vec : std_logic_vector) return color_t;

    -- color definitions
    constant COLOR_TRANSPARENT : color_t := (R => (others => '1'), G => (others => '0'), B => (others => '1'));
    constant COLOR_BLACK       : color_t := (R => (others => '0'), G => (others => '0'), B => (others => '0'));

    /*
    Holds sprite info
     */
    type sprite_t is record
        ROM_FILE    : string;   -- path to ROM file
        WIDTH       : integer;  -- width of a single sprite frame
        HEIGHT      : integer;  -- height of a single sprite frame
        FRAMES      : integer;  -- number of frames in the sprite (stored vertically)
        TRANSPARENT : color_t;  -- transparent color 
    end record;

    function sprite_get_address_width(sprite : sprite_t) return integer;

end package video_package_generic;

package body video_package_generic is

    function log2i(value : integer) return integer is
    begin
        return integer(ceil(log2(real(value))));
    end function;

    function video_get_hline_length(timing : video_timing_t) return integer is
    begin
        return timing.H_ACTIVE + timing.H_FPORCH + timing.H_SYNC + timing.H_BPORCH;
    end function;

    function video_get_vline_length(timing : video_timing_t) return integer is
    begin
        return timing.V_ACTIVE + timing.V_FPORCH + timing.V_SYNC + timing.V_BPORCH;
    end function;

    function video_get_counters_width(timing : video_timing_t) return integer is
    begin
        return log2i(video_get_hline_length(timing));
    end function;

    function color2vec(color : color_t) return std_logic_vector is
    begin
        return color.R & color.B & color.G;
    end function;

    function vec2color(vec : std_logic_vector) return color_t is
    begin
        return (R => vec(3 * COLOR_WIDTH - 1 downto 2 * COLOR_WIDTH), G => vec(2 * COLOR_WIDTH - 1 downto COLOR_WIDTH), B => vec(COLOR_WIDTH - 1 downto 0));
    end function;

    function sprite_get_address_width(sprite : sprite_t) return integer is
    begin
        return log2i(sprite.FRAMES * sprite.WIDTH * sprite.HEIGHT);
    end function;

end package body video_package_generic;
