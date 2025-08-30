-- tb_life_fsm.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_life_fsm is
end entity;

architecture sim of tb_life_fsm is
  constant COIN_WIDTH_C : integer := 9;

  -- DUT I/O
  signal clk        : std_logic := '0';
  signal rst        : std_logic := '0';
  signal start      : std_logic := '0';
  signal revive     : std_logic := '0';
  signal quit       : std_logic := '0';
  signal game_rst   : std_logic := '0';
  signal sad_done   : std_logic := '0';
  signal coin_value : unsigned(COIN_WIDTH_C-1 downto 0) := (others => '0');

  signal is_title   : std_logic;
  signal is_alive   : std_logic;
  signal is_dead    : std_logic;

  constant Tclk : time := 10 ns;

  -- === Helpers ===
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

  procedure expect_onehot(constant name : string;
                          constant t, a, d : std_logic) is
    variable sum : integer := 0;
  begin
    if t = '1' then sum := sum + 1; end if;
    if a = '1' then sum := sum + 1; end if;
    if d = '1' then sum := sum + 1; end if;

    assert is_title = t report name & " : is_title mismatch" severity error;
    assert is_alive = a report name & " : is_alive mismatch" severity error;
    assert is_dead  = d report name & " : is_dead mismatch"  severity error;
    assert sum = 1  report name & " : outputs not one-hot"   severity error;

    report "OK: " & name severity note;
  end procedure;

begin
  -- Clock
  clk <= not clk after Tclk/2;

  -- DUT
  dut: entity work.life_fsm
    generic map ( COIN_WIDTH => COIN_WIDTH_C )
    port map (
      clk        => clk,
      rst        => rst,
      start      => start,
      revive     => revive,
      quit       => quit,
      sad_done   => sad_done,
      coin_value => coin_value,
      game_rst   => game_rst,
      is_title   => is_title,
      is_alive   => is_alive,
      is_dead    => is_dead
    );

  -- Stimulus
  stim : process
  begin
    --------------------------------------------------------------------
    -- Reset ? Title
    --------------------------------------------------------------------
    rst <= '1'; tick(2);
    rst <= '0'; tick(1);
    expect_onehot("After rst ? Title", '1','0','0');

    --------------------------------------------------------------------
    -- start: Title ? Rock_Alive
    --------------------------------------------------------------------
    pulse(start, 1);   -- one cycle is enough; DUT samples on rising edge
    tick(1);
    expect_onehot("After start ? Alive", '0','1','0');

    --------------------------------------------------------------------
    -- sad_done: Alive ? Dead
    --------------------------------------------------------------------
    pulse(sad_done, 1);
    tick(1);
    expect_onehot("After sad_done ? Dead", '0','0','1');

    --------------------------------------------------------------------
    -- revive with NOT enough coins (coin_value = 4 < 5): stay Dead
    --------------------------------------------------------------------
    coin_value <= to_unsigned(4, COIN_WIDTH_C);
    pulse(revive, 1);
    tick(1);
    expect_onehot("Revive w/ 4 coins (fail) ? still Dead", '0','0','1');

    --------------------------------------------------------------------
    -- revive with enough coins (coin_value = 5): Dead ? Alive
    --------------------------------------------------------------------
    coin_value <= to_unsigned(5, COIN_WIDTH_C);
    pulse(revive, 1);
    tick(1);
    expect_onehot("Revive w/ 5 coins (ok) ? Alive", '0','1','0');

    --------------------------------------------------------------------
    -- quit from Alive ? Title
    --------------------------------------------------------------------
    pulse(quit, 1);
    tick(1);
    expect_onehot("quit from Alive ? Title", '1','0','0');

    --------------------------------------------------------------------
    -- Start again ? Alive, then game_rst forces Title
    --------------------------------------------------------------------
    pulse(start, 1); tick(1);
    expect_onehot("Start again ? Alive", '0','1','0');

    pulse(game_rst, 1);  -- one-cycle pulse
    tick(1);
    expect_onehot("game_rst ? Title", '1','0','0');

    --------------------------------------------------------------------
    -- From Title, start ? Alive, then drive to Dead and quit ? Title
    --------------------------------------------------------------------
    pulse(start, 1); tick(1);
    expect_onehot("Alive (pre-quit)", '0','1','0');

    pulse(sad_done, 1); tick(1);
    expect_onehot("Dead (pre-quit)", '0','0','1');

    pulse(quit, 1); tick(1);
    expect_onehot("quit from Dead ? Title", '1','0','0');

    report "All life_fsm tests completed." severity note;
    wait;
  end process;

end architecture;
