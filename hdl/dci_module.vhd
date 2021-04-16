----------------------------------------------------------------------------------
-- Company: Wroclaw University of Science and Technology 
-- Engineer: Kamil Zbroinski
-- 
-- Create Date: 16.04.2021 13:23:08
-- Design Name: Digital Camera Interface Module
-- Module Name: dci_module - Behavioral
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity dci_module is
    Port ( pixCLK : in STD_LOGIC;
           hSync : in STD_LOGIC;
           vSync : in STD_LOGIC;
           dciData : in STD_LOGIC_VECTOR (13 downto 0));
end dci_module;

architecture Behavioral of dci_module is

begin


end Behavioral;
