library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity GraphicsManager is
  generic (
    COIN_WIDTH  : integer := 9
  );
  Port(
    clk        : in  std_logic;  -- pixel clock
    video_on   : in  std_logic;  -- high only in active video area
    test_port  : in  std_logic;
    is_title   : in  std_logic;
    is_alive   : in  std_logic;
    is_dead    : in  std_logic;
    is_happy   : in  std_logic;
    is_bored   : in  std_logic;
    is_mad     : in  std_logic;
    is_dance   : in  std_logic;
    is_sad     : in  std_logic;
    is_pet     : in  std_logic;
    coin_value  : in unsigned(COIN_WIDTH-1 downto 0);
    pixel_x    : in  std_logic_vector(9 downto 0);  -- 0..639
    pixel_y    : in  std_logic_vector(8 downto 0);  -- 0..479
    red        : out std_logic_vector(3 downto 0);
    green      : out std_logic_vector(3 downto 0);
    blue       : out std_logic_vector(3 downto 0)
  );
end GraphicsManager;

architecture Behavioral of GraphicsManager is

  component blk_mem_gen_2
    Port (
      clka  : in  std_logic;
      ena   : in  std_logic;
      addra : in  std_logic_vector(17 downto 0);
      douta : out std_logic_vector(8 downto 0) -- change for bit 3
    );
  end component;

  constant F_TITLE   : unsigned(17 downto 0) := to_unsigned(0*19200, 18);
  constant F_BORED   : unsigned(17 downto 0) := to_unsigned(1*19200, 18);
  constant F_HAPPY   : unsigned(17 downto 0) := to_unsigned(2*19200, 18);
  constant F_SAD     : unsigned(17 downto 0) := to_unsigned(3*19200, 18);
  constant F_MAD     : unsigned(17 downto 0) := to_unsigned(4*19200, 18);
  constant F_DEAD    : unsigned(17 downto 0) := to_unsigned(5*19200, 18);
  constant F_PETTING : unsigned(17 downto 0) := to_unsigned(6*19200, 18);
  constant F_FOOD    : unsigned(17 downto 0) := to_unsigned(7*19200, 18);

  constant IMG_W : integer := 160;
  constant IMG_H : integer := 120;
  
  constant FRAME_X_OFFSET : integer := 0;
  constant FRAME_Y_OFFSET : integer := 0;


  signal x_u      : unsigned(9 downto 0);
  signal y_u      : unsigned(8 downto 0);
  signal y_s      : unsigned(6 downto 0);      -- y/4 fits in 7 bits (0..119)
  signal x_s8     : unsigned(7 downto 0);      -- x/4 fits in 8 bits (0..159)
  signal base_xy    : unsigned(17 downto 0);  -- y*160 + x   (scaled)
  signal frame_base : unsigned(17 downto 0);
  --signal frame_base_c : unsigned(17 downto 0);
  signal addr18   : unsigned(17 downto 0);  -- 0..15999 fits (actually 0..19199)
  


  --signal addr_u   : unsigned(18 downto 0);
  --signal addr_u_scaled : unsigned(14 downto 0);
  signal video_on_d : std_logic; -- 1-cycle delayed
  signal rom_en   : std_logic;
  signal rom_dout : std_logic_vector(8 downto 0);  --change for 3 bits
  signal r,g,b : std_logic_vector(2 downto 0);
  signal r4,g4,b4 : std_logic_vector(2 downto 0);
  signal rom_en_d    : std_logic;
  signal rom_pix_nonzero_d : std_logic := '0';
  signal x_scaled, y_scaled : integer range 0 to 159;
  signal frame_valid        : std_logic;
  signal r_d, g_d, b_d : std_logic_vector(2 downto 0);
  signal is_title_frame : std_logic := '0';

  type digit_bitmap is array(0 to 8) of std_logic_vector(5 downto 0);  --6*9 each digit
  type font_array is array(0 to 9) of digit_bitmap;  --10 digits
  
  signal coin_int     : integer range 0 to 511 := 0;
  signal coin_clamped : integer range 0 to 99  := 0;
  signal digit_left   : integer range 0 to 9   := 0;
  signal digit_right  : integer range 0 to 9   := 0;

  constant GOLD_R : std_logic_vector(3 downto 0) := "1110";
  constant GOLD_G : std_logic_vector(3 downto 0) := "1010";
  constant GOLD_B : std_logic_vector(3 downto 0) := "0000";

  constant DIGIT_FONT : font_array := (
    -- 0
    ( "011110",
      "100001",
      "100011",
      "100101",
      "101001",
      "110001",
      "100001",
      "100001",
      "011110"  ),
    -- 1
    ( "001100",
      "011100",
      "101100",
      "001100",
      "001100",
      "001100",
      "001100",
      "001100",
      "111111" ),
    -- 2
    ( "011110",
      "100001",
      "000001",
      "000010",
      "000100",
      "001000",
      "010000",
      "100000",
      "111111" ),
    -- 3
    ( "011110",
      "100001",
      "000001",
      "000110",
      "001110",
      "000001",
      "000001",
      "100001",
      "011110" ),
    -- 4
    ( "000010",
      "000110",
      "001010",
      "010010",
      "100010",
      "111111",
      "000010",
      "000010",
      "000010" ),
    -- 5
    ( "111111",
      "100000",
      "100000",
      "111110",
      "000001",
      "000001",
      "000001",
      "100001",
      "011110" ),
    -- 6
    ( "001110",
      "010001",
      "100000",
      "101110",
      "110001",
      "100001",
      "100001",
      "100001",
      "011110" ),
    -- 7
    ( "111111",
      "000001",
      "000010",
      "000100",
      "001000",
      "010000",
      "010000",
      "010000",
      "010000" ),
    -- 8
    ( "011110",
      "100001",
      "100001",
      "011110",
      "100001",
      "100001",
      "100001",
      "100001",
      "011110" ),
    -- 9
    ( "011110",
      "100001",
      "100001",
      "100001",
      "011111",
      "000001",
      "000010",
      "000100",
      "011000" )
  );


begin
  -- Convert inputs
  x_u <= unsigned(pixel_x);
  y_u <= unsigned(pixel_y);
  
  rom_en <= frame_valid and test_port;


 --when (x_u < IMG_W) and (y_u < IMG_H) else '0';

  -- Address = y*160 + x (resize to 18 bits)
  --addr_u <= resize((y_u sll 9) + (y_u sll 7) + x_u, 18);
  --addr_u <= (("000" & y_u & "0000000") + ("00000" & y_u & "00000") + ("000000000" & x_u));
  --addr_u_scaled <= addr_u(16 downto 2);

  -- final ROM address
  addr18 <= frame_base + base_xy;
  
  coin_int     <= to_integer(coin_value);
  coin_clamped <= (coin_int) when coin_int <= 99 else 99;
  digit_left   <= coin_clamped / 10;
  digit_right  <= coin_clamped mod 10;
   
   
  --- select frame by state
  process(is_title, is_alive, is_dead, is_happy, is_bored, is_mad, is_dance, is_sad)
  begin
    if    is_title = '1' then 
        frame_base <= F_TITLE;
        is_title_frame <= '1';

    elsif is_dance = '1' then frame_base <= F_FOOD;  --we dont have a state for food like the coin to alive
    elsif is_dead  = '1' then frame_base <= F_DEAD;
    elsif is_happy = '1' then frame_base <= F_HAPPY;
    elsif is_bored = '1' then frame_base <= F_BORED;
    elsif is_mad   = '1' then frame_base <= F_MAD;
    elsif is_pet = '1' then frame_base <= F_PETTING;
    elsif is_sad   = '1' then frame_base <= F_SAD;
    else                      
        frame_base <= F_TITLE;  -- default
        is_title_frame <= '1';
    end if;
  end process;
  
  process(x_u, y_u)
    begin
      if x_u >= FRAME_X_OFFSET and x_u < FRAME_X_OFFSET + IMG_W*4 and
         y_u >= FRAME_Y_OFFSET and y_u < FRAME_Y_OFFSET + IMG_H*4 then
    
        -- 4x scale: divide by 4
        x_scaled <= to_integer(x_u - FRAME_X_OFFSET) / 4;
        y_scaled <= to_integer(y_u - FRAME_Y_OFFSET) / 4;
        frame_valid <= '1';
    
      else
        x_scaled <= 0;
        y_scaled <= 0;
        frame_valid <= '0';
      end if;
    end process;
  base_xy <= to_unsigned(y_scaled * IMG_W + x_scaled, 18);
    addr18  <= frame_base + base_xy;

  -- register frame_base and video_on for stability
  -- process(clk)
  -- begin
  --  if rising_edge(clk) then
  --    frame_base <= frame_base_c;
  --    video_on_d <= video_on;
  --  end if;
  --end process;


  -- ROM instance (uncomment when ready)
  u_rom: blk_mem_gen_2
     port map (
       clka  => clk,
       ena   => rom_en,
       addra => std_logic_vector(addr18),
       --addra => std_logic_vector(addr_u_scaled),
       douta => rom_dout
     );

  -- Unpack and expand color
  --r <= rom_dout(8 downto 6);
  --g <= rom_dout(5 downto 3);
  --b <= rom_dout(2 downto 0);
  
  process(clk)
    begin
      if rising_edge(clk) then
        rom_en_d <= rom_en;
        r_d <= rom_dout(8 downto 6);
        g_d <= rom_dout(5 downto 3);
        b_d <= rom_dout(2 downto 0);
      
          if rom_dout = "000000000" then
            rom_pix_nonzero_d <= '0';
          else
            rom_pix_nonzero_d <= '1';
          end if;
          
        end if;
    end process;


  -- Drive outputs with video_on gating

  background: process(video_on, rom_en_d, r_d, g_d, b_d, y_u,
                      is_title_frame, is_title, x_scaled, y_scaled,
                      digit_left, digit_right)
  begin
    if test_port = '0' then
      red   <= "0000";
      green <= "0000";
      blue  <= "0000";
    elsif video_on = '0' then
      red   <= "0000";
      green <= "0000";
      blue  <= "0000";
    else
      -- Background
      if y_u < 300 then  
        red   <= "1110";
        green <= "1101";
        blue  <= "1011";
      else
        red   <= "1000";
        green <= "0101";
        blue  <= "0010";
      end if;

      -- ROM image
      if rom_en_d = '1' and rom_pix_nonzero_d = '1' then
        red   <= "0" & r_d;
        green <= "0" & g_d;
        blue  <= "0" & b_d;
      end if;

      -- Coin digits (tens and ones)
      if is_title = '0' then
        if (x_scaled >= 32 and x_scaled < 38) and (y_scaled >= 98 and y_scaled < 107) then
          if DIGIT_FONT(digit_left)(y_scaled - 98)(5 - (x_scaled - 32)) = '1' then
            red   <= GOLD_R;
            green <= GOLD_G;
            blue  <= GOLD_B;
          end if;
        end if;

        if (x_scaled >= 40 and x_scaled < 46) and (y_scaled >= 98 and y_scaled < 107) then
          if DIGIT_FONT(digit_right)(y_scaled - 98)(5 - (x_scaled - 40)) = '1' then
            red   <= GOLD_R;
            green <= GOLD_G;
            blue  <= GOLD_B;
          end if;
        end if;
      end if;
    end if;
  end process;

end Behavioral;
