library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity petrock_behavioral_shell is
    generic (
        TIMER_WIDTH  : integer := 9    -- up to 512
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;

        -- Button Inputs
        start       : in  std_logic;
        revive      : in  std_logic;
        quit        : in  std_logic;
        pet         : in  std_logic;
        feed        : in  std_logic;
        new_game    : in  std_logic;

        -- Outputs
        is_title    : out std_logic;
        is_alive    : out std_logic;
        is_dead     : out std_logic;

        is_happy    : out std_logic;
        is_bored    : out std_logic;
        is_mad      : out std_logic;
        is_sad      : out std_logic;
        is_dance    : out std_logic;
        is_pet      : out std_logic;

        coin_value  : out unsigned(8 downto 0);
        coin_zero   : out std_logic;
        spend_fail  : out std_logic
        --sad_done    : out std_logic
    );
end entity;

architecture rtl of petrock_behavioral_shell is

    -- Handshake signals
    signal happy_done   : std_logic;
    signal bored_done   : std_logic;
    signal mad_done     : std_logic;
    signal dance_done   : std_logic;
    signal pet_done     : std_logic;
    signal sad_done_int : std_logic;
    signal happy_coin   : std_logic;

    -- Life/Mood visibility
    signal is_alive_int : std_logic;
    signal is_title_int : std_logic;
    signal is_dead_int  : std_logic;

    signal is_happy_int : std_logic;
    signal is_bored_int : std_logic;
    signal is_mad_int   : std_logic;
    signal is_sad_int   : std_logic;
    signal is_pet_int   : std_logic;
    signal is_dance_int : std_logic;
    

    -- Coin manager
    signal coin_value_int : unsigned(8 downto 0);

    -- Edge-detect for START and NEW_GAME
    signal start_d,    new_game_d    : std_logic := '0';
    signal start_pulse,new_game_pulse: std_logic := '0';

    -- New game qualified (only on Title)
    signal new_game_go  : std_logic := '0';

    -- Resets to other blocks
    signal game_rst  : std_logic := '0';  -- to mood_fsm
    signal coin_init : std_logic := '0';  -- to coin_manager
    signal revive_allowed : std_logic := '0';
    signal feed_allowed: std_logic := '0';
    signal start_to_life : std_logic := '0';

begin
    
    revive_allowed  <= revive and is_dead_int; -- gate when revive is allowed
    feed_allowed <= feed and not is_dead_int;
    ------------------------------------------------------------------------
    -- Edge detection for start & new_game
    ------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                start_d      <= '0';
                new_game_d   <= '0';
                start_pulse  <= '0';
                new_game_pulse <= '0';
            else
                start_pulse    <= start    and (not start_d);
                new_game_pulse <= new_game and (not new_game_d);
                start_d        <= start;
                new_game_d     <= new_game;
            end if;
        end if;
    end process;

    -- Only allow NEW GAME when we are on the Title screen
    new_game_go <= '1' when (is_title_int = '1' and new_game_pulse = '1') else '0';

    -- New game resets coins and mood/timers
    coin_init <= new_game_go;   -- reload START_COINS in coin_manager
    game_rst  <= new_game_go;   -- reset mood_fsm to Happy, timers will clear
    start_to_life <= start_pulse or new_game_go;
    ------------------------------------------------------------------------
    -- Life FSM (start happens either by START or NEW GAME)
    ------------------------------------------------------------------------
    life_inst: entity work.life_fsm
      port map (
        clk       => clk,
        rst       => rst,
        start     => start_to_life, -- NEW GAME also starts
        revive    => revive_allowed,
        quit      => quit,                         -- quit only returns to Title
        game_rst  => game_rst,
        coin_value => coin_value_int,
        sad_done  => sad_done_int,
        is_title  => is_title_int,
        is_alive  => is_alive_int,
        is_dead   => is_dead_int
      );

    ------------------------------------------------------------------------
    -- Mood FSM
    ------------------------------------------------------------------------
    mood_inst: entity work.mood_fsm
      port map (
        clk         => clk,
        rst         => rst,
        happy_done  => happy_done,
        pet         => pet,
        feed        => feed_allowed,
        bored_done  => bored_done,
        mad_done    => mad_done,
        sad_done    => sad_done_int,
        pet_done    => pet_done,
        dance_done  => dance_done,
        revive  => revive_allowed,
        game_rst    => game_rst,     -- only on NEW GAME
        is_alive    => is_alive_int,
        coin_value  => coin_value_int,
        is_happy    => is_happy_int,
        is_bored    => is_bored_int,
        is_pet      => is_pet_int,
        is_mad      => is_mad_int,
        is_dance    => is_dance_int,
        is_sad      => is_sad_int
      );

    ------------------------------------------------------------------------
    -- Time Manager
    ------------------------------------------------------------------------
    timer_inst: entity work.time_manager
      generic map ( TIMER_WIDTH => 9 )
      port map (
        clk         => clk,
        rst         => rst,
        is_alive    => is_alive_int,
        is_happy    => is_happy_int,
        is_bored    => is_bored_int,
        is_mad      => is_mad_int,
        is_sad      => is_sad_int,
        is_pet      => is_pet_int,
        is_dance    => is_dance_int,
        happy_coin  => happy_coin,
        happy_done  => happy_done,
        bored_done  => bored_done,
        dance_done  => dance_done,
        pet_done    => pet_done,
        mad_done    => mad_done,
        sad_done    => sad_done_int
      );
      

    ------------------------------------------------------------------------
    -- Coin Manager
    ------------------------------------------------------------------------
    coin_inst: entity work.coin_manager
      generic map ( COIN_WIDTH => 9 )
      port map (
        clk         => clk,
        rst         => rst,
        happy_coin  => happy_coin,
        coin_init   => coin_init,   -- only on NEW GAME
        revive      => revive_allowed,
        feed        => feed_allowed,
        coin_value  => coin_value_int,
        coin_zero   => coin_zero,
        spend_fail  => spend_fail
      );

    ------------------------------------------------------------------------
    -- Outputs
    ------------------------------------------------------------------------
    is_alive   <= is_alive_int;
    is_title   <= is_title_int;
    is_dead    <= is_dead_int;

    is_happy   <= is_happy_int;
    is_bored   <= is_bored_int;
    is_mad     <= is_mad_int;
    is_sad     <= is_sad_int;
    is_dance   <= is_dance_int;
    is_pet     <= is_pet_int;

    coin_value <= coin_value_int;

end architecture;
