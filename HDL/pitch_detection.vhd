----------------------------------------------------------------------------------
-- FILENAME: pitch_detection.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 1/21/2022
--
-- DESCRIPTION: Uses CAMDF algorithm to detect pitch of input stream
--
-- ENITIES: pitch_det
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.user_pkg.all;

entity pitch_det is
	port (
        clk 	: in std_logic;
		  rst		: in std_logic;
		  go		: in std_logic;
		  load	: in std_logic;
		  input	: in std_logic_vector(BUFF_DATA_RANGE);
		  pitch	: out std_logic_vector(DATA_RANGE)
	);
end pitch_det;

architecture STR of pitch_det is
	
	-- signals
	signal in_buff_full, buffers_ld, shift,
			valid_out, pitch_ld					: std_logic;
	signal pitch_reg							: std_logic_vector(DATA_RANGE);		
	signal adder_tree_out						: std_logic_vector(TREE_OUT_RANGE);
	signal adder_tree_in						: std_logic_vector(FRAME_SIZE*(BUFF_DATA_SIZE+2)-1 downto 0);
	signal in_buff_out, circular_buff_out,
			 static_buff_out					: BUFF_ARR;

begin
	
	-- input buffer
	U_IN_BUFF : entity work.smart_buffer
		generic map (
			data_width  => BUFF_DATA_SIZE,
			buff_size   => FRAME_SIZE)
		port map (
			clk         => clk,
			rst         => rst,
			write       => load,
			full        => in_buff_full,
			input	    => input,
			output	   	=> in_buff_out
		);
			
	-- circular buffer
	U_CIRC_BUFF : entity work.circular_buff
		port map (
			clk		=> clk,
			rst      => rst,
			en   	   => buffers_ld,
			shift		=> shift,
			input	   => in_buff_out,
			output	=> circular_buff_out
	);
	
	-- static buffer
	U_STATIC_BUFF : entity work.static_buff
		port map (
			clk		=> clk,
			rst      => rst,
			en   	   => buffers_ld,
			input	   => in_buff_out,
			output	=> static_buff_out
	);
	
	-- subtract and take absolute value
	U_ABS_SUB : entity work.abs_sub
		port map (
		  clk		=> clk,
		  rst		=> rst,
        input1	=> circular_buff_out,
		  input2 => static_buff_out,
		  output	=> adder_tree_in
		);
	
	-- adder tree
	U_ADD_TREE : entity work.add_tree
		generic map (
			num_inputs => FRAME_SIZE,
			data_width => BUFF_DATA_SIZE+2
		)
		port map (
			clk    => clk,
			rst    => rst,
			en     => go,
			input  => adder_tree_in,
			output => adder_tree_out
		);
	
	-- signal delay
	U_DELAY : entity work.valid_pipeline
		generic map (
			num_inputs => DELAY
		)
		port map (
			clk         => clk,
			rst         => rst,
			valid_in	=> shift,
			valid_out	=> valid_out
	);
	
	-- pitch register
	U_PITCH : entity work.reg
		generic map (
			width  => DATA_SIZE
		)
		port map (
			clk    => clk,
			rst    => rst,
			en     => pitch_ld,
			input  => pitch_reg,
			output => pitch
	);
	
	-- buffers controller 1
	U_BUFFS_CONT1 : entity work.buffer_controller1
		port map (
			clk         => clk,
			rst         => rst,
			go          => go,
			load		=> load,
			buffers_ld  => buffers_ld
	);
	
	-- buffers controller 1
	U_BUFFS_CONT2 : entity work.buffer_controller2
		port map (
			clk         => clk,
			rst         => rst,
			go          => go,
			load		=> buffers_ld,
			shift		=> shift
	);
	
	-- pitch detection controller
	U_PITCH_CONT : entity work.pitch_controller
		port map (
			clk		=> clk,
			rst		=> rst,
			go		=> valid_out,
			done	=> pitch_ld,
			input	=> adder_tree_out,
			period	=> pitch_reg
		);
	
end STR;