library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity divider_tb is
end entity divider_tb;

architecture RTL of divider_tb is

    -- we will hold both divison products in single "signal"
    type QR_t is record
        Q : unsigned;
        R : unsigned;
    end record QR_t;

    -- utility conversion for the debug
    -- this one converts unsigned to string (as decimal number)
    function to_istring(value : unsigned)
    return string is
        variable retval : string(integer(ceil(log10(real(2**value'length)))) - 1 downto 0);
        variable str_idx : integer := 0;
        variable last_digit, quotient : unsigned(value'length - 1 downto 0);
    begin
        if is_x(std_logic_vector(value)) then
            return "NaN";
        end if;
        if value = 0 then
            return "0";
        end if;
        str_idx := 0;
        quotient := value;
        while quotient /= 0 loop
            last_digit := quotient mod 10;
            quotient := quotient / 10;
            retval(str_idx downto str_idx) := integer'image(to_integer(last_digit(3 downto 0)));
            str_idx := str_idx + 1;
        end loop;
        return retval(str_idx - 1 downto 0);
    end function to_istring;

    -- utility conversion for the debug
    -- prints (QR.Q, QR.R)
    function to_string(QR : QR_t)
    return string is
    begin
        return "(" & to_istring(QR.Q) & "," & to_istring(QR.R) & ")";
    end function to_string;

    -- this one is our golden reference. 
    function div_lib(nominator : unsigned; denominator : unsigned)
    return QR_t is
        variable QR : QR_t(Q(nominator'range), R(nominator'range));
    begin
        QR.Q := nominator / denominator;
        QR.R := nominator rem denominator;
        return QR;
    end function div_lib;

    /*
    Restoring division
    high level description for unsigned nom and den
    see https://en.wikipedia.org/wiki/Division_algorithm#Restoring_division
    */
    function div_restoring(nom : unsigned; den : unsigned)
    return QR_t is
        constant C_WIDTH : integer := nom'length;
        variable QR      : QR_t(Q(C_WIDTH - 1 downto 0), R(C_WIDTH - 1 downto 0));
        variable R : unsigned(den'length*2 downto 0);
        variable D : unsigned(den'length*2-1 downto 0);
        
    begin
        -- test length of both. Support only equal lengths
        assert nom'length = den'length report "nom/den width mismatch" severity error;
        assert den /= 0 report "division by 0" severity error;
        /*
        implement restoring division described in pseudocode.
        R := N
        D := D << n             -- R and D need twice the word width of N and Q. 
                                -- R requires +1 bit on top of that, due to the nature of the unsigned addition in the numeric lib
        for i := n 31 .. 0 do  -- downto
            R := 2 * R - D          -- shift instead of multiplication. Use shift_left(u, N) function, where N is shift count
            if R >= 0 then          -- will be always true with unsigned. Cast to signed (the +1 bit is required here)
                q(i) := 1          
            else
                q(i) := 0           
                R := R + D          -- New partial remainder is (restored) shifted value
            end
        end
        Do not forget to assigne both Q and R. Remainder is in upper half of the R variable
        */

        -- implement here
        R := resize(nom,R'length);
        D := resize(den,D'length);
        for i in C_WIDTH - 1 downto 0 loop
            R := shift_left(R, 2) - resize(D, R'length);
            if signed(QR.R) >= 0 then
                QR.Q(i) := '1';
            else
                QR.Q(i) := '0';
                R := R + D;
            end if;
        end loop;
        QR.R := R(C_WIDTH*2-1 downto C_WIDTH);
        return QR;
    end function div_restoring;

    /*
    Non-Restoring divison
    high level description for unsigned nom and dim
    see https://en.wikipedia.org/wiki/Division_algorithm#Non-restoring_division
    */
    function div_nonrestoring(nom : unsigned; den : unsigned)
    return QR_t is
        constant C_WIDTH : integer := nom'length;
        variable QR      : QR_t(Q(C_WIDTH - 1 downto 0), R(C_WIDTH - 1 downto 0));
    begin
        assert nom'length = den'length report "nom/den width mismatch" severity error;
        assert den /= 0 report "division by 0" severity error;
        /*
        implement non-restoring division described in pseudocode.
            R := N
            D := D << n             -- R and D need twice the word width of N and Q. R requires +1
                for i = n 31 .. 0 do   -- for example 31..0 for 32 bits
                if R >= 0 then          -- remember comparison in previous example
                    q(i) := +1
                    R := 2 * R - D
                else
                    q(i) := -1          -- how to code -1?
                    R := 2 * R + D
                end if
            end
            Q := Q - bit.bnot(Q)    -- we are working in -1, 1 state
            if R < 0 then
                Q := Q - 1
                R := R + D  -- Needed only if the remainder is of interest.
            end if
            Do not forget to assigne both Q and R. Remainder is in upper half of the R variable
        */
        return QR;
    end function div_nonrestoring;

    constant C_WIDTH                                         : integer := 8;
    signal N, D                                              : unsigned(C_WIDTH - 1 downto 0);
    signal result_restoring, result_lib, result_nonrestoring : QR_t(Q(C_WIDTH - 1 downto 0), R(C_WIDTH - 1 downto 0));
begin

    tb : process
    begin
        wait for 10 ns;
        -- insert your tests here

        -- perform whole test after implementation
        for nom in 2 ** C_WIDTH - 1 downto 1 loop
            N <= to_unsigned(nom, N'length);
            for den in 1 to 2 ** C_WIDTH - 1 loop
                D                   <= to_unsigned(den, D'length); 
                wait for 10 ns;
                result_lib          <= div_lib(N, D);
                result_restoring    <= div_restoring(N, D);
                -- result_nonrestoring <= div_nonrestoring(N, D);
                wait for 10 ns;
                assert result_lib = result_restoring /*and result_lib = result_nonrestoring*/ report integer'image(nom) & "/" & integer'image(den) & " != " & "lib: " & to_string(result_lib) & " != restoring: " & to_string(result_restoring) & " != nonrestoring: " & to_string(result_nonrestoring) severity failure;
            end loop;
        end loop;
        assert false report "Simulation Finished OK" severity failure;
        wait;
    end process;

end architecture RTL;
