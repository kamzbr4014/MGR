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
           FRSTO        : out STD_LOGIC;
           WEA          : out STD_LOGIC;
           WEB          : out STD_LOGIC;
           RSTA         : out STD_LOGIC;
           RSTB         : out STD_LOGIC;
           nCtrlEnOut   : out STD_LOGIC;
           ADDRA        : out STD_LOGIC_VECTOR(10 downto 0);
           ADDRB        : out STD_LOGIC_VECTOR(10 downto 0));
end BRAM_ctrl_logic;

architecture Behavioral of BRAM_ctrl_logic is
    type clkCtrlState_t is (sWait, sFetch, sIdle);
    type rowBufferPhase_t is (pA, pAB, pABC);
    subtype rowCnt_t is unsigned(15 downto 0);
    subtype colCnt_t is unsigned(15 downto 0);
    signal rowCnt, nRowCnt           : rowCnt_t := (others => '0');
    signal colCnt, nColCnt           : colCnt_t := (others => '0');
    signal clkCtrlState     : clkCtrlState_t := sIdle; 
    signal nClkCtrlState    : clkCtrlState_t := sIdle;
    signal rowFull          : std_logic := '0';
    signal frameEnd         : std_logic := '0';
    signal intRST, nIntRST  : std_logic := '0';
    signal enLatch          : std_logic := '0';
    signal rowBufferPhase , nRowBufferPhase : rowBufferPhase_t := pA;
    constant addrOffset     : integer   := 1024 - 1;
    signal cntRST : std_logic := '0';
    signal ADDRAS, nADDRAS : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
    signal ADDRBS, nADDRBS : STD_LOGIC_VECTOR(10 downto 0) := std_logic_vector(to_unsigned(addrOffset, ADDRAS'length));
    signal RSTAS, nRSTAS    : std_logic := '1';
    signal RSTBS, nRSTBS    : std_logic := '1';
    signal FRSTOS, nFRSTOS    : std_logic := '0';
begin

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
                rowCnt <= (others => '0');
                colCnt <= (others => '0');
                ADDRAS <= std_logic_vector(rowCnt(10 downto 0) + 1);       
                ADDRBS <= std_logic_vector(rowCnt(10 downto 0) + addrOffset + 1);
                RSTAS <= '1';
                RSTBS <= '1';
                FRSTOS <= '0';  
            else
                rowBufferPhase <= nRowBufferPhase;
                intRST <= nIntRST;
                rowCnt <= nRowCnt;
                colCnt <= nColCnt;
                ADDRAS <= nADDRAS;
                ADDRBS <= nADDRBS;
                RSTAS <= nRSTAS;
                RSTBS <= nRSTBS;
                FRSTOS <= nFRSTOS;                     
            end if;
        end if;
    end process;
            
    CntHandler : process(clkCtrlState, FRST, intRST,rowCnt,ADDRAS,ADDRBS,FRSTOS,colCnt)
        variable tmpRowCnt, tmpColCnt : unsigned(15 downto 0) := (others => '0');
    begin
    if FRST = '1' or intRST = '1' then
        ADDRA <= (others => '0'); 
        ADDRB <= std_logic_vector(to_unsigned(addrOffset, ADDRBS'length));
        nFRSTOS <= '0';
        nIntRST <= '0';        
    else
        rowFull <= '0';
        frameEnd <= '0';
        nIntRST <= '0';
        nRowCnt <= rowCnt;
        ADDRA <= ADDRAS; 
        ADDRB <= ADDRBS;
        nFRSTOS <= '0';
        FRSTO <= FRSTOS;
        case clkCtrlState is    
            when sFetch =>
                tmpRowCnt := rowCnt + 1;
                if tmpRowCnt < imgWidth then
                    nRowCnt <= tmpRowCnt;
                    rowFull <= '0';
                    nADDRAS <= std_logic_vector(rowCnt(10 downto 0) + 1);       
                    nADDRBS <= std_logic_vector(rowCnt(10 downto 0) + addrOffset + 1);  
                else
                    tmpColCnt := colCnt + 1;
                    if tmpColCnt < imgHeight then
                        nColCnt <= tmpColCnt;
                        frameEnd <= '0';
                    else
                        nColCnt <= (others => '0');
                        frameEnd <= '1';
                        nIntRST <= '1';
                        nFRSTOS <= '1';           
                    end if; 
                    nRowCnt <= (others => '0');
                    rowFull <= '1';
                    nADDRAS <= (others => '0');
                    nADDRBS <= std_logic_vector(to_unsigned(addrOffset, ADDRBS'length));
                end if;
            when others =>    
        end case; 
    end if;
    end process;
    
    ClkCtrlStateData : process (clkCtrlState, FRST, intRST, rowBufferPhase, frameEnd, rowFull, RSTAS, RSTBS)
    begin
        if FRST = '1' or intRST = '1'  then
            nRowBufferPhase <= pA;
            nCtrlEnOut <= '0'; 
            enLatch <= '0';
            WEA <= '0';
            WEB <= '0';    
            nRSTAS <= '1';
            nRSTBS <= '1'; 
        else
            nRowBufferPhase <= rowBufferPhase;
            WEA <= '0';
            WEB <= '0';
            RSTA <= RSTAS;
            RSTB <= RSTBS;
            nCtrlEnOut <= '0';
            case clkCtrlState is
                when sFetch =>
                    enLatch <= '1';
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
                            WEB <= '0';
--                                RSTA <= '1';
--                                RSTB <= '1';
                        when pAB =>
                            WEA <= '1';
                            WEB <= '1';
--                                RSTA <= '0';
--                                RSTB <= '1';
                        when pABC => 
                            WEA <= '1';
                            WEB <= '1';
--                                RSTA <= '0';
--                                RSTB <= '0';                            
                     end case;
                when sIdle =>
                    if rowBufferPhase = pABC then
                        nCtrlEnOut <= '1';
                    else 
                        nCtrlEnOut <= '0';
                    end if; 
--                        RSTA <= '1';  -- TODO: add counter to prevent errors while unexpected errr occurs
--                        RSTB <= '1';                         
                when sWait =>
                    case rowBufferPhase is
                        when pA =>
                            nRSTAS <= '1';
                            nRSTBS <= '1';
                        when pAB =>
                            nRSTAS <= '0';
                            nRSTBS <= '1';
                        when pABC => 
                            nRSTAS <= '0';
                            nRSTBS <= '0';                            
                     end case;
                when others =>
            end case;
        end if;
    end process;
    
end Behavioral;