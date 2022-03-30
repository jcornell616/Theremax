----------------------------------------------------------------------------------
-- FILENAME: user_pkg.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 2/4/2021
--
-- DESCRIPTION: File to set system parameters.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package user_pkg is
	
	-- System constraints (CHANGE BASED OFF SYSTEM)
	constant SYS_CLK			: positive := 10000000;
	constant ADC_CLK			: positive := 10000000;
	constant ADC_DATA_SIZE	: positive := 12;
   
	-- Application specific constraints	(CHANGE BASED ON APPLICATION)
	constant SAMPLE_RATE		: positive := 12000;
	constant FRAME_SIZE		: positive := 512;
	constant BUFF_DATA_SIZE	: positive := 12;
	constant SPI_DATA_SIZE	: positive := 8; 
	constant DATA_SIZE		: positive := 16;
	constant PER_CUTOFF		: positive := 5;
	constant BAUD_RATE		: positive := 31250;
	constant NOISE_THRESH	: integer  := 256;
	
	-- Calculated values (DON'T EDIT)
	constant MAX_CNT			: positive := FRAME_SIZE / 2;
	constant DELAY				: positive := integer(ceil(log2(real(FRAME_SIZE)))) + 7;
	
	subtype ADC_DATA_RANGE	is natural range ADC_DATA_SIZE-1 downto 0;
	subtype BUFF_DATA_RANGE is natural range BUFF_DATA_SIZE-1 downto 0;
	subtype SPI_DATA_RANGE	is natural range SPI_DATA_SIZE-1 downto 0;
	subtype DATA_RANGE		is natural range DATA_SIZE-1 downto 0;
	subtype CNT_RANGE			is natural range integer(ceil(log2(real(FRAME_SIZE))))-1 downto 0;
	subtype TREE_OUT_RANGE	is natural range BUFF_DATA_SIZE+2+integer(ceil(log2(real(FRAME_SIZE))))-1 downto 0;
	subtype MIDI_RANGE		is natural range 7 downto 0;
	
	type BUFF_ARR		is array (0 to FRAME_SIZE-1) of std_logic_vector(BUFF_DATA_RANGE);
	
	-- Commands (CHANGE AS NEEDED)
	constant CMD : std_logic_vector(SPI_DATA_RANGE) := "00000001";
	
	constant NOTE_ON			: std_logic_vector(MIDI_RANGE) := "10010000";
	constant NOTE_OFF			: std_logic_vector(MIDI_RANGE) := "00000000";
	constant NOTE_VELOCITY	: std_logic_vector(MIDI_RANGE) := "11110000";

end user_pkg;