library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity time_manager is
  generic (
    TIMER_WIDTH  : integer := 9    -- up to 512
  );
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    is_alive    : in  std_logic;

    -- state flags (from mood_fsm)
    is_happy    : in  std_logic;
    is_bored    : in  std_logic;
    is_mad      : in  std_logic;
    is_sad      : in  std_logic;

    -- outputs
    happy_coin  : out std_logic;
    happy_done  : out std_logic;
    bored_done  : out std_logic;
    mad_done    : out std_logic;
    sad_done    : out std_logic
  );
end entity;

architecture rtl of time_manager is
  -- Timer registers
  signal happy_timer  : unsigned(TIMER_WIDTH-1 downto 0) := (others => '0');
  signal bored_timer  : unsigned(TIMER_WIDTH-1 downto 0) := (others => '0');
  signal mad_timer    : unsigned(TIMER_WIDTH-1 downto 0) := (others => '0');
  signal sad_timer    : unsigned(TIMER_WIDTH-1 downto 0) := (others => '0');

  -- Coin output internal
  signal happy_coin_int : std_logic := '0';

begin

  ---------------------------------------------------------------------------
  -- Happy timer: coin every 60 cycles, done after 300
  ---------------------------------------------------------------------------
  HappyTimer: process(clk, rst)
  begin
    if rst = '1' then
      happy_timer     <= (others => '0');
      happy_coin_int  <= '0';
    elsif rising_edge(clk) then
      if is_alive = '1' and is_happy = '1' then
        happy_timer <= happy_timer + 1;

        -- Coin pulse every 60 cycles (1-cycle pulse)
        if happy_timer /= 0 and happy_timer mod 60 = 0 then
          happy_coin_int <= '1';
        else
          happy_coin_int <= '0';
        end if;

        -- Clamp to 300 max
        if happy_timer = to_unsigned(300, TIMER_WIDTH) then
          happy_timer <= happy_timer;  -- hold
        end if;
      else
        happy_timer    <= (others => '0');
        happy_coin_int <= '0';
      end if;
    end if;
  end process;

  happy_done <= '1' when happy_timer = to_unsigned(300, TIMER_WIDTH) else '0';
  happy_coin <= happy_coin_int;

  ---------------------------------------------------------------------------
  -- Bored timer: done at 240
  ---------------------------------------------------------------------------
  BoredTimer: process(clk, rst)
  begin
    if rst = '1' then
      bored_timer <= (others => '0');
    elsif rising_edge(clk) then
      if is_alive = '1' and is_bored = '1' then
        bored_timer <= bored_timer + 1;
        if bored_timer = to_unsigned(240, TIMER_WIDTH) then
          bored_timer <= bored_timer; -- hold
        end if;
      else
        bored_timer <= (others => '0');
      end if;
    end if;
  end process;

  bored_done <= '1' when bored_timer = to_unsigned(240, TIMER_WIDTH) else '0';

  ---------------------------------------------------------------------------
  -- Mad timer: done at 360
  ---------------------------------------------------------------------------
  MadTimer: process(clk, rst)
  begin
    if rst = '1' then
      mad_timer <= (others => '0');
    elsif rising_edge(clk) then
      if is_alive = '1' and is_mad = '1' then
        mad_timer <= mad_timer + 1;
        if mad_timer = to_unsigned(360, TIMER_WIDTH) then
          mad_timer <= mad_timer; -- hold
        end if;
      else
        mad_timer <= (others => '0');
      end if;
    end if;
  end process;

  mad_done <= '1' when mad_timer = to_unsigned(360, TIMER_WIDTH) else '0';

  ---------------------------------------------------------------------------
  -- Sad timer: done at 505
  ---------------------------------------------------------------------------
  SadTimer: process(clk, rst)
  begin
    if rst = '1' then
      sad_timer <= (others => '0');
    elsif rising_edge(clk) then
      if is_alive = '1' and is_sad = '1' then
        sad_timer <= sad_timer + 1;
        if sad_timer = to_unsigned(505, TIMER_WIDTH) then
          sad_timer <= sad_timer; -- hold
        end if;
      else
        sad_timer <= (others => '0');
      end if;
    end if;
  end process;

  sad_done <= '1' when sad_timer = to_unsigned(505, TIMER_WIDTH) else '0';

end architecture;
