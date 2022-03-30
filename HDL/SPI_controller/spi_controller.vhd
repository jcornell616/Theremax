----------------------------------------------------------------------------------
-- FILENAME: spi_controller.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 1/22/2021
--
-- DESCRIPTION: Controller for SPI slave module
--
-- ENITIES: spi_controller
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.user_pkg.all;

entity spi_controller is
   port (
        clk         : in std_logic;
        rst         : in std_logic;
        go          : in std_logic;
		  din_rdy	  : in std_logic;
		  dout_vld	  : in std_logic;
        din_vld	  : out std_logic;
		  data_ld	  : out std_logic;
		  dout		  : in std_logic_vector(SPI_DATA_RANGE)
	);
end spi_controller;

architecture FSM of spi_controller is
    --states
    type STATE_TYPE is (S_START, S_WAIT, S_CMD, S_SEND);
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
    process(go, state, din_rdy, dout_vld, dout)
    begin
        case state is
            when S_START =>
                -- wait for 'go' to be true
                if (go = '1') then
                    next_state <= S_WAIT;
                else
                    next_state <= S_START;
                end if;
                -- invalid input data
                din_vld <= '0';
					 data_ld <= '0';
            when S_WAIT =>
                -- wait to recieve data
                if (dout_vld = '1') then
                    next_state <= S_CMD;
                else
                    next_state <= S_WAIT;
                end if;
                -- invalid input data
                din_vld <= '0';
					 data_ld <= '1';
            when S_CMD =>
                -- check if data received is command
					 if (dout = CMD) then
						  next_state <= S_SEND;
						  data_ld 	 <= '1';
					 else
						  next_state 	<= S_WAIT;
						  data_ld		<= '0';
					 end if;
					 -- invalid input data
					 din_vld <= '0';
				when S_SEND =>
					 -- wait for all bits to be sent
					 if (din_rdy = '1') then
						  next_state <= S_WAIT;
					 else
						  next_state <= S_SEND;
					 end if;
					 -- valid input data
					 din_vld <= '1';
					 data_ld <= '0';
            when others => null;
        end case;
    end process;
end FSM;
