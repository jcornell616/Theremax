----------------------------------------------------------------------------------
-- FILENAME: smart_buffer_controller.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 11/18/2021
--
-- DESCRIPTION: Controller for smart buffer
--
-- ENITIES: buff_controller
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity buff_controller is
    generic (
        buff_size : positive := 128);
    port (
        clk         : in std_logic;
        rst         : in std_logic;
        go          : in std_logic;
        write       : in std_logic;
        full        : out std_logic;
        buff_en     : out std_logic);
end buff_controller;

architecture FSM of buff_controller is
    --states
    type STATE_TYPE is (S_START, S_CNT);
    signal state, next_state   : STATE_TYPE;
    --counter
    constant C_MAX_CNT           : natural := buff_size - 1;
    constant C_MAX_COUNT_BITS    : natural := integer(ceil(log2(real(C_MAX_CNT))));
    signal cnt, next_cnt       : unsigned(C_MAX_COUNT_BITS-1 downto 0);
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
    process(go, state, cnt, write)
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
                full        <= '0';
                buff_en     <= '0';
					 next_cnt    <= (others => '0');
            when S_CNT =>
					 -- continuously go through count stage
                next_state <= S_CNT;
                --handle flags based off count value
                if (cnt = C_MAX_CNT) then
						  full		<= '1';
                else
                    full      <= '0';
                end if;
                --handle count iteration
					 if (write = '1' AND cnt /= C_MAX_CNT) then
						next_cnt <= cnt + 1;
						buff_en	<= '1';
					 elsif (write = '1' AND cnt = C_MAX_CNT) then
						next_cnt <= cnt;
						buff_en	<= '1';
					 else
						next_cnt <= cnt;
						buff_en <= '0';
					 end if;
            when others => null;
        end case;
    end process;
end FSM;
