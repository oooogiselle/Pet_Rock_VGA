library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_coin_fsm is
end entity;

architecture sim of tb_coin_fsm is

    -- Component declaration
    component coin_fsm
        port (
            clk         : in  std_logic;
        rst         : in  std_logic;  -- Global system reset

        -- Inputs
        happy_coin  : in std_logic;
        coin_zero   : in std_logic;
        mad_done    : in std_logic;
        revive      : in std_logic;
        spend_coin : in  std_logic; 
        new_game    : in std_logic;

        -- Outputs
        inc_en      : out std_logic;
        dec_en      : out std_logic;
        coin_init   : out std_logic;
        spend_amt   : out unsigned(2 downto 0);
        venmo       : out std_logic
        );
    end component;

    -- Signals for testbench
    signal clk        : std_logic := '0';
    signal rst        : std_logic := '0';
    signal happy_coin : std_logic := '0';
    signal coin_zero  : std_logic := '0';
    signal mad_done   : std_logic := '0';
    signal revive     : std_logic := '0';
    signal new_game   : std_logic := '0';

    signal inc_en     : std_logic;
    signal dec_en     : std_logic;
    signal coin_init  : std_logic;
    signal venmo      : std_logic;
    signal spend_coin : std_logic := '0';
    signal spend_amt  : unsigned(2 downto 0);

    constant clk_period : time := 10 ns;
    signal sim_finished : boolean := false;

begin

    -- Instantiate the DUT
    uut: coin_fsm
        port map (
            clk        => clk,
            rst        => rst,
            happy_coin => happy_coin,
            coin_zero  => coin_zero,
            mad_done   => mad_done,
            revive     => revive,
            spend_coin => spend_coin,
            new_game   => new_game,
            inc_en     => inc_en,
            dec_en     => dec_en,
            coin_init  => coin_init,
            spend_amt  => spend_amt,
            venmo      => venmo
        );

    -- Clock process
    clk_process: process
    begin
 
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;

    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Step 1: Reset the system
        rst <= '1';
        wait for 2 * clk_period;
        rst <= '0';
        wait for clk_period;

        -- Now in Initial_Coin => expect coin_init = 1
        wait for 2 * clk_period;

        -- Step 2: Trigger happy_coin => move to Earn
        happy_coin <= '1';
        wait for clk_period;
        happy_coin <= '0';
        wait for 2 * clk_period;

        -- Expect inc_en = 1

        -- Step 3: Trigger revive => move to Spend
        revive <= '1';
        wait for clk_period;
        revive <= '0';
        wait for 2 * clk_period;

        -- Expect dec_en = 1

        -- Step 4: Trigger mad_done and coin_zero => move to Zero
        mad_done <= '1';
        coin_zero <= '1';
        wait for clk_period;
        mad_done <= '0';
        coin_zero <= '0';
        wait for 2 * clk_period;

        -- Expect venmo = 1

        -- Step 5: Pulse new_game => back to Initial_Coin
        new_game <= '1';
        wait for clk_period;
        new_game <= '0';
        wait for 2 * clk_period;

        -- End simulation
        report "FSM test completed successfully.";
        sim_finished <= true;
        wait;
    end process;

end architecture;
