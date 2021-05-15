----------------------------------------------------------------------------------
-- Company: Wroclaw University of Science and Technology 
-- Engineer: Kamil Zbroinski
-- 
-- Create Date: 14.05.2021 21:03:19
-- Design Name: Filter module
-- Module Name: filter_module - Behavioral
-- Project Name: Master thesis project 
-- Target Devices: Basys3
-- Tool Versions: Vivado 2020.2
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity filter_module_tb is
--  Port ( );
end filter_module_tb;

architecture Behavioral of filter_module_tb is
    component filter_module 
      Generic (W            : integer := 3;
               imgWidth     : integer := 10;
               imgHeight    : integer := 10);
      Port (pixCLK  : in std_logic;
            RST     : in std_logic;
            dataRdy : in std_logic;
            dataIn  : in std_logic_vector(7 downto 0);
            dataOut : out std_logic_vector(7 downto 0));
    end component;
    
    signal pixCLK  : std_logic;
    signal RST     : std_logic;
    signal dataRdy : std_logic := '0';
    signal dataIn  : std_logic_vector(7 downto 0) := (others => '0');
    signal dataOut : std_logic_vector(7 downto 0);
    constant W : integer := 5;
    constant imgWidth : integer := 10;
    constant imgHeight : integer := 10;    
    constant pixCLKPeriod     : time := 10 ns;
begin
    CLKSim : process
    begin
        pixCLK <= '0';
        wait for pixCLKPeriod / 2;
        pixCLK <= '1';
        wait for pixCLKPeriod / 2;
    end process;
    
    dataStim : process
        variable cnt : unsigned(7 downto 0) := (others => '0');
        variable dataRdyTmp : std_logic := '0';
    begin
--        wait for pixCLKPeriod;
        for j in 0 to imgHeight-1 loop
            for i in 0 to (imgWidth*2) - 1 loop
                wait until rising_edge(pixCLK);
                dataRdyTmp := not dataRdy;
                if dataRdyTmp = '1' then
                    cnt := cnt + 1;
                end if;
                dataRdy <= dataRdyTmp;
                dataIn <= std_logic_vector(cnt); 
            end loop;
            dataRdy <= '0';
            wait for 2*pixCLKPeriod;
        end loop;
--        wait;
    end process;

    uut : filter_module
        port map (pixCLK => pixCLK,
           RST => RST,
           dataRdy => dataRdy,
           dataIn => dataIn,
           dataOut => dataOut);

end Behavioral;
