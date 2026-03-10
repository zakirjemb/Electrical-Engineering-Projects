
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lap_control is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        lap_btn     : in  std_logic;
        mode        : in  std_logic;  -- Only works in stopwatch mode
        hours_in    : in  unsigned(4 downto 0);
        minutes_in  : in  unsigned(5 downto 0);
        seconds_in  : in  unsigned(5 downto 0);
        hours_out   : out unsigned(4 downto 0);
        minutes_out : out unsigned(5 downto 0);
        seconds_out : out unsigned(5 downto 0)
    );
end entity;

architecture Behavioral of lap_control is
    signal latched_h : unsigned(4 downto 0) := (others => '0');
    signal latched_m, latched_s : unsigned(5 downto 0) := (others => '0');
    signal lap_active   : std_logic := '0';
    signal lap_btn_prev : std_logic := '0';
begin
    process(clk, reset)
    begin
        if reset = '1' then
            lap_active   <= '0';
            lap_btn_prev <= '0';
            latched_h    <= (others => '0');
            latched_m    <= (others => '0');
            latched_s    <= (others => '0');
        elsif rising_edge(clk) then
            lap_btn_prev <= lap_btn;

            if (mode = '1') and (lap_btn = '1' and lap_btn_prev = '0') then
                lap_active <= not lap_active;
                if lap_active = '0' then
                    latched_h <= hours_in;
                    latched_m <= minutes_in;
                    latched_s <= seconds_in;
                end if;
            end if;
        end if;
    end process;

    -- Output: Latched values if lap is active, else live stopwatch time
    hours_out   <= latched_h when lap_active = '1' else hours_in;
    minutes_out <= latched_m when lap_active = '1' else minutes_in;
    seconds_out <= latched_s when lap_active = '1' else seconds_in;
end architecture;

