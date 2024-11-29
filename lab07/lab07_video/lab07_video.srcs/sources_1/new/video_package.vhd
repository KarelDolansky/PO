library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

package video_package is

    type video_timing_t is record
        C_H_ACTIVE    : integer;
        C_H_FPORCH    : integer;
        C_H_SYNC      : integer;
        C_H_BPORCH    : integer;
        C_H_POLARITY  : std_logic;
        C_V_ACTIVE    : integer;
        C_V_FPORCH    : integer;
        C_V_SYNC      : integer;
        C_V_BPORCH    : integer;
        C_V_POLARITY  : std_logic;
        C_REQ_FREQ_HZ : integer;
    end record;

    constant TIMING_test : video_timing_t := (
        C_H_ACTIVE    => 8,
        C_H_FPORCH    => 3,
        C_H_SYNC      => 2,
        C_H_BPORCH    => 3,
        C_H_POLARITY  => '0',
        C_V_ACTIVE    => 8,
        C_V_FPORCH    => 3,
        C_V_SYNC      => 2,
        C_V_BPORCH    => 3,
        C_V_POLARITY  => '1',
        C_REQ_FREQ_HZ => 100_000_000
    );

    constant TIMING_480p : video_timing_t := (
        C_H_ACTIVE    => 640,
        C_H_FPORCH    => 16,
        C_H_SYNC      => 96,
        C_H_BPORCH    => 48,
        C_H_POLARITY  => '0',
        C_V_ACTIVE    => 480,
        C_V_FPORCH    => 10,
        C_V_SYNC      => 2,
        C_V_BPORCH    => 33,
        C_V_POLARITY  => '0',
        C_REQ_FREQ_HZ => 25_175_000
    );

    constant TIMING_600p : video_timing_t := (
        C_H_ACTIVE    => 800,
        C_H_FPORCH    => 40,
        C_H_SYNC      => 128,
        C_H_BPORCH    => 80,
        C_H_POLARITY  => '1',
        C_V_ACTIVE    => 600,
        C_V_FPORCH    => 1,
        C_V_SYNC      => 4,
        C_V_BPORCH    => 23,
        C_V_POLARITY  => '1',
        C_REQ_FREQ_HZ => 40_000_000
    );

    constant TIMING_768p : video_timing_t := (
        C_H_ACTIVE    => 1024,
        C_H_FPORCH    => 24,
        C_H_SYNC      => 136,
        C_H_BPORCH    => 160,
        C_H_POLARITY  => '1',
        C_V_ACTIVE    => 768,
        C_V_FPORCH    => 3,
        C_V_SYNC      => 6,
        C_V_BPORCH    => 29,
        C_V_POLARITY  => '1',
        C_REQ_FREQ_HZ => 65_000_000
    );

    -- for others see http://www.tinyvga.com/vga-timing

    function video_get_hline_length(timing : video_timing_t) return integer;
    function video_get_vline_length(timing : video_timing_t) return integer;
    function video_get_counters_width(timing : video_timing_t) return integer;

end package video_package;

package body video_package is

    function video_get_hline_length(timing : video_timing_t) return integer is
    begin
        return timing.C_H_ACTIVE + timing.C_H_FPORCH + timing.C_H_SYNC + timing.C_H_BPORCH;
    end function;

    function video_get_vline_length(timing : video_timing_t) return integer is
    begin
        return timing.C_V_ACTIVE + timing.C_V_FPORCH + timing.C_V_SYNC + timing.C_V_BPORCH;
    end function;

    function video_get_counters_width(timing : video_timing_t) return integer is
    begin
        return integer(ceil(log2(real(video_get_hline_length(timing)))));
    end function;

end package body video_package;
