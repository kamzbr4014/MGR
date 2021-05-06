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
    end component;
    
    signal   CLK          :  STD_LOGIC := '0';
    signal   EN           : STD_LOGIC := '0';
    signal   FRST         : STD_LOGIC := '0';
    signal   cntIn        : STD_LOGIC_VECTOR (9 downto 0) := (others => '0');
    signal   nCtrlEnIn    : STD_LOGIC := '0';
    signal   WEA          : STD_LOGIC := '0';
    signal   WEB          : STD_LOGIC := '0';
    signal   RSTA         : STD_LOGIC := '0';
    signal   RSTB         : STD_LOGIC := '0';
    signal   cntOut       : STD_LOGIC_VECTOR (9 downto 0) := (others => '0');
    signal   FRSTOut      : STD_LOGIC := '0';
    signal   nCtrlEnOut   : STD_LOGIC := '0';
    constant pixCLKPeriod     : time := 10 ns;
    
begin
    CLKSim : process
    begin
        CLK <= '0';
        wait for pixCLKPeriod / 2;
        CLK <= '1';
        wait for pixCLKPeriod / 2;
    end process;
    
    dataRdyStim : process
    begin
        wait for pixCLKPeriod;
        for i in 0 to 10 loop
            wait until rising_edge(CLK);
            EN <= not EN;  
        end loop;
    end process;

    uut : BRAM_ctrl_logic
        port map (CLK => CLK,
                  EN => EN,
                  FRST => FRST,
                  cntIn => cntIn,
                  nCtrlEnIn => nCtrlEnIn,
                  WEA => WEA,
                  WEB => WEB,
                  RSTA => RSTA,
                  RSTB => RSTB,
                  cntOut => cntOut,
                  FRSTOut => FRSTOut,
                  nCtrlEnOut => nCtrlEnOut);
                 
end Behavioral;
