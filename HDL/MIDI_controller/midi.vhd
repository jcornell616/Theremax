----------------------------------------------------------------------------------
-- FILENAME: midi.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 2/18/2022
--
-- DESCRIPTION: Sends MIDI output signal based off input pitch
--
-- ENITIES: midi
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.user_pkg.all;

entity midi is
	port (
        clk		: in std_logic;
		  rst		: in std_logic;
		  go		: in std_logic;
		  TX		: out std_logic;
		  pitch	: in std_logic_vector(DATA_RANGE);
		  key_out : out std_logic_vector(MIDI_RANGE) -- for testing
	);
end midi;

architecture STR of midi is

	-- signals
	signal key, data		: std_logic_vector(MIDI_RANGE);
	signal send, waiting	: std_logic;

	-- component declaration
	component rom
		port (
			address	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			clock		: IN STD_LOGIC;
			q			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	end component;

begin

	-- UART driver
	U_UART : entity work.uart
	generic map (
        baud                => BAUD_RATE,
        clock_frequency     => SYS_CLK
    )
    port map (  
        clock               => clk,
        reset               => rst,  
        data_stream_in      => data,
        data_stream_in_stb  => send,
        data_stream_in_ack  => waiting,
        data_stream_out     => open,
        data_stream_out_stb => open,
        tx                  => TX,
        rx                  => '1'
    );
	 
	-- convert pitch to MIDI key
	U_MIDI_LUT : rom
	port map (
		address	=> pitch(MIDI_RANGE),
		clock		=> clk,
		q			=> key
	);
	 
	-- MIDI controller
	U_MIDI_CONT : entity work.midi_controller
	port map (
		clk			=> clk,
		rst			=> rst,
		go				=> go,
		waiting		=> waiting,
		send			=> send,
		key			=> key,
		uart_data	=> data
	);
	
	key_out <= key; -- for testing

end STR;