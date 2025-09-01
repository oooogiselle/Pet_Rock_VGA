library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity coin_manager is
  generic (
    COIN_WIDTH  : integer := 9
  );
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;

    -- inputs
    happy_coin  : in  std_logic;   -- 1-cycle pulse: earn +1
    coin_init   : in  std_logic;   -- async/sync re-init to START_COINS
    revive      : in  std_logic;   -- spend 5 coins
    feed        : in  std_logic;   -- spend 3 coins (for happy dance)

    -- outputs
    coin_value  : out unsigned(COIN_WIDTH-1 downto 0);
    coin_zero   : out std_logic;
    spend_fail  : out std_logic  -- 1-cycle pulse when spend fails
  );
end entity;

architecture rtl of coin_manager is
  -- registers
  signal coin_v : unsigned(COIN_WIDTH-1 downto 0) := (others => '0');

  -- edge detect signals
  signal revive_d, feed_d : std_logic := '0';
  signal revive_pulse, feed_pulse : std_logic := '0';

  -- outputs (1-cycle registered)
  signal spend_fail_i     : std_logic := '0';

  -- constants
  constant COIN_MAX    : unsigned(COIN_WIDTH-1 downto 0) := (others => '1');
  constant START_COINS : unsigned(COIN_WIDTH-1 downto 0) := to_unsigned(10, COIN_WIDTH);
begin

  -----------------------------------------------------------------------
  -- Edge detection (rising edges for revive, spend, feed)
  -----------------------------------------------------------------------
  EdgeDetection: process(clk, rst)
  begin
    if rst = '1' then
      revive_d     <= '0';
      feed_d       <= '0';
      revive_pulse <= '0';
      feed_pulse   <= '0';
    elsif rising_edge(clk) then
      revive_pulse <= revive     and (not revive_d);
      feed_pulse   <= feed       and (not feed_d);
      revive_d     <= revive;
      feed_d       <= feed;
    end if;
  end process;

  -----------------------------------------------------------------------
  -- Coin register update logic
  -----------------------------------------------------------------------
  CoinReg: process(clk, rst, coin_init)
  begin
    if rst = '1' or coin_init = '1' then
      coin_v        <= START_COINS;
      spend_fail_i  <= '0';

    elsif rising_edge(clk) then
      -- default pulses reset each cycle
      spend_fail_i  <= '0';

      -- spend 5 for revive
      if revive_pulse = '1' then
        if coin_v >= to_unsigned(5, COIN_WIDTH) then
          coin_v <= coin_v - to_unsigned(5, COIN_WIDTH);
        else

          spend_fail_i <= '1';
        end if;

      -- spend 3 for feed (happy dance)
      elsif feed_pulse = '1' then
        if coin_v >= to_unsigned(3, COIN_WIDTH) then
          coin_v <= coin_v - to_unsigned(3, COIN_WIDTH);
        else
          spend_fail_i <= '1';
        end if;

      -- earn 1 from happy_coin
      elsif happy_coin = '1' then
        if coin_v < COIN_MAX then
          coin_v <= coin_v + 1;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------
  -- Outputs
  -----------------------------------------------------------------------
  coin_value <= coin_v;
  coin_zero  <= '1' when coin_v = 0 else '0';
  spend_fail <= spend_fail_i;

end architecture;
