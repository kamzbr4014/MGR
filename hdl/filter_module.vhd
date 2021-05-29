----------------------------------------------------------------------------------
-- Company: Wroclaw University of Science and Technology 
-- Engineer: Kamil Zbroinski
-- 
-- Create Date: 03.05.2021 19:19:16
-- Design Name: Filter module
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
use IEEE.std_logic_textio.all, std.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

use work.ramPKG.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity filter_module is
  Generic (W            : integer := 3;
           imgWidth     : integer := 640;
           imgHeight    : integer := 480);
  Port (pixCLK  : in std_logic;
        RST     : in std_logic;
        dataRdy : in std_logic;
        dbgFCtrl: out std_logic;
        dataIn  : in std_logic_vector(7 downto 0);
        dataOut : out std_logic_vector(7 downto 0));
end filter_module;

architecture Behavioral of filter_module is
   
    constant numOfBRAMs         : integer := ((W - 1) / 2) - 1;
    constant numOfBRAMPorts     : integer := ((W - 1) * 2) - 1;
    type addrBus_t              is array(numOfBRAMPorts downto 0) of std_logic_vector(10 downto 0);
    type coeffsRow_t            is array(W - 1 downto 0) of  std_logic_vector(7 downto 0);
    type coeffsArray_t          is array(W - 1 downto 0) of  coeffsRow_t;
    type stdSignalarr_t         is array(numOfBRAMPorts downto 0) of std_logic;
    type directShifterRow_t     is array(W - 1 downto 0) of std_logic_vector(7 downto 0);
    type directShifterArray_t   is array(W - 1 downto 0) of directShifterRow_t;
    type postMultRow_t          is array(W - 1 downto 0) of unsigned(15 downto 0);
    type postAdderRow_t         is array(W - 1 downto 0) of unsigned(15 downto 0);
    type postMultArray_t        is array(W - 1 downto 0) of postMultRow_t;
    type postAdderArray_t       is array(W - 1 downto 0) of postAdderRow_t;
    type filterInputs_t         is array(W - 1 downto 0) of std_logic_vector(7 downto 0);
    type filterInputsRST_t      is array(W - 1 downto 0) of std_logic;    
    type FlushShifterRow_t      is array((W - 1)/2 - 1 downto 0) of std_logic_vector(7 downto 0);
    type FlushShifter_t         is array(W - 1 downto 0) of FlushShifterRow_t;
    type adderRes_t is array(W - 1 downto 0) of unsigned(15 downto 0);
    
    signal ADDRA                :  addrBus_t := (others => (others => '0'));
    signal ADDRB                :  addrBus_t := (others => (others => '0'));
    signal dataRdys             : STD_LOGIC := '0';
    signal EN                   : stdSignalarr_t := (others => '0');
    signal FRST                 : STD_LOGIC := '0';
    signal nCtrlEnIn            : STD_LOGIC := '0';
    signal WEA                  : stdSignalarr_t := (others => '0');
    signal WEB                  : stdSignalarr_t := (others => '0');
    signal RSTA                 : stdSignalarr_t := (others => '0');
    signal RSTB                 : stdSignalarr_t := (others => '0');
    signal nCtrlEnOut           : stdSignalarr_t :=(others => '0');
    signal postMultArray        : postMultArray_t := (others => (others => (others => '0')));
    signal directShifterArray   : directShifterArray_t := (others => (others => (others => '0'))); -- TODO: take look at signal initialization
    signal filterInputs         : filterInputs_t;
    signal filterInputsRST      : filterInputsRST_t;
    signal filterCtrl           : std_logic := '0';
    signal shifterCtrl          : std_logic := '0';
    signal FlushShifter         : FlushShifter_t := (others => (others => (others => '0')));
    signal zeroFlush            : std_logic := '0';
    signal shifterFlush         : std_logic := '0';
    signal rowDataCollected     : std_logic := '0';
    signal colDataCollected     : std_logic := '0';
    signal postMultTrgg         : std_logic := '0';
    signal dbgFilterOut         : std_logic := '0';
    signal filterMuxCtrl        : std_logic := '0';
    signal adderSignals         :  postAdderArray_t := (others => (others => (others => '0')));  
    signal adderRes             : adderRes_t := (others => (others => '0'));
    
    impure function coeffsInit(filename : string) return coeffsArray_t is
        file  textFile          : text;
        variable textLine       : line;
        variable tmpData        : std_logic_vector(7 downto 0);
        variable tmpArr         : coeffsArray_t;
        variable readSucess     : boolean;
    begin
        file_open(textFile, filename, read_mode);
        for i in 0 to W - 1 loop
            for j in 0 to W - 1 loop
                readline(textFile, textLine);
                hread(textLine, tmpData);
                assert readSucess
                    report "jebane gowno dupa";
                tmpArr(i)(j) := tmpData;
            end loop;
        end loop;
        return tmpArr;
    end function;  
     
    constant coeffsFilePath : string := "../../../../../matlab/gen/filter_coeffs.txt";
    constant coeffsFilePathRTL : string := "../matlab/gen/filter_coeffs.txt";
    constant coeffsArray : coeffsArray_t := coeffsInit(filename => coeffsFilePathRTL);
     
    type adderTreeSignalNum_t is array(W downto 0) of natural;
    
    impure function getAdderTreeSignalNum                                      --signal number per tree stage
        return adderTreeSignalNum_t is   
            variable ws     : natural := ((W-1) / 2 + 1);                      -- start number of sum of roots to match  
            variable retTab : adderTreeSignalNum_t := (others => 0);
            variable tmp    : natural := 0;
    begin
    retTab(0) := ws;
    for i in 0 to W - 1 loop
        if ws - 1 >= 2 then
            tmp := natural(floor(real(((ws)/2))));                          -- find how many sum of roots are in this stage
            ws := tmp + (ws mod 2);                                         --
            retTab(i + 1) := ws;                                          
        else                                                                -- loop ends at n - 1 stages 
            retTab(i + 1) := 1;                                             -- so here last stage is assigned manualy
            exit;                                                           -- it is alwas a single sum of roots
        end if;
    end loop;
        return retTab;
    end function;
    
    impure function getAdderTreeStageOperations (                                   -- return count of operation all stages 
        table       : adderTreeSignalNum_t;                                         -- (sum and delay buffers)
        iterator    : natural) 
        return natural is
            variable retLoopSum : integer := 0;
    begin
    for i in 0 to iterator loop
        retLoopsum := retLoopsum + table(i);
    end loop;
    return retLoopSum;
    end function;
    
    impure function getAdderTreeStages                                           -- return count of tree adder sum stages
        return natural is 
            variable ws        : natural := ((W-1) / 2 + 1);   
            variable retStages : natural := ws;
            variable tmp       : natural := 0;
    begin
    for i in 0 to W loop
        if ws - 1 >= 2 then
            tmp := natural(floor(real(((ws)/2))));                     
            ws := tmp + (ws mod 2);  
        else
            retStages := i + 1; 
            exit;   
        end if;
    end loop;
    return retStages;
    end function;
    
    function getSum(                                                            -- return sum of all stages operation to given moment 'index'
        table : adderTreeSignalNum_t;                                           -- use for calculate proper index in tree
        index : integer)
        return integer is
            variable tmpSum : integer := 0;
            variable iterator : integer;
    begin
        if index = 0 then
            tmpSum := 0;
        else
            for i in 0 to index - 1 loop
                tmpSum := tmpSum + table(i);    
            end loop;
        end if;  
        return tmpSum;
    end function;
    
    constant aTStages : natural :=  getAdderTreeStages;
    constant aTSignalNum : adderTreeSignalNum_t := getAdderTreeSignalNum;
    constant aTStageOpe : natural :=  getAdderTreeStageOperations(aTSignalNum, aTStages);
    type adderTree_t is array(aTStageOpe - 1 downto 0) of unsigned(15 downto 0);
    type preAdderTree_t is array(W - 1 downto 0) of adderTree_t;
    signal adderTree : adderTree_t := (others => (others => '0'));
    signal preAdderTree : preAdderTree_t := (others => (others => (others => '0')));

begin
    shifterCtrlProc : process(pixClk, dataRdy, rowDataCollected)
    begin
        if rising_edge(pixCLK) then
            if dataRdy = '1' and rowDataCollected = '1' then -- maybe we should move collecteddata flag to filter ctrl
                shifterCtrl <= not shifterCtrl;
            else
                shifterCtrl <= '0';        
            end if;
        end if;
    end process;
    
    filterCtrlProc : process(pixClk, shifterCtrl)
    begin
        if rising_edge(pixCLK) then
            if shifterCtrl = '1' and colDataCollected = '1' then
                filterCtrl <= not filterCtrl;
            else
                filterCtrl <= '0';        
            end if;
        end if;
    end process;
    ------- dbg Only ---------
    dbgFCtrl <= dbgFilterOut;
    
    MultPrcess : process(pixCLK, filterCtrl)
    begin
        if rising_edge(pixCLK) then
            if filterCtrl = '1' then
                postMultTrgg <= '1';
                for i in 0 to W - 1 loop
                    for j in 0 to W - 1 loop
                        postMultArray(i)(j) <= unsigned(coeffsArray(i)(j)) * unsigned(directShifterArray(i)(j));   
                    end loop;
                end loop; 
             else
                postMultTrgg <= '0';   
             end if;
        end if;
    end process;
    
    AdderProcess : process(pixCLK, postMultTrgg)
        variable dbgFilterOutLatch : std_logic := '0'; 
        variable dbgOutTmp : unsigned(15 downto 0) := (others => '0');
        variable dbgCounter: integer := 0;
        constant zeroSig : unsigned(15 downto 0) := (others => '0');          
    begin
        if rising_edge(pixCLK) then
            if postMultTrgg = '1' then
                for c in 0 to W - 1 loop    
                for m in 0 to aTStages loop    
                    for n in 0 to aTSignalNum(m) - 1 loop
                        if m = 0 then
                            if n < aTSignalNum(m) - 1 then
                                preAdderTree(c)(n) <= postMultArray(c)(n*2) + postMultArray(c)(n*2 + 1);
                            else
                                preAdderTree(c)(n) <= postMultArray(c)(W - 1);
                            end if;
                        else
                            if aTSignalNum(m - 1) mod 2 = 0 then 
                                preAdderTree(c)(n + getSum(aTSignalNum, m)) <= preAdderTree(c)(n*2 + getSum(aTSignalNum, m - 1)) 
                                                                      + preAdderTree(c)(n*2 + 1 + getSum(aTSignalNum, m - 1));
                            else
                                if n < aTSignalNum(m) - 1 then  
                                    preAdderTree(c)(n + getSum(aTSignalNum, m)) <= preAdderTree(c)(n*2 + getSum(aTSignalNum, m - 1)) 
                                                                          + preAdderTree(c)(n*2 + 1 + getSum(aTSignalNum, m - 1));
                                else
                                    preAdderTree(c)(n + getSum(aTSignalNum, m)) <= preAdderTree(c)(n*2 + getSum(aTSignalNum, m - 1)); 
                                end if;                                      
                            end if;
                        end if;    
                    end loop;
                end loop;
                end loop;
                   
                for m in 0 to aTStages loop    
                    for n in 0 to aTSignalNum(m) - 1 loop
                        if m = 0 then
                            if n < aTSignalNum(m) - 1 then
                                adderTree(n) <= preAdderTree(n*2)(aTStageOpe - 1) + preAdderTree(n*2 + 1)(aTStageOpe - 1);
                            else
                                adderTree(n) <= preAdderTree(n*2)(aTStageOpe - 1);
                            end if;
                        else
                            if aTSignalNum(m - 1) mod 2 = 0 then 
                                adderTree(n + getSum(aTSignalNum, m)) <= adderTree(n*2 + getSum(aTSignalNum, m - 1)) 
                                                                      + adderTree(n*2 + 1 + getSum(aTSignalNum, m - 1));
                            else
                                if n < aTSignalNum(m) - 1 then  
                                    adderTree(n + getSum(aTSignalNum, m)) <= adderTree(n*2 + getSum(aTSignalNum, m - 1)) 
                                                                          + adderTree(n*2 + 1 + getSum(aTSignalNum, m - 1));
                                else
                                    adderTree(n + getSum(aTSignalNum, m)) <= adderTree(n*2 + getSum(aTSignalNum, m - 1)); 
                                end if;                                      
                            end if;
                        end if;    
                    end loop;
                end loop;
                
                dbgCounter := dbgCounter + 1;
                if dbgCounter < 2*(aTStages + 1)  then      -- refactor needed
                else
                   dbgFilterOut <= '1'; 
                end if; 
            else
                dbgFilterOut <= '0';
            end if;
        end if;
    end process;
    dataOut <= std_logic_vector(adderTree(adderTree'high)(15 downto 8));
    
    filterInputs(0) <= dataIn;
    DirectShifter : process(pixCLK, shifterCtrl)
    begin
        if rising_edge(pixCLK) then
            if shifterCtrl = '1' then
                FlushShifterLoopRow : for i in 0 to  W - 1 loop
                    FlushShifterLoopCol : for j in 0 to  FlushShifterRow_t'length - 1 loop
                        if j = 0 then 
                            FlushShifter(i)(j) <= filterInputs(i);    
                        else
                            FlushShifter(i)(j) <= FlushShifter(i)(j - 1);
                        end if;
                    end loop;
                end loop;  
                shifterLoopRow : for i in 0 to W - 1 loop
                    shifterLoopCol : for j in 0 to W - 1 loop
                        if j = 0 then
                            if filterInputsRST(i) = '1' then
                                directShifterArray(i)(j) <= (others => '0');
                            else
                                if zeroFlush = '1' then
                                    directShifterArray(i)(j) <= (others => '0'); 
                                else
                                    directShifterArray(i)(j) <= filterInputs(i);
                                end if;           
                            end if;
                        elsif j > 0 and j <= (W - 1)/2 then                      
                            if filterInputsRST(i) = '1' then
                                directShifterArray(i)(j) <=  (others => '0');
                            else
                                if shifterFlush = '1' then
                                    directShifterArray(i)(j) <= FlushShifter(i)(j - 1);
                                else
                                    directShifterArray(i)(j) <=  directShifterArray(i)(j - 1);
                                end if;
                            end if;
                        elsif j > (W - 1)/2 then
                            if filterInputsRST(i) = '1' then
                                directShifterArray(i)(j) <=  (others => '0');
                            else
                                if shifterFlush = '1' then
                                    directShifterArray(i)(j) <= (others => '0');
                                else
                                    directShifterArray(i)(j) <=  directShifterArray(i)(j - 1);
                                end if;
                            end if;                             
                        else
                            if filterInputsRST(i) = '1' then
                                directShifterArray(i)(j) <=  (others => '0');
                            else
                                directShifterArray(i)(j) <=  directShifterArray(i)(j - 1);                          
                            end if;                                
                        end if;
                    end loop shifterLoopCol;
                end loop shifterLoopRow;
            end if;
        end if;
    end process;
    
    FirstRowInputsRST : process(pixCLK, dataRdy, FRST, filterMuxCtrl)
    begin
        if rising_edge(pixCLK) then
            if FRST = '1' then
                filterInputsRST(0) <= '1';
            else
--                if dataRdy = '1' then
--                   filterInputsRST(0) <= '0'; 
                if filterMuxCtrl = '1' then
                   filterInputsRST(0) <= '1'; 
                else
                   filterInputsRST(0) <= '0';     
                end if;
            end if;
        end if;
    end process; 

    BRAMGen : for i in 0 to numOfBRAMs generate
        BRAM0 : if i = 0 generate
            BRAM : BRAM_TDP_RF_module
                       port map (
                          DOA => filterInputs(i*2 + 1),      
                          DOB => filterInputs(i*2 + 2),      
                          ADDRA => ADDRA(i),   
                          ADDRB => ADDRB(i),   
                          CLKA => pixCLK,     
                          CLKB => pixCLK,     
                          DIA => dataIn,       
                          DIB => filterInputs(i*2 + 1),       
                          ENA => '1',       
                          ENB => '1',       
                          RSTA => '0',     
                          RSTB => '0',     
                          WEA => WEA(i),      
                          WEB => WEB(i));            
        end generate BRAM0;
        BRAMN : if i > 0 generate
            BRAM : BRAM_TDP_RF_module
                       port map (
                          DOA => filterInputs(i*2 + 1),       
                          DOB => filterInputs(i*2 + 2),      
                          ADDRA => ADDRA(i),   
                          ADDRB => ADDRB(i),   
                          CLKA => pixCLK,     
                          CLKB => pixCLK,     
                          DIA => filterInputs(i*2),       
                          DIB => filterInputs(i*2 + 1),       
                          ENA => '1',       
                          ENB => '1',       
                          RSTA => '0',     
                          RSTB => '0',     
                          WEA => WEA(i),      
                          WEB => WEB(i));    
        end generate BRAMN; 
    end generate BRAMGen;

    BRAMCtrlGen : for i in 0 to numOfBRAMs generate
            BRAMctrl0 : if i = 0 generate
                BRAMctrl : BRAM_ctrl_logic
                        generic map ( filterSize => W,
                          index => i, 
                          imgWidth => imgWidth,
                          imgHeight => imgHeight - 2*i)
                        port map (CLK => pixCLK,
                          EN => '1',
                          dataRdy => dataRdy,
                          FRST => RST,
                          FRSTO => FRST,
                          filterCtrl => open,
                          filterMuxCtrl => filterMuxCtrl,
                          WEA => WEA(i),
                          WEB => WEB(i),
                          RSTA => filterInputsRST(i*2 + 1),
                          RSTB => filterInputsRST(i*2 + 2),
                          ADDRA => ADDRA(i),
                          ADDRB => ADDRB(i),
                          zeroFlush => zeroFlush,
                          shifterFlush => shifterFlush,
                          rowDataCollected => rowDataCollected,
                          colDataCollected => colDataCollected,
                          nCtrlEnOut => nCtrlEnOut(i));
            end generate BRAMctrl0;
            BRAMctrlN : if i > 0 generate
                BRAMctrl : BRAM_ctrl_logic
                        generic map ( filterSize => W,
                          index => i, 
                          imgWidth => imgWidth,
                          imgHeight => imgHeight)                
                        port map (CLK => pixCLK,
                          EN => nCtrlEnOut(i - 1),
                          dataRdy => dataRdy,
                          FRST => FRST,
                          FRSTO => open,
                          filterCtrl => open,
                          filterMuxCtrl => open,
                          WEA => WEA(i),
                          WEB => WEB(i),
                          RSTA => filterInputsRST(i*2 + 1),
                          RSTB => filterInputsRST(i*2 + 2),
                          ADDRA => ADDRA(i),
                          ADDRB => ADDRB(i), 
                          zeroFlush => open,
                          shifterFlush => open,
                          rowDataCollected => open,  
                          colDataCollected => open,                       
                          nCtrlEnOut => nCtrlEnOut(i));            
            end generate BRAMctrlN;
        end generate BRAMCtrlGen;              
end Behavioral;