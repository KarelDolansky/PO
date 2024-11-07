library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.all;

entity top is
    port(
        rstn                         : in    std_logic;
        SW                           : in    std_logic_vector(15 downto 0);
        LED                          : out   std_logic_vector(15 downto 0);
        segments                     : out   std_logic_vector(7 downto 0);
        displays                     : out   std_logic_vector(7 downto 0);
        btnc, btnu, btnl, btnr, btnd : in    std_logic;
        PMOD_JA                      : inout std_logic_vector(7 downto 0);
        PMOD_JB                      : inout std_logic_vector(7 downto 0)
    );
end top;

/*
    Clock capable pins:
    btnc, PMOD_JB(7)
*/

architecture Behavioral of top is

    signal clk : std_logic;

begin

    -- sh_insgen: entity work.shreg_generic
    --     generic map(
    --         C_WIDTH => 16
    --     )
    --     port map(
    --         clk   => clk,
    --         shift => PMOD_JB(5),
    --         s     => PMOD_JB(4),
    --         d     => SW,
    --         q     => LED
    --     );

    --     clk <= PMOD_JB(7);
    --     PMOD_JB(1 downto 0)<=btnl & btnl;
    --     PMOD_JB(3 downto 2)<=btnr & btnr;
    --     PMOD_JB(6)<=LED(0);


    /*Proveďte instanci čtyř čtyřbitových čítačů:
    a. Využijte příkaz generate se schématem for
    b. Pro vstup rst platí stejné pravidlo jako v předchozí úloze.
    c. Na vstup clk přiveďte signál z tlačítka btnl
    d. Výstupy q napojte na vhodné LED, využijte řídící proměnnou cyklu
    e. Výstup q_bin nezapojujte.
    f. Vstup ena připojte na log. 1*/
    
        gen: for i in 0 to 3 generate
            johnson: entity work.johnson_generic
                generic map(
                    C_WIDTH    => 4,
                    C_BIN_WIDTH => 4
                )
                port map(
                    clk     => btnl,
                    rst     => not(rstn),
                    ena     => '1',
                    q       => open,
                    q_bin   => LED(4*(i+1)-1 downto 4*i)
                );
        end generate gen;

    /*V souboru top.vhd zakomentujte instanci johnsonova čítače a vložte instanci LFSR o délce
    16 bit.
    7. Vhodně ji zapojte. Zdroj hodin volte btnl, nezapomeňte ošetřit všechny vstupy */

    -- lfsr: entity work.lfsr_generic
    --     generic map(
    --         C_WIDTH => 16
    --     )
    --     port map(
    --         clk=>btnl,
    --         rst=>rstn,
    --         ena=>'1',
    --         q=>LED
    --     );
        

end Behavioral;
