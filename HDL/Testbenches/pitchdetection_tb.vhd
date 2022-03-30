----------------------------------------------------------------------------------
-- FILENAME: pitchdetection_tb.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 2/1/2022
--
-- DESCRIPTION: Tesbench for pitch detection component
--
-- ENITIES: pitchdetection_tb
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.math_custom.all;

use work.user_pkg.all;

entity pitchdetection_tb is
end pitchdetection_tb;

architecture TB of pitchdetection_tb is
	
	component pitch_det
		port (
			clk 	: in std_logic;
			rst		: in std_logic;
			go		: in std_logic;
			load	: in std_logic;
			input1	: in std_logic_vector(BUFF_DATA_RANGE);
			input2	: in std_logic_vector(BUFF_DATA_RANGE);
			pitch1	: out std_logic_vector(DATA_RANGE);
			pitch2	: out std_logic_vector(DATA_RANGE)
		);
	end component;

	constant array_size	: positive := 8*FRAME_SIZE;
	constant period1	: positive := 117;
	constant period2	: positive := 82;
	--constant TIMEOUT	: time     := 10 ms;
	
 	signal clk  : std_logic := '0';
	signal rst  : std_logic := '1';
	signal go   : std_logic := '0';
	signal load	: std_logic := '0';
	
	signal input1	: std_logic_vector(BUFF_DATA_RANGE);
	signal pitch1	: std_logic_vector(DATA_RANGE);
	signal input2	: std_logic_vector(BUFF_DATA_RANGE);
	signal pitch2	: std_logic_vector(DATA_RANGE);

	type input_array is array (0 to array_size-1) of std_logic_vector(BUFF_DATA_RANGE);
	
	signal adc1_data, adc2_data : input_array;

begin
			
	UUT : pitch_det
		port map (
			clk 	=> clk,
			rst		=> rst,
			go		=> go,
			load	=> load,
			input1	=> input1,
			input2	=> input2,
			pitch1	=> pitch2,
			pitch2	=> pitch2
		);

	clk <= not clk after 5 ns;

	process

		-- writes periodic function to input array to simulate input stream
		function WRITE_TO_ARR1 (array_size : integer;
				       data_width : integer) return input_array is
			variable in_arr : input_array;
			begin
				for i in 0 to array_size-1 loop
					in_arr(i) := std_logic_vector(to_unsigned(i mod period1 + 1, data_width));
				end loop;
			return in_arr;
		end function;
		
		-- writes periodic function to input array to simulate input stream
		function WRITE_TO_ARR2 (array_size : integer;
				       data_width : integer) return input_array is
			variable in_arr : input_array;
			begin
				for i in 0 to array_size-1 loop
					in_arr(i) := std_logic_vector(to_unsigned(i mod period2 + 1, data_width));
				end loop;
			return in_arr;
		end function;

	begin

		-- starting values		
		rst  		<= '1';
		go          <= '0';
		load		<= '0';
		input1		<= (others => '0');
		input2		<= (others => '0');
		adc1_data	<= WRITE_TO_ARR1 (array_size, BUFF_DATA_SIZE);
		adc2_data	<= WRITE_TO_ARR2 (array_size, BUFF_DATA_SIZE);

    	-- set reset false
    	wait for 50 ns;
    	rst <= '0';

		-- start system
		wait for 50 ns;
		go <= '1';
		
		-- start sampling	
		for i in 0 to array_size-1 loop
			input1	<= adc1_data(i);
			input2	<= adc2_data(i);
			load	<= '1';
			wait for 10 ns;
			load	<= '0';
			wait for 250 ns;
		end loop;

		-- wait some time
		wait for 100 ns;

		-- terminate testbench
    	report "DONE!" severity note;
    	wait;

	end process;
end TB;