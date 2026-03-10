library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pause_control is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        pause_btn   : in  std_logic;
        mode        : in  std_logic;           -- '1' = Stopwatch mode
        pause_en    : out std_logic;          -- active-high when running
        blink_colon : out std_logic           -- toggles colon LED
    );
end entity;

architecture Behavioral of pause_control is
    signal paused          : std_logic := '0';
    signal colon_blink     : std_logic := '1';
    signal counter         : integer range 0 to 25_000_000 := 0;  -- half-second blink
    signal prev_btn        : std_logic := '0';
begin
    process(clk, reset)
    begin
        if reset = '1' then
            paused      <= '0';
            colon_blink <= '1';
            counter     <= 0;
            prev_btn    <= '0';
        elsif rising_edge(clk) then
            prev_btn <= pause_btn;

            if mode = '1' then  -- Only applies in stopwatch mode
                if (pause_btn = '1' and prev_btn = '0') then
                    paused <= not paused;
                end if;

                if paused = '1' then
                    if counter = 25_000_000 then
                        counter <= 0;
                        colon_blink <= not colon_blink;
                    else
                        counter <= counter + 1;
                    end if;
                else
                    colon_blink <= '1';
                    counter <= 0;
                end if;
            else
                paused <= '0';
                colon_blink <= '1';
                counter <= 0;
            end if;
        end if;
    end process;

    pause_en    <= not paused;
    blink_colon <= colon_blink;
end architecture;

