library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock_counter is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        format_12hr : in  std_logic;        -- '1' = 12hr, '0' = 24hr
		  set_hr      : in  std_logic;
        set_min     : in  std_logic;
        set_sec     : in  std_logic;
        hours       : out unsigned(4 downto 0);
        minutes     : out unsigned(5 downto 0);
        seconds     : out unsigned(5 downto 0);
        am_pm       : out std_logic      -- '1' = AM, '0' = PM
        
    );
end entity;

architecture Behavioral of clock_counter is
    signal hr :  unsigned(4 downto 0) := (others => '0');
    signal min, sec : unsigned(5 downto 0) := (others => '0');
    signal am_flag : std_logic := '1'; -- Start at AM for reset
    signal hr_display : unsigned( 4 downto 0);
begin
    process(clk, reset)
    begin
	      -- reset
        if reset = '1' then
            hr <= (others => '0');
            min <= (others => '0');
            sec <= (others => '0');
            am_flag <= '1'; -- AM
        elsif rising_edge(clk) then

		  
            -- Setting logic with priority 
            if set_hr = '1' then
                if hr = 23 then
                    hr <= (others => '0');
                else
                    hr <= hr + 1;
                end if;
            elsif set_min = '1' then
                if min = 59 then
                    min <= (others => '0');
                else
                    min <= min + 1;
                end if;
            elsif set_sec = '1' then
                if sec = 59 then
                    sec <= (others => '0');
                else
                    sec <= sec + 1;
                end if;
            else
                -- Counting logic
                if sec = 59 then
                    sec <= (others => '0');
                    if min = 59 then
                        min <= (others => '0');
                        if hr = 23 then
                            hr <= (others => '0');
                        else
                            hr <= hr + 1;
                        end if;
                    else
                        min <= min + 1;
                    end if;
                else
                    sec <= sec + 1;
                end if;

                -- AM/PM flip: Flip at 12:00:00, both directions
                if (hr = 11 and min = 59 and sec = 59) or (hr = 23 and min = 59 and sec = 59) then
                    am_flag <= not am_flag;
                end if;
            end if;
        end if;
    end process;

    -- 12hr/24hr Display mapping (returns 12 for 0, otherwise hr mod 12)
    hr_display <= to_unsigned(12, 5) when (format_12hr = '1' and hr = 0) else
                  hr - 12             when (format_12hr = '1' and hr > 12) else
                  hr                  when (format_12hr = '0' or hr = 12);

    hours   <= hr_display;
    minutes <= min;
    seconds <= sec;
    am_pm   <= am_flag;
end architecture;
