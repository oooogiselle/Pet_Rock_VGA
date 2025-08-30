-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY VGA IS
PORT ( 	clk		:	in	STD_LOGIC; --100 MHz clock
		V_sync_port	: 	out	STD_LOGIC;
		H_sync_port	: 	out	STD_LOGIC;
        video_on_port:	out	STD_LOGIC;
		pixel_x_port : out std_logic_vector(9 downto 0);
        pixel_y_port : out std_logic_vector(8 downto 0);
        red   : out std_logic_vector(3 downto 0);
  		green : out std_logic_vector(3 downto 0);
  		blue  : out std_logic_vector(3 downto 0)
        --PCLK_out : out std_logic
        );
end VGA;


architecture behavior of VGA is

--VGA Constants (taken directly from VGA Class Notes)

constant left_border : integer := 48;
constant h_display : integer := 640;
constant right_border : integer := 16;
constant h_retrace : integer := 96;
constant HSCAN : integer := left_border + h_display + right_border + h_retrace - 1; --number of PCLKs in an H_sync period


constant top_border : integer := 29;
constant v_display : integer := 480;
constant bottom_border : integer := 10;
constant v_retrace : integer := 2;
constant VSCAN : integer := top_border + v_display + bottom_border + v_retrace - 1; --number of H_syncs in an V_sync period

signal H_video_on : STD_LOGIC := '0';
signal V_video_on : STD_LOGIC := '0';
--Add your signals here
signal PCLK : STD_LOGIC := '0';  -- 25 MHz pixel clock
signal CLK_DIV_CNT : unsigned(1 downto 0) := (others => '0'); -- divide-by-4 toggle every 2 cycles
signal PCLK_prev  : std_logic := '0';  -- To detect rising edge on PCLK
signal h_count : integer range 0 to HSCAN := 0;
signal v_count : integer range 0 to VSCAN := 0;
signal H_sync_prev : std_logic := '1';
signal H_sync : std_logic := '0';
signal V_sync : std_logic := '0';

signal pixel_x : std_logic_vector(9 downto 0);
signal pixel_y : std_logic_vector(8 downto 0);

signal video_on : std_logic := '0';


BEGIN

--PCLK Generating Process
PCLK_proc : process(clk)
begin
	if rising_edge(clk) then
    --put your PCLK generation code here
    	if CLK_DIV_CNT = "01" then -- 2 clk cycles = 20 ns
        	PCLK <= not PCLK; -- toggle => 40 ns period => 25 MHz
            CLK_DIV_CNT <= (others => '0');
      	else
			CLK_DIV_CNT <= CLK_DIV_CNT + 1;
end if;
    end if;
end process PCLK_proc;



--H_sync generating process
Hsync_proc : process(clk)
begin
	if rising_edge(clk) then
       --H_sync and H_video_on generation code goes here
       PCLK_prev <= PCLK; -- to keep track
       
       -- Detect rising edge of PCLK
        if (PCLK = '1' and PCLK_prev = '0') then
            -- Increment horizontal counter and wrap at HSCAN
            if h_count = HSCAN then
                h_count <= 0;
            else
                h_count <= h_count + 1;
            end if;

            -- Horizontal video active during visible display area
            if (h_count >= left_border) and (h_count < left_border + h_display) then
                H_video_on <= '1';
            else
                H_video_on <= '0';
            end if;

            -- H_sync low 
            if (h_count >= left_border + h_display + right_border) and 
               (h_count < left_border + h_display + right_border + h_retrace) then
                H_sync <= '0';
            else
                H_sync <= '1';
            end if;
        end if;
    end if;
end process Hsync_proc;

--V_sync generating process
Vsync_proc : process(clk)
begin
	if rising_edge(clk) then
       --V_sync and V_video_on generation code goes here
       -- Detect rising edge of H_sync
        if (H_sync = '1' and H_sync_prev = '0') then  -- Rising edge
            if v_count = VSCAN then
                v_count <= 0;
            else
                v_count <= v_count + 1;
            end if;

            -- Vertical video active region
            if (v_count >= top_border) and (v_count < top_border + v_display) then
                V_video_on <= '1';
            else
                V_video_on <= '0';
            end if;

            -- V_sync active low 
            if (v_count >= top_border + v_display + bottom_border) and
               (v_count < top_border + v_display + bottom_border + v_retrace) then
                V_sync <= '0';
            else
                V_sync <= '1';
            end if;
        end if;
        H_sync_prev <= H_sync;
    end if;
end process Vsync_proc;

--Generate the pixel_x and pixel_y outputs
process(clk)
begin
  if rising_edge(clk) then
    if video_on = '1' then
      pixel_x <= std_logic_vector(to_unsigned(h_count - left_border, 10));
      pixel_y <= std_logic_vector(to_unsigned(v_count - top_border, 9));
    else
      pixel_x <= (others => '0');
      pixel_y <= (others => '0');
    end if;
  end if;
end process;

--RGB
process(pixel_x, pixel_y, video_on)
begin
  if video_on = '1' then
    if pixel_x > pixel_y then
        red <= "1111";
        blue <= "0000";

    else 
        blue <= "1111";
        green <= (others => '0');
    end if;
    
  else -- Outside active area
    red <= (others => '0');
    green <= (others => '0');
    blue <= (others => '0');
  end if;
end process;

H_sync_port <= H_sync;
V_sync_port <= V_sync;

pixel_x_port <= pixel_x;
pixel_y_port <= pixel_y;
video_on_port <= video_on;


video_on <= H_video_on AND V_video_on; --Only enable video out when H_video_out and V_video_out are high. It's important to set the output to zero when you aren't actively displaying video. That's how the monitor determines the black level.

-- test 
-- PCLK_out <= PCLK;

end behavior;
        
        
        