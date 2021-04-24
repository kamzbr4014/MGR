----------------------------------------------------------------------------------
-- Company: Wroclaw University of Science and Technology 
-- Engineer: Kamil Zbroinski
-- 
-- Create Date: 24.04.2021 23:03:36
-- Design Name: Dci and preprocessing block design tb
-- Module Name: dci_preprocessing_bd_tb - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dci_preprocessing_bd_tb is 
end dci_preprocessing_bd_tb;


architecture Behavioral of dci_preprocessing_bd_tb is
    component dci_preprocessing is
        port ( dataOut       : out STD_LOGIC_VECTOR (7 downto 0);
          dataReadyOut  : out STD_LOGIC;
          dciData       : in STD_LOGIC_VECTOR (7 downto 0);
          hSync         : in STD_LOGIC;
          mainCLK       : in STD_LOGIC;
          pixCLK        : in STD_LOGIC;
          vSync         : in STD_LOGIC);
          
    end component dci_preprocessing;

    type colorArray is array (2 downto 0) of STD_LOGIC_VECTOR (7 downto 0);
    
    signal dataOut      : STD_LOGIC_VECTOR (7 downto 0);
    signal dataReadyOut : STD_LOGIC;
    signal dciData      : STD_LOGIC_VECTOR (7 downto 0);
    signal hSync        : STD_LOGIC;
    signal mainCLK      : STD_LOGIC;
    signal pixCLK       : STD_LOGIC;
    signal vSync        : STD_LOGIC;
    signal cArray       : colorArray;
    signal vFlag        : STD_LOGIC := '0';
    
    constant filePath   : string := "../../../../../matlab/gen/test_pattern_1_dat.txt";
                
begin
    DataReader : process 
        file textFile           : text;
        variable textLine       : line;
        variable readDciData    : std_logic_vector(7 downto 0) := (others => '0');
        variable readValRGB     : colorArray;
        variable readHSync      : std_logic := '0';
        variable readVSync      : std_logic := '0';
        variable readVFlag      : std_logic := '0';
        variable readSucess     : boolean;
        variable spaceChar      : character;
    begin
        file_open(textFile, filePath, read_mode);
        while not endfile(textFile) loop
            readline(textFile, textLine);
            if textLine.all'length = 0 then
                next;
            end if;
            
            hread(textLine, readDciData, readSucess);
            assert readSucess
                severity failure;                
            read(textLine, readHSync, readSucess);
            assert readSucess
                severity failure;                        
            read(textLine, readVSync, readSucess);
            assert readSucess
                severity failure;
            read(textLine, readVFlag, readSucess);
            assert readSucess
                severity failure;
            hread(textLine, readValRGB(2), readSucess);
            assert readSucess
                severity failure;
            hread(textLine, readValRGB(1), readSucess);
            assert readSucess
                severity failure;
            hread(textLine, readValRGB(0), readSucess);
            assert readSucess
                severity failure;        
            
            dciData <= readDciData;
            hSync <= readHSync;
            vSync <= readVSync;
            cArray <= readValRGB;   
            vFlag <= readVFlag;
            wait until rising_edge(pixCLK);
        end loop;
        
        file_close(textFile);
        report "Read done";
        wait;
    
    end process;
    
    MainCLKStim : process
    begin
         mainCLK <= '0';
         wait for 10.0 ns;
         mainCLK <= '1';
         wait for 10.0 ns;
    end process;
    
    PixCLKStim : process
    begin
          pixCLK <= '0';
          wait for 50.0 ns;
          pixCLK <= '1';
          wait for 50.0 ns;
    end process;
    
    uut: component dci_preprocessing 
        port map ( dataOut => dataOut,
              dataReadyOut => dataReadyOut,
              dciData => dciData,
              hSync => hSync,
              mainCLK => mainCLK,
              pixCLK => pixCLK,
              vSync => vSync);

end Behavioral;