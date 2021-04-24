----------------------------------------------------------------------------------
-- Company: Wroclaw University of Science and Technology 
-- Engineer: Kamil Zbroinski
-- 
-- Create Date: 17.04.2021 11:43:25
-- Design Name: Digital Camera Interface Module - TB
-- Module Name: dci_module_tb - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dci_module_tb is
--  Port ( );
end dci_module_tb;

architecture Behavioral of dci_module_tb is
    component dci_module
        Port ( pixCLK   :   in  STD_LOGIC;
               mainCLK  :   in  STD_LOGIC;
               hSync    :   in  STD_LOGIC;
               vSync    :   in  STD_LOGIC;
               dciData  :   in  STD_LOGIC_VECTOR (7 downto 0);
               rOut     :   out STD_LOGIC_VECTOR (7 downto 0);
               gOut     :   out STD_LOGIC_VECTOR (7 downto 0);
               bOut     :   out STD_LOGIC_VECTOR (7 downto 0));
               
    end component;
    
    constant ASSERTION_TEST : boolean := false;
    type colorArray is array (2 downto 0) of STD_LOGIC_VECTOR (7 downto 0);
    
    signal pixCLK   : STD_LOGIC := '0';  
    signal mainCLK  : STD_LOGIC := '0';          
    signal hSync    : STD_LOGIC := '0';
    signal vSync    : STD_LOGIC := '0';
    signal dciData  : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal rOut     : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal gOut     : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal bOut     : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
 
    signal cArray   : colorArray;
    signal vFlag    : STD_LOGIC := '0';
 
    constant mainCLKPeriod  : time := 1 ns;
    constant pixCLKPeriod   : time := 10 ns;
    constant filePath       : string := "../../../../../matlab/gen/test_pattern_1_dat.txt";
begin
    MainCLKSim : process
    begin
        mainCLK <= '0';
        wait for mainCLKPeriod / 2;
        mainCLK <= '1';
        wait for mainCLKPeriod / 2;
    end process;

    PixCLKSim : process
    begin
        pixCLK <= '0';
        wait for pixCLKPeriod / 2;
        pixCLK <= '1';
        wait for pixCLKPeriod / 2;
    end process;
   
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
    
    AS : if ASSERTION_TEST generate
        ValidColorSplit : process
        begin
            -- add valid color split test
        end process;
    end generate;
       
    uut: dci_module port map(pixCLK => pixCLK,
        mainCLK => mainCLK,
        hSync => hSync,
        vSync => vSync,
        dciData => dciData,
        rOut => rOut,
        bOut => bOut,
        gOut => gOut);

end Behavioral;