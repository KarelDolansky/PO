library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use work.ALU_package.all;

entity top is
    port(
        clk                          : in  std_logic;
        rstn                         : in  std_logic;
        SW                           : in  std_logic_vector(15 downto 0);
        LED                          : out std_logic_vector(15 downto 0);
        segments                     : out std_logic_vector(7 downto 0);
        displays                     : out std_logic_vector(7 downto 0);
        LED_RGB                      : out std_logic_vector(5 downto 0);
        btnc, btnu, btnl, btnr, btnd : in  std_logic
    );
end top;

architecture Behavioral of top is

    signal counter : unsigned(31 downto 0);
    signal pressed : std_logic;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rstn = '0' then
                counter <= (others => '0');
            elsif pressed then
                counter <= counter + 1;
            end if;
        end if;
    end process;

    display_driver_inst : entity work.display_driver
        port map(
            clk      => clk,
            rst      => not rstn,
            din      => std_logic_vector(counter),
            segments => segments,
            displays => displays
        );

        fsm_button_inst : entity work.fsm_button
            generic map(
                C_CLK_PERIOD_NS => 10,
                C_PUSH_NS       => 1_000_000,
                C_REPEAT_NS     => 500_000_000
            )
            port map(
                clk   => clk,
                rst  => not rstn,
                d    => btnc,
                q    => pressed
            );

end;
