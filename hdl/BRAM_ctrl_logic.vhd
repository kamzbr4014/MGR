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
    Generic ( filterSize: integer := 5; -- TODO: add functionality to removed bool flag - generate flag for shifter only in master
              index     : integer := 0;
              imgWidth  : integer := 640;
              imgHeight : integer := 480);
    Port ( CLK          : in STD_LOGIC;
           EN           : in STD_LOGIC;
           dataRdy      : in STD_LOGIC;
           FRST         : in STD_LOGIC;
           FRSTO        : out STD_LOGIC;
           filterCtrl   : out STD_LOGIC;
           filterMuxCtrl: out STD_LOGIC;            
           WEA          : out STD_LOGIC;
           WEB          : out STD_LOGIC;
           RSTA         : out STD_LOGIC;
           RSTB         : out STD_LOGIC;
           nCtrlEnOut   : out STD_LOGIC;
           colDataCollected : out std_logic;
           rowDataCollected : out std_logic;
           shifterFlush : out std_logic;
           zeroFlush    : out std_logic;
           ADDRA        : out STD_LOGIC_VECTOR(10 downto 0);
           ADDRB        : out STD_LOGIC_VECTOR(10 downto 0));
end BRAM_ctrl_logic;

architecture Behavioral of BRAM_ctrl_logic is
    type clkCtrlState_t     is (sWait, sFetch, sIdle);
    type rowBufferPhase_t   is (pA, pAB, pABC, pNotA, pNotAB, pNotABC);
    subtype rowCnt_t        is unsigned(15 downto 0);
    subtype colCnt_t        is unsigned(15 downto 0);
    constant addrOffset                     : integer   := 1024 - 1;
    signal rowCnt, nRowCnt                  : rowCnt_t := (others => '0');
    signal colCnt, nColCnt                  : colCnt_t := to_unsigned((2*index), 16);
    signal clkCtrlState                     : clkCtrlState_t := sIdle; 
    signal nClkCtrlState                    : clkCtrlState_t := sIdle;
    signal rowFull, nRowFull                : std_logic := '0';
    signal frameEnd, nFrameEnd              : std_logic := '0'; 
    signal intRST, nIntRST                  : std_logic := '0';
    signal enLatch                          : std_logic := '0';
    signal rowBufferPhase , nRowBufferPhase : rowBufferPhase_t := pA;
    signal cntRST                           : std_logic := '0';
    signal ADDRAS, nADDRAS                  : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
    signal ADDRBS, nADDRBS                  : STD_LOGIC_VECTOR(10 downto 0) := std_logic_vector(to_unsigned(addrOffset, ADDRAS'length));
    signal RSTAS, nRSTAS                    : std_logic := '1';
    signal RSTBS, nRSTBS                    : std_logic := '1';
    signal FRSTOS, nFRSTOS                  : std_logic := '0';
    signal zeroFlushS, nZeroFlushS          : std_logic := '0';
    signal shifterFlushS, nShifterFlushS    : std_logic := '0';
    signal rowDataCollectedS, nRowDataCollectedS : std_logic := '0';
    signal colDataCollectedS, nColDataCollectedS : std_logic := '0';
    signal postFrameEnd, nPostFrameEnd :     std_logic := '0';
    signal filterMuxCtrlS, nFilterMuxCtrlS  : std_logic := '0';
    signal nCtrlEnOutS, nnCtrlEnOutS        : std_logic := '0';

    type frameResetHandler_r is record
        transitionState : rowBufferPhase_t;
        resetState : rowBufferPhase_t;
        counterResetVal : unsigned(15 downto 0);  
    end record frameResetHandler_r;

    impure function functionOfDefVal (index : integer) return frameResetHandler_r is
        variable tmp : integer := 0;
        variable state : frameResetHandler_r;
        constant bramCount : integer := (filterSize - 1)/2;
    begin
        tmp := bramCount mod 2;
        if filterSize = 3 then
            state.transitionState := pABC;
            state.resetState := pAB;
            state.counterResetVal := to_unsigned(bramCount, 16);  
        else
            if tmp = 0 then
                if index <= (bramCount/2) - 1 then
                    state.transitionState := pNotA;
                    state.resetState := pABC;
                    state.counterResetVal := to_unsigned(bramCount, 16);
                    -- for lower than => pABC
                else
                    state.transitionState := pABC;
                    state.resetState := pA;
                    state.counterResetVal := to_unsigned(bramCount, 16);
                    -- for greater than => pA
                end if;
            else
                if index < (bramCount + 1)/2 - 1  then
                    state.transitionState := pNotA;
                    state.resetState := pABC;
                    state.counterResetVal := to_unsigned(bramCount, 16);
                    -- => pABC
                elsif index = (bramCount + 1)/2 - 1 then
                    state.transitionState := pABC;
                    state.resetState := pAB;
                    state.counterResetVal := to_unsigned(bramCount, 16);
                    -- => pAB
                else
                state.transitionState := pABC;
                state.resetState := pA;
                state.counterResetVal := to_unsigned(bramCount + 1, 16);
                    -- => pA
                end if;
            end if;
        end if;
        return state;
    end function;
  
    constant frameResetHandler : frameResetHandler_r := functionOfDefVal(index);
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
                        nClkCtrlState <= ClkCtrlState; -- TODO: eliminate latch
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
                intRST          <= '0';
                rowBufferPhase  <= pA;
                rowCnt          <= (others => '0');
                colCnt          <= (others => '0');
                rowFull         <= '0';
                ADDRAS          <= std_logic_vector(rowCnt(10 downto 0));       
                ADDRBS          <= std_logic_vector(rowCnt(10 downto 0) + addrOffset);
                RSTAS           <= '1';
                RSTBS           <= '1';
                FRSTOS          <= '0'; 
                zeroFlushS      <= '0';
                rowDataCollectedS <= '0'; 
                colDataCollectedS <= '0';
                shifterFlushS   <= '0';
                frameEnd        <= '0';
                postFrameEnd    <= '0';
            else
                intRST          <= nIntRST;
                rowBufferPhase  <= nRowBufferPhase;
                rowCnt          <= nRowCnt;
                colCnt          <= nColCnt;
                rowFull         <= nRowFull;
                ADDRAS          <= nADDRAS;
                ADDRBS          <= nADDRBS;
                RSTAS           <= nRSTAS;
                RSTBS           <= nRSTBS;
                FRSTOS          <= nFRSTOS;
                zeroFlushS      <= nZeroFlushS;   
                rowDataCollectedS <= nRowDataCollectedS; 
                colDataCollectedS <= ncolDataCollectedS;
                shifterFlushS   <= nShifterFlushS;   
                frameEnd        <= nFrameEnd;    
                postFrameEnd    <= nPostFrameEnd;
                filterMuxCtrlS  <= nFilterMuxCtrlS;             
            end if;
        end if;
    end process;
   
    CntHandler : process(clkCtrlState, FRST, intRST,rowCnt,ADDRAS, ADDRBS, FRSTOS, colCnt, zeroFlushS, 
                    rowDataCollectedS, shifterFlushS, colDataCollectedS, frameEnd, postFrameEnd)
        variable tmpRowCnt, tmpColCnt : unsigned(15 downto 0) := (others => '0');
    begin
    if FRST = '1' or intRST = '1' then
        nIntRST         <= '0';
        nRowCnt         <= (others => '0'); 
        nColCnt         <= (others => '0');
        nRowFull        <= '0';        
        ADDRA           <= (others => '0'); 
        ADDRB           <= std_logic_vector(to_unsigned(addrOffset, ADDRBS'length));
        nADDRAS         <= (others => '0'); 
        nADDRBS         <= std_logic_vector(to_unsigned(addrOffset, ADDRBS'length));        
        nFRSTOS         <= '0';
        nzeroFlushS     <= '0';
        nrowDataCollectedS <= '0';
        nshifterFlushS  <= '0'; 
        FRSTO           <= '0';
        zeroFlush       <= '0';
        shifterFlush    <= '0';
        rowDataCollected    <= '0';
        ncolDataCollectedS  <= '0';
        colDataCollected    <= '0';
        nFrameEnd       <= '0';
        nPostFrameEnd   <= '0';
        nFilterMuxCtrlS <= '0';
        filterMuxCtrl   <= '0';
    else
        nIntRST         <= '0';
        nRowCnt         <= rowCnt;
        nColCnt         <= ColCnt;
        nRowFull        <= '0';
        ADDRA           <= ADDRAS; 
        ADDRB           <= ADDRBS;
        nADDRAS         <= ADDRAS; 
        nADDRBS         <= ADDRBS;
        nFRSTOS         <= '0';
        FRSTO           <= FRSTOS;
        nzeroFlushS     <= zeroFlushS;
        zeroFlush       <= zeroFlushS;
        nrowDataCollectedS  <= rowDataCollectedS;
        rowDataCollected    <= rowDataCollectedS;
        nshifterFlushS  <= '0'; 
        shifterFlush    <= shifterFlushS;
        ncolDataCollectedS <= colDataCollectedS;
        colDataCollected    <= colDataCollectedS;
        nFrameEnd       <= frameEnd;
        nPostFrameEnd   <= postFrameEnd;
        tmpRowCnt       := RowCnt;
        nfilterMuxCtrlS <= filterMuxCtrlS;
        filterMuxCtrl   <= filterMuxCtrlS;
        case clkCtrlState is    
            when sFetch =>
                tmpRowCnt := rowCnt + 1;
                if tmpRowCnt < imgWidth then
                    if tmpRowCnt = (filterSize - 1)/2 then
                        if RowDataCollectedS = '1' then
                            nColDataCollectedS <= '1';
                        end if;
                        nzeroFlushS <= '0';    
                    end if;
                    nRowCnt <= tmpRowCnt;
                    nADDRAS <= std_logic_vector(rowCnt(10 downto 0) + 1);       
                    nADDRBS <= std_logic_vector(rowCnt(10 downto 0) + addrOffset + 1);  
                else
                    tmpColCnt := colCnt + 1;
                    if tmpColCnt < imgHeight + (filterSize - 1)/2 then
                        nColCnt <= tmpColCnt;                   
                        if tmpColCnt < imgHeight then
                            if tmpColCnt = (filterSize - 1)/2 then
                                nRowDataCollectedS <= '1';
                            end if;
                            nFilterMuxCtrlS <= '0';
                        else
                            nFilterMuxCtrlS <= '1';
                            nRowDataCollectedS <= '1';
                            if tmpColCnt = imgHeight then
                                nframeEnd <= '1';  
                            end if;
                        end if;
                    else 
                        tmpColCnt := (others => '0');
                        nColCnt <= frameResetHandler.counterResetVal;
                        nFilterMuxCtrlS <= '0';
                        nPostFrameEnd <= '1';
                    end if; 
                    nRowCnt <= (others => '0');
                    nRowFull <= '1';
                    nzeroFlushS <= '1';
                    nADDRAS <= (others => '0');
                    nADDRBS <= std_logic_vector(to_unsigned(addrOffset, ADDRBS'length));  
                end if;
            when sWait =>
                if tmpRowCnt = (filterSize - 1)/2 then
                    nshifterFlushS <= '1';     
                end if;
                nFrameEnd <= '0';
                nPostFrameEnd <= '0';
            when others =>    
        end case; 
    end if;
    end process;
    
    ClkCtrlStateData : process (clkCtrlState, nPostFrameEnd, FRST, intRST, rowBufferPhase, frameEnd,
                         nRowFull, RSTAS, RSTBS, nFrameEnd)
    begin
        if FRST = '1' or intRST = '1'  then
            nRowBufferPhase     <= pA;
            nCtrlEnOut          <= '0'; 
            enLatch             <= '0';
            WEA                 <= '0';
            WEB                 <= '0';    
            nRSTAS              <= '1';
            nRSTBS              <= '1';
            RSTA                <= '1';
            RSTB                <= '1';
            filterCtrl          <= '0';              
        else
            nRowBufferPhase     <= rowBufferPhase;
            nCtrlEnOut          <= '0';
            WEA                 <= '0';
            WEB                 <= '0';
            nRSTAS              <= RSTAS;
            nRSTBS              <= RSTBS;           
            RSTA                <= RSTAS;
            RSTB                <= RSTBS;
            filterCtrl          <= '0'; 
            case clkCtrlState is
                when sFetch =>
                    enLatch <= '1';
                    filterCtrl <= '1'; 
                    if nRowFull = '1' then  -- TODO: rename signal (next prefix is confusing)
                        if nPostFrameEnd = '1' then
                            nRowBufferPhase <= frameResetHandler.resetState;
                            enLatch <= '0'; 
                        elsif nFrameEnd = '1' then
                            nRowBufferPhase <= frameResetHandler.transitionState;       
                        else                       
                            case rowBufferPhase is
                                when pA =>
                                    nRowBufferPhase <= pAB;
                                when pAB => 
                                    nRowBufferPhase <= pABC;
                                when pNotA =>
                                    nRowBufferPhase <= pNotAB;
                                when pNotAB =>
                                    nRowBufferPhase <= pNotABC;                                    
                                when others =>
                             end case;
                         end if;
                     end if;
                    case rowBufferPhase is
                        when pA =>
                            WEA <= '1';
                            WEB <= '0';
                        when pAB =>
                            WEA <= '1';
                            WEB <= '1';
                        when pABC => 
                            WEA <= '1';
                            WEB <= '1';
                        when others =>
                            WEA <= '1';
                            WEB <= '1';                       
                     end case;
                when sIdle =>
                    if rowBufferPhase = pABC then
                        nCtrlEnOut <= '1';
                    else 
                        nCtrlEnOut <= '0';
                    end if;     -- TODO: add counter to prevent errors while unexpected errr occurs                     
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
                        when pNotA =>
                            nRSTAS <= '0';
                            nRSTBS <= '0';
                        when pNotAB =>
                            nRSTAS <= '1';
                            nRSTBS <= '0';
                        when pNotABC =>
                            nRSTAS <= '1';
                            nRSTBS <= '1';                                                                                                              
                     end case;
                when others =>
            end case;
        end if;
    end process;
    
end Behavioral;