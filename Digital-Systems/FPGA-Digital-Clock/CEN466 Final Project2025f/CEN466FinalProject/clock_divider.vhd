library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock_divider is
    generic (
        DIVISOR: integer := 50_000_000  -- 50 MHz for DE2 board
    );
    port (
        clk_in  : in std_logic;
        reset   : in  std_logic;
        clk_out : out std_logic  -- 1 Hz pulse output
    );
end entity;

architecture Behavioral of clock_divider is
    signal counter : integer range 0 to (DIVISOR - 1) := 0;
    signal pulse   : std_logic := '0';
begin
    process(clk_in, reset)
    begin
        if reset = '1' then
            counter <= 0;
            pulse   <= '0';
        elsif rising_edge(clk_in) then
            if counter = DIVISOR - 1 then
                counter <= 0;
                pulse   <= not pulse;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    clk_out <= pulse;
end architecture;

