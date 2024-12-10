library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.video_package.all;

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
        VGA_R, VGA_G, VGA_B          : out std_logic_vector(3 downto 0);
        VGA_HS, VGA_VS               : out std_logic
    );
end top;

architecture Behavioral of top is

    component clock_generator
        port(                           -- Clock in ports
                                        -- Clock out ports
            video_clk : out std_logic;
            -- Status and control signals
            resetn    : in  std_logic;
            locked    : out std_logic;
            clk_in1   : in  std_logic
        );
    end component;

    signal video_clk  : std_logic;
    signal locked     : std_logic;
    constant C_TIMING : video_timing_t := TIMING_768p;


    signal active : std_logic;
    signal hsync : std_logic;
    signal vsync : std_logic;
    signal pos_x : unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);
    signal pos_y : unsigned(video_get_counters_width(C_TIMING) - 1 downto 0);
    signal active_end : std_logic;
    signal frame_end : std_logic;

begin

    clock_generator_inst : component clock_generator
        port map(
            video_clk => video_clk,
            resetn    => rstn,
            locked    => locked,
            clk_in1   => clk
        );

        video_generator_inst : entity work.video_generator
            generic map(
                C_TIMING => C_TIMING
            )
            port map(
                clk        => video_clk,
                rst        => not locked,
                active     => active,
                hsync      => hsync,
                vsync      => vsync,
                pos_x      => pos_x,
                pos_y      => pos_y,
                active_end => active_end,
                frame_end  => frame_end
            );
        
    -- use locked instead of rstn in the rest of the circuit
    -- do not use "clk" input in the rest of the circuit

    -- insert a video_generator instance here

    -- using pos_x, pos_y from video_generator create simple patterns feeding VGA_R,G,B. Feed 0,0,0 when not active.
    -- use SW[15:14] to select pattern
    -- 0) full color screen controlled by SW[11:0] (R[11:8],G[7 ...)
    -- 1) 8 Color bars [black, blue, green, cyan, red, magenta, yellow, white]
    -- 2) Checkered flag with pixsize 16px. Color of "white" fields is determined by SW[11:0]
    -- 3) 256x256 image from image_ROM placed on 0,0.

    pattern_gen : process(video_clk)        
    begin
        if rising_edge(video_clk) then
            if locked = '0'then
                VGA_R   <= (others => '0');
                VGA_G   <= (others => '0');
                VGA_B   <= (others => '0');
                VGA_HS  <= '0';
                VGA_VS  <= '0';
            else
                VGA_HS <= hsync;
                VGA_VS <= vsync;

                if active then
                    case SW(15 downto 14) is
                        when "00" =>
                            VGA_R <= SW(11 downto 8);
                            VGA_G <= SW(7 downto 4);
                            VGA_B <= SW(3 downto 0);
                        when "01"  =>
                            case pos_x(pos_x'high downto (pos_x'high-3)) is
                                when "0000" => 
                                    VGA_R <= "1111";
                                    VGA_G <= "0000";
                                    VGA_B <= "0000";
                                when "0001" =>
                                    VGA_R <= "0000";
                                    VGA_G <= "0000";
                                    VGA_B <= "1111";
                                when "0010" =>
                                    VGA_R <= "0000";
                                    VGA_G <= "1111";
                                    VGA_B <= "0000";
                                when "0011" =>
                                    VGA_R <= "0000";
                                    VGA_G <= "1111";
                                    VGA_B <= "1111";
                                when "0100" =>
                                    VGA_R <= "1111";
                                    VGA_G <= "0000";
                                    VGA_B <= "1111";
                                when "0101" =>
                                    VGA_R <= "1111";
                                    VGA_G <= "1111";
                                    VGA_B <= "0000";
                                when "0110" =>
                                    VGA_R <= "1111";
                                    VGA_G <= "1111";
                                    VGA_B <= "1111";
                                when "0111" =>
                                    VGA_R <= "0000";
                                    VGA_G <= "0000";
                                    VGA_B <= "0000";
                                when others => null;
                            end case;
                        when "10"  =>
                            if ((pos_x(4) xor pos_y(4))='0') then
                                VGA_R <= SW(11 downto 8);
                                VGA_G <= SW(7 downto 4);
                                VGA_B <= SW(3 downto 0);
                            else
                                VGA_R <= (others => '0');
                                VGA_G <= (others => '0');
                                VGA_B <= (others => '0');
                            end if;
                        when "11"  =>
                            VGA_R <= (others => '0');
                            VGA_G <= (others => '0');
                            VGA_B <= (others => '0');
                        when others => null;
                    end case;
                    
                else
                    VGA_R <= (others => '0');
                    VGA_G <= (others => '0');
                    VGA_B <= (others => '0');
                end if;
                /*
                 -- connect hsync and vsync from video_generator
                VGA_HS <= hsync;
                VGA_VS <= vsync;
                 -- use active output from video_generator
                if active then
                    -- insert pattern generator here
                else
                    VGA_R <= (others => '0');
                    VGA_G <= (others => '0');
                    VGA_B <= (others => '0');
                end if;*/
            end if;
        end if;
    end process;
    -- insert image_ROM (xpm_rom_wrapper) here
    -- set full path to  ?\lab07\python\image.mem
    -- resolution is 256*256 (16bit address)

end Behavioral;
