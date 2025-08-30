library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity life_fsm is
    generic (
        COIN_WIDTH : integer := 9
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;

        -- Inputs
        start     : in  std_logic;
        revive    : in  std_logic;
        quit      : in  std_logic;
        sad_done  : in  std_logic;
        coin_value: in  unsigned(COIN_WIDTH-1 downto 0);

        -- New Game reset (one-cycle pulse)
        game_rst  : in  std_logic;

        -- Outputs
        is_title  : out std_logic;
        is_alive  : out std_logic;
        is_dead   : out std_logic
    );
end entity;

architecture rtl of life_fsm is
    type state_type is (Title, Rock_Alive, Rock_Dead);
    signal curr_state, next_state : state_type;
begin
    --------------------------------------------------------------------
    -- State register
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            -- Only rst or game_rst force back to Title
            if (rst = '1') or (game_rst = '1') then
                curr_state <= Title;
            else
                curr_state <= next_state;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Next-state logic (quit is a normal transition, not a reset)
    --------------------------------------------------------------------
    process(curr_state, start, revive, quit, sad_done, coin_value)
    begin
        next_state <= curr_state;

        case curr_state is
            when Title =>
                if start = '1' then
                    next_state <= Rock_Alive;
                end if;

            when Rock_Alive =>
                if sad_done = '1' then
                    next_state <= Rock_Dead;
                elsif quit = '1' then
                    next_state <= Title;     -- back to title screen
                end if;

            when Rock_Dead =>
                if revive = '1' and coin_value >= to_unsigned(5, COIN_WIDTH)then
                    next_state <= Rock_Alive;
                elsif quit = '1' then
                    next_state <= Title;     -- back to title screen
                end if;

            when others =>
                next_state <= Title;
        end case;
    end process;

    --------------------------------------------------------------------
    -- Output logic
    --------------------------------------------------------------------
    process(curr_state)
    begin
        is_title <= '0';
        is_alive <= '0';
        is_dead  <= '0';


        case curr_state is
            when Title      => is_title <= '1';
            when Rock_Alive => is_alive <= '1';
            when Rock_Dead  => is_dead  <= '1';
            when others     => null;
        end case;

    end process;
    
end architecture;
