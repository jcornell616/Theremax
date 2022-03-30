----------------------------------------------------------------------------------
-- FILENAME: midi_tb.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 3/16/2022
--
-- DESCRIPTION: Tesbench for midi controller
--
-- ENITIES: midi_tb
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.math_custom.all;

use work.user_pkg.all;

entity midi_tb is
end midi_tb;

architecture TB of midi_tb is
	
	-- component declaration
	component midi_controller
		port (
			clk			: in std_logic;
			rst			: in std_logic;
			go				: in std_logic;
			waiting		: in std_logic;
			send			: out std_logic;
			key			: in std_logic_vector(MIDI_RANGE);
			uart_data	: out std_logic_vector(MIDI_RANGE)
		);
	end component;
	
	-- signals
 	signal clk  	: std_logic := '0';
	signal rst  	: std_logic := '1';
	signal go   	: std_logic := '0';
	signal send		: std_logic := '0';
	signal waiting	: std_logic := '0';
	
	signal key, data	: std_logic_vector(MIDI_RANGE);

begin
			
	-- components
	UUT : midi_controller
	port map (
		clk			=> clk,
		rst			=> rst,
		go				=> go,
		waiting		=> waiting,
		send			=> send,
		key			=> key,
		uart_data	=> data
	);
	
	-- clk signal
	clk <= not clk after 5 ns;

	process
	begin

		-- starting values		
		rst  		<= '1';
		go       <= '0';
		waiting	<= '0';
		key		<= "00011110";

    	-- set reset false
    	wait for 50 ns;
    	rst <= '0';

		-- start system
		wait for 50 ns;
		go <= '1';
		
		-- send value
		for i in 1 to 10 loop
			wait for 50 ns;
			waiting <= '1';
			wait for 100 ns;
			waiting <= '0';
		end loop;

		-- wait some time
		for i in 1 to 10 loop
			key <= (others => '0');
			wait for 50 ns;
			waiting <= '1';
			wait for 100 ns;
			waiting <= '0';
		end loop;
		
		-- send value
		for i in 1 to 10 loop
			key <= "00101010";
			wait for 50 ns;
			waiting <= '1';
			wait for 100 ns;
			waiting <= '0';
		end loop;
		
		-- send value
		for i in 1 to 10 loop
			key <= "00100111";
			wait for 50 ns;
			waiting <= '1';
			wait for 100 ns;
			waiting <= '0';
		end loop;

		-- terminate testbench
    	report "DONE!" severity note;
    	wait;

	end process;
end TB;