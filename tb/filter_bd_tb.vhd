----------------------------------------------------------------------------------
-- Company: Wroclaw University of Science and Technology 
-- Engineer: Kamil Zbroinski
-- 
-- Create Date: 20.05.2021 10:01:32
-- Design Name: filter block design testbench
-- Module Name: filter_bd_tb - Behavioral
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

entity test_filter_bd is 
end test_filter_bd;


architecture TB of test_filter_bd is

    component filter_bd is
    port (
        FilterOut : out STD_LOGIC_VECTOR (7 downto 0);
        RST : in STD_LOGIC;
        dbgFCtrl : out STD_LOGIC;
        dciData : in STD_LOGIC_VECTOR (7 downto 0);
        hSync : in STD_LOGIC;
        mainCLK : in STD_LOGIC;
        pixCLK : in STD_LOGIC;
        vSync : in STD_LOGIC
    );
    end component filter_bd;

    type colorArray is array (2 downto 0) of STD_LOGIC_VECTOR (7 downto 0);
    signal FilterOut : STD_LOGIC_VECTOR (7 downto 0);
    signal RST : STD_LOGIC;
    signal dciData : STD_LOGIC_VECTOR (7 downto 0);
    signal hSync : STD_LOGIC;
    signal dbgFCtrl: std_logic;
    signal mainCLK : STD_LOGIC;
    signal pixCLK : STD_LOGIC;
    signal vSync : STD_LOGIC;
    signal dataOut      : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal dataReadyOut : STD_LOGIC := '0';
    signal cArray       : colorArray;
    signal vFlag        : STD_LOGIC := '0';
    constant W : integer := 5;
    constant pixCLKPeriod : time := 10 ns;
    constant mainCLKPeriod : time := 5 ns;
    constant dataFilePathTs  : string  := "../../../../../../matlab/gen/test_pattern_1_dat.txt";
    constant dataFilePath    : string  := "../../../../../matlab/gen/test_pattern_1_dat.txt";
    constant resFilePath     : string  := "../../../../../tb/res/test_pattern_1_res.txt";  
begin

    DUT: component filter_bd 
        port map (FilterOut => FilterOut,
            RST => RST,
            dbgFCtrl => dbgFCtrl,
            dciData => dciData,
            hSync => hSync,
            mainCLK => mainCLK,
            pixCLK => pixCLK,
            vSync => vSync
    );

    MainCLKStim : process
    begin
        mainCLK <= '0';
        wait for mainCLKPeriod / 2;
        mainCLK <= '1';
        wait for mainCLKPeriod / 2;
    end process;

    PixCLKStim : process
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
        file_open(textFile, dataFilePath, read_mode);
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
        report "---------- Read done ----------";
        wait;
    
    end process;
    
    WriteResults : process
        file simRes : text;
        variable flagCount : integer := 0; 
        variable tmp : std_logic_vector(7 downto 0) := x"FF";
        variable oLine  : line;
    begin
        file_open(simRes, resFilePath, write_mode);
        wait until dbgFCtrl = '1'; -- hardcoded wait for filter processing 
        while true loop
            wait until rising_edge(pixCLK);
            if flagCount < 10 then
                flagCount := flagCount + 1;
                if dbgFCtrl = '1' then
                    hwrite(oLine, FilterOut, right, 2);
                    writeline(simRes, oLine);
                    flagCount := 0;    
                end if; 
             else
                exit;
             end if;   
        end loop;
        for i in 0 to (W - 1)/2 - 1 loop        --frame end simulation (in continious mode this loop should be unnecessery)
            hwrite(oLine, FilterOut, right, 2);
            writeline(simRes, oLine);            
        end loop;
        file_close(simRes);
        report "---------- Write done ----------";
        assert false report "Test: OK" severity failure;
    end process;

end TB;