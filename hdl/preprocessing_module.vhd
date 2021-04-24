----------------------------------------------------------------------------------
-- Company: Wroclaw University of Science and Technology 
-- Engineer: Kamil Zbroinski
-- 
-- Create Date: 24.04.2021 19:43:12
-- Design Name: Preprocessing module
-- Module Name: preprocessing_module - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity preprocessing_module is
    Port ( CLK          : in STD_LOGIC;
           rIn          : in STD_LOGIC_VECTOR (7 downto 0);
           gIn          : in STD_LOGIC_VECTOR (7 downto 0);
           bIn          : in STD_LOGIC_VECTOR (7 downto 0);
           dataReadyIn  : in STD_LOGIC);
end preprocessing_module;

architecture Behavioral of preprocessing_module is

begin


end Behavioral;
