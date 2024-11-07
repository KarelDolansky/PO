library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

/*
    Implement generic shift register
        reacts on rising edge
        positive synchronous reset
        shifts left when shift in 1, feeds from sin from left
        loads parallel d when shift in 0
        outputs current state on q
*/

entity shreg_generic is
    generic(
        C_WIDTH : integer := 8
    );
    port(
        clk   : in std_logic;
        shift : in std_logic;
        s   : in std_logic;
        d : in std_logic_vector(C_WIDTH - 1 downto 0);
        q : out std_logic_vector(C_WIDTH - 1 downto 0)
    );
end shreg_generic;

architecture Behavioral of shreg_generic is

        -- no need to create signal when using VHDL 2008
        -- can use q instead
begin

    /*
        Implement shift register
    */
    process(clk)
    begin
        if rising_edge(clk) then
            if shift = '1' then
                q <= s & q(C_WIDTH - 1  downto 1);
            else
                q <= d;
            end if;
        end if;
    end process;



end Behavioral;
