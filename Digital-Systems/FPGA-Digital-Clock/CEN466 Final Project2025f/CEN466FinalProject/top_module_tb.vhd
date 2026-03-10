library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_top_module is
end tb_top_module;

architecture Behavioral of tb_top_module is
    -- Component Under Test
    component top_module
        port (
            clk, reset               : in std_logic;
            set_clock_hr_btn        : in std_logic;
            set_clock_min_btn       : in std_logic;
            set_clock_sec_btn       : in std_logic;
            mode_switch             : in std_logic;
            format_toggle_switch    : in std_logic;
            start_btn               : in std_logic;
            pause_btn               : in std_logic;
            lap_btn                 : in std_logic;
            reset_sw                : in std_logic;

            sec_1s, sec_10s         : out std_logic_vector(6 downto 0);
            colon_sec_min           : out std_logic_vector(6 downto 0);
            min_1s, min_10s         : out std_logic_vector(6 downto 0);
            colon_min_hr            : out std_logic_vector(6 downto 0);
            hr_1s, hr_10s           : out std_logic_vector(6 downto 0);
            am_pm_led, heartbeat_led: out std_logic;
            pause_en                : out std_logic
        );
    end component;

    -- Signals
    signal clk                   : std_logic := '0';
    signal reset                 : std_logic := '0';
    signal set_clock_hr_btn      : std_logic := '0';
    signal set_clock_min_btn     : std_logic := '0';
    signal set_clock_sec_btn     : std_logic := '0';
    signal mode_switch           : std_logic := '0';
    signal format_toggle_switch  : std_logic := '0';
    signal start_btn             : std_logic := '0';
    signal pause_btn             : std_logic := '0';
    signal lap_btn               : std_logic := '0';
    signal reset_sw              : std_logic := '0';

    signal sec_1s, sec_10s       : std_logic_vector(6 downto 0);
    signal colon_sec_min         : std_logic_vector(6 downto 0);
    signal min_1s, min_10s       : std_logic_vector(6 downto 0);
    signal colon_min_hr          : std_logic_vector(6 downto 0);
    signal hr_1s, hr_10s         : std_logic_vector(6 downto 0);
    signal am_pm_led             : std_logic;
    signal heartbeat_led         : std_logic;
    signal pause_en              : std_logic;

begin
    -- Instantiate DUT
    uut: top_module
        port map (
            clk                   => clk,
            reset                 => reset,
            set_clock_hr_btn      => set_clock_hr_btn,
            set_clock_min_btn     => set_clock_min_btn,
            set_clock_sec_btn     => set_clock_sec_btn,
            mode_switch           => mode_switch,
            format_toggle_switch  => format_toggle_switch,
            start_btn             => start_btn,
            pause_btn             => pause_btn,
            lap_btn               => lap_btn,
            reset_sw              => reset_sw,

            sec_1s                => sec_1s,
            sec_10s               => sec_10s,
            colon_sec_min         => colon_sec_min,
            min_1s                => min_1s,
            min_10s               => min_10s,
            colon_min_hr          => colon_min_hr,
            hr_1s                 => hr_1s,
            hr_10s                => hr_10s,
            am_pm_led             => am_pm_led,
            heartbeat_led         => heartbeat_led,
            pause_en              => pause_en
        );

    -- Clock generation: 20ns period = 50MHz
    clk_process : process
    begin
        clk <= '0';
        wait for 10 ns;
        clk <= '1';
        wait for 10 ns;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Initial reset
        reset <= '1';
        wait for 50 ns;
        reset <= '0';

        -- Set initial clock time
        set_clock_hr_btn <= '1';
        wait for 40 ns;
        set_clock_hr_btn <= '0';

        set_clock_min_btn <= '1';
        wait for 40 ns;
        set_clock_min_btn <= '0';

        set_clock_sec_btn <= '1';
        wait for 40 ns;
        set_clock_sec_btn <= '0';

        -- Toggle format to 12-hour
        format_toggle_switch <= '1';
        wait for 20 ns;
        format_toggle_switch <= '0';

        -- Switch to Stopwatch mode
        mode_switch <= '1';
        wait for 20 ns;
        mode_switch <= '0';

        -- Start Stopwatch
        start_btn <= '1';
        wait for 20 ns;
        start_btn <= '0';

        -- Wait and then pause
        wait for 300 ns;
        pause_btn <= '1';
        wait for 20 ns;
        pause_btn <= '0';

        -- Activate Lap
        lap_btn <= '1';
        wait for 20 ns;
        lap_btn <= '0';

        -- Reset stopwatch logic
        wait for 300 ns;
        reset_sw <= '1';
        wait for 20 ns;
        reset_sw <= '0';

        -- Simulation end
        wait for 500 ns;
        assert false report "Testbench completed." severity note;
        wait;
    end process;

end Behavioral;
