----------------------------------------------------------------------------------
-- FILENAME: ADC.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 1/21/2021
--
-- DESCRIPTION: ADC driver
--
-- ENITIES: ADC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.user_pkg.all;

entity ADC is
	port (
        clk 	 	: in std_logic;
		  rst			: in std_logic;
		  buff_ld	: out std_logic;
		  voltage1	: out std_logic_vector(BUFF_DATA_RANGE);
		  voltage2	: out std_logic_vector(BUFF_DATA_RANGE)
	);
end ADC;

architecture STR of ADC is

	-- component instantiation from Intel IP
	component ADC_Driver is
		port (
			CLOCK : in  std_logic                     := 'X'; 	  -- clk
			RESET : in  std_logic                     := 'X';    -- reset
			CH0   : out std_logic_vector(ADC_DATA_RANGE);        -- CH0
			CH1   : out std_logic_vector(ADC_DATA_RANGE);        -- CH1
			CH2   : out std_logic_vector(ADC_DATA_RANGE);        -- CH2
			CH3   : out std_logic_vector(ADC_DATA_RANGE);        -- CH3
			CH4   : out std_logic_vector(ADC_DATA_RANGE);        -- CH4
			CH5   : out std_logic_vector(ADC_DATA_RANGE);        -- CH5
			CH6   : out std_logic_vector(ADC_DATA_RANGE);        -- CH6
			CH7   : out std_logic_vector(ADC_DATA_RANGE)         -- CH7
		);
	end component ADC_Driver;
	
	-- signals
	signal adc_clk, sample		: std_logic;
	signal ch0, ch1, ch2, ch3,
			 ch4, ch5, ch6, ch7	: std_logic_vector(ADC_DATA_RANGE);

begin

	-- adc controller
	U_ADC_CONT : entity work.adc_controller
   port map (
        clk         => clk,
        rst         => rst,
        go          => '1',
		  clk_in		  => adc_clk,
		  sample		  => sample,
		  buff_ld	  => buff_ld
	);

	-- clock divider
	U_CLK_DIV : entity work.clk_div
	generic map (
		clk_in_freq  => SYS_CLK,
      clk_out_freq => 2*SAMPLE_RATE)
   port map (
      clk_in  => clk,
      clk_out => adc_clk,
      rst     => rst
	);

	-- ADC driver
	U_ADC_DR : component ADC_Driver
	port map (
		CLOCK => clk,
		CH0   => ch0,
		CH1   => ch1,
		CH2   => ch2,
		CH3   => ch3,
		CH4   => ch4,
		CH5   => ch5,
		CH6   => ch6,
		CH7   => ch7,
		RESET => '0'
	);
	
	-- output register
	U_VOLT1 : entity work.reg
	generic map (
		width  => BUFF_DATA_SIZE
	)
	port map (
		clk    => clk,
		rst    => rst,
		en     => sample,
		input  => ch0(11 downto (ADC_DATA_SIZE - BUFF_DATA_SIZE)),
		output => voltage1
	);
	
	-- output register
	U_VOLT2 : entity work.reg
	generic map (
		width  => BUFF_DATA_SIZE
	)
	port map (
		clk    => clk,
		rst    => rst,
		en     => sample,
		input  => ch1(11 downto (ADC_DATA_SIZE - BUFF_DATA_SIZE)),
		output => voltage2
	);
		
end STR;
