library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.ALU_package.all;

entity ALU_tb is
end ALU_tb;

architecture Behavioral of ALU_tb is
    constant C_WIDTH : integer := 8;

    constant CLK_P : time := 10 ns;

    signal clk : std_logic := '0';
    signal ce  : std_logic := '0';
    signal rst : std_logic := '0';
    signal op  : OP_type   := OP_NONE;

    signal a : unsigned(C_WIDTH - 1 downto 0) := (others => '0');
    signal b : unsigned(C_WIDTH - 1 downto 0) := (others => '0');

    signal q_l : unsigned(C_WIDTH - 1 downto 0);
    signal q_h : unsigned(C_WIDTH - 1 downto 0);

begin

    clk <= not clk after CLK_P / 2;

    dut : entity work.ALU
        generic map(
            C_WIDTH => C_WIDTH
        )
        port map(
            clk => clk,
            ce  => ce,
            rst => rst,
            op  => op,
            a   => a,
            b   => b,
            q_l => q_l,
            q_h => q_h
        );

    tb : process
        variable operation : OP_type;
    begin
        for a_i in 0 to 2 ** C_WIDTH - 1 loop
            for b_i in 0 to 2 ** C_WIDTH - 1 loop
                for o in OP_type'left to OP_type'right loop
                    operation := o;
                    -- assign a from a_i, b from b_i, control ce, rst, etc

                    wait for CLK_P;

                    -- observe q_l and q_h and compare with expected results
                    case operation is
                        when OP_NONE =>
                            null;
                        when OP_ADD =>
                            if q_l /= a_i + b_i then
                                report integer'image(a_i) & "+" & integer'image(b_i) & "!=" & integer'image(to_integer(unsigned(q_l)));
                            end if;
                        when OP_SUB =>
                            null;
                        when OP_NAND =>
                            null;
                        when OP_MUL =>
                            null;
                        when OP_SHL =>
                            null;
                        when OP_DIV =>
                            null;
                        when OP_UNKNOWN =>
                            null;
                    end case;
                end loop;
            end loop;
        end loop;
        wait;
    end process;

end Behavioral;
