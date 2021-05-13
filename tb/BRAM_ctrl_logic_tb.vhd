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

entity BRAM_ctrl_logic_tb is
--  Port ( );
end BRAM_ctrl_logic_tb;

architecture Behavioral of BRAM_ctrl_logic_tb is
    component BRAM_ctrl_logic
        Generic ( isMaster  : boolean := false;
                  imgWidth  : integer := 10;
                  imgHeight : integer := 10);
        Port ( CLK          : in STD_LOGIC;
               EN           : in STD_LOGIC;
               dataRdy      : in STD_LOGIC;
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
    end component;
    
    constant H : integer := 5;
    constant imgWidth : integer := 10;
    constant imgHeight : integer := 10;
    type stdSignalarr_t     is array ((H - 1 / 2) - 1 downto 0) of std_logic;
    type stdVectSignalarr_t is array ((H - 1 / 2) - 1 downto 0) of std_logic_vector(7 downto 0);
    signal   CLK          : STD_LOGIC := '0';
    signal   dataRdy      : STD_LOGIC := '0';
    signal   EN           : stdSignalarr_t := (others => '0');
    signal   FRST         : STD_LOGIC := '0';
    signal   cntIn        : STD_LOGIC_VECTOR (9 downto 0) := (others => '0');
    signal   nCtrlEnIn    : STD_LOGIC := '0';
    signal   WEA          : stdSignalarr_t := (others => '0');
    signal   WEB          : stdSignalarr_t := (others => '0');
    signal   RSTA         : stdSignalarr_t := (others => '0');
    signal   RSTB         : stdSignalarr_t := (others => '0');
    signal   cntOut       : STD_LOGIC_VECTOR (9 downto 0) := (others => '0');
    signal   FRSTOut      : STD_LOGIC := '0';
    signal   nCtrlEnOut   : stdSignalarr_t :=(others => '0');
    constant pixCLKPeriod     : time := 10 ns;
    
begin
    CLKSim : process
    begin
        CLK <= '0';
        wait for pixCLKPeriod / 2;
        CLK <= '1';
        wait for pixCLKPeriod / 2;
    end process;
    
--    EN <= '1';--, '0' after pixCLKPeriod;
    
    dataRdyStim : process
    begin
--        wait for pixCLKPeriod;
        for j in 0 to imgHeight loop
            for i in 0 to (imgWidth*2) - 1 loop
                wait until rising_edge(CLK);
                dataRdy <= not dataRdy;  
            end loop;
            dataRdy <= '0';
            wait for 2*pixCLKPeriod;
        end loop;
        wait;
    end process;

    uutGen : for i in 0 to ((H - 1) / 2)-1 generate
        master : if i = 0 generate
                uut0 : BRAM_ctrl_logic
                    port map (CLK => CLK,
                      EN => '1',
                      dataRdy => dataRdy,
                      FRST => FRST,
                      cntIn => cntIn,
                      nCtrlEnIn => nCtrlEnIn,
                      WEA => WEA(i),
                      WEB => WEB(i),
                      RSTA => RSTA(i),
                      RSTB => RSTB(i),
                      cntOut => cntOut,
                      FRSTOut => FRSTOut,
                      nCtrlEnOut => nCtrlEnOut(i));
        end generate master;
        slaves : if i > 0 generate
                uutX : BRAM_ctrl_logic
                    port map (CLK => CLK,
                      EN => nCtrlEnOut(i - 1),
                      dataRdy => dataRdy,
                      FRST => FRST,
                      cntIn => cntIn,
                      nCtrlEnIn => '1',
                      WEA => WEA(i),
                      WEB => WEB(i),
                      RSTA => RSTA(i),
                      RSTB => RSTB(i),
                      cntOut => cntOut,
                      FRSTOut => FRSTOut,
                      nCtrlEnOut => nCtrlEnOut(i));            
        end generate slaves;
    end generate uutGen;              
end Behavioral;
