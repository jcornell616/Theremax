----------------------------------------------------------------------------------
-- FILENAME: buffer.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 11/17/2021
--
-- DESCRIPTION: Buffer using shift register with serial in, parallel out.
--	       'data_width' defines width of input data in bits
--	       'buff_size' defines number of registers in buffer/shift register
--
-- ENITIES: shift_reg
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.user_pkg.all;

entity shift_reg is
	generic (
		data_width  : positive := 16;
	   buff_size   : positive := 128);
	port (
      clk         : in  std_logic;
      rst         : in  std_logic;
      en   	    	: in  std_logic;
      input	    	: in  std_logic_vector(data_width-1 downto 0);
		output	   : out BUFF_ARR
	);
end shift_reg;

architecture STR of shift_reg is

	-- variables
	signal temp_out : BUFF_ARR;

begin

	-- first register
	U_REG1 : entity work.reg
			generic map (
				width   => data_width)
			port map (
				clk     => clk,
				rst     => rst,
				en      => en,
				input   => input,
				output  => temp_out(0)
			);

	-- generate shift register of size 'buff_size'
	U_SHIFT_REG : for i in 1 to buff_size-1 generate
		U_REG : entity work.reg
			generic map (
				width   => data_width)
			port map (
				clk     => clk,
				rst     => rst,
				en      => en,
				input   => temp_out(i-1),
				output  => temp_out(i)
			);
	end generate;

	--connect remaining signals
	output <= temp_out;

end STR;