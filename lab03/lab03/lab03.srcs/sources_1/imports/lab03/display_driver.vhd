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
    signal cnt : unsigned(7 downto 0);
    signal done  : std_logic := '0';
begin
    process(clk)
        variable div : integer range 0 to 10_000 := 0;
    begin
        if rising_edge(clk) then
            if rst = '0' then
                div := 0;
                cnt <= (others => '0');
                done <= '0';
            elsif div >= 9_999 then
                div := 0;
                done <= '0';
                cnt <= cnt + 1;
                if cnt >= to_unsigned(7, cnt'length) then
                    cnt <= (others => '0');
                    done <= '1';
                end if;
            end if;
            div := div+1;
        end if;
    end process;

    process(clk)
        variable idk : std_logic_vector(3 downto 0);
    begin
        if rising_edge(clk) then
            if rst then
                segments <= (others => '1');
                displays <= (others => '1');
            else
                idk := din((to_integer(cnt)+1)*4-1 downto to_integer(cnt)*4);
                case cnt is
                    when "000" =>
                    displays <= "11111110"; 
                    when "001" =>
                    displays <= "11111101";
                    when "010" =>
                    displays <= "11111011";
                    when "011" =>
                    displays <= "11110111";
                    when "100" =>
                    displays <= "11101111";
                    when "101" =>
                    displays <= "11011111";
                    when "110" =>
                    displays <= "10111111";
                    when "111" =>
                    displays <= "01111111";
                    when others =>
                        displays <= (others => '1');
                end case;
                case idk is
                    when "0000" => segments <= "00000011"; -- 0
                    when "0001" => segments <= "10011111"; -- 1
                    when "0010" => segments <= "00100101"; -- 2
                    when "0011" => segments <= "00001101"; -- 3
                    when "0100" => segments <= "10011001"; -- 4
                    when "0101" => segments <= "01001001"; -- 5
                    when "0110" => segments <= "01000001"; -- 6
                    when "0111" => segments <= "00011111"; -- 7
                    when "1000" => segments <= "00000001"; -- 8
                    when "1001" => segments <= "00001001"; -- 9
                    when others => segments <= "11111111"; -- default to all segments off
                end case;
            end if;
        end if;
    end process;
end Behavioral;
