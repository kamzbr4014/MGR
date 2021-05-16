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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

use work.ramPKG.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity filter_module is
  Generic (W            : integer := 5;
           imgWidth     : integer := 640;
           imgHeight    : integer := 480);
  Port (pixCLK  : in std_logic;
        RST     : in std_logic;
        dataRdy : in std_logic;
        dataIn  : in std_logic_vector(7 downto 0);
        dataOut : out std_logic_vector(7 downto 0));
end filter_module;

architecture Behavioral of filter_module is
   
    constant numOfBRAMs     : integer := ((W - 1) / 2) - 1;
    constant numOfBRAMPorts : integer := ((W - 1) * 2) - 1;
    type dataIO_t is array(numOfBRAMPorts downto 0) of std_logic_vector(7 downto 0);
    type addrBus_t is array(numOfBRAMPorts downto 0) of std_logic_vector(10 downto 0);
    subtype WEN_t is std_logic_vector(numOfBRAMPorts downto 0);
    type stdSignalarr_t     is array (numOfBRAMPorts downto 0) of std_logic;
    type stdVectSignalarr_t is array (numOfBRAMPorts downto 0) of std_logic_vector(7 downto 0);    
    signal DOA          :  dataIO_t := (others => x"00");
    signal DOB          :  dataIO_t := (others => x"00");
    signal DIA          :  dataIO_t := (others => x"00");
    signal DIB          :  dataIO_t := (others => x"00");
    signal ADDRA        :  addrBus_t := (others => (others => '0'));
    signal ADDRB        :  addrBus_t := (others => (others => '0'));
    signal dataRdys     : STD_LOGIC := '0';
    signal EN           : stdSignalarr_t := (others => '0');
    signal FRST         : STD_LOGIC := '0';
    signal cntIn        : STD_LOGIC_VECTOR (9 downto 0) := (others => '0');
    signal nCtrlEnIn    : STD_LOGIC := '0';
    signal WEA          : stdSignalarr_t := (others => '0');
    signal WEB          : stdSignalarr_t := (others => '0');
    signal RSTA         : stdSignalarr_t := (others => '0');
    signal RSTB         : stdSignalarr_t := (others => '0');
    signal cntOut       : STD_LOGIC_VECTOR (9 downto 0) := (others => '0');
    signal FRSTOut      : STD_LOGIC := '0';
    signal nCtrlEnOut   : stdSignalarr_t :=(others => '0');
    type directShifterRow_t is array(W - 1 downto 0) of std_logic_vector(7 downto 0);
    type directShifterArray_t is array (W - 1 downto 0) of directShifterRow_t;
    signal directShifterArray : directShifterArray_t;
    type filterInputs_t is array(W - 1 downto 0) of std_logic_vector(7 downto 0);
    signal filterInputs : filterInputs_t;  
begin
--------- process added only for generate design ---------
    process(pixCLK)
        variable sum : unsigned(7 downto 0);
    begin
        for i in 0 to W - 1 loop
            sum := sum + unsigned(directShifterArray(i)(W - 1));
        end loop;
        dataOut <= std_logic_vector(sum);
    end process;
----------------------------------------------------------
    DirectShifter : process(pixCLK)
    begin
        if rising_edge(pixCLK) then
            shifterLoopRow : for i in 0 to W - 1 loop
                shifterLoopCol : for j in 0 to W - 1 loop
                    if j = 0 then
                        directShifterArray(i)(j) <= filterInputs(i + (j * (W-1)));
                    else
                        directShifterArray(i)(j) <=  directShifterArray(i)(j - 1);   
                    end if;
                end loop shifterLoopCol;
            end loop shifterLoopRow;
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
                          RSTA => RSTA(i),     
                          RSTB => RSTB(i),     
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
                          RSTA => RSTA(i),     
                          RSTB => RSTB(i),     
                          WEA => WEA(i),      
                          WEB => WEB(i));    
        end generate BRAMN; 
    end generate BRAMGen;
    
    BRAMCtrlGen : for i in 0 to numOfBRAMs generate
            BRAMctrl0 : if i = 0 generate
                BRAMctrl : BRAM_ctrl_logic
                        port map (CLK => pixCLK,
                          EN => '1',
                          dataRdy => dataRdy,
                          FRST => FRST,
                          WEA => WEA(i),
                          WEB => WEB(i),
                          RSTA => RSTA(i),
                          RSTB => RSTB(i),
                          ADDRA => ADDRA(i),
                          ADDRB => ADDRB(i),
                          nCtrlEnOut => nCtrlEnOut(i));
            end generate BRAMctrl0;
            BRAMctrlN : if i > 0 generate
                BRAMctrl : BRAM_ctrl_logic
                        port map (CLK => pixCLK,
                          EN => nCtrlEnOut(i - 1),
                          dataRdy => dataRdy,
                          FRST => FRST,
                          WEA => WEA(i),
                          WEB => WEB(i),
                          RSTA => RSTA(i),
                          RSTB => RSTB(i),
                          ADDRA => ADDRA(i),
                          ADDRB => ADDRB(i),                          
                          nCtrlEnOut => nCtrlEnOut(i));            
            end generate BRAMctrlN;
        end generate BRAMCtrlGen;              
end Behavioral;