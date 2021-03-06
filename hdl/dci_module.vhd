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
    Port ( pixCLK   :   in  STD_LOGIC;
           mainCLK  :   in  STD_LOGIC;
           RST      :   in  STD_LOGIC;
           hSync    :   in  STD_LOGIC;
           vSync    :   in  STD_LOGIC;
           dataReady:   out STD_LOGIC;
           dciData  :   in  STD_LOGIC_VECTOR (7 downto 0);
           rOut     :   out STD_LOGIC_VECTOR (7 downto 0);
           gOut     :   out STD_LOGIC_VECTOR (7 downto 0);
           bOut     :   out STD_LOGIC_VECTOR (7 downto 0));
    
end dci_module;

architecture Behavioral of dci_module is
    signal vSyncActive  : std_logic := '0';
    signal hSyncActive  : std_logic := '0';
    signal dataReadyFlag: std_logic := '0';
    
    signal rReg         : std_logic_vector(7 downto 0) := (others => '0');
    signal gReg         : std_logic_vector(7 downto 0) := (others => '0');
    signal bReg         : std_logic_vector(7 downto 0) := (others => '0');
    
    signal edgeDetectorA : std_logic := '0';
    signal edgeDetectorB : std_logic := '0';
    
begin
    VSyncTracker : process(mainCLK) -- TODO add CLK synchro
        variable edgePulseRE : std_logic := '0';
        variable edgePulseFE : std_logic := '0';
    begin
        if rising_edge(mainCLK) then
            if RST = '1' then
                vSyncActive <= '0';
                edgePulseFE := '0';
                edgePulseRE := '0';
            else
                edgeDetectorA <= vSync;
                edgePulseFE :=  edgeDetectorA and not vSync;
                edgePulseRE :=  not edgeDetectorA and vSync;
                if edgePulseFE = '1'  then
                    vSyncActive <= '1';
                elsif edgePulseRE = '1' then
                    vSyncActive <= '0';
                end if;
            end if;        
        end if;
    end process;
    
    hSyncTracker : process(mainCLK) -- TODO add CLK synchro, reset trigerred by data extraction process
        variable edgePulseRE : std_logic := '0';
        variable edgePulseFE : std_logic := '0';
    begin
        if rising_edge(mainCLK) then
             if RST = '1' then
                hSyncActive <= '0';
                edgePulseFE := '0';
                edgePulseRE := '0';
             else
                edgeDetectorB <= hSync;
                edgePulseFE :=  edgeDetectorB and not hSync;
                edgePulseRE :=  not edgeDetectorB and hSync;
                if edgePulseFE = '1'  then
                    hSyncActive <= '1';
                elsif edgePulseRE = '1' then
                    hSyncActive <= '0';
                end if;   
             end if;     
        end if;
    end process;

    DataExtraction : process(pixCLK, vSyncActive, hSyncActive)
        variable regCount : std_logic := '0';
        variable frameSR  : std_logic_vector(15 downto 0) := (others => '0');
    begin
        if rising_edge(pixCLK) then
            if RST = '1' then 
                regCount := '0';
                frameSR := (others => '0');
                dataReadyFlag  <= '0';
            else
                if vSyncActive = '1' then
                    if hSyncActive = '1' then
                        frameSR := frameSR(7 downto 0) & dciData; -- TODO: take a better look at simulation if this not a poblem
                        if regCount = '0' then
                            regCount := '1';
                            dataReadyFlag  <= '0';
                        else
                            regCount := '0';
                            dataReadyFlag  <= '1';
                            rReg <= frameSR(15 downto 11) & frameSR(15 downto 13);
                            gReg <= frameSR(10 downto 5)  & frameSR(10 downto 9);
                            bReg <= frameSR(4  downto 0)  & frameSR(4 downto 2);
                        end if;
                    else
                        dataReadyFlag  <= '0';
                    end if;
                else
                    dataReadyFlag  <= '0';
                end if;
            end if;
        end if;
    end process;
    
    dataReady <= dataReadyFlag;
    rOut <= rReg;
    gOut <= gReg;
    bOut <= bReg;

end Behavioral;