----------------------------------------------------------------------------------
-- FILENAME: static_buffer.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 1/28/2021
--
-- DESCRIPTION: array of registers
--
-- ENITIES: static_buff
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.user_pkg.all;

entity static_buff is
	port (
      clk         : in std_logic;
      rst         : in std_logic;
      en   	    	: in std_logic;
      input	    	: in BUFF_ARR;
		output	   : out BUFF_ARR
	);
end static_buff;

architecture STR of static_buff is
begin

	-- array of registers
	U_BUFF_REG : for i in 0 to FRAME_SIZE-1 generate
		U_REG : entity work.reg
			generic map (
				width   => BUFF_DATA_SIZE
			)
			port map (
				clk     => clk,
				rst     => rst,
				en      => en,
				input   => input(i),
				output  => output(i)
			);
	end generate;

end STR;