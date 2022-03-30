----------------------------------------------------------------------------------
-- FILENAME: smart_buffer.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 11/18/2021
--
-- DESCRIPTION: Top level structure of smart buffer
-- ENITIES: smart_buffer
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.user_pkg.all;

entity smart_buffer is
    generic (
        data_width  : positive := 16;
        buff_size   : positive := 128);
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        write       : in std_logic;
        full        : out std_logic;
        input	     : in  std_logic_vector(data_width-1 downto 0);
		  output	     : out BUFF_ARR
	);
end smart_buffer;

architecture STR of smart_buffer is
    --intermediary signals
    signal buff_en : std_logic;
begin
        
    U_CONTROLLER : entity work.buff_controller
        generic map (
            buff_size   => buff_size)
        port map (
            clk         => clk,
            rst         => rst,
            go          => '1',
            write       => write,
            full        => full,
            buff_en     => buff_en);
            
    U_BUFFER : entity work.shift_reg
        generic map (
            data_width  => data_width,
				buff_size   => buff_size)
	    port map (
            clk         => clk,
				rst         => rst,
				en   	    	=> buff_en,
				input	    	=> input,
				output	   => output);
  
end STR;