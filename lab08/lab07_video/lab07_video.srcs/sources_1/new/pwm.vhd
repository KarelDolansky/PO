library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity pwm is
    generic(
        C_SAMPLE_WIDTH : integer := 8
    );
    port(
        clk       : in  std_logic;
        rst       : in  std_logic;
        pwm_value : in  unsigned(C_SAMPLE_WIDTH - 1 downto 0);
        pwm       : out std_logic
    );
end pwm;

architecture Behavioral of pwm is

    signal cnt : unsigned(pwm_value'range);
begin

pwm_p : process (clk) is
begin
    if rising_edge(clk) then
        if rst then
            cnt <= (others => '0');
            pwm <= '0';
        else
            cnt <= cnt + 1;
            if pwm_value = 0 then
                pwm <= '0';
            else
                if pwm_value <= cnt then
                    pwm <= '1';
                else
                    pwm <= '0';
                end if;
            end if;
        end if;
    end if;
end process pwm_p;

    
end Behavioral;
