library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mode_fsm is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        switch_mode : in  std_logic;  -- actual switch input (level signal)
        mode        : out std_logic   -- '0' = Clock, '1' = Stopwatch
    );
end entity;

architecture Behavioral of mode_fsm is
    type state_type is (CLOCK_MODE, STOPWATCH_MODE);
    signal current_state, next_state : state_type;

    signal switch_prev : std_logic := '0';  -- to detect switch state changes
begin

    -- Edge detection: remember previous switch state
    process(clk)
    begin
        if rising_edge(clk) then
            switch_prev <= switch_mode;
        end if;
    end process;

    -- FSM State Transition
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= CLOCK_MODE;
        elsif rising_edge(clk) then
            if switch_prev /= switch_mode then  -- switch flipped
                if current_state = CLOCK_MODE then
                    current_state <= STOPWATCH_MODE;
                else
                    current_state <= CLOCK_MODE;
                end if;
            end if;
        end if;
    end process;

    -- Output logic
    mode <= '0' when current_state = CLOCK_MODE else '1';

end architecture;
