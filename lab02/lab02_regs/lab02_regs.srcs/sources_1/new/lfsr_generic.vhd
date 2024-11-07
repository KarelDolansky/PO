library ieee;
use ieee.std_logic_1164.all;

entity lfsr_generic is
    generic(
        C_WIDTH : integer := 1
    );
    port(
        clk : in  std_logic;
        rst : in  std_logic;
        ena : in  std_logic;
        q   : out std_logic_vector(C_WIDTH - 1 downto 0)
    );
end entity lfsr_generic;

/*
    Create generic LFSR   
        see https://docs.amd.com/v/u/en-US/xapp052 for details
        register shifts right        
        Q1 is the leftmost, QN is the rightmost
        use C_FLOOPS constant array bellow to create feedback
            value > 0 indicates feedback from Q(value) passing trough xnor gate
            feedback is always connected to D(1)
            
                for example on LFSR of length 3:
                D(1) = C_FLOOPS(3, 2) xnor (C_FLOOPS(3, 3)) == D(1) <= Q(3) xnor Q(2);
            -1 means do not create feedback
            
        use one process
        use variables to create feedback
        use for loop to create cascaded xnor gate
        
*/

architecture RTL of lfsr_generic is

    type feedback_loops_t is array (3 to 32, 0 to 3) of integer;
    constant C_FLOOPS : feedback_loops_t := (
        (-1, -1, 3, 2),                 --3
        (-1, -1, 4, 3),                 --4
        (-1, -1, 5, 3),                 --5
        (-1, -1, 6, 5),                 --6
        (-1, -1, 7, 6),                 --7
        (8, 6, 5, 4),                   --8
        (-1, -1, 9, 5),                 --9
        (-1, -1, 10, 7),                --10
        (-1, -1, 11, 9),                --11
        (12, 6, 4, 1),                  --12
        (14, 4, 3, 1),                  --13
        (14, 5, 3, 1),                  --14
        (-1, -1, 15, 14),               --15
        (16, 15, 13, 4),                --16
        (-1, -1, 17, 14),               --17
        (-1, -1, 18, 11),               --18
        (19, 6, 2, 1),                  --19
        (-1, -1, 20, 17),               --20
        (-1, -1, 21, 19),               --21
        (-1, -1, 22, 21),               --22
        (-1, -1, 23, 18),               --23
        (24, 23, 22, 17),               --24
        (-1, -1, 25, 22),               --25
        (26, 6, 2, 1),                  --26
        (27, 5, 2, 1),                  --27
        (-1, -1, 28, 25),               --28
        (-1, -1, 29, 27),               --29
        (30, 6, 4, 1),                  --30
        (-1, -1, 31, 28),               --31
        (32, 22, 2, 1)                  --32
    );

    signal lfsr : std_logic_vector(1 to C_WIDTH);

begin
    

    process(clk)
        variable feedback : std_logic := '0';        
    begin
        if rising_edge(clk) then
            if rst = '1' then
                lfsr <= (others => '1');
            else
                if ena = '1' then
                    feedback := '0';
                    for i in 0 to 3 loop
                        if C_FLOOPS(C_WIDTH, i) > 0 then
                            feedback := feedback xnor lfsr(C_FLOOPS(C_WIDTH, i));
                        end if;
                    end loop;
                    lfsr <= feedback & lfsr(1 to C_WIDTH - 1);
                end if;
            end if;
        end if;
    end process;
    q<=lfsr;



        

end architecture RTL;

