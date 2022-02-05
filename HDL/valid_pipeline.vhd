----------------------------------------------------------------------------------
-- FILENAME: valid_pipeline.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 11/23/2021
--
-- DESCRIPTION: Pipeline to keep track of valid inputs
-- ENITIES: valid_pipeline
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity valid_pipeline is
    generic (
        num_inputs : positive);
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
		valid_in	: in std_logic;
		valid_out	: out std_logic);
end valid_pipeline;

architecture STR of valid_pipeline is

	constant depth : natural := integer(ceil(log2(real(num_inputs)))) + 1;
	
	type reg_array is array (0 to depth) of std_logic;
	signal regs : reg_array;

begin
        
    U_GENERATE_PIPE : for i in 0 to depth-1 generate
		U_REG : entity work.reg
			generic map (
				width  => 1)
			port map (
				clk    		=> clk,
				rst   		=> rst,
				en     		=> '1',
				input(0)	=> regs(i),
				output(0)	=> regs(i+1));
	end generate U_GENERATE_PIPE;
	
	regs(0)		<= valid_in;
	valid_out	<= regs(depth);
  
end STR;