----------------------------------------------------------------------------------
-- FILENAME: circular_buffer.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 1/28/2021
--
-- DESCRIPTION: circular buffer
--
-- ENITIES: circular_buff
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.user_pkg.all;

entity circular_buff is
	port (
      clk         : in std_logic;
      rst         : in std_logic;
      en   	    	: in std_logic;
		shift			: in std_logic;
      input	    	: in BUFF_ARR;
		output	   : out BUFF_ARR
	);
end circular_buff;

architecture STR of circular_buff is

	-- buffer
	signal mux_out	: BUFF_ARR;
	signal temp_out	: BUFF_ARR;
	signal en_temp	: std_logic;

begin

	-- first mux
	U_MUX1 : entity work.mux_2x1
		generic map (
			width  => BUFF_DATA_SIZE
		)
		port map (
			sel    => shift,
			input1 => input(0),
			input2 => temp_out(FRAME_SIZE-1),
			output => mux_out(0)
		);

	-- generate muxes to select load or shift input
	U_MUX_ARR : for i in 1 to FRAME_SIZE-1 generate
		U_MUX : entity work.mux_2x1
			generic map (
				width  => BUFF_DATA_SIZE
			)
			port map (
				sel    => shift,
				input1 => input(i),
				input2 => temp_out(i-1),
				output => mux_out(i)
			);
	end generate;

	-- generate shift register of size 'buff_size'
	U_BUFF_REG : for j in 0 to FRAME_SIZE-1 generate
		U_REG : entity work.reg
			generic map (
				width   => BUFF_DATA_SIZE
			)
			port map (
				clk     => clk,
				rst     => rst,
				en      => en_temp,
				input   => mux_out(j),
				output  => temp_out(j)
			);
	end generate;

	--connect remaining signals
	output  <= temp_out;
	en_temp	<= en OR shift;

end STR;