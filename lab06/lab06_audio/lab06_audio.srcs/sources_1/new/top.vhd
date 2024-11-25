library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top is
    port(
        clk                          : in  std_logic;
        rstn                         : in  std_logic;
        SW                           : in  std_logic_vector(15 downto 0);
        LED                          : out std_logic_vector(15 downto 0);
        segments                     : out std_logic_vector(7 downto 0);
        displays                     : out std_logic_vector(7 downto 0);
        LED_RGB                      : out std_logic_vector(5 downto 0);
        btnc, btnu, btnl, btnr, btnd : in  std_logic;
        audio_PWM, audio_SD          : out std_logic
    );
end top;



architecture Behavioral of top is

    

    constant C_CLK_FREQ_HZ    : integer := 100_000_000;
    constant C_SAMPLE_FREQ_HZ : integer := 8_000;
    constant C_SAMPLES        : integer := 27264;
    constant C_SAMPLE_WIDTH   : integer := 8;

    signal pwm : std_logic;

    /*
    TODO 1:
        Complete function
    */
    type ROM_t is array (0 to 1023) of unsigned(C_SAMPLE_WIDTH - 1 downto 0);
    function fill_ROM_sin return ROM_t is
        variable retval : ROM_t;
    begin
        -- fill ROM with one period of sin(x) signal
        -- y = sin(t) is in range <-1, 1>. Modify output to range <0, 2**C_SAMPLE_WIDTH - 1>
        -- t is in range <0, 2Pi> => <0, 1023>
        for i in 0 to 1023 loop
            retval(i) := to_unsigned(integer((sin(i * 2.0 * MATH_PI / 1024.0) + 1.0) * 255.0/2), C_SAMPLE_WIDTH);
        end loop;
        
            
        return retval;
    end function;
    
    signal ROM_sin : ROM_t := fill_ROM_sin;
    signal ROM_cnt : integer := 0;

begin
    
    pwm_inst : entity work.pwm
        generic map(
            C_SAMPLE_WIDTH => 8
        )
        port map(
            clk       => clk,
            rst       => not rstn,
            pwm_value => ROM_sin(ROM_cnt),
            pwm       => pwm
        );
    
    

        process(clk)
            variable counter : unsigned(9 downto 0) := (others => '0');
        begin
            if rising_edge(clk) then
                if not rstn then
                    counter := (others => '0');
                    ROM_cnt <= 0;
                else
                    if counter <222 then
                        counter := counter+1;
                    else
                        counter := (others => '0');
                        ROM_cnt <= ROM_cnt + 1;
                    end if;
                end if;
            end if;
        end process;
            

    /*
    TODO 2: Add PWM module here (need to be implemented first ;)
        drive pwm_value from ROM_sin
        connect pwm output to pwm signal        
    */
    
    
    -- do not change (see )
    audio_PWM <= 'Z' when pwm else '0';
    audio_SD  <= '1';    

    /*
    TODO 3: add xpm_rom_wrapper inst
        compute C_ADDRESS_WIDTH based on C_SAMPLES
        use proper C_SAMPLE_PATH as C_MEM_FILE        
    */

    /*
    TODO 4: add counter that drives XPM ROM address port
        count up to C_SAMPLES
        count in freq. C_SAMPLE_FREQ_HZ
    */



end Behavioral;
