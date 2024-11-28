library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity fsm_button is
    generic(
        C_CLK_PERIOD_NS : integer := 10; -- clock period in NS
        C_PUSH_NS       : integer := 100; -- minimum push duration
        C_REPEAT_NS     : integer := 10_000_000 -- push duration to repeat pulse
    );
    port(
        clk : in  std_logic;
        rst : in  std_logic;
        d   : in  std_logic;            -- input (btn)
        q   : out std_logic             -- output pulse after C_PUSH_NS. Duration 1CLKP max. Repeat if pressed for C_REPEAT_NS
    );
end entity fsm_button;

architecture RTL of fsm_button is

    type fsm_t is (SNotPressed, SPressed, SPulse, SHolding);
    signal state : fsm_t := SNotPressed;

begin

    process(clk)
        -- will need counter. Use unsigned with log2(C_REPEAT_NS/C_CLK_PERIOD_NS) width
        variable counter : unsigned(integer(ceil(log2(real(C_REPEAT_NS)/real(C_CLK_PERIOD_NS)))) downto 0);
        
    begin
        if rising_edge(clk) then
            if rst then
                state <= SNotPressed;
                counter :=(others => '0');
                q<='0';
            else
                q<='0';
                case state is
                    when SNotPressed =>
                        if d then
                            state <= SPressed;
                            counter :=(others => '0');
                        end if;
                        -- Go to Spressed on btn press
                    when SPressed =>
                        if d then
                            counter := counter + 1;
                            if counter > C_PUSH_NS/C_CLK_PERIOD_NS then
                                state <= SPulse;
                            end if;
                        else
                            state <= SNotPressed;
                        end if;
                        -- count up until PUSH_NS and go to SPulse
                    when SPulse =>
                        q<= '1';
                        if d then
                            state <= SHolding;
                            counter :=(others => '0');
                        else
                            state <= SNotPressed;
                        end if;
                        -- generate pulse on q
                        -- go to SHolding if still holding
                    when SHolding =>
                        if d then
                            counter := counter + 1;
                            if counter > C_REPEAT_NS/C_CLK_PERIOD_NS then
                                state <= SPulse;
                            end if;
                        else
                            state <= SNotPressed;
                        end if;
                        -- if still holding, wait REPEAT_NS and generate pulse again
                        -- if NOT holding go to SNotPressed
                    when others =>
                        -- go to SNotPressed or SPressed depending on d value
                end case;
            end if;
        end if;
    end process;

end architecture RTL;
