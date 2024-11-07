library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity top is
    port(
        clk                          : in    std_logic;
        rstn                         : in    std_logic;
        SW                           : in    std_logic_vector(15 downto 0);
        LED                          : out   std_logic_vector(15 downto 0);
        segments                     : out   std_logic_vector(7 downto 0);
        displays                     : out   std_logic_vector(7 downto 0);
        LED_RGB                      : out   std_logic_vector(5 downto 0)
    );
end top;

architecture Behavioral of top is
    signal counter : unsigned(31 downto 0);
    -- signal done  : std_logic := '0';

    
begin
    display_driver_inst : entity work.display_driver
        port map(
            clk      => clk,
            rst      => rstn,
            din      => std_logic_vector(counter),
            segments => segments,
            displays => displays
        );
    
    process(clk)
        variable div : integer range 0 to 1_000_000 := 0;
        variable name : std_logic_vector(31 downto 0) := (others => '0');
        
    begin
        if rising_edge(clk) then
            if rstn = '0' then
                div := 0;
                counter <= (others => '0');
                -- done <= '0';
            elsif div >= 999_999 then
                div:=0;
                -- done <= '0';
                counter <= counter + 1;
                name(31 downto 16):=SW;
                if name <= std_logic_vector(counter) then
                    counter <= (others => '0');
                    -- done <= '1';
                end if;
            end if;
            div := div+1;
        end if;
    end process;

    -- LED_RGB(0)<=done;
    LED <= std_logic_vector(counter(31 downto 16));


end;
