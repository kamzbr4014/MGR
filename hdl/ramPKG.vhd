----------------------------------------------------------------------------------
-- Company: Wroclaw University of Science and Technology 
-- Engineer: Kamil Zbroinski
-- 
-- Create Date: 15.05.2021 12:46:49
-- Design Name: ramPKG
-- Module Name: ramPKG - Behavioral
-- Project Name: Master thesis project 
-- Target Devices: Basys3
-- Tool Versions: Vivado 2020.2
-- Description: Used for direct filter module 
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

package RamPKG is
    component BRAM_ctrl_logic is
        Generic ( filterSize: integer := 5;
                index   : integer := 0;
                imgWidth    : integer := 640;
                imgHeight   : integer := 480);
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
    end component;
    component BRAM_TDP_RF_module
        Generic ( BRAMSize  : integer := 2048);      
        Port ( CLKA         : in std_logic;
               CLKB         : in std_logic;
               ENA          : in std_logic;
               ENB          : in std_logic;
               WEA          : in std_logic;
               WEB          : in std_logic;
               RSTA         : in std_logic;
               RSTB         : in std_logic;
               ADDRA        : in std_logic_vector(10 downto 0);
               ADDRB        : in std_logic_vector(10 downto 0);
               DIA          : in std_logic_vector(7 downto 0);
               DIB          : in std_logic_vector(7 downto 0);
               DOA          : out std_logic_vector(7 downto 0);
               DOB          : out std_logic_vector(7 downto 0));
        end component;      
end ramPKG;

package body ramPKG is
    -- none
end ramPKG;