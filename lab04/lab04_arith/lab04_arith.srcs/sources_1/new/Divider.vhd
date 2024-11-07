library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider is
    generic(
        C_WIDTH : integer := 8
    );
    port(
        clk       : in  std_logic;
        rst       : in  std_logic;
        run       : in  std_logic;
        done      : out std_logic;
        busy      : out std_logic;
        err       : out std_logic;
        den       : in  unsigned(C_WIDTH - 1 downto 0);
        nom       : in  unsigned(C_WIDTH - 1 downto 0);
        divison   : out unsigned(C_WIDTH - 1 downto 0);
        remainder : out unsigned(C_WIDTH - 1 downto 0)
    );
end entity divider;

architecture RTL of divider is

begin

end architecture RTL;
