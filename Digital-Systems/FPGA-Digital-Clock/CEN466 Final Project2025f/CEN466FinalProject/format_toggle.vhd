library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity format_toggle is
    port (
        clk         : in  std_logic;      -- for debouning
        reset       : in  std_logic;
        switch_in   : in  std_logic;       -- Switch input (0 = 24hr, 1 = 12hr)
        format_12hr : out std_logic        -- '0' = 24-hour, '1' = 12-hour
    );
end entity;

architecture Behavioral of format_toggle is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            format_12hr <= '0';  -- Default to 24-hour on reset
        elsif rising_edge(clk) then
            format_12hr <= switch_in;  -- Directly pass switch state
        end if;
    end process;
end architecture;