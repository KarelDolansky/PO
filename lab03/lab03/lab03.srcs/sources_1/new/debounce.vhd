library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity debounce is
    generic(
        C_CLK_FREQ_HZ         : integer := 100_000_000;
        C_REQ_SCAN_RATE_HZ : integer := 100
    );
    port(
        clk         : in  std_logic;
        rst         : in  std_logic;        
        din         : in  std_logic;
        pressed     : out std_logic
    );
end debounce;

architecture Behavioral of debounce is

begin

end Behavioral;
