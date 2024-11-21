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
        quotient  : out unsigned(C_WIDTH - 1 downto 0);
        remainder : out unsigned(C_WIDTH - 1 downto 0)
    );
end entity divider;

architecture RTL of divider is
    type fsm_t is (start,count,stop);
    signal state : fsm_t := start;
    signal R_out,D_out : unsigned(C_WIDTH*2 downto 0);
    signal Q_out : unsigned(C_WIDTH-1 downto 0);
    signal index : integer :=0;
begin
    process(clk)
        variable R : unsigned(C_WIDTH*2 downto 0);
    begin
        if rising_edge(clk) then
            if rst then
                state <= start;
                done <= '0';
                err <= '0';
                quotient <= (others => '0');
                remainder <= (others => '0');
                busy <= '0';
                index <= 0;
                Q_out <= (others => '0');
                R_out <= (others => '0');
                D_out <= (others => '0');
            elsif run then
                case state is
                    when start =>
                        state <= count;
                        busy <= '1';
                        done <= '0';
                        R_out <= resize(nom, R'length);
                        D_out <= ('0', den, others => '0');
                    when count =>
                        R := shift_left(R_out,1) - D_out;
                        if signed(R) >= 0 then
                            Q_out(Q_out'high - index) <= '1';
                            R_out <= R;
                        else
                            R_out <= R + D_out;
                            Q_out(Q_out'high-index) <= '0';
                        end if;
                        index <= index + 1;
                        if index >= C_WIDTH-1 then
                            state <= stop;
                        end if;
                    when stop =>
                        done <= '1';
                        busy <= '0';
                        remainder <= R_out(R_out'high - 1 downto C_WIDTH);
                        quotient <= Q_out;
                end case;
            end if;
        end if;
    end process;

end architecture RTL;
