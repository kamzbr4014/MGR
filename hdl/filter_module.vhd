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
  Generic (W            : integer := 3;
           imgWidth     : integer := 640;
           imgHeight    : integer := 480);
  Port (pixCLK  : in std_logic;
        RST     : in std_logic;
        dataRdy : in std_logic;
        dataIn  : in std_logic_vector(7 downto 0);
        dataOut : out std_logic_vector(7 downto 0));
end filter_module;

architecture Behavioral of filter_module is
--    component BRAM_ctrl_logic is
--        Generic ( isMaster  : boolean := false;
--                  imgWidth  : integer := 640;
--                  imgHeight : integer := 480);
--        Port ( CLK          : in STD_LOGIC;
--               EN           : in STD_LOGIC;
--               dataRdy      : in STD_LOGIC;
--               FRST         : in STD_LOGIC;
--               WEA          : out STD_LOGIC;
--               WEB          : out STD_LOGIC;
--               RSTA         : out STD_LOGIC;
--               RSTB         : out STD_LOGIC;
--               nCtrlEnOut   : out STD_LOGIC;
--               ADDRA        : out STD_LOGIC_VECTOR(10 downto 0);
--               ADDRB        : out STD_LOGIC_VECTOR(10 downto 0));
--    end component;
    
    constant numOfBRAMs     : integer := (W - 1) / 2;
    constant numOfBRAMPorts : integer := ((W - 1) * 2) - 1;
    type dataIO_t is array(numOfBRAMPorts downto 0) of std_logic_vector(7 downto 0);
    type addrBus_t is array(numOfBRAMPorts downto 0) of std_logic_vector(10 downto 0);
    subtype WEN_t is std_logic_vector(numOfBRAMPorts downto 0);
    type stdSignalarr_t     is array (numOfBRAMPorts downto 0) of std_logic;
    type stdVectSignalarr_t is array (numOfBRAMPorts downto 0) of std_logic_vector(7 downto 0);    
    signal DOA      :  dataIO_t := (others => x"00");
    signal DOB      :  dataIO_t := (others => x"00");
    signal DIA      :  dataIO_t := (others => x"00");
    signal DIB      :  dataIO_t := (others => x"00");
    signal ADDRA    :  addrBus_t := (others => (others => '0'));
    signal ADDRB    :  addrBus_t := (others => (others => '0'));
    signal dataRdys      : STD_LOGIC := '0';
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
        
begin
   process(pixCLK)
    variable sum : unsigned(7 downto 0);
   begin
    sum := unsigned(DOA(0)) + unsigned(DOB(0));
    dataOut <= std_logic_vector(sum);
   end process;

    BRAM : BRAM_TDP_RF_module
               port map (
                  DOA => DOA(0),       
                  DOB => DOB(0),      
                  ADDRA => ADDRA(0),   
                  ADDRB => ADDRB(0),   
                  CLKA => pixCLK,     
                  CLKB => pixCLK,     
                  DIA => dataIn,       
                  DIB => DOA(0),       
                  ENA => '1',       
                  ENB => '1',       
                  RSTA => RSTA(0),     
                  RSTB => RSTB(0),     
                  WEA => WEA(0),      
                  WEB => WEB(0)       
               );
    ctrl0 : BRAM_ctrl_logic
               port map (CLK => pixCLK,
                  EN => '1',
                  dataRdy => dataRdy,
                  FRST => FRST,
                  WEA => WEA(0),
                  WEB => WEB(0),
                  RSTA => RSTA(0),
                  RSTB => RSTB(0),
                  ADDRA => ADDRA(0),
                  ADDRB => ADDRB(0),
                  nCtrlEnOut => nCtrlEnOut(0));          
--    BRAMCtrlGen : for i in 0 to numOfBRAMs generate
--            row0 : if i = 0 generate
--                    ctrl0 : BRAM_ctrl_logic
--                        port map (CLK => pixCLK,
--                          EN => '1',
--                          dataRdy => dataRdy,
--                          FRST => FRST,
--                          WEA => WEA(i),
--                          WEB => WEB(i),
--                          RSTA => RSTA(i),
--                          RSTB => RSTB(i),
--                          ADDRA => ADDRA(i),
--                          ADDRB => ADDRB(i),
--                          nCtrlEnOut => nCtrlEnOut(i));
--            end generate row0;
--            rowN : if i > 0 generate
--                    ctrlN : BRAM_ctrl_logic
--                        port map (CLK => pixCLK,
--                          EN => nCtrlEnOut(i - 1),
--                          dataRdy => dataRdy,
--                          FRST => FRST,
--                          WEA => WEA(i),
--                          WEB => WEB(i),
--                          RSTA => RSTA(i),
--                          RSTB => RSTB(i),
--                          ADDRA => ADDRA(i),
--                          ADDRB => ADDRB(i),                          
--                          nCtrlEnOut => nCtrlEnOut(i));            
--            end generate rowN;
--        end generate BRAMCtrlGen;              

end Behavioral;