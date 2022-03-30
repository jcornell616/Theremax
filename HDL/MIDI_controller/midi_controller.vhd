----------------------------------------------------------------------------------
-- FILENAME: midi_controller.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 2/18/2022
--
-- DESCRIPTION: Sends MIDI output signal based off input pitch
--
-- ENITIES: midi_controller
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.user_pkg.all;

entity midi_controller is
	port (
		clk			: in std_logic;
		rst			: in std_logic;
		go				: in std_logic;
		waiting		: in std_logic;
		send			: out std_logic;
		key			: in std_logic_vector(MIDI_RANGE);
		uart_data	: out std_logic_vector(MIDI_RANGE)
	);
end midi_controller;

architecture BHV of midi_controller is
	 
	-- states
    type STATE_TYPE is (S_START, S_IDLE, S_ON, S_KEY1, S_KEY2, S_VEL, S_OFF);
    signal state, next_state   : STATE_TYPE;
	 
	 -- variables
	 signal prev_key, next_prev_key : std_logic_vector(MIDI_RANGE);
	 
	 -- constants
	 constant zero : std_logic_vector(MIDI_RANGE) := "00000000";
	 
begin

    -- handle resets and state transitions
    process(clk, rst)
    begin
        if (rst = '1') then
            state		<= S_START;
            prev_key <= (others => '0');
        elsif (rising_edge(clk)) then
            state		<= next_state;
				prev_key	<= next_prev_key;
        end if;
    end process;
    
	--handle combinational logic
   process(go, state, waiting, key, prev_key)
   begin
		-- defaults
		send		 		<= '0';
		uart_data 		<= (others => '0');
		next_prev_key	<= prev_key;
		next_state		<= state;
		-- states
      case state is
			when S_START =>
				-- wait for go
				if (go = '1') then
					next_state <= S_IDLE;
				else
					next_state <= S_START;
				end if;
			when S_IDLE =>
				-- if changing from zero to key
				if ((key /= prev_key) AND (prev_key = zero)) then
					next_state		<= S_ON;
					next_prev_key	<= key;
				-- if changing key from different key
				elsif ((key /= prev_key)) then
					next_state		<= S_KEY2;
				-- wait for change in key
				else
					next_state <= S_IDLE;
				end if;
			when S_ON =>
				-- wait for signal to send
				if (waiting = '1') then
					next_state <= S_KEY1;
				else
					next_state <= S_ON;
				end if;
				-- write command
				uart_data	<= NOTE_ON;
				send			<= '1';
			when S_KEY1 =>
				-- wait for signal to send
				if (waiting = '1') then
					next_state <= S_VEL;
				else
					next_state	<= S_KEY1;
				end if;
				-- write command
				uart_data	<= key;
				send			<= '1';
			when S_VEL =>
				-- wait for signal to send
				if (waiting = '1') then
					next_state	<= S_IDLE;
					next_prev_key <= key;
				else
					next_state  <= S_VEL;
				end if;
				-- write command
				uart_data	<= NOTE_VELOCITY;
				send			<= '1';
			when S_KEY2 =>
				-- wait for signal to send
				if (waiting = '1') then
					next_state	<= S_OFF;
				else
					next_state <= S_KEY2;
				end if;
				-- write command
				uart_data	<= prev_key;
				send			<= '1';
			when S_OFF =>
				-- wait for signal to send
				if ((waiting = '1') AND (key /= zero)) then
					next_state <= S_ON;
				elsif ((waiting = '1') AND (key = zero)) then
					next_state <= S_IDLE;
					next_prev_key <= key;
				else
					next_state <= S_OFF;
				end if;
				-- write command
				uart_data	<= NOTE_OFF;
				send			<= '1';				
         when others => null;
      end case;
	end process;

end BHV;