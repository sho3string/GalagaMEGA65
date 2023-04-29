----------------------------------------------------------------------------------
-- MiSTer2MEGA65 Framework
--
-- Wrapper for the MiSTer core that runs exclusively in the core's clock domanin
--
-- MiSTer2MEGA65 done by sy2002 and MJoergen in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.video_modes_pkg.all;

entity main is
   generic (
      G_VDNUM                 : natural                     -- amount of virtual drives     
   );
   port (
      clk_main_i              : in  std_logic;
      reset_soft_i            : in  std_logic;
      reset_hard_i            : in  std_logic;
      pause_i                 : in  std_logic;

      -- MiSTer core main clock speed:
      -- Make sure you pass very exact numbers here, because they are used for avoiding clock drift at derived clocks
      clk_main_speed_i        : in natural;
      
      main_clk_o              : out std_logic;        -- Galaga's 18 MHz main clock
      main_rst_o              : out std_logic;        -- Galaga's reset, synchronized
        
      video_clk_o             : out std_logic;        -- video clock 48 MHz
      video_rst_o             : out std_logic;        -- video reset, synchronized

      -- Video output
      video_ce_o              : out std_logic;
      video_ce_ovl_o          : out std_logic;
      video_retro15kHz_o      : out std_logic;
      video_red_o             : out std_logic_vector(7 downto 0);
      video_green_o           : out std_logic_vector(7 downto 0);
      video_blue_o            : out std_logic_vector(7 downto 0);
      video_vs_o              : out std_logic;
      video_hs_o              : out std_logic;
      video_hblank_o          : out std_logic;
      video_vblank_o          : out std_logic;
      
     
      -- Audio output (Signed PCM)
      audio_left_o            : out signed(15 downto 0);
      audio_right_o           : out signed(15 downto 0);
      
      -- M2M Keyboard interface
      kb_key_num_i            : in  integer range 0 to 79;    -- cycles through all MEGA65 keys
      kb_key_pressed_n_i      : in  std_logic;                -- low active: debounced feedback: is kb_key_num_i pressed right now?
      
      -- MEGA65 joysticks and paddles/mouse/potentiometers
      joy_1_up_n_i            : in  std_logic;
      joy_1_down_n_i          : in  std_logic;
      joy_1_left_n_i          : in  std_logic;
      joy_1_right_n_i         : in  std_logic;
      joy_1_fire_n_i          : in  std_logic;

      joy_2_up_n_i            : in  std_logic;
      joy_2_down_n_i          : in  std_logic;
      joy_2_left_n_i          : in  std_logic;
      joy_2_right_n_i         : in  std_logic;
      joy_2_fire_n_i          : in  std_logic;

      pot1_x_i                : in std_logic_vector(7 downto 0);
      pot1_y_i                : in std_logic_vector(7 downto 0);
      pot2_x_i                : in std_logic_vector(7 downto 0);
      pot2_y_i                : in std_logic_vector(7 downto 0)      
   );
end entity main;

architecture synthesis of main is

-- @TODO: Remove these demo core signals
signal keyboard_n          : std_logic_vector(79 downto 0);

signal pause_cpu         : std_logic; -- to do later
signal status            : signed(31 downto 0);
signal flip_screen       : std_logic := status(8);
signal flip              : std_logic := '0';
signal video_rotated     : std_logic;
signal rotate_ccw        : std_logic := flip_screen;
signal direct_video      : std_logic;
signal forced_scandoubler: std_logic;
signal no_rotate         : std_logic := status(2) OR direct_video;
signal gamma_bus         : std_logic_vector(21 downto 0);

signal audio             : std_logic_vector(15 downto 0);
signal AUDIO_L           : std_logic_vector(15 downto 0) := audio;
signal AUDIO_R           : std_logic_vector(15 downto 0) := AUDIO_L;
signal AUDIO_S           : std_logic_vector(15 downto 0) := (others => '0');


-- horizontal blank, vertical blank, vertical sync & horizontal sync signals.
signal hbl,vbl,vs,hs     : std_logic;
 -- red, green, blue
signal r,g                : std_logic_vector(2 downto 0); -- 3 bits for red and green
signal b                  : std_logic_vector(1 downto 0); -- 2 bits for blue

-- dipswitches
type dsw_type is array (0 to 3) of std_logic_vector(7 downto 0); -- each dipswitch is 8 bits wide.
signal dsw : dsw_type;

signal ioctl_download : std_logic;
signal ioctl_wr       : std_logic;
signal ioctl_addr     : std_logic_vector(24 downto 0);
signal ioctl_dout     : std_logic_vector(7 downto 0);
signal ioctl_index  : std_logic_vector(7 downto 0);

signal rom_download : std_logic := ioctl_download and not std_logic(ioctl_index(0));

-- inputs

-- I/O board button press simulation ( active high )
-- b[1]: user button
-- b[0]: osd button

signal buttons           : std_logic_vector(1 downto 0);
signal reset             : std_logic  := reset_hard_i or reset_soft_i or status(0) or buttons(1) or rom_download;
signal  joystick_0,joystick_1 : std_logic_vector(15 downto 0);
signal  joy : std_logic_vector(15 downto 0) := joystick_0 or joystick_1;

signal  m_up    : std_logic := joy(3);
signal  m_down  : std_logic := joy(2);
signal  m_left  : std_logic := joy(1);
signal  m_right : std_logic := joy(0);
signal  m_fire  : std_logic := joy(4);
signal  m_start1: std_logic := joystick_0(5) or joystick_1(6);
signal  m_start2: std_logic := joystick_1(5) or joystick_0(6);
signal  m_coin1 : std_logic := joystick_0(7);
signal  m_coin2 : std_logic := joystick_1(7);
signal  m_pause : std_logic := joy(8);

-- highscore system
signal hs_address : std_logic_vector(15 downto 0);
signal hs_data_in : std_logic_vector(7 downto 0);
signal hs_data_out : std_logic_vector(7 downto 0);
signal hs_write_enable : std_logic;


begin

    i_galaga : entity work.galaga
    port map (
    
    clock_18   => main_clk_o,
    --reset      => reset,
    reset      => main_rst_o,
    
    dn_addr    => ioctl_addr(15 downto 0), -- MiSTer core had 16:0 ,is that a typo ?
    dn_data    => ioctl_dout,
    dn_wr      => ioctl_wr and rom_download,
    
    video_r    => r,
    video_g    => g,
    video_b    => b,
    
    --video_csync => open,
    video_hs    => hs,
    video_vs    => vs,
    blank_h     => hbl,
    blank_v     => vbl,
    
    audio       => audio,
    
    self_test  => dsw(2)(0),
    service    => dsw(2)(1),
    coin1      => m_coin1,
    coin2      => m_coin2,
    start1     => m_start1,
    start2     => m_start2,
    up1        => m_up,
    down1      => m_down,
    left1      => m_left,
    right1     => m_right,
    fire1      => m_fire,
    up2        => m_up,
    down2      => m_down,
    left2      => m_left,
    right2     => m_right,
    fire2      => m_fire,
    dip_switch_a    => not dsw(0),
    dip_switch_b    => not dsw(1),
    h_offset   => status(27 downto 24),
    v_offset   => status(31 downto 28),
    pause      => pause_cpu,
    
    hs_address => hs_address,
    hs_data_out => hs_data_out,
    hs_data_in => hs_data_in,
    hs_write   => hs_write_enable
 );

   -- @TODO: Add the actual MiSTer core here
   -- The demo core's purpose is to show a test image and to make sure, that the MiSTer2MEGA65 framework
   -- can be synthesized and run stand-alone without an actual MiSTer core being there, yet
 /*  i_democore : entity work.democore
      port map (
         clk_main_i           => clk_main_i,
         
         reset_i              => reset_soft_i or reset_hard_i,       -- long and short press of reset button mean the same
         pause_i              => pause_i,
         
         ball_col_rgb_i       => x"EE4020",                          -- ball color (RGB): orange
         paddle_speed_i       => x"1",                               -- paddle speed is about 50 pixels / sec (due to 50 Hz)          
         
         keyboard_n_i         => keyboard_n,                         -- move the paddle with the cursor left/right keys...
         joy_up_n_i           => joy_1_up_n_i,                       -- ... or move the paddle with a joystick in port #1
         joy_down_n_i         => joy_1_down_n_i,
         joy_left_n_i         => joy_1_left_n_i,
         joy_right_n_i        => joy_1_right_n_i,
         joy_fire_n_i         => joy_1_fire_n_i,
         
         vga_ce_o             => video_ce_o,
         vga_red_o            => video_red_o,
         vga_green_o          => video_green_o,
         vga_blue_o           => video_blue_o,
         vga_vs_o             => video_vs_o,
         vga_hs_o             => video_hs_o,
         vga_hblank_o         => video_hblank_o,
         vga_vblank_o         => video_vblank_o,
         
         audio_left_o         => audio_left_o,
         audio_right_o        => audio_right_o
      ); -- i_democore
      
   -- On video_ce_o and video_ce_ovl_o: You have an important @TODO when porting a core:
   -- video_ce_o: You need to make sure that video_ce_o divides clk_main_i such that it transforms clk_main_i
   --             into the pixelclock of the core (means: the core's native output resolution pre-scandoubler)
   -- video_ce_ovl_o: Clock enable for the OSM overlay and for sampling the core's (retro) output in a way that
   --             it is displayed correctly on a "modern" analog input device: Make sure that video_ce_ovl_o
   --             transforms clk_main_o into the post-scandoubler pixelclock that is valid for the target
   --             resolution specified by VGA_DX/VGA_DY (globals.vhd)
   -- video_retro15kHz_o: '1', if the output from the core (post-scandoubler) in the retro 15 kHz analog RGB mode.
   --             Hint: Scandoubler off does not automatically mean retro 15 kHz on.
   video_ce_ovl_o <= video_ce_o;
   video_retro15kHz_o <= '0';

   -- @TODO: Keyboard mapping and keyboard behavior
   -- Each core is treating the keyboard in a different way: Some need low-active "matrices", some
   -- might need small high-active keyboard memories, etc. This is why the MiSTer2MEGA65 framework
   -- lets you define literally everything and only provides a minimal abstraction layer to the keyboard.
   -- You need to adjust keyboard.vhd to your needs
*/
   i_keyboard : entity work.keyboard
      port map (
         clk_main_i           => clk_main_i,

         -- Interface to the MEGA65 keyboard
         key_num_i            => kb_key_num_i,
         key_pressed_n_i      => kb_key_pressed_n_i,

         -- @TODO: Create the kind of keyboard output that your core needs
         -- "example_n_o" is a low active register and used by the demo core:
         --    bit 0: Space
         --    bit 1: Return
         --    bit 2: Run/Stop
         example_n_o          => keyboard_n
      ); -- i_keyboard

end architecture synthesis;

