library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mood_fsm is
  generic ( COIN_WIDTH : integer := 9 );
  port (
    clk, rst           : in  std_logic;
    pet, feed          : in  std_logic;  -- raw button levels
    happy_done         : in  std_logic;
    bored_done         : in  std_logic;
    mad_done           : in  std_logic;
    sad_done           : in  std_logic;
    dance_done         : in  std_logic;
    pet_done           : in  std_logic;

    revive             : in  std_logic;  -- raw button level (from user)

    game_rst           : in  std_logic;
    is_alive           : in  std_logic;
    coin_value         : in  unsigned(COIN_WIDTH-1 downto 0);

    is_happy, is_bored, is_mad, is_dance, is_sad, is_pet : out std_logic
  );
end entity;

architecture rtl of mood_fsm is
  type state_type is (Happy, Bored, Mad, Sad, Happy_Dance, Petting);
  signal curr_state, next_state                  : state_type;
  signal pet_return_state, next_pet_return_state : state_type;

  -- Edge-detect
  signal pet_d, feed_d, revive_d  : std_logic := '0';
  signal pet_pulse, feed_pulse, revive_pulse : std_logic := '0';
begin
  ---------------------------------------------------------------------
  -- Edge detection (make 1-cycle pulses)
  ---------------------------------------------------------------------
  EdgeDetection : process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') or (game_rst = '1') then
        pet_d        <= '0';  feed_d       <= '0';  revive_d     <= '0';
        pet_pulse    <= '0';  feed_pulse   <= '0';  revive_pulse <= '0';
      else
        pet_pulse    <= pet    and (not pet_d);
        feed_pulse   <= feed   and (not feed_d);
        revive_pulse <= revive and (not revive_d);

        pet_d    <= pet;
        feed_d   <= feed;
        revive_d <= revive;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------
  -- State register
  ---------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') or (game_rst = '1') then
        curr_state       <= Happy;
        pet_return_state <= Happy;
      else
        curr_state       <= next_state;
        pet_return_state <= next_pet_return_state;
      end if;
    end if;
  end process;


  NextStateLogic: process(curr_state, happy_done, pet_pulse, bored_done, mad_done, sad_done,
                          feed_pulse, coin_value,revive_pulse,
                          dance_done, pet_done)
  begin
    next_state            <= curr_state;
    next_pet_return_state <= pet_return_state;

    -- Highest priority: on revive, jump straight to Bored
    -- (life_fsm should already have checked coins & dead-state)
    if (revive_pulse = '1') then
      next_state <= Bored;

    elsif (feed_pulse = '1') and (coin_value >= to_unsigned(3, COIN_WIDTH)) and (curr_state /= Petting) then
      next_state <= Happy_Dance;

    else
      case curr_state is
        when Happy =>
          if happy_done = '1' then
            next_state <= Bored;
          elsif pet_pulse = '1' then
            next_state            <= Petting;
            next_pet_return_state <= Happy;
          end if;

        when Bored =>
          if bored_done = '1' then
            next_state <= Mad;
          elsif pet_pulse = '1' then
            next_state            <= Petting;
            next_pet_return_state <= Happy;
          end if;

        when Mad =>
          if mad_done = '1' then
            next_state <= Sad;
          elsif pet_pulse = '1' then
            next_state            <= Petting;
            next_pet_return_state <= Bored;
          end if;

        when Sad =>
          if sad_done = '1' then
            null;
          end if;

        when Happy_Dance =>
          if dance_done = '1' then
            next_state <= Happy;
          end if;

        when Petting =>
          if pet_done = '1' then
            next_state <= pet_return_state;
          end if;
      end case;
    end if;
  end process;

  ---------------------------------------------------------------------
  -- Output Logic (One-Hot), gated by is_alive
  ---------------------------------------------------------------------
  OutputLogic: process(curr_state, is_alive, revive_pulse)
  begin
    is_happy <= '0'; is_bored <= '0'; is_mad <= '0';
    is_sad   <= '0'; is_dance <= '0'; is_pet <= '0';

    if is_alive = '1' then
        if revive_pulse = '1' then
            is_bored <= '1';
        else
          case curr_state is
            when Happy        => is_happy <= '1';
            when Bored        => is_bored <= '1';
            when Mad          => is_mad   <= '1';
            when Sad          => is_sad   <= '1';
            when Happy_Dance  => is_dance <= '1';
            when Petting      => is_pet   <= '1';
          end case;
        end if;
    end if;
  end process;
end architecture;
