library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity display_driver is
    port(
        clk      : in  std_logic;
        rst      : in  std_logic;
        din      : in  std_logic_vector(31 downto 0);
        segments : out std_logic_vector(7 downto 0);
        displays : out std_logic_vector(7 downto 0)
    );
end display_driver;

architecture Behavioral of display_driver is

    signal cnt : unsigned(2 downto 0);

begin

    process(clk)
        variable div : integer range 0 to 10000;
    begin
        if rising_edge(clk) then
            if rst then
                div := 0;
                cnt <= (others => '0');
            else
                if div < 9999 then
                    div := div + 1;
                else
                    div := 0;
                    cnt <= cnt + 1;
                end if;
            end if;
        end if;
    end process;

    dec18 : process(clk)
    begin
        if rising_edge(clk) then
            if rst then
                displays <= (others => '1');
            else
                displays                  <= (others => '1');
                displays(to_integer(cnt)) <= '0';
            end if;
        end if;
    end process;

    decSS : process(clk)
        variable val : std_logic_vector(3 downto 0);
        variable segments_n : std_logic_vector(segments'range);
    begin
        if rising_edge(clk) then
            if rst then
                segments_n := (others => '1');
            else
                val := din((4 * (to_integer(cnt) + 1)) - 1 downto (to_integer(cnt) * 4));
                case val is
                    when X"0"   => segments_n := "00111111";
                    when X"1"   => segments_n := "00000110";
                    when X"2"   => segments_n := "01011011";
                    when X"3"   => segments_n := "01001111";
                    when X"4"   => segments_n := "01100110";
                    when X"5"   => segments_n := "01101101";
                    when X"6"   => segments_n := "01111101";
                    when X"7"   => segments_n := "00000111";
                    when X"8"   => segments_n := "01111111";
                    when X"9"   => segments_n := "01100111";
                    when X"A"   => segments_n := "01110111";
                    when X"b"   => segments_n := "01111100";
                    when X"C"   => segments_n := "00111001";
                    when X"d"   => segments_n := "01011110";
                    when X"E"   => segments_n := "01111001";
                    when others => segments_n := "01110001";
                end case;
            end if;
            segments <= not segments_n;
        end if;
    end process;

end Behavioral;
