-- tb_coin_manager.vhd  (VHDL-93 friendly)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_coin_manager is
end entity;

architecture sim of tb_coin_manager is
  constant COIN_WIDTH_C : integer := 9;
  constant Tclk : time := 10 ns;

  -- DUT I/O
  signal clk        : std_logic := '0';
  signal rst        : std_logic := '0';
  signal happy_coin : std_logic := '0';
  signal coin_init  : std_logic := '0';
  signal revive     : std_logic := '0';
  signal feed       : std_logic := '0';

  signal coin_value : unsigned(COIN_WIDTH_C-1 downto 0);
  signal coin_zero  : std_logic;
  signal spend_fail : std_logic;

  -- expected tracking (for simple checks)
  signal exp_val    : unsigned(COIN_WIDTH_C-1 downto 0) := (others => '0');

begin
  --------------------------------------------------------------------
  -- Clock
  --------------------------------------------------------------------
  clk <= not clk after Tclk/2;

  --------------------------------------------------------------------
  -- DUT
  --------------------------------------------------------------------
  dut: entity work.coin_manager
    generic map ( COIN_WIDTH => COIN_WIDTH_C )
    port map (
      clk        => clk,
      rst        => rst,
      happy_coin => happy_coin,
      coin_init  => coin_init,
      revive     => revive,
      feed       => feed,
      coin_value => coin_value,
      coin_zero  => coin_zero,
      spend_fail => spend_fail
    );

  --------------------------------------------------------------------
  -- Stimulus
  --------------------------------------------------------------------
  stim : process
  begin
    -- ========= RESET (async in DUT) -> START_COINS (=10) =========
    rst <= '1';
    wait for 3 ns;                         -- async path; no clock needed
    assert coin_value = to_unsigned(10, COIN_WIDTH_C)
      report "After rst: coin_value not 10" severity error;
    assert coin_zero = '0' report "After rst: coin_zero should be 0" severity error;

    -- release reset
    wait until rising_edge(clk);
    rst <= '0';
    wait until rising_edge(clk);

    -- ========= EARN via happy_coin (two pulses) =========
    -- pulse 1 (hold high for a full cycle so edge-sampling sees it)
    happy_coin <= '1';
    wait until rising_edge(clk);
    happy_coin <= '0';
    wait until rising_edge(clk);  -- value updates on the sampled rising edge
    assert coin_value = to_unsigned(11, COIN_WIDTH_C)
      report "After +1: coin_value not 11" severity error;

    -- pulse 2
    happy_coin <= '1';
    wait until rising_edge(clk);
    happy_coin <= '0';
    wait until rising_edge(clk);
    assert coin_value = to_unsigned(12, COIN_WIDTH_C)
      report "After +2: coin_value not 12" severity error;

    -- ========= SPEND 3 via feed (edge-detected) =========
    feed <= '1';
    wait until rising_edge(clk);
    feed <= '0';
    wait until rising_edge(clk);
    assert coin_value = to_unsigned(9, COIN_WIDTH_C)
      report "After feed spend 3: coin_value not 9" severity error;
    assert spend_fail = '0' report "spend_fail asserted on successful feed" severity error;

    -- ========= SPEND 5 via revive (edge-detected) =========
    revive <= '1';
    wait until rising_edge(clk);
    revive <= '0';
    wait until rising_edge(clk);
    assert coin_value = to_unsigned(4, COIN_WIDTH_C)
      report "After revive spend 5: coin_value not 4" severity error;
    assert spend_fail = '0' report "spend_fail asserted on successful revive" severity error;

    -- ========= coin_init (async level) -> START_COINS (=10) =========
    coin_init <= '1';                       -- async in sensitivity list
    wait for 1 ns;                          -- no clock edge required
    assert coin_value = to_unsigned(10, COIN_WIDTH_C)
      report "After coin_init: coin_value not 10" severity error;
    assert spend_fail = '0' report "spend_fail should be 0 after coin_init" severity error;
    coin_init <= '0';
    wait until rising_edge(clk);

    -- ========= Drain to 1 via consecutive FEED (3 each): 10->7->4->1 =========
    feed <= '1'; wait until rising_edge(clk); feed <= '0'; wait until rising_edge(clk);
    assert coin_value = to_unsigned(7, COIN_WIDTH_C)
      report "Drain step 1 failed" severity error;

    feed <= '1'; wait until rising_edge(clk); feed <= '0'; wait until rising_edge(clk);
    assert coin_value = to_unsigned(4, COIN_WIDTH_C)
      report "Drain step 2 failed" severity error;

    feed <= '1'; wait until rising_edge(clk); feed <= '0'; wait until rising_edge(clk);
    assert coin_value = to_unsigned(1, COIN_WIDTH_C)
      report "Drain step 3 failed" severity error;

    -- ========= Try FEED again with only 1 coin -> clamp to 0 + spend_fail 1-cycle =========
    feed <= '1'; wait until rising_edge(clk); feed <= '0';
    -- On the same sampled edge, DUT sets value to 0 and spend_fail = '1'
    wait for 1 ns;  -- settle
    assert coin_value = to_unsigned(0, COIN_WIDTH_C)
      report "Feed fail: coin_value not clamped to 0" severity error;
    assert coin_zero = '1' report "Feed fail: coin_zero should be 1" severity error;
    assert spend_fail = '1' report "Feed fail: spend_fail should pulse 1" severity error;

    -- Next clock: spend_fail must clear
    wait until rising_edge(clk);
    assert spend_fail = '0' report "spend_fail did not clear after 1 cycle" severity error;

    -- ========= Try REVIVE at 0 -> fail (still 0, spend_fail pulse) =========
    revive <= '1'; wait until rising_edge(clk); revive <= '0';
    wait for 1 ns;
    assert coin_value = to_unsigned(0, COIN_WIDTH_C)
      report "Revive fail: coin_value changed from 0" severity error;
    assert spend_fail = '1' report "Revive fail: spend_fail should pulse 1" severity error;

    wait until rising_edge(clk);
    assert spend_fail = '0' report "spend_fail did not clear after revive fail" severity error;

    -- ========= Earn again from 0 -> coin_zero deasserts =========
    happy_coin <= '1'; wait until rising_edge(clk); happy_coin <= '0';
    wait until rising_edge(clk);
    assert coin_value = to_unsigned(1, COIN_WIDTH_C)
      report "Earn from 0: coin_value not 1" severity error;
    assert coin_zero = '0' report "Earn from 0: coin_zero should be 0" severity error;

    report "tb_coin_manager completed OK." severity note;
    wait;
  end process;

end architecture;
