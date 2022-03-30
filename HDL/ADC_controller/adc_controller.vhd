----------------------------------------------------------------------------------
-- FILENAME: adc_controller.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 1/26/2021
--
-- DESCRIPTION: Controller for ADC driver
--
-- ENITIES: adc_controller
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.user_pkg.all;

entity adc_controller is
   port (
        clk         : in std_logic;
        rst         : in std_logic;
        go          : in std_logic;
		  clk_in		  : in std_logic;
		  sample		  : out std_logic;
		  buff_ld	  : out std_logic
	);
end adc_controller;

architecture FSM of adc_controller is
    --states
    type STATE_TYPE is (S_START, S_WAIT1, S_SAMPLE, S_LOAD, S_WAIT2);
    signal state, next_state   : STATE_TYPE;

begin

    -- handle resets and state transitions
    process(clk, rst)
    begin
        if (rst = '1') then
            state <= S_START;
        elsif (rising_edge(clk)) then
            state <= next_state;
        end if;
    end process;
    
    -- handle combinational logic
    process(go, state, clk_in)
    begin
        case state is
            when S_START =>
                -- wait for 'go' to be true
                if (go = '1') then
                    next_state <= S_WAIT1;
                else
                    next_state <= S_START;
                end if;
                -- invalid input data
                sample	<= '0';
					 buff_ld <= '0';
            when S_WAIT1 =>
                -- check if rising clock edge
                if (clk_in = '1') then
                    next_state <= S_SAMPLE;
                else
                    next_state <= S_WAIT1;
                end if;
                -- invalid input data
                sample	<= '0';
					 buff_ld <= '0';
            when S_SAMPLE =>
                -- go to load state
					 next_state <= S_LOAD;
					 -- sample adc
					 sample	<= '1';
					 buff_ld <= '0';
				when S_LOAD =>
					 -- go to wait state
					 next_state <= S_WAIT2;
					 -- load buffers
					 sample	<= '0';
					 buff_ld <= '1';
				when S_WAIT2 =>
					-- wait for low signal
					if (clk_in = '0') then
						next_state <= S_WAIT1;
					else
						next_state <= S_WAIT2;
					end if;
					-- do nothing
					sample	<= '0';
					buff_ld	<= '0';
            when others => null;
        end case;
    end process;
end FSM;
