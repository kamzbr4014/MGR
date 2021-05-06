----------------------------------------------------------------------------------
-- Company: Wroclaw University of Science and Technology 
-- Engineer: Kamil Zbroinski
-- 
-- Create Date: 04.05.2021 22:32:18
-- Design Name: Filter module - BRAM control logic
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity BRAM_ctrl_logic is
    Generic ( isMaster  : boolean := false;
              imgWidth  : integer := 640;
              imgHeight : integer := 480);
    Port ( CLK          : in STD_LOGIC;
           EN           : in STD_LOGIC;
           FRST         : in STD_LOGIC;
           cntIn        : in STD_LOGIC_VECTOR (9 downto 0);
           nCtrlEnIn    : in STD_LOGIC;
           WEA          : out STD_LOGIC;
           WEB          : out STD_LOGIC;
           RSTA         : out STD_LOGIC;
           RSTB         : out STD_LOGIC;
           cntOut       : out STD_LOGIC_VECTOR (9 downto 0);
           FRSTOut      : out STD_LOGIC;
           nCtrlEnOut   : out STD_LOGIC);
end BRAM_ctrl_logic;

architecture Behavioral of BRAM_ctrl_logic is
    type clkCtrlState_t is (sWait, sFetch, sIdle);
    signal clkCtrlState  : clkCtrlState_t := sIdle; 
    signal nClkCtrlState : clkCtrlState_t := sWait;
    signal dataRdy, nDataRdy      : std_logic := '0';
begin
    clkCtrlStateNUpdate : process(CLK, FRST)
    begin
        if rising_edge(CLK) then
            if FRST = '1' then
                clkCtrlState <= sIdle;
            else
                clkCtrlState <= nClkCtrlState;
            end if;
        end if;
    end process;
    
    clkCtrlStateLogic : process(clkCtrlState, FRST, EN)
    begin
        if FRST = '1' then
            nClkCtrlState <= sIdle;
        else    
            case (clkCtrlState) is
                when sIdle =>
                    if EN = '1' then
                        nClkCtrlState <= sFetch;
                    else
                        nClkCtrlState <= sIdle;
                    end if;
                 when sFetch => 
                    nClkCtrlState <= sWait;
                 when sWait =>
                    if EN = '1' then
                        nClkCtrlState <= sFetch;
                    else
                        nClkCtrlState <= sIdle;
                    end if;
                 when others => 
                    nClkCtrlState <= sIdle;
                 end case;
             end if;
        end process; 
        
        clkCtrlStateNData : process(CLK) 
        begin
            if rising_edge(CLK) then
                if FRST = '1' then
                    dataRdy <= '0';
                else
                    dataRdy <= nDataRdy;
                end if;
            end if;
        end process;        

        clkCtrlStateData : process (clkCtrlState)
        begin
            if FRST = '1' then
                nDataRdy <= '0';
            else
                nDataRdy <= dataRdy;
                case clkCtrlState is
                    when sFetch => 
                        nDataRdy <= '1';
                    when sWait =>
                        nDataRdy <= '0';
                    when others =>
                end case;
            end if;
        end process;
    
end Behavioral;