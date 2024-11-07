library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.all;

entity johnson_generic is
    generic (
        C_WIDTH : integer := 8;
        C_BIN_WIDTH : integer := integer(ceil(log2(real(2*C_WIDTH))))
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        ena : in std_logic;
        q : out std_logic_vector(C_WIDTH - 1 downto 0);
        q_bin : out std_logic_vector(C_BIN_WIDTH - 1 downto 0)
    );
end johnson_generic;

architecture Behavioral of johnson_generic is
    
    type johnson_values_t is array(0 to 2*C_WIDTH) of std_logic_vector(C_WIDTH - 1 downto 0);

    function generate_johnson_decoder(width:integer)
    return johnson_values_t is
        variable table : johnson_values_t:= (others => (others => '0'));
        variable johnson_counter : std_logic_vector(width - 1 downto 0);
    begin
        johnson_counter := (others => '0');
        for i in 0 to 2*width - 1 loop
            table(i) := johnson_counter;
            johnson_counter := NOT(johnson_counter(0)) & johnson_counter(width - 1 downto 1);
        end loop;
        return table;
    end generate_johnson_decoder;

    constant C_JOHNSON_2_BIN_TABLE : johnson_values_t := generate_johnson_decoder(C_WIDTH);

    signal johnson_cnt_reg : std_logic_vector(C_WIDTH - 1 downto 0);
begin
    /*
    Implement generic Johnson couter using process
        shift right on rising edge
        make reset synchronous clearing register to 0s
        Feed negative LSb to MSb
        Homework: How to make universal johnson code to bin code decoder?
    */
    process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                johnson_cnt_reg <= (others => '0');
            else
                if ena = '1' then
                    johnson_cnt_reg <= NOT(q(0)) & johnson_cnt_reg(C_WIDTH - 1  downto 1);
                end if;
            end if;
        end if;
        end process;

    q<=johnson_cnt_reg;

    dec : process(all)
    begin
        q_bin   <= (others => '1');
        for i in 0 to C_WIDTH - 1 loop
            if johnson_cnt_reg = C_JOHNSON_2_BIN_TABLE(i) then
                q_bin <= std_logic_vector(to_unsigned(i, q_bin'length));
            end if;
        end loop;
    end process dec;
       
end Behavioral;
