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

    signal prev_acl_sclk : std_logic;
    signal csb_counter : unsigned(4 downto 0);
    
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
	    -- Verify correct state behavior after reset
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
		
		-- Verify registers are all read correctly (from Caroline Hagen)
		wait for 10 ms; -- wait100ms timer shortened to 1 ms for testbench
		assert ID_AD = x"AD"
        report "Error: ID_AD should be 0xAD after reading register 0x00"
        severity failure;

        -- Check the value of ID_1D
        assert ID_1D = x"1D"
        report "Error: ID_1D should be 0x1D"
        severity failure;

        -- Check the value of DATA_X
        assert DATA_X = x"12"
        report "Error: DATA_X should be X_VAL"
        severity failure;

        -- Check the value of DATA_Y
        assert DATA_Y = x"34"
        report "Error: DATA_Y should be Y_VAL"
        severity failure;

        -- Check the value of DATA_Z
        assert DATA_Z = x"56"
        report "Error: DATA_Z should be Z_VAL"
        severity failure;
		
		
		--TODO: Verify acl_enabled goes high after initial write
		--			This can be done through the waveform viewer or by writing checks in the testbench
		
		wait;
	end process;
	
	-- ACL SCLK Width Check (from Kevin Nguyen)
	s_chk_spi_sclk : process (ACL_SCLK) 
    begin
        if ACL_SCLK'EVENT then
            if (ACL_SCLK = '1') then
                assert  (ACL_SCLK'LAST_EVENT /= T_SCLK_HI) 
                report "Error: SPI SCLK violated logic high width time."
                severity failure;
            else 
                -- ACL_SCLK'EVENT then
                assert  (ACL_SCLK'LAST_EVENT /= T_SCLK_LO)
                report "Error: SPI SCLK violated logic low width time."
                severity failure;
            end if;
        end if;
    end process;
	
	
	-- Test tming of CSb (from Bill Lee)
	process(clk, reset)
    begin
        if reset = '1' then
            csb_counter <= (others => '0');
        elsif(rising_edge(clk)) then
            if prev_acl_sclk = '0' and ACL_SCLK = '1' then
                if ACL_CSN = '0' then
                    csb_counter <= csb_counter + 1;  
                else
                    assert csb_counter <= 24
                    report "Error: Chip select is driven low for more than 24 SCLK cycles"
                    severity failure;
                    csb_counter <= (others=>'0');
                end if;
            end if;
            prev_acl_sclk <= ACL_SCLK;
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