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
    Port ( pixCLK   :   in STD_LOGIC;
           hSync    :   in STD_LOGIC;
           vSync    :   in STD_LOGIC;
           dciData  :   in STD_LOGIC_VECTOR (7 downto 0));
end dci_module;

architecture Behavioral of dci_module is
    signal vSyncActive  : std_logic := '0';
    signal hSyncActive  : std_logic := '0';
    signal frameSR      : std_logic_vector(15 downto 0) := (others => '0');
    signal dataReady    : std_logic := '0';
    
    signal rReg         : std_logic_vector(7 downto 0) := (others => '0');
    signal gReg         : std_logic_vector(7 downto 0) := (others => '0');
    signal bReg         : std_logic_vector(7 downto 0) := (others => '0');
    
begin
    VSyncTracker : process(vSync) -- TODO add CLK synchro
    begin
        if falling_edge(vSync)
            vSyncActive <= '1';
        else
            vSyncActive <= '0';         
        end if;
    end process;
    
    HSyncTracker : process(hSync) -- TODO add CLK synchro
    begin
        if falling_edge(hSync) then
            hSyncActive <= '1';
        else
            hSyncActive <= '0';         
        end if;
    end process;

    DataExtraction : process(pixCLK, vSyncActive, hSyncActive)
        variable regCount : std_logic := '0';
    begin
        if rising_edge(pixCLK) then
            if vSyncActive = '1' then
                if hSyncActive = '1' then
                    frameSR <= frameSR(7 downto 0) & dciData;
                    if regCount = '0' then
                        regCount := '1';
                        dataReady  <= '0';
                    else
                        regCount := '0';
                        dataReady  <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    DataSegregation : process(dataReady)
    begin
        if dataReady = '1' then
            rReg <= frameSR(15 downto 11) & "000";
            gReg <= frameSR(10 downto 5)  & "000";
            bReg <= frameSR(4  downto 0)  & "000";
        end if;
    end process;
    
end Behavioral;
