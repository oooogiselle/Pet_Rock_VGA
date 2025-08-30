library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_petrock_behavioral_shell is
end entity;

architecture sim of tb_petrock_behavioral_shell is
  constant CLK_PERIOD : time := 10 ns;  -- 100 MHz

  -- DUT inputs
  signal clk      : std_logic := '0';
  signal rst      : std_logic := '0';
  signal start    : std_logic := '0';
  signal revive   : std_logic := '0';
  signal quit     : std_logic := '0';
  signal pet      : std_logic := '0';
  signal feed     : std_logic := '0';
  signal new_game : std_logic := '0';

  -- DUT outputs
  signal is_title : std_logic;
  signal is_alive : std_logic;
  signal is_dead  : std_logic;

  signal is_happy : std_logic;
  signal is_bored : std_logic;
  signal is_mad   : std_logic;
  signal is_sad   : std_logic;
  signal is_dance : std_logic;
  signal is_pet   : std_logic;

  signal coin_value : unsigned(8 downto 0);
  signal coin_zero  : std_logic;
  signal spend_fail : std_logic;
begin
  --------------------------------------------------------------------
  -- Clock
  --------------------------------------------------------------------
  clk_process: process
  begin
    clk <= '0'; wait for CLK_PERIOD/2;
    clk <= '1'; wait for CLK_PERIOD/2;
  end process;

  --------------------------------------------------------------------
  -- DUT  (faster timers for simulation)
  --------------------------------------------------------------------
  dut: entity work.petrock_behavioral_shell
    generic map (
      TIMER_WIDTH => 3       -- <<< speed up timeouts for sim
    )
    port map (
      clk        => clk,
      rst        => rst,
      start      => start,
      revive     => revive,
      quit       => quit,
      pet        => pet,
      feed       => feed,
      new_game   => new_game,
      is_title   => is_title,
      is_alive   => is_alive,
      is_dead    => is_dead,
      is_happy   => is_happy,
      is_bored   => is_bored,
      is_mad     => is_mad,
      is_sad     => is_sad,
      is_dance   => is_dance,
      is_pet     => is_pet,
      coin_value => coin_value,
      coin_zero  => coin_zero,
      spend_fail => spend_fail
    );

  --------------------------------------------------------------------
  -- Stimulus (kept in your fixed-delay style)
  --------------------------------------------------------------------
  stim: process
  begin
    -- Reset
    rst <= '1';            wait for 200 ns;
    rst <= '0';            wait for 200 ns;

    -- START (pulse)
    start <= '1';          wait for 200 ns;
    start <= '0';

    -- Let timers run all the way to DEAD (with TIMER_WIDTH=3 this is quick).
    -- Use a comfortable fixed wait instead of waits on signals.
    wait for 50 us;

    -- While DEAD: try FEED and PET (should be ignored / no spend / no mood change)
    feed <= '1';           wait for 200 ns;  feed <= '0';
    wait for 1 us;
    pet  <= '1';           wait for 200 ns;  pet  <= '0';
    wait for 1 us;

    -- REVIVE (pulse) - your shell gates it so it only passes while DEAD
    revive <= '1';         wait for 200 ns;  revive <= '0';

    -- Give time for state registers to update and Bored to assert
    wait for 2 us;

    -- QUIT back to Title
    quit <= '1';           wait for 200 ns;  quit <= '0';
    wait for 1 us;

    -- NEW GAME (refill coins & reset mood/timers), then START again
    new_game <= '1';       wait for 200 ns;  new_game <= '0';
    wait for 1 us;

    start <= '1';          wait for 200 ns;  start <= '0';

    -- Run a bit, then finish
    wait for 10 us;
    assert false report "Simulation finished" severity failure;
  end process;

end architecture;
