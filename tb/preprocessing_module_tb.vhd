----------------------------------------------------------------------------------
-- Company: Wroclaw University of Science and Technology 
-- Engineer: Kamil Zbroinski
-- 
-- Create Date: 25.04.2021 17:36:51
-- Design Name: Preprocessing module TB
-- Module Name: preprocessing_module_tb - Behavioral
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

entity preprocessing_module_tb is
--  Port ( );
end preprocessing_module_tb;

architecture Behavioral of preprocessing_module_tb is
    component preprocessing_module
        Port ( CLK          : in  STD_LOGIC;
               rIn          : in  STD_LOGIC_VECTOR (7 downto 0);
               gIn          : in  STD_LOGIC_VECTOR (7 downto 0);
               bIn          : in  STD_LOGIC_VECTOR (7 downto 0);
               dataReadyIn  : in  STD_LOGIC;
               dataReadyOut : out  STD_LOGIC;
               dataOut      : out STD_LOGIC_VECTOR (7 downto 0));
    end component;
    
    signal CLK          :   STD_LOGIC := '0';
    signal rIn          :   STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal gIn          :   STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal bIn          :   STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal dataReadyIn  :   STD_LOGIC := '0';
    signal dataReadyOut :   STD_LOGIC := '0';
    signal dataOut      :   STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    
--    signal rInVec, gInVec, bInVec : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    
    constant CLK_PERIOD : time := 10 ns;
    
begin
    CLKStim : process
    begin
        CLK <= '0';
        wait for CLK_PERIOD / 2;
        CLK <= '1';
        wait for CLK_period / 2;
    end process;
    
    dataStim : process
    begin
        dataReadyIn <= '0';
        wait until rising_edge(CLK);
        dataReadyIn <= '1';
        rIn <= std_logic_vector(to_unsigned(255, 8));
        gIn <= std_logic_vector(to_unsigned(0, 8));
        bIn <= std_logic_vector(to_unsigned(0, 8));
        wait;
    end process;

    uut : preprocessing_module
        port map (CLK => CLK,
            rIn => rIn,
            gIn => gIn,
            bIn => bin,
            dataReadyIn => dataReadyIn,
            dataReadyOut => dataReadyOut,
            dataOut => dataOut);

end Behavioral;
