library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity stopwatch_counter is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        start   : in  std_logic;
        pause   : in  std_logic;
        hours   : out unsigned(4 downto 0);
        minutes : out unsigned(5 downto 0);
        seconds : out unsigned(5 downto 0)
    );
end entity;

architecture Behavioral of stopwatch_counter is
    signal hr : unsigned(4 downto 0) := (others => '0');
    signal min, sec : unsigned(5 downto 0) := (others => '0');
    signal running : std_logic := '0';
begin
    process(clk, reset)
    begin
        if reset = '1' then
            hr <= (others => '0');
            min <= (others => '0');
            sec <= (others => '0');
            running <= '0';
        elsif rising_edge(clk) then
            if start = '1' then
                running <= '1';
            elsif pause = '1' then
                running <= '0';
            end if;

            if running = '1' then
                if sec = 59 then
                    sec <= (others => '0');
                    if min = 59 then
                        min <= (others => '0');
                        hr <= hr + 1;
                    else
                        min <= min + 1;
                    end if;
                else
                    sec <= sec + 1;
                end if;
            end if;
        end if;
    end process;

    hours   <= hr;
    minutes <= min;
    seconds <= sec;
end architecture;

