library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity clk_div is
    generic(clk_in_freq  : natural := 50000000;
            clk_out_freq : natural := 1000);
    port (
        clk_in  : in  std_logic;
        clk_out : out std_logic;
        rst     : in  std_logic);
end clk_div;

architecture divider of clk_div is

	signal count : integer range 0 to (clk_in_freq / clk_out_freq)-1;
	signal state : std_logic;
	
begin

	process(clk_in, rst)
	begin
	
		-- if rst true, reset divider
		if (rst = '1') then
			count <= 0;
			state <= '0';
			
		-- if rising edge clock, iterate	
		elsif (rising_edge(clk_in)) then	
		
			-- if count reaches 500000, change state and restart count
			if (count = (clk_in_freq / clk_out_freq)-1) then
			
				-- reset state
				count <= 0;
				
				-- change state
				if (state = '0') then
					state <= '1';
				else
					state <= '0';
				end if;
				
			-- else, iterate normally
			else
				count <= count + 1;			
			end if;
		end if;
		
		-- assign state to clk_out
		clk_out <= state;
		
	end process;
end divider;