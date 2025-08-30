-- tb_mood_fsm.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mood_fsm is
end entity;

architecture sim of tb_mood_fsm is
  constant COIN_WIDTH_C : integer := 9;

  -- DUT ports
  signal clk        : std_logic := '0';
  signal rst        : std_logic := '0';
  signal pet        : std_logic := '0';
  signal feed       : std_logic := '0';
  signal happy_done : std_logic := '0';
  signal bored_done : std_logic := '0';
  signal mad_done   : std_logic := '0';
  signal sad_done   : std_logic := '0';
  signal dance_done : std_logic := '0';
  signal pet_done   : std_logic := '0';
  signal revive     : std_logic := '0';
  signal game_rst   : std_logic := '0';
  signal is_alive   : std_logic := '1';
  signal coin_value : unsigned(COIN_WIDTH_C-1 downto 0) := (others => '0');

  signal is_happy   : std_logic;
  signal is_bored   : std_logic;
  signal is_mad     : std_logic;
  signal is_sad     : std_logic;
  signal is_dance   : std_logic;
  signal is_pet     : std_logic;

  constant Tclk : time := 10 ns;

  -- Helpers
  procedure tick(n : positive := 1) is
  begin
    for i in 1 to n loop
      wait until rising_edge(clk);
    end loop;
  end procedure;

  procedure pulse(signal s : out std_logic; cycles : positive := 1) is
  begin
    for i in 1 to cycles loop
      s <= '1'; tick(1);
      s <= '0'; tick(1);
    end loop;
  end procedure;

  procedure expect_state(
    constant name : string;
    constant h, b, m, dnc, s, p : std_logic
  ) is
  begin
    assert is_happy = h report name & " : is_happy mismatch" severity error;
    assert is_bored = b report name & " : is_bored mismatch" severity error;
    assert is_mad   = m report name & " : is_mad mismatch"   severity error;
    assert is_dance = dnc report name & " : is_dance mismatch" severity error;
    assert is_sad   = s report name & " : is_sad mismatch"   severity error;
    assert is_pet   = p report name & " : is_pet mismatch"   severity error;
    report "OK: " & name severity note;
  end procedure;

begin
  --------------------------------------------------------------------
  -- Clock
  --------------------------------------------------------------------
  clk <= not clk after Tclk/2;

  --------------------------------------------------------------------
  -- DUT
  --------------------------------------------------------------------
  dut: entity work.mood_fsm
    generic map ( COIN_WIDTH => COIN_WIDTH_C )
    port map (
      clk        => clk,
      rst        => rst,
      pet        => pet,
      feed       => feed,
      happy_done => happy_done,
      bored_done => bored_done,
      mad_done   => mad_done,
      sad_done   => sad_done,
      dance_done => dance_done,
      pet_done   => pet_done,
      revive     => revive,
      game_rst   => game_rst,
      is_alive   => is_alive,
      coin_value => coin_value,
      is_happy   => is_happy,
      is_bored   => is_bored,
      is_mad     => is_mad,
      is_sad     => is_sad,
      is_dance   => is_dance,
      is_pet     => is_pet
    );

  --------------------------------------------------------------------
  -- Stimulus
  --------------------------------------------------------------------
  stimulus : process
  begin
    ----------------------------------------------------------------
    -- Global reset ? Happy
    ----------------------------------------------------------------
    rst <= '1'; tick(2);
    rst <= '0'; tick(1);
    expect_state("After rst (should be Happy)", '1','0','0','0','0','0');

    ----------------------------------------------------------------
    -- Pet from Happy ? Petting ? back to Happy (pet_done)
    ----------------------------------------------------------------
    pulse(pet, 1);                 -- edge-detected inside DUT
    tick(1);
    expect_state("Petting from Happy", '0','0','0','0','0','1');

    pulse(pet_done, 1);
    tick(1);
    expect_state("Return to Happy after pet_done", '1','0','0','0','0','0');

    ----------------------------------------------------------------
    -- Happy -> Bored (happy_done)
    ----------------------------------------------------------------
    pulse(happy_done, 1);
    tick(1);
    expect_state("Now Bored", '0','1','0','0','0','0');

    ----------------------------------------------------------------
    -- Pet from Bored ? Petting ? return to Happy (per policy)
    ----------------------------------------------------------------
    pulse(pet, 1);
    tick(1);
    expect_state("Petting from Bored", '0','0','0','0','0','1');

    pulse(pet_done, 1);
    tick(1);
    expect_state("Return to Happy after pet from Bored", '1','0','0','0','0','0');

    ----------------------------------------------------------------
    -- Happy -> Bored -> Mad (happy_done, bored_done)
    ----------------------------------------------------------------
    pulse(happy_done, 1); tick(1);
    expect_state("Bored again", '0','1','0','0','0','0');

    pulse(bored_done, 1); tick(1);
    expect_state("Now Mad", '0','0','1','0','0','0');

    ----------------------------------------------------------------
    -- Feed with enough coins ? Happy_Dance
    ----------------------------------------------------------------
    coin_value <= to_unsigned(3, COIN_WIDTH_C);
    pulse(feed, 1);
    tick(1);
    expect_state("Happy_Dance after feed (>=3 coins)", '0','0','0','1','0','0');

    -- Finish dance ? Happy
    pulse(dance_done, 1);
    tick(1);
    expect_state("Back to Happy after dance", '1','0','0','0','0','0');

    ----------------------------------------------------------------
    -- Walk to Sad: Happy -> Bored -> Mad -> Sad
    ----------------------------------------------------------------
    pulse(happy_done, 1); tick(1);
    expect_state("Bored before Sad path", '0','1','0','0','0','0');

    pulse(bored_done, 1); tick(1);
    expect_state("Mad before Sad", '0','0','1','0','0','0');

    pulse(mad_done, 1); tick(1);
    expect_state("Now Sad", '0','0','0','0','1','0');

    -- (Optional) acknowledge sad_done (no transition here per your logic)
    pulse(sad_done, 1); tick(1);
    expect_state("Still Sad after sad_done (no effect)", '0','0','0','0','1','0');

    ----------------------------------------------------------------
    -- Revive pulse ? immediate Bored
    ----------------------------------------------------------------
    pulse(revive, 1);
    tick(1);
    expect_state("Bored after revive", '0','1','0','0','0','0');

    ----------------------------------------------------------------
    -- NEW GAME reset (game_rst) ? Happy
    ----------------------------------------------------------------
    game_rst <= '1'; tick(1);
    game_rst <= '0'; tick(1);
    expect_state("Happy after game_rst", '1','0','0','0','0','0');

    ----------------------------------------------------------------
    -- Gate outputs by is_alive = '0' (everything off)
    ----------------------------------------------------------------
    is_alive <= '0'; tick(1);
    -- All outputs should be '0' when not alive
    expect_state("Outputs gated when is_alive='0'", '0','0','0','0','0','0');

    report "All tests completed." severity note;
    wait;
  end process;

end architecture;
