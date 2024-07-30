----------------------------------------------------------------------------------
-- 
-- Accelerometer Testbench to verify Accel Controller for Lab 5
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_textio.all;
use work.all;

entity accel_spi_rw_tb is
end entity accel_spi_rw_tb;

architecture sim of accel_spi_rw_tb is

	signal clk : std_logic;
	signal reset : std_logic;
	
	--SPI Control Signals
	signal ACL_CSN, ACL_MOSI, ACL_SCLK, ACL_MISO : std_logic;
	
	--Output from Model which denotes if Accel is enabled/powered up
	signal acl_enabled : std_logic;
	
	signal ID_AD, ID_1D, DATA_X, DATA_Y, DATA_Z  : STD_LOGIC_VECTOR(7 downto 0);

    constant T_SCLK_HI : time := 50ns;
    constant T_SCLK_LO : time := 50ns;

begin

	--100MHz clock
	process
	begin
		clk <= '0';
		wait for 5 ns;
		clk <= '1';
		wait for 5 ns;
	end process;
	
	--Main testbench process
	process
	begin
		reset <= '1';
		wait for 1 ns;
		
		assert  ACL_CSN = '1'
		report "Error: Reset condition should have ACL_CSN = '1'"
		severity failure;
		
		assert  ACL_SCLK = '0'
        report "Error: Reset condition should have ACL_SCLK = '0'"
        severity failure;
		
		wait for 100 ns;
		reset <= '0';
		
		--TODO: Add Verification for DATA_X, Y, Z, and ID_AD/1D
		--TODO: Verify acl_enabled goes high after initial write
		--			This can be done through the waveform viewer or by writing checks in the testbench
		
		wait;
	end process;

    s_chk_spi_sclk : process (ACL_SCLK) 
    begin

        if ACL_SCLK'EVENT then
            if (ACL_SCLK = '1') then
                assert  (ACL_SCLK'LAST_EVENT /= T_SCLK_HI) 
                report "Error: SPI SCLK violated logic high width time."
                severity failure;
            else 
                ACL_SCLK'EVENT then
                assert  (ACL_SCLK'LAST_EVENT /= T_SCLK_LO) 
                report "Error: SPI SCLK violated logic low width time."
                severity failure;
            end if;
        end if;
    end process;
	
	--ACL Model
	ACL_DUMMY : entity acl_model port map (
		rst => reset,
		ACL_CSN => ACL_CSN, 
		ACL_MOSI => ACL_MOSI,
		ACL_SCLK => ACL_SCLK,
		ACL_MISO => ACL_MISO,
		--- ACCEL VALUES ---
		X_VAL => x"12",
		Y_VAL => x"34",
		Z_VAL => x"56",
		acl_enabled => acl_enabled);
	
	--Unit under test
	ACEL_DUT : entity accel_spi_rw port map (
		clk => clk,
		reset =>  reset,
		--Values from Accel
		DATA_X => DATA_X,
		DATA_Y => DATA_Y,
		DATA_Z => DATA_Z,
		ID_AD => ID_AD,
		ID_1D => ID_1D,
		--SPI Signals
		CSb => ACL_CSN,
		MOSI => ACL_MOSI,
		SCLK => ACL_SCLK,
		MISO => ACL_MISO);

end sim;