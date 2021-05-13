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
use IEEE.NUMERIC_STD.ALL;

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
           dataRdy      : in STD_LOGIC;
           FRST         : in STD_LOGIC;
           WEA          : out STD_LOGIC;
           WEB          : out STD_LOGIC;
           RSTA         : out STD_LOGIC;
           RSTB         : out STD_LOGIC;
           nCtrlEnOut   : out STD_LOGIC);
end BRAM_ctrl_logic;

architecture Behavioral of BRAM_ctrl_logic is
    type clkCtrlState_t is (sWait, sFetch, sIdle);
    type rowBufferPhase_t is (pA, pAB, pABC);
    
    subtype rowCnt_t is unsigned(15 downto 0);
    subtype colCnt_t is unsigned(15 downto 0);
    signal rowCnt           : rowCnt_t := (others => '0');
    signal colCnt           : colCnt_t := (others => '0');
    signal clkCtrlState     : clkCtrlState_t := sIdle; 
    signal nClkCtrlState    : clkCtrlState_t := sIdle;
    signal rowFull          : std_logic := '0';
    signal frameEnd         : std_logic := '0';
    signal intRST, nIntRST  : std_logic := '0';
    signal enLatch          : std_logic := '0';
    signal rowBufferPhase , nRowBufferPhase : rowBufferPhase_t := pA;

begin
    CntUpdate : process(CLK, dataRdy)           -- check if there is no latches
        variable lastRowCnt : rowCnt_t := (others => '0');
        variable lastColCnt : rowCnt_t := (others => '0');
    begin
        if rising_edge(CLK) then
            if FRST = '1' or intRST = '1' then
                rowCnt <= (others => '0');
                colCnt <= (others => '0');
                rowFull <= '0';
                lastRowCnt := (others => '0');     
            else
                if dataRdy = '1' then   -- probably here is a neeed of if for En/enLatch - work properly, but enabling by en can save some energy
                    lastRowCnt := rowCnt + 1;
                    if lastRowCnt < imgWidth then 
                        rowCnt <= lastRowCnt;
                        rowFull <= '0'; 
                    else
                        lastRowCnt := (others => '0');
                        rowCnt <= lastRowCnt;
                        lastColCnt := colCnt + 1;
                        if lastColCnt < imgHeight then
                           colCnt <=  lastColCnt;
                        else
                           lastColCnt := (others => '0');
                           colCnt <=  lastColCnt;
                           frameEnd <= '1';
                        end if;
                        rowFull <= '1';
                    end if;
                else
                    rowCnt <= lastRowCnt;
                    lastRowCnt := rowCnt; 
                    frameEnd <= '0';
                    rowFull <= '0';  
                end if;       
            end if;
        end if;
    end process;

    ClkCtrlStateNUpdate : process(CLK, FRST)
    begin
        if rising_edge(CLK) then
            if FRST = '1' or intRST = '1' then
                clkCtrlState <= sIdle;
            else
                clkCtrlState <= nClkCtrlState;
            end if;
        end if;
    end process;
    
    ClkCtrlStateLogic : process(clkCtrlState, FRST, dataRdy, intRST, EN, enLatch)
    begin
        if FRST = '1' or intRST = '1' then
            nClkCtrlState <= sIdle;
        else    
            case (clkCtrlState) is
                when sIdle =>
                    if dataRdy = '1' and (enLatch = '1' or En = '1') then
                        if dataRdy = '1' then
                            nClkCtrlState <= sFetch;
                        else
                            nClkCtrlState <= sIdle;
                        end if;
                    else
--                        nClkCtrlState <= sIdle; -- TODO: eliminate latch
                    end if;
                 when sFetch => 
                        nClkCtrlState <= sWait;
                 when sWait =>
                    if dataRdy = '1' then
                        nClkCtrlState <= sFetch;
                    else
                        nClkCtrlState <= sIdle;
                    end if;
                 when others => 
                    nClkCtrlState <= sIdle;
                 end case;
             end if;
        end process; 
        
        ClkCtrlStateNData : process(CLK) 
        begin
            if rising_edge(CLK) then
                if FRST = '1' or intRST = '1'  then
                    rowBufferPhase <= pA;
                    intRST <= '0';
                else
                    rowBufferPhase <= nRowBufferPhase;
                    intRST <= nIntRST;
                end if;
            end if;
        end process;        

        ClkCtrlStateData : process (clkCtrlState, FRST, intRST, rowBufferPhase, frameEnd, rowFull)
        begin
            if FRST = '1' or intRST = '1'  then
                nRowBufferPhase <= pA;
                nCtrlEnOut <= '0'; 
                enLatch <= '0';
                nIntRST <= '0';
                WEA <= '0';
                WEB <= '0';    
                RSTA <= '1';
                RSTB <= '1';  
            else
                nRowBufferPhase <= rowBufferPhase;
                WEA <= '0';
                WEB <= '0';
                nCtrlEnOut <= '0';
                case clkCtrlState is
                    when sFetch =>
                        enLatch <= '1';
                        if frameEnd = '1' then 
                            nIntRST <= '1';
                        end if;
                        if rowFull = '1' then
                            case rowBufferPhase is
                                when pA =>
                                    nRowBufferPhase <= pAB;
                                when pAB => 
                                    nRowBufferPhase <= pABC;
                                when pABC =>
                             end case;
                         end if;                    
                        case rowBufferPhase is
                            when pA =>
                                WEA <= '1';
                                RSTA <= '1';
                                RSTB <= '1';
                            when pAB =>
                                WEA <= '1';
                                WEB <= '1';
                                RSTA <= '0';
                                RSTB <= '1';
                            when pABC => 
                                WEA <= '1';
                                WEB <= '1';
                                RSTA <= '0';
                                RSTB <= '0';                            
                         end case;
                    when sIdle =>
                        if rowBufferPhase = pABC then
                            nCtrlEnOut <= '1';
                        else 
                            nCtrlEnOut <= '0';
                        end if; 
                        RSTA <= '1';
                        RSTB <= '1';                         
--                    when sWait =>
--                        if rowBufferPhase = pABC then
--                            nCtrlEnOut <= '1';
--                        else 
----                            nCtrlEnOut <= '0';
--                        end if;
                    when others =>
                end case;
            end if;
        end process;
    
end Behavioral;