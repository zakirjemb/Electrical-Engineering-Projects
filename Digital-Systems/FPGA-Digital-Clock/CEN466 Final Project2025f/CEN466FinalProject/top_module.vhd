library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_module is
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;
		  -- set Buttons
		  set_clock_hr_btn : in std_logic;
		  set_clock_min_btn : in std_logic;
		  set_clock_sec_btn : in std_logic;
		  

        -- other Inputs
        mode_switch      : in  std_logic; -- '1' for stopwatch '0' for the clock
        format_toggle_switch  : in  std_logic; -- '1' for 12-hour format '0' for 24-hour format 
        start_btn     : in  std_logic;
        pause_btn     : in  std_logic;
        lap_btn       : in  std_logic;
		 

        -- Switch Input
        reset_sw      : in  std_logic;

        -- Display outputs
        sec_1s, sec_10s, colon_sec_min, min_1s,
        min_10s, colon_min_hr, hr_1s, hr_10s : out std_logic_vector(6 downto 0);

        -- LED indicators
        am_pm_led     : out std_logic;
        heartbeat_led : out std_logic;
		  pause_en  : out std_logic -- active-high when running
    );
end entity;

architecture Behavioral of top_module is
    
     -- signals for clock dividers
    signal clk_1hz, clk_1khz : std_logic;

    -- Debounced inputs
    signal mode_clean, toggle_clean, pause_clean, lap_clean, start_clean : std_logic;
    signal set_clock_min_btn_clean , set_clock_hr_btn_clean, set_clock_sec_btn_clean : std_logic; -- signals for clock setters


    -- Time signals
    signal clk_hr, sw_hr : unsigned(4 downto 0);
    signal clk_min, clk_sec , sw_min, sw_sec : unsigned(5 downto 0);
    signal lap_hr,disp_hr : unsigned(4 downto 0);
    signal lap_min, lap_sec , disp_min, disp_sec : unsigned(5 downto 0);

    -- AM/PM internal logic
    signal am_pm: std_logic;  --  Internal signal for AM/PM status from clock_counter
	 -- signal for clock format 
     signal format_12hr : std_logic; 
	  --signal for mode
	  signal mode : std_logic;
    -- BCD digits
    signal h_tens, h_ones, m_tens, m_ones, s_tens, s_ones : std_logic_vector(3 downto 0);
	 signal colon_indicator : std_logic;

begin

    -- Clock dividers
    clk_div_inst: entity work.clock_divider
        generic map (DIVISOR => 50_000_000)
        port map (clk_in => clk, reset => reset, clk_out => clk_1hz);

    fast_clk_inst: entity work.clock_divider
        generic map (DIVISOR => 50_000)
        port map (clk_in => clk, reset => reset, clk_out => clk_1khz);
		  
		  

   -- debouncer direct component instantiation
	debounce_set_clock_hr: entity work.debouncer 
		generic map ( STABLE_TIME => 10) 
		port map(clk => clk_1khz, reset => reset, btn_in => set_clock_hr_btn, btn_out => set_clock_hr_btn_clean);
	debounce_set_clock_min: entity work.debouncer 
		generic map ( STABLE_TIME => 10)
		port map (clk => clk_1khz, reset => reset, btn_in => set_clock_min_btn, btn_out => set_clock_min_btn_clean);
   debounce_set_clock_sec: entity work.debouncer
		generic map ( STABLE_TIME => 10)	
		port map(clk => clk_1khz, reset => reset, btn_in => set_clock_sec_btn, btn_out => set_clock_sec_btn_clean);

   debounce_toggle: entity work.debouncer
	     generic map ( STABLE_TIME => 10)
        port map (clk => clk_1khz, reset => reset, btn_in => format_toggle_switch, btn_out => toggle_clean);
	debounce_start: entity work.debouncer
	     generic map ( STABLE_TIME => 10)
        port map (clk => clk_1khz, reset => reset, btn_in => start_btn, btn_out => start_clean);
  debounce_pause: entity work.debouncer
	     generic map ( STABLE_TIME => 10)
        port map (clk => clk_1khz, reset => reset, btn_in => pause_btn, btn_out => pause_clean);
  debounce_lap: entity work.debouncer
	     generic map ( STABLE_TIME => 10)
        port map (clk => clk_1khz, reset => reset, btn_in => lap_btn, btn_out => lap_clean);
  debounce_mode : entity work.debouncer
	     generic map ( STABLE_TIME => 10)
        port map (clk => clk_1khz, reset => reset, btn_in => mode_switch, btn_out => mode_clean);


		  
		  
  
   mode_fsm_inst: entity work.mode_fsm
		port map (clk => clk_1khz, reset => reset, switch_mode => mode_clean, mode => mode);


    format_toggle_inst: entity work.format_toggle
    port map (
        clk => clk_1khz,
        reset => reset,
        switch_in => toggle_clean,  
        format_12hr => format_12hr
    );
		  
		  
		  pause_control: entity work.pause_control
		   port map (
        clk => clk,
        reset => reset,   
        pause_btn => pause_clean,  
        mode => mode,                  -- '1' = Stopwatch mode
        pause_en => pause_en,            -- active-high when running
        blink_colon => colon_indicator         -- toggles colon LED
    );

    -- Clock Counter
    clk_counter_inst: entity work.clock_counter
        port map (
            clk => clk_1hz, 
				reset => reset,
				format_12hr => format_12hr,
				set_hr => set_clock_hr_btn_clean, 
				set_min => set_clock_min_btn_clean, 
				set_sec => set_clock_sec_btn_clean, 
            hours => clk_hr,
				minutes => clk_min, 
				seconds => clk_sec,
            am_pm => am_pm
				
        );

    -- Stopwatch Counter
    sw_counter_inst: entity work.stopwatch_counter
        port map (
            clk => clk_1hz, reset => reset_sw,
            start => start_clean, pause => pause_clean,
            hours => sw_hr, minutes => sw_min, seconds => sw_sec
        );

    -- Lap Control
    lap_control_inst: entity work.lap_control
        port map (
            clk => clk_1hz, reset => reset,
            lap_btn => lap_clean, mode => mode_clean,
            hours_in => sw_hr, minutes_in => sw_min, seconds_in => sw_sec,
            hours_out => lap_hr, minutes_out => lap_min, seconds_out => lap_sec
        );

    -- Display Selection Logic
    disp_hr   <= lap_hr   when mode = '1' else clk_hr;
    disp_min  <= lap_min  when mode = '1' else clk_min;
    disp_sec  <= lap_sec  when mode = '1' else clk_sec;

    -- Binary to BCD
    bin_to_bcd_hr: entity work.binary_to_bcd
	     generic map(N => 5)
        port map (binary_in => disp_hr, tens => h_tens, ones => h_ones);

    bin_to_bcd_min: entity work.binary_to_bcd
	     generic map(N => 6)
        port map (binary_in => disp_min, tens => m_tens, ones => m_ones);

    bin_to_bcd_sec: entity work.binary_to_bcd
	     generic map(N => 6)
        port map (binary_in => disp_sec, tens => s_tens, ones => s_ones);

    -- Segment Display Mapping
    seg0_driver: entity work.seven_segment_driver port map(digit => s_ones, seg => sec_1s);
    seg1_driver: entity work.seven_segment_driver port map(digit => s_tens, seg => sec_10s);
    seg3_driver: entity work.seven_segment_driver port map(digit => m_ones, seg => min_1s);
    seg4_driver: entity work.seven_segment_driver port map(digit => m_tens, seg => min_10s);
    seg6_driver: entity work.seven_segment_driver port map(digit => h_ones, seg => hr_1s);
    seg7_driver: entity work.seven_segment_driver port map(digit => h_tens, seg => hr_10s);

    -- Colon Blink via Process
    process(clk)
    begin
        if rising_edge(clk) then
            if colon_indicator = '1' then
                colon_sec_min <= "1110110"; -- colon on
                colon_min_hr <= "1110110"; -- colon on
            else
                colon_sec_min <= "1111111"; -- colon off
               colon_min_hr <= "1111111"; -- colon off
            end if;
        end if;
    end process;

    -- Heartbeat LED Generator
    heartbeat_inst: entity work.heartbeat_gen
        port map (clk => clk, reset => reset, led_out => heartbeat_led);



-- ON only during AM in 12hr mode, OFF otherwise
am_pm_led <= '1' when (toggle_clean = '1' and am_pm = '0') else '0';

end Behavioral;
