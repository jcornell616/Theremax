----------------------------------------------------------------------------------
-- FILENAME: pitch_controller.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 1/23/2022
--
-- DESCRIPTION: Controller for pitch detection
--
-- ENITIES: pitch_controller
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.user_pkg.all;

entity pitch_controller is
    port (
        clk         : in std_logic;
        rst         : in std_logic;
        go          : in std_logic;
		  done		  : out std_logic;
        input		  : in std_logic_vector(TREE_OUT_RANGE);
		  period		  : out std_logic_vector(DATA_RANGE);
		  magnitude	  : out std_logic_vector(TREE_OUT_RANGE) -- for testing
	 );
end pitch_controller;

architecture FSM of pitch_controller is
	--states
    type STATE_TYPE is (S_START, S_CNT, S_DONE);
    signal state, next_state   : STATE_TYPE;
    -- variables
    signal cnt, next_cnt					: unsigned(DATA_RANGE);
	 signal min_index, next_min_index	: std_logic_vector(DATA_RANGE);
	 signal prev_val, next_prev_val		: std_logic_vector(TREE_OUT_RANGE);
	 signal min_val, next_min_val			: std_logic_vector(TREE_OUT_RANGE);

begin

	-- resize min_index for output
	period <= min_index;

    -- handle resets and state transitions
    process(clk, rst)
    begin
        if (rst = '1') then
			state <= S_START;
            cnt			<= (others => '0');
			min_index	<= (others => '0');
			prev_val		<= (others => '0');
			min_val		<= (others => '1');
        elsif (rising_edge(clk)) then
			state <= next_state;
            cnt     		<= next_cnt;
			min_index	<= next_min_index;
			prev_val		<= next_prev_val;
			min_val		<= next_min_val;
        end if;
    end process;
	
	-- handle combinational logic
    process(go, cnt, state, input, min_index, prev_val, min_val)
			--constant NOISE : std_logic_vector(TREE_OUT_RANGE) := std_logic_vector(to_unsigned(NOISE_THRESH, NOISE'length));
    begin
		case state is
            when S_START =>
                -- wait for 'go' to be true
                if (go = '1') then
                    next_state <= S_CNT;
                else
                    next_state <= S_START;
                end if;
                --default values
                next_cnt		<= (others => '0');
				next_min_index	<= (others => '0');
				next_prev_val	<= (others => '0');
				next_min_val	<= (others => '1');
				done			<= '0';
            when S_CNT =>
                -- check if max
				if ((cnt = MAX_CNT-1) OR (go = '0')) then
					next_state <= S_DONE;
				else
					next_state <= S_CNT;
				end if;
				-- handle logic
				next_prev_val	<= input;
				next_cnt			<= cnt + 1;
				if ((input < min_val) AND (input < prev_val) AND (input > std_logic_vector(to_unsigned(NOISE_THRESH, 22))) AND (cnt > PER_CUTOFF)) then
					next_min_val	<= input;
					next_min_index	<= std_logic_vector(cnt);
					magnitude		<= min_val; -- for testing
				else
					next_min_val	<= min_val;
					next_min_index	<= min_index;
				end if;
				done <= '0';
			when S_DONE =>
                -- go to start
				next_state <= S_START;
                -- default values
                next_cnt		<= (others => '0');
				next_min_index	<= (others => '0');
				next_prev_val	<= (others => '0');
				next_min_val	<= min_val;
				done			<= '1';
            when others => null;
        end case;
	end process;
	
end FSM;
