library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity binary_to_bcd is
    generic (
        N    : integer := 6  -- width of input binary_in (set to 5, or 6)
    );
    port (
        binary_in : in  unsigned(N-1 downto 0);
        tens      : out std_logic_vector(3 downto 0);
        ones      : out std_logic_vector(3 downto 0)
    );
end entity;

architecture Behavioral of binary_to_bcd is
    -- Shift register: [tens][ones][binary] = 4+4+N
    signal shift_reg : unsigned( N+7 downto 0);
begin
    process(binary_in)
        variable temp_reg : unsigned(N+7 downto 0);
    begin
        temp_reg := (others => '0');
        temp_reg(N-1 downto 0) := binary_in;

        -- Double Dabble: N_BITS shifts
        for i in 0 to N-1 loop
            if temp_reg(N+7 downto N+4) > 4 then
                temp_reg(N +7 downto N +4) := temp_reg(N +7 downto N+4) + 3;
            end if;
            if temp_reg(N+3 downto N) > 4 then
                temp_reg(N+3 downto N) := temp_reg(N+3 downto N) + 3;
            end if;
            temp_reg := temp_reg(N+6 downto 0) & '0'; -- shift left by 1
        end loop;

        tens <= std_logic_vector(temp_reg(N+7 downto N+4));
        ones <= std_logic_vector(temp_reg(N+3 downto N));
    end process;
end architecture;
