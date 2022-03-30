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
		  input1	: in std_logic_vector(BUFF_DATA_RANGE);
		  input2	: in std_logic_vector(BUFF_DATA_RANGE);
		  pitch1	: out std_logic_vector(DATA_RANGE);
		  pitch2	: out std_logic_vector(DATA_RANGE);
		  magnitude : out std_logic_vector(TREE_OUT_RANGE) -- for testing
	);
end pitch_det;

architecture STR of pitch_det is
	
	-- signals
	signal in_buff_full1, in_buff_full2, buffers_ld, shift,
			valid_out, pitch_ld, buf_sel, reg_en1, reg_en2,
			buff_cont, buff_cont2					: std_logic;
	signal pitch_reg								: std_logic_vector(DATA_RANGE);		
	signal adder_tree_out							: std_logic_vector(TREE_OUT_RANGE);
	signal adder_tree_in							: std_logic_vector(FRAME_SIZE*(BUFF_DATA_SIZE+2)-1 downto 0);
	signal in_buff_out1, in_buff_out2, circular_buff_out,
			 static_buff_out, camdf_in				: BUFF_ARR;

begin
	
	-- input buffer 1
	U_IN_BUFF1 : entity work.smart_buffer
		generic map (
			data_width  => BUFF_DATA_SIZE,
			buff_size   => FRAME_SIZE)
		port map (
			clk         => clk,
			rst         => rst,
			write       => load,
			full        => in_buff_full1,
			input	    	=> input1,
			output	   => in_buff_out1
		);
		
	-- input buffer 2
	U_IN_BUFF2 : entity work.smart_buffer
		generic map (
			data_width  => BUFF_DATA_SIZE,
			buff_size   => FRAME_SIZE)
		port map (
			clk         => clk,
			rst         => rst,
			write       => load,
			full        => in_buff_full2,
			input	    	 => input2,
			output	   => in_buff_out2
		);
		
	-- buffer select
	U_GEN_MUX: for i in 0 to FRAME_SIZE-1 generate
      U_BUF_MUX : entity work.mux_2x1
			generic map (
				width => BUFF_DATA_SIZE)
			port map (
				sel    => buf_sel,
				input1 => in_buff_out1(i),
				input2 => in_buff_out2(i),
				output => camdf_in(i)
			);
   end generate U_GEN_MUX;
			
	-- circular buffer
	U_CIRC_BUFF : entity work.circular_buff
		port map (
			clk		=> clk,
			rst      => rst,
			en   	   => buffers_ld,
			shift		=> shift,
			input	   => camdf_in,
			output	=> circular_buff_out
	);
	
	-- static buffer
	U_STATIC_BUFF : entity work.static_buff
		port map (
			clk		=> clk,
			rst      => rst,
			en   	   => buffers_ld,
			input	   => camdf_in,
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
			valid_in		=> shift,
			valid_out	=> valid_out
	);
	
	-- pitch register 1
	U_PITCH1 : entity work.reg
		generic map (
			width  => DATA_SIZE
		)
		port map (
			clk    => clk,
			rst    => rst,
			en     => reg_en1,
			input  => pitch_reg,
			output => pitch1
	);
	
	-- pitch register 2
	U_PITCH2 : entity work.reg
		generic map (
			width  => DATA_SIZE
		)
		port map (
			clk    => clk,
			rst    => rst,
			en     => reg_en2,
			input  => pitch_reg,
			output => pitch2
	);
	
	-- buffers controller 1
	U_BUFFS_CONT1 : entity work.buffer_controller1
		port map (
			clk         => clk,
			rst         => rst,
			go          => go,
			load		=> load,
			buffers_ld  => buff_cont
	);
	
	-- buffers controller 2
	U_BUFFS_CONT2 : entity work.buffer_controller2
		port map (
			clk         => clk,
			rst         => rst,
			go          => go,
			load		=> buff_cont,
			shift		=> shift,
			buf_sel		=> buf_sel,
			buffers_ld	=> buff_cont2
	);
	
	-- pitch detection controller
	U_PITCH_CONT : entity work.pitch_controller
		port map (
			clk		=> clk,
			rst		=> rst,
			go		=> valid_out,
			done	=> pitch_ld,
			input	=> adder_tree_out,
			period	=> pitch_reg,
			magnitude => magnitude -- for testing
		);
		
	-- output register enables
	reg_en1	<= pitch_ld AND NOT buf_sel;
	reg_en2	<= pitch_ld AND buf_sel;
	-- buffer enables
	buffers_ld <= buff_cont OR buff_cont2;
	
end STR;