library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

entity GraphicsManager is
    Port(
         is_title    : in std_logic;
        is_alive    : in std_logic;
        is_dead     : in std_logic;
        is_happy    : in std_logic;
        is_bored    : in std_logic;
        is_mad      : in std_logic;
        is_dance    : in std_logic;
        is_sad      : in std_logic;
        pixel_x     : in std_logic_vector(9 downto 0);
        pixel_y     : in std_logic_vector(8 downto 0);
        red   : out std_logic_vector(3 downto 0);
        green : out std_logic_vector(3 downto 0);
        blue  : out std_logic_vector(3 downto 0)
     );
  end GraphicsManager;

architecture Behavioral of GraphicsManager is
signal clk50: std_logic;
signal binary_in: std_logic_vector(17 downto 0);
signal rom_enable: std_logic;
signal bcd_out   : std_logic_vector(7 downto 0);
signal red_out: std_logic_vector(3 downto 0);
signal green_out: std_logic_vector(3 downto 0);
signal blue_out: std_logic_vector(3 downto 0);
signal x_unsign: unsigned(9 downto 0) := "0000000000";
signal y_unsign: unsigned(8 downto 0):= "000000000";

component BlockROM is
  Port (
    clka:   in    std_logic;
    addra:  in    std_logic_vector(17 downto 0);
    ena:    in    std_logic;
    douta:  out   std_logic_vector(7 downto 0)
  );
end component;

begin

XYConversion: process(y_unsign,x_unsign)
begin
    binary_in <= std_logic_vector(to_unsigned(160 * to_integer(y_unsign) + to_integer(x_unsign),18));
end process;


Binary2BCD: BlockROM
    port map (
    clka => clk50, 
    addra => binary_in,
    ena => rom_enable,
    douta => bcd_out
    );


end Behavioral;
