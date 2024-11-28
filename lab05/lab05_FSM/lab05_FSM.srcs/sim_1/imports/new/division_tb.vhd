library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider_tb is
end entity divider_tb;

architecture RTL of divider_tb is
    
    type QR_t is record
        Q : unsigned;
        R : unsigned;
    end record QR_t;

    function to_string(QR : QR_t)
        return string is
    begin
        return "(" & to_string(QR.Q) & "," & to_string(QR.R) & ")";
    end function to_string;
    

    function div_lib(nominator : unsigned; denominator : unsigned)
        return QR_t is
        variable QR : QR_t(Q(nominator'range), R(nominator'range));
    begin
        QR.Q := nominator / denominator;
        QR.R := nominator rem denominator;
        return QR;
    end function div_lib;    

    /*
    Restoring high level description for unsigned nom and den
    see https://en.wikipedia.org/wiki/Division_algorithm#Restoring_division
    */
	function div_restoring(nom : unsigned; den : unsigned)
    return QR_t is
        constant C_WIDTH : integer := nom'length;
        variable R, D : unsigned(C_WIDTH*2 downto 0);
        variable Q : unsigned(C_WIDTH - 1 downto 0) := (others => '0');
        variable QR : QR_t(Q(C_WIDTH - 1 downto 0), R(C_WIDTH - 1 downto 0));
    begin
        assert nom'length = den'length report "nom/den width mismatch" severity error;
        R := resize(nom, R'length);
        D := ('0', den, others => '0');
        for i in 0 to nom'length - 1 loop
			R := shift_left(R,1) - D;
            if signed(R) >= 0 then
				Q(Q'high - i) := '1';
            else
				R := R + D;
                Q(Q'high - i) := '0';
            end if;
        end loop;
		QR.Q := Q;
        QR.R := R(R'high-1 downto C_WIDTH);
        return QR;
    end function div_restoring;
	
	
	/*
    Non-Restoring high level description
    see https://en.wikipedia.org/wiki/Division_algorithm#Non-restoring_division
    */
    function div_nonrestoring(nom : unsigned; den : unsigned)
    return QR_t is
        constant C_WIDTH : integer := nom'length;
        variable R, D : unsigned(C_WIDTH*2 downto 0);
        variable Q : unsigned(C_WIDTH - 1 downto 0) := (others => '0');
        variable QR : QR_t(Q(C_WIDTH - 1 downto 0), R(C_WIDTH - 1 downto 0));
    begin
        assert nom'length = den'length report "nom/den width mismatch" severity error;
        R := resize(nom, R'length);
        D := ('0', den, others => '0');
        for i in 0 to nom'length - 1 loop            
            if signed(R) >= 0 then
				R := shift_left(R,1) - D;
				Q(Q'high - i) := '1';
            else
				R := shift_left(R,1) + D;
                Q(Q'high - i) := '0';
            end if;
        end loop;
		Q := Q - not(Q);		        
		if signed(R) < 0 then
			Q := Q - 1;
			R := R + D;
		end if;
		QR.Q := Q(QR.Q'range);
        QR.R := unsigned(R(R'high - 1 downto C_WIDTH));
        return QR;
    end function div_nonrestoring;

    constant C_WIDTH : integer := 8;
    signal N, D : unsigned(C_WIDTH - 1 downto 0);
	signal result_rest, result_lib, result_nonrest : QR_t(Q(C_WIDTH - 1 downto 0), R(C_WIDTH - 1 downto 0));
	
	signal match : std_logic := '0';
begin

    tb : process
    begin
		
		wait for 10 ns;
		
        for nom in 2**C_WIDTH - 1 downto 1 loop
			N <= to_unsigned(nom, N'length);
			for den in 1 to 2**C_WIDTH -  1 loop
				D <= to_unsigned(den, D'length);
				wait for 10 ns;
				result_lib <= div_lib(N, D);
        		result_rest <= div_restoring(N, D);
                result_nonrest <= div_nonrestoring(N, D);
				wait for 10 ns;
                assert result_lib = result_rest and result_lib = result_nonrest report to_string(nom) & "/" & to_string(den) & "/=" & 
                "lib: " & to_string(result_lib) & " != restoring: " & to_string(result_rest) & " != nonrestoring: " & to_string(result_nonrest) severity error;
			end loop;
		end loop;
        assert false report "Simulation Finished" severity failure;
        wait;
    end process;

end architecture RTL;
