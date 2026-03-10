library IEEE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debouncer is
    generic (
        STABLE_TIME : integer := 500_000  -- ~10ms at 50MHz
    );
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        btn_in  : in  std_logic;
        btn_out : out std_logic
    );
end entity;

architecture Behavioral of debouncer is
    signal count    : integer range 0 to STABLE_TIME := 0;
    signal stable   : std_logic := '0';
    signal sampled  : std_logic := '0';
begin
    process(clk, reset)
    begin
        if reset = '1' then
            count   <= 0;
            stable  <= '0';
            sampled <= '0';
            btn_out <= '0';
        elsif rising_edge(clk) then
            if btn_in /= sampled then
                sampled <= btn_in;
                count   <= 0;
            elsif count < STABLE_TIME then
                count <= count + 1;
                btn_out <= '0';
            else
                if sampled /= stable then
                    stable  <= sampled;
                    btn_out <= sampled;
                else
                    btn_out <= '0';
                end if;
            end if;
        end if;
    end process;
end architecture;

