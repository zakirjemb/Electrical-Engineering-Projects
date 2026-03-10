library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity heartbeat_gen is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        led_out : out std_logic
    );
end entity;

architecture Behavioral of heartbeat_gen is
    constant MAX_COUNT : integer := 25_000_000; -- Half-period for 1Hz at 50MHz
    signal counter     : integer range 0 to MAX_COUNT := 0;
    signal led_state   : std_logic := '0';
begin
    process(clk, reset)
    begin
        if reset = '1' then
            counter   <= 0;
            led_state <= '0';
        elsif rising_edge(clk) then
            if counter = MAX_COUNT then
                counter   <= 0;
                led_state <= not led_state;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    led_out <= led_state;
end architecture;

