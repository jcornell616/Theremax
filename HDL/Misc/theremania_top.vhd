----------------------------------------------------------------------------------
-- FILENAME: theremania_top.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 1/20/2022
--
-- DESCRIPTION: Top level entity for theremania FPGA application
--
-- ENITIES: theremania_top
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.user_pkg.all;

entity theremania_top is
	port (
        clk 	 : in std_logic;
		  sclk	 : in std_logic;
		  cs		 : in std_logic;
		  mosi	 : in std_logic;
		  miso	 : out std_logic;
		  TX		 : out std_logic;
		  HEX0    : out std_logic_vector(7 downto 0);
		  HEX1    : out std_logic_vector(7 downto 0);
		  HEX2    : out std_logic_vector(7 downto 0);
		  HEX3    : out std_logic_vector(7 downto 0);
		  HEX4    : out std_logic_vector(7 downto 0);
		  HEX5    : out std_logic_vector(7 downto 0)
	);
end theremania_top;

architecture STR of theremania_top is

	-- constants
	constant C0 : std_logic_vector(3 downto 0) := "0000";
	
	-- signals
	signal voltage1, voltage2			: std_logic_vector(BUFF_DATA_RANGE);
	signal pitch1, pitch2, pitch_out	: std_logic_vector(DATA_RANGE);
	signal buff_ld							: std_logic;
	
	signal key_out		: std_logic_vector(MIDI_RANGE); -- for testing
	signal magnitude	: std_logic_vector(TREE_OUT_RANGE); -- for testing

begin

	-- ADC driver
	U_ADC : entity work.ADC
	port map (
		  clk 	 	=> clk,
		  rst			=> '0',
		  buff_ld	=> buff_ld,
		  voltage1	=> voltage1,
		  voltage2	=> voltage2
	);
	
	-- Pitch detection
	U_PITCH_DET : entity work.pitch_det
	port map (
        clk 	=> clk,
		  rst		=> '0',
		  go		=> '1',
		  load	=> buff_ld,
		  input1	=> voltage1,
		  input2	=> voltage2,
		  pitch1	=> pitch1,
		  pitch2 => pitch2,
		  magnitude => magnitude -- for testing
	);
	
	-- SPI slave driver
	U_SPI : entity work.spi_driver
	port map (
        clk 	 => clk,
		  rst		 => '0',
		  go		 => '1',
		  sclk	 => sclk,
		  cs		 => cs,
		  mosi	 => mosi,
		  miso	 => miso,
		  data_in => pitch1(7 downto 0)
	);
	
	-- MIDI driver
	U_MIDI : entity work.midi
	port map (
        clk		=> clk,
		  rst		=> '0',
		  go		=> '1',
		  TX		=> TX,
		  pitch	=> pitch1,
		  key_out => key_out -- for testing
	);

	-- 7 segment decoders
	U_LED5 : entity work.decoder7seg
	port map (
		input		=> key_out(3 downto 0),
		output 	=> HEX0(6 DOWNTO 0)
	);
		
	U_LED4 : entity work.decoder7seg
	port map (
		input		=> key_out(7 downto 4),
		output 	=> HEX1(6 DOWNTO 0));
		
	U_LED3 : entity work.decoder7seg
	port map (
		input		=> pitch1(3 downto 0),
		output 	=> HEX2(6 DOWNTO 0)
	);
	
	U_LED2 : entity work.decoder7seg
	port map (
		input		=> pitch1(7 downto 4),
		output 	=> HEX3(6 DOWNTO 0)
	);
		
	U_LED1 : entity work.decoder7seg
	port map (
		input		=> pitch2(3 downto 0),
		output 	=> HEX4(6 DOWNTO 0)
	);
		
	U_LED0 : entity work.decoder7seg
	port map (
		input		=> pitch2(7 downto 4	),
		output 	=> HEX5(6 DOWNTO 0)
	);
		
	HEX0(7) <= '1';
	HEX1(7) <= '1';
   HEX2(7) <= '1';
   HEX3(7) <= '1';
   HEX4(7) <= '1';
   HEX5(7) <= '1';
		
end STR;
