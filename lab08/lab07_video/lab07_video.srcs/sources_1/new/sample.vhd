library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.video_package.all;

entity sample is
    generic(
        C_SAMPLE_WIDTH : integer := 8;
        C_CLK_FREQ     : integer := 100_000_000;
        C_SAMPLE_FREQ  : integer := 8_000;
        C_SAMPLE_PATH  : string  := "c:\work\2024\PO\lab08\python\sound\tick.mem";
        C_NUM_SAMPLES  : integer := 16#4B6#
    );
    port(
        clk    : in  std_logic;
        rst    : in  std_logic;
        play   : in  std_logic;
        sample : out std_logic_vector(C_SAMPLE_WIDTH - 1 downto 0)
    );
end entity sample;

architecture RTL of sample is
    constant C_ADDRESS_WIDTH : integer := log2i(C_NUM_SAMPLES + 1);
    constant C_DATA_WIDTH    : integer := C_SAMPLE_WIDTH;
    constant C_MEM_FILE      : string  := C_SAMPLE_PATH;

    signal sample_cnt : unsigned(C_ADDRESS_WIDTH - 1 downto 0);
    signal rom_data   : std_logic_vector(C_DATA_WIDTH - 1 downto 0);

    type audio_fsm is (SIdle, SPlay);
    signal state : audio_fsm := SIdle;

begin

    process(clk) is
        variable div : unsigned(log2i((C_CLK_FREQ / C_SAMPLE_FREQ) + 1) - 1 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                div        := (others => '0');
                sample_cnt <= (others => '0');
                state      <= SIdle;
            else
                case state is
                    when SIdle =>
                        sample_cnt <= (others => '0');
                        div        := (others => '0');
                        if play then
                            state <= SPlay;
                        end if;
                    when SPlay =>
                        if div < (C_CLK_FREQ / C_SAMPLE_FREQ) then
                            div := div + 1;
                        else
                            div := (others => '0');
                            if sample_cnt < C_NUM_SAMPLES then
                                sample_cnt <= sample_cnt + 1;
                            else
                                state <= SIdle;
                            end if;
                        end if;
                        if play then
                            sample_cnt <= (others => '0');
                            div        := (others => '0');
                            state      <= SPlay;
                        end if;
                end case;
            end if;
        end if;
    end process;

    xmp_rom_wrapper_inst : entity work.xmp_rom_wrapper
        generic map(
            C_ADDRESS_WIDTH => C_ADDRESS_WIDTH,
            C_DATA_WIDTH    => C_DATA_WIDTH,
            C_MEM_FILE      => C_MEM_FILE
        )
        port map(
            clk     => clk,
            rst     => rst,
            address => std_logic_vector(sample_cnt),
            data    => rom_data
        );

    sample <= rom_data when state = SPlay else (others => '0');

end architecture RTL;
