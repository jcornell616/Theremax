----------------------------------------------------------------------------------
-- FILENAME: absolute_subtract.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 1/28/2022
--
-- DESCRIPTION: Take absolute value of subtraction
--
-- ENITIES: abs_sub
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.user_pkg.all;

entity abs_sub is
    port (
		  clk		: in std_logic;
		  rst		: in std_logic;
        input1	: in BUFF_ARR;
		  input2 : in BUFF_ARR;
		  output	: out std_logic_vector(FRAME_SIZE*(BUFF_DATA_SIZE+2)-1 downto 0)
	 );
end abs_sub;

architecture STR of abs_sub is

    -- variables
	 type TEMP_VECT	is array (0 to FRAME_SIZE-1) of std_logic_vector(BUFF_DATA_SIZE+1 downto 0);
	 type TEMP_ARR		is array (0 to FRAME_SIZE-1) of signed(BUFF_DATA_SIZE+1 downto 0);
	 signal append_arr1, append_arr2, reg_out		: TEMP_VECT;
	 signal signed_arr1, signed_arr2, temp_out	: TEMP_ARR;
	 
	 -- functions
	 function vectorize(input        : TEMP_VECT;
							  arraySize    : natural;
                       elementWidth : positive) return std_logic_vector is
		variable temp : std_logic_vector(arraySize*elementWidth-1 downto 0);
		begin
			for i in 0 to arraySize-1 loop
				temp((i+1)*elementWidth-1 downto i*elementWidth) := input(input'left+i);
			end loop;
		return temp;
	end function;
	
begin

	-- append zeros and convert to signed so info not lost
	U_APPEND : for i in 0 to FRAME_SIZE-1 generate
		append_arr1(i) <= "00" & input1(i);
		append_arr2(i) <= "00" & input2(i);
		signed_arr1(i) <= signed(append_arr1(i));
		signed_arr2(i) <= signed(append_arr2(i));
	end generate;
	
	-- take subtraction and absolute value
	U_SUB : for j in 0 to FRAME_SIZE-1 generate
		temp_out(j) <= abs(signed_arr1(j) - signed_arr2(j));
	end generate;
	
	-- pipelined output
	U_REG_ARR : for k in 0 to FRAME_SIZE-1 generate
		U_REG : entity work.reg
			generic map (
				width   => BUFF_DATA_SIZE+2
			)
			port map (
				clk     => clk,
				rst     => rst,
				en      => '1',
				input   => std_logic_vector(temp_out(k)),
				output  => reg_out(k)
			);
	end generate;
	
	-- revert back to std_logic_vector
	output <= vectorize(reg_out, FRAME_SIZE, BUFF_DATA_SIZE+2);
   
end STR;
