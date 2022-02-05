----------------------------------------------------------------------------------
-- FILENAME: buffer_controller2.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 2/1/2021
--
-- DESCRIPTION: Controller for buffers
--
-- ENITIES: buffer_controller
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.user_pkg.all;

entity buffer_controller2 is
    port (
        clk         : in std_logic;
        rst         : in std_logic;
        go          : in std_logic;
        load		: in std_logic;
		shift		: out std_logic
	);
end buffer_controller2;

architecture FSM of buffer_controller2 is
    --states
    type STATE_TYPE is (S_START, S_WAIT, S_CNT);
    signal state, next_state   : STATE_TYPE;
    --counter
    signal cnt, next_cnt       : unsigned(CNT_RANGE);
begin

    --handle resets and state transitions
    process(clk, rst)
    begin
        if (rst = '1') then
            state   <= S_CNT;
            cnt     <= (others => '0');
        elsif (rising_edge(clk)) then
            state   <= next_state;
            cnt     <= next_cnt;
        end if;
    end process;
    
    --handle combinational logic
    process(go, state, cnt, load)
    begin
        case state is
            when S_START =>
                -- wait for 'go' to be true
                if (go = '1') then
                    next_state <= S_WAIT;
                else
                    next_state <= S_START;
                end if;
                --default values
                shift		<= '0';
				next_cnt   	<= (others => '0');
            when S_WAIT =>
                -- wait for 'full' to be true
                if (load = '1') then
                    next_state <= S_CNT;
                else
                    next_state <= S_WAIT;
                end if;
                --default values
                shift		<= '0';
				next_cnt   	<= (others => '0');
            when S_CNT =>
                -- check if max
				if (cnt = MAX_CNT) then
					next_state <= S_WAIT;
				else
					next_state <= S_cnt;
				end if;
                shift		<= '1';
				next_cnt   	<= cnt + 1;
            when others => null;
        end case;
    end process;
end FSM;
