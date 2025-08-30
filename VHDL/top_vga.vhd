library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Top_VGA is
    Port(
        clk100     : in  std_logic;   -- 100 MHz board clock
        test_port  : in  std_logic;

        -- Basys3 buttons (raw)
        btnC       : in  std_logic;  -- start
        btnU       : in  std_logic;  -- revive
        btnD       : in  std_logic;  -- quit
        btnL       : in  std_logic;  -- pet
        btnR       : in  std_logic;  -- feed

        -- VGA outputs
        hsync      : out std_logic;
        vsync      : out std_logic;
        red        : out std_logic_vector(3 downto 0);
        green      : out std_logic_vector(3 downto 0);
        blue       : out std_logic_vector(3 downto 0)
    );
end Top_VGA;

architecture Behavioral of Top_VGA is
    -- VGA internals
    signal pixel_x   : std_logic_vector(9 downto 0);
    signal pixel_y   : std_logic_vector(8 downto 0);
    signal gm_red    : std_logic_vector(3 downto 0);
    signal gm_green  : std_logic_vector(3 downto 0);
    signal gm_blue   : std_logic_vector(3 downto 0);
    signal video_on  : std_logic;

    -- PetRock FSM signals
    signal is_title_sig : std_logic;
    signal is_alive_sig : std_logic;
    signal is_dead_sig  : std_logic;
    signal is_happy_sig : std_logic;
    signal is_bored_sig : std_logic;
    signal is_mad_sig   : std_logic;
    signal is_sad_sig   : std_logic;
    signal is_pet_sig   : std_logic;
    signal is_dance_sig : std_logic;

    signal coin_val     : unsigned(8 downto 0);
    signal coin_zero    : std_logic;
    signal spend_fail   : std_logic;
    signal venmo        : std_logic;
    signal sad_done     : std_logic;

    signal system_clk : std_logic;
begin
    --------------------------------------------------------------------
    -- VGA timing
    --------------------------------------------------------------------
    u_vga: entity work.VGA
        port map (
            clk            => clk100,
            V_sync_port    => vsync,
            H_sync_port    => hsync,
            video_on_port  => video_on,
            pixel_x_port   => pixel_x,
            pixel_y_port   => pixel_y,
            red            => open,
            green          => open,
            blue           => open
        );

    clk_div_inst: entity work.system_clock_generation
        generic map (CLK_DIVIDER_RATIO => 1666667) -- ~60 Hz game tick
        port map (
            input_clk_port  => clk100,
            system_clk_port => system_clk
        );

    --------------------------------------------------------------------
    -- Game logic
    --------------------------------------------------------------------
    u_petrock: entity work.petrock_behavioral_shell
        port map (
            clk         => system_clk,
            rst         => '0',
            start       => btnC,
            revive      => btnU,
            quit        => btnD,
            pet         => btnL,
            feed        => btnR,
            new_game    => test_port,

            is_title    => is_title_sig,
            is_alive    => is_alive_sig,
            is_dead     => is_dead_sig,

            is_happy    => is_happy_sig,
            is_bored    => is_bored_sig,
            is_mad      => is_mad_sig,
            is_sad      => is_sad_sig,
            is_dance    => is_dance_sig,
            is_pet      => is_pet_sig,

            coin_value  => coin_val,
            coin_zero   => coin_zero,
            spend_fail  => spend_fail
            --sad_done    => sad_done
        );

    --------------------------------------------------------------------
    -- Graphics
    --------------------------------------------------------------------
    u_gfx: entity work.GraphicsManager
        port map (
            clk        => clk100,
            video_on   => video_on,
            test_port  => test_port,
            is_title   => is_title_sig,
            is_alive   => is_alive_sig,
            is_dead    => is_dead_sig,
            is_happy   => is_happy_sig,
            is_bored   => is_bored_sig,
            is_mad     => is_mad_sig,
            is_dance   => is_dance_sig,
            is_sad     => is_sad_sig,
            is_pet     => is_pet_sig,
            coin_value => coin_val,
            pixel_x    => pixel_x,
            pixel_y    => pixel_y,
            red        => gm_red,
            green      => gm_green,
            blue       => gm_blue
        );

    -- Final VGA outputs
    red   <= gm_red;
    green <= gm_green;
    blue  <= gm_blue;
end Behavioral;
