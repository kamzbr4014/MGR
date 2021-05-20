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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity preprocessing_module is
    Port ( CLK          : in  STD_LOGIC;
           rIn          : in  STD_LOGIC_VECTOR (7 downto 0);
           gIn          : in  STD_LOGIC_VECTOR (7 downto 0);
           bIn          : in  STD_LOGIC_VECTOR (7 downto 0);
           dataReadyIn  : in  STD_LOGIC;
           dataReadyOut : out  STD_LOGIC;
           dataOut      : out STD_LOGIC_VECTOR (7 downto 0));
end preprocessing_module;

architecture Behavioral of preprocessing_module is
    signal dataRdBuff   : std_logic := '0';
    signal outBuff      : std_logic_vector(9 downto 0) := (others => '0');

begin
    RGBToY : process(CLK)
        variable rBuff, gBuff, bBuff : unsigned(7 downto 0) := (others => '0');
        variable tmpA, tmpB  : unsigned(8 downto 0) := (others => '0');
        variable tmpC : unsigned(9 downto 0) := (others => '0');
    begin
        if rising_edge(CLK) then
            if dataReadyIn = '1' then
                rBuff := unsigned(rIn);
                gBuff := unsigned(gIn);
                bBuff := unsigned(bIn);
                
                tmpA := ('0' & rBuff) + ('0' & bBuff);
                tmpB := shift_left(('0' & gBuff), 1);
                tmpC := ('0' & tmpA) + ('0' & tmpB);
                
                outBuff <= std_logic_vector(shift_right(tmpC, 2));
                dataRdBuff <= '1';
             else
                outBuff <= outBuff;
                dataRdBuff <= '0';
             end if;
         end if;    
    end process;
    
    dataOut <= outBuff(7 downto 0);
    dataReadyOut <= dataRdBuff;
    
end Behavioral;