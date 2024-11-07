library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    port(
        SW                           : in  std_logic_vector(15 downto 0);
        LED                          : out std_logic_vector(15 downto 0);
        segments                     : out std_logic_vector(7 downto 0);
        displays                     : out std_logic_vector(7 downto 0);
        btnc, btnu, btnl, btnr, btnd : in  std_logic
    );
end top;

architecture Behavioral of top is

    signal btns : std_logic_vector(3 downto 0);

begin

    -- btns <= btnc & btnu & btnl & btnr & btnd;
    btns <= (btnl, btnr, btnu, btnd);

    /*
        TASK 1
        Mux between btns (l,r,u,d) -> LED 0, controlled using SW[1:0]
        use conditional statement or process
    */

    /*
        TASK 2
        Decoders
            A] SW[6:4] selects display; use select statement for  
            B] SW[15:12] controls display value (ie. segments); use case within process        
    */


end Behavioral;
