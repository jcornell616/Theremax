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

entity add_tree_delay is
	generic (
        cycles : natural;
        width  : positive;
        init   : std_logic_vector);
    port (
        clk    : in std_logic;
        rst    : in std_logic;
        en     : in std_logic;
        input  : in std_logic_vector(width-1 downto 0);
        output : out std_logic_vector(width-1 downto 0));
end add_tree_delay;

architecture STR of add_tree_delay is

	type reg_array is array (0 to cycles-1) of std_logic_vector(width-1 downto 0);
	signal regs : reg_array;

begin
        
    U_CYCLES_GT_0 : if cycles > 0 generate
	
		process(clk, rst)
		begin
			if (rst = '1') then
				for i in 0 to cycles-1 loop
					regs(i) <= init;
				end loop;
			elsif (clk'event and clk = '1') then
				if (en = '1') then
					regs(0) <= input;
				end if;
				for i in 0 to cycles-2 loop
					if (en = '1') then
						regs(i+1) <= regs(i);
					end if;
				end loop;
			end if;
		end process;
		
		output <= regs(cycles-1);
		
	end generate U_CYCLES_GT_0;

	U_CYCLES_EQ_0 : if cycles = 0 generate

		output <= input;

  end generate U_CYCLES_EQ_0;
  
end STR;