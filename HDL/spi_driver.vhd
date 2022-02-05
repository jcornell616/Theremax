----------------------------------------------------------------------------------
-- FILENAME: spi_driver.vhd
-- AUTHOR: Jackson Cornell
-- CREATE DATE: 1/22/2022
--
-- DESCRIPTION: SPI driver
--
-- ENITIES: spi_driver
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.user_pkg.all;

entity spi_driver is
	port (
        clk 	 : in std_logic;
		  rst		 : in std_logic;
		  go		 : in std_logic;
		  sclk	 : in std_logic;
		  cs		 : in std_logic;
		  mosi	 : in std_logic;
		  miso	 : out std_logic;
		  data_in : in std_logic_vector(SPI_DATA_RANGE)
	);
end spi_driver;

architecture STR of spi_driver is
	
	-- signals
	signal din, dout										: std_logic_vector(SPI_DATA_RANGE);
	signal din_vld, din_rdy, dout_vld, data_ld	: std_logic;
	
	
begin

	-- input data register
	u_DATA_IN : entity work.reg
	generic map (
		width => SPI_DATA_SIZE
	)
	port map (
		clk    => clk,
		rst    => rst,
		en     => data_ld,
		input  => data_in,
		output => din
	);
	
	-- SPI Slave
	U_SPI_SLAVE : entity work.SPI_SLAVE
   generic map (
        WORD_SIZE => SPI_DATA_SIZE
   )
   port map (
        CLK      => clk,
        RST      => rst,
        SCLK     => sclk,
        CS_N     => cs,
        MOSI     => mosi,
        MISO     => miso,
        DIN      => din,
        DIN_VLD  => din_vld,
        DIN_RDY  => din_rdy,
        DOUT     => dout,
        DOUT_VLD => dout_vld
   );
		
	-- SPI controller
	U_SPI_CONT : entity work.spi_controller
   port map (
        clk         => clk,
        rst         => rst,
        go          => go,
		  din_rdy	  => din_rdy,
		  dout_vld	  => dout_vld,
        din_vld	  => din_vld,
		  data_ld	  => data_ld,
		  dout		  => dout
	);
		
end STR;
