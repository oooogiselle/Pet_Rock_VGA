library IEEE;
use IEEE.std_logic_1164.all;

entity VGA_tb is
end VGA_tb;

architecture testbench of VGA_tb is

    component VGA IS
    PORT (
        clk : in STD_LOGIC; --100 MHz clock
        V_sync_port : out STD_LOGIC;
        H_sync_port : out STD_LOGIC;
        red : out std_logic_vector(3 downto 0);
        green : out std_logic_vector(3 downto 0);
        blue : out std_logic_vector(3 downto 0)

        --video_on: out STD_LOGIC;
        --pixel_x : std_logic_vector(9 downto 0);
		--pixel_y : std_logic_vector(8 downto 0)
        -- PCLK_out :  out std_logic
    );
    end component;

    signal clk : STD_LOGIC := '0'; --100 MHz clock
    signal V_sync_port : STD_LOGIC;
    signal H_sync_port : STD_LOGIC;
    signal red : std_logic_vector(3 downto 0);
    signal green : std_logic_vector(3 downto 0);
    signal blue : std_logic_vector(3 downto 0);
    --signal video_on: STD_LOGIC;
	--signal pixel_x : std_logic_vector(9 downto 0);
	--signal pixel_y : std_logic_vector(8 downto 0);
    signal last_edge_time : time := 0 ns;

begin

    uut : VGA PORT MAP(
        clk  => clk,
        V_sync_port => V_sync_port,
        H_sync_port => H_sync_port,
        red => red,
        blue => blue,
        green => green

        --video_on => video_on,
        --pixel_x => pixel_x,
        --pixel_y => pixel_y
    );

    clk_proc : process
    BEGIN
      clk <= '0';
      wait for 0.05 ns;   
      clk <= '1';
      wait for 0.05 ns;
    END PROCESS clk_proc;

    stim_proc : process
    begin
    	wait for 100 us;
    	assert false report "Simulation finished." severity note;
    	wait;
    end process stim_proc;

end testbench;