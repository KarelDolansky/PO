/*
******************************************************
    ALU package defines OP_type and helper functions
******************************************************
*/
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use ieee.math_real.all;

package ALU_package is
    type OP_type is (
        OP_NONE,                        -- no operation
        OP_ADD,                         -- a + b -> q_l, c < q_h(0)
        OP_SUB,                         -- a - b -> q_l, c < q_h(0)
        OP_NAND,                        -- a nand b -> q_l
        OP_MUL,                         -- a*b -> q_h & q_l
        OP_SHL,                         -- a << b(log2(C_WIDTH)) -> q_h & q_l
        OP_DIV,                         -- a / b -> q_l, a rem b -> q_h
        OP_UNKNOWN
    );

    constant C_OP_WIDTH : integer := integer(ceil(log2(real(OP_type'pos(OP_UNKNOWN)))));

    /*
        OP <-> std_logic_vector
    */
    function to_OP(OP : std_logic_vector) return OP_type;
    function to_std_logic_vector(OP : OP_type) return std_logic_vector;

end package ALU_package;

package body ALU_package is

    function to_OP(OP : std_logic_vector) return OP_type is
    begin
        return OP_type'val(to_integer(unsigned(OP)));
    end function;

    function to_std_logic_vector(OP : OP_type) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(OP_type'pos(OP), C_OP_WIDTH));
    end function;

end package body ALU_package;

/*
******************************************************
ALU circuit
******************************************************
*/

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

use work.ALU_package.all;

entity ALU is
    generic(
        C_WIDTH : integer := 32
    );
    port(
        clk : in  std_logic;
        ce  : in  std_logic;
        rst : in  std_logic;
        op  : in  OP_type;
        a   : in  unsigned(C_WIDTH - 1 downto 0);
        b   : in  unsigned(C_WIDTH - 1 downto 0);
        q_l : out unsigned(C_WIDTH - 1 downto 0);
        q_h : out unsigned(C_WIDTH - 1 downto 0)
    );
end ALU;

architecture RTL of ALU is

begin

    -- create synchronnous process with reset and ce
    -- use case to implement ALU OPs
    -- elaborate after each function to see what time of hardware was inferred
    -- simulate the design in ALU_tb

    process(clk)
        variable result : unsigned(C_WIDTH*2-1 downto 0);
        variable a_tmp : unsigned(C_WIDTH downto 0);
        variable b_tmp : unsigned(C_WIDTH downto 0);
        variable shift : integer := integer(ceil(log2(real(C_WIDTH))));
        
        
        
    begin
        if rising_edge(clk) then
            if rst = '1' then
                q_l <= (others => '0');
                q_h <= (others => '0');
            elsif ce = '1' then
                q_l <= (others => '0');
                q_h <= (others => '0');
                result :=(others => '0');
                case op is
                    -- when OP_NONE =>
                    --     q_l <= (others => '0');
                    --     q_h <= (others => '0');
                    when OP_ADD =>
                        a_tmp  := resize(a,C_WIDTH+1);
                        b_tmp :=resize(b,C_WIDTH+1);
                        result(C_WIDTH downto 0) := a_tmp + b_tmp;
                        q_l <= result(C_WIDTH-1 downto 0);
                        q_h(0) <= result(C_WIDTH);
                    when OP_SUB =>
                        a_tmp  := resize(a,C_WIDTH+1);
                        b_tmp :=resize(b,C_WIDTH+1);
                        result(C_WIDTH downto 0) := a_tmp - b_tmp;
                        q_l <= result(C_WIDTH-1 downto 0);
                        q_h(0) <= result(C_WIDTH);
                    when OP_NAND =>
                        q_l <= a nand b;
                    when OP_MUL =>
                        result := a * b;
                        q_l <= result(C_WIDTH-1 downto 0);
                        q_h <= result(C_WIDTH*2-1 downto C_WIDTH);
                    when OP_SHL =>
                        result(C_WIDTH+to_integer(b(shift downto 0))-1 downto to_integer(b(shift downto 0))) := a;
                        q_l <= result(C_WIDTH-1 downto 0);
                        q_h <= result(C_WIDTH*2-1 downto C_WIDTH);
                    when OP_DIV =>
                        q_l <= a / b;
                        q_h <= a rem b;
                    when others =>
                        q_l <= (others => '0');
                        q_h <= (others => '0');
                end case;
            end if;
        end if;
    end process;

end RTL;
