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

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity filter_module is
  Generic (W            : integer := 3;
           imgWidth     : integer := 640;
           imgHeight    : integer := 480);
  Port (pixCLK  : in std_logic;
        RST     : in std_logic;
        dataIn  : in std_logic_vector(7 downto 0);
        dataOut : out std_logic_vector(7 downto 0));
end filter_module;

architecture Behavioral of filter_module is
    type dataIO_t is array(W - 2 downto 0) of std_logic_vector(7 downto 0);
    type addrBus_t is array(W - 2 downto 0) of std_logic_vector(10 downto 0);
    type wEN_t is array(W - 2 downto 0) of std_logic;
    
    signal DOA      :  dataIO_t := (others => x"00");
    signal DOB      :  dataIO_t := (others => x"00");
    signal DIA      :  dataIO_t := (others => x"00");
    signal DIB      :  dataIO_t := (others => x"00");
    signal ADDRA    :  addrBus_t := (others => "00000000000");
    signal ADDRB    :  addrBus_t := (others => "00000000000");
    signal WEA      :  wEN_t := (others => '0');
    signal WEB      :  wEN_t := (others => '0');
begin

    BRAMGeneratorLoop : for i in 0 to (W - 1) / 2 generate
        BRAMMacro : BRAM_TDP_MACRO
           generic map (
              BRAM_SIZE => "18Kb", -- Target BRAM, "18Kb" or "36Kb" 
              DEVICE => "7SERIES", -- Target Device: "VIRTEX5", "VIRTEX6", "7SERIES", "SPARTAN6" 
              DOA_REG => 0, -- Optional port A output register (0 or 1)
              DOB_REG => 0, -- Optional port B output register (0 or 1)
              INIT_A => X"000000000", -- Initial values on A output port
              INIT_B => X"000000000", -- Initial values on B output port
              INIT_FILE => "NONE",
              READ_WIDTH_A => 8,   -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
              READ_WIDTH_B => 8,   -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
              SIM_COLLISION_CHECK => "ALL", -- Collision check enable "ALL", "WARNING_ONLY", 
                                            -- "GENERATE_X_ONLY" or "NONE" 
              SRVAL_A => X"000000000",   -- Set/Reset value for A port output
              SRVAL_B => X"000000000",   -- Set/Reset value for B port output
              WRITE_MODE_A => "READ_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE" 
              WRITE_MODE_B => "READ_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE" 
              WRITE_WIDTH_A => 8, -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
              WRITE_WIDTH_B => 8, -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
              -- The following INIT_xx declarations specify the initial contents of the RAM
              INIT_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
              INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",

           port map (
              DOA => DOA(i),       -- Output port-A data, width defined by READ_WIDTH_A parameter
              DOB => DOB(i),       -- Output port-B data, width defined by READ_WIDTH_B parameter
              ADDRA => ADDRA(i),   -- Input port-A address, width defined by Port A depth
              ADDRB => ADDRB(i),   -- Input port-B address, width defined by Port B depth
              CLKA => pixCLK,     -- 1-bit input port-A clock
              CLKB => pixCLK,     -- 1-bit input port-B clock
              DIA => DIA(i),       -- Input port-A data, width defined by WRITE_WIDTH_A parameter
              DIB => DIB(i),       -- Input port-B data, width defined by WRITE_WIDTH_B parameter
              ENA => '1',       -- 1-bit input port-A enable
              ENB => '1',       -- 1-bit input port-B enable
              REGCEA => '1', -- 1-bit input port-A output register enable
              REGCEB => '1', -- 1-bit input port-B output register enable
              RSTA => '0',     -- 1-bit input port-A reset
              RSTB => '0',     -- 1-bit input port-B reset
              WEA => WEA(i),       -- Input port-A write enable, width defined by Port A depth
              WEB => WEB(i)        -- Input port-B write enable, width defined by Port B depth
           );
    end generate; 

end Behavioral;
