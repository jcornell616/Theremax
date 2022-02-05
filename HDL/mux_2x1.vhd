----------------------------------------------------------------------------------
-- FILENAME: mux_2x1.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 09/11/2021
--
--DESCRIPTION: 2x1 mux
--
--ENITIES: mux_2x1
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity mux_2x1 is
  generic (
    width  :     positive);
  port (
    sel    : in  std_logic;
    input1 : in  std_logic_vector(width-1 downto 0);
    input2 : in  std_logic_vector(width-1 downto 0);
    output : out std_logic_vector(width-1 downto 0));
end mux_2x1;

architecture BHV of mux_2x1 is
begin
    process (sel, input1, input2)
    begin
        if (sel = '0') then
            output <= input1;
        else
            output <= input2;
        end if;
    end process;
end BHV;