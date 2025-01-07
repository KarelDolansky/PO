----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.12.2024 08:06:46
-- Design Name: 
-- Module Name: top_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_tb is
    --  Port ( );
end top_tb;

architecture Behavioral of top_tb is

    constant CLK_P : time := 10 ns;

    signal clk      : std_logic                     := '0';
    signal rstn     : std_logic                     := '0';
    signal SW       : std_logic_vector(15 downto 0) := (others => '0');
    signal LED      : std_logic_vector(15 downto 0);
    signal segments : std_logic_vector(7 downto 0);
    signal displays : std_logic_vector(7 downto 0);
    signal LED_RGB  : std_logic_vector(5 downto 0);
    signal btnc     : std_logic                     := '0';
    signal btnu     : std_logic                     := '0';
    signal btnl     : std_logic                     := '0';
    signal btnr     : std_logic                     := '0';
    signal btnd     : std_logic                     := '0';
    signal VGA_R    : std_logic_vector(3 downto 0);
    signal VGA_G    : std_logic_vector(3 downto 0);
    signal VGA_B    : std_logic_vector(3 downto 0);
    signal VGA_HS   : std_logic;
    signal VGA_VS   : std_logic;

begin

    clk <= not clk after CLK_P / 2;

    dut : entity work.top
        port map(
            clk      => clk,
            rstn     => rstn,
            SW       => SW,
            LED      => LED,
            segments => segments,
            displays => displays,
            LED_RGB  => LED_RGB,
            btnc     => btnc,
            btnu     => btnu,
            btnl     => btnl,
            btnr     => btnr,
            btnd     => btnd,
            VGA_R    => VGA_R,
            VGA_G    => VGA_G,
            VGA_B    => VGA_B,
            VGA_HS   => VGA_HS,
            VGA_VS   => VGA_VS
        );

    tb: process
    begin
        rstn <= '0';
        wait for CLK_P * 10;
        rstn <= '1';
    end process;
end Behavioral;
