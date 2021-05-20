----------------------------------------------------------------------------------
-- Company: Wroclaw University of Science and Technology 
-- Engineer: Kamil Zbroinski
-- 
-- Create Date: 15.05.2021 12:05:50
-- Design Name: BRAM_TDP_module
-- Module Name: BRAM_TDP_module - Behavioral
-- Project Name: Master thesis project 
-- Target Devices: Basys3
-- Tool Versions: Vivado 2020.2
-- Description: Modyfied design from xilinx example (ug901)
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

entity BRAM_TDP_RF_module is
    Generic (BRAMSize        : integer := 2048);                 
    Port ( CLKA : in std_logic;
        CLKB    : in std_logic;
        ENA     : in std_logic;
        ENB     : in std_logic;
        WEA     : in std_logic;
        WEB     : in std_logic;
        RSTA    : in std_logic;
        RSTB    : in std_logic;
        ADDRA   : in std_logic_vector(10 downto 0);
        ADDRB   : in std_logic_vector(10 downto 0);
        DIA     : in std_logic_vector(7 downto 0);
        DIB     : in std_logic_vector(7 downto 0);
        DOA     : out std_logic_vector(7 downto 0);
        DOB     : out std_logic_vector(7 downto 0));
end BRAM_TDP_RF_module;

architecture Behavioral of BRAM_TDP_RF_module is
    
    type ram_type is array (BRAMSize - 1 downto 0) of std_logic_vector(7 downto 0);
    shared variable RAM : ram_type;
    attribute ramStyle : string;
    attribute ramStyle of RAM : variable is "block";
begin
    process(CLKA)
    begin
        if rising_edge(CLKA) then
            if ENA = '1' then
                if RSTA = '1' then
                    DOA <= (others => '0');    
                else
                    DOA <= RAM(to_integer(unsigned(ADDRA)));
                end if;
                if WEA = '1' then
                    RAM(to_integer(unsigned(ADDRA))) := DIA;
                end if;
            end if;
        end if;
    end process;
    process(CLKB)
    begin
        if rising_edge(CLKB) then
            if ENB = '1' then
                if RSTB = '1' then
                    DOB <= (others => '0');
                else
                    DOB <= RAM(to_integer(unsigned(ADDRB)));
                end if;    
                if WEB = '1' then
                    RAM(to_integer(unsigned(ADDRB))) := DIB;
                end if;
            end if;
        end if;
    end process;
end Behavioral;