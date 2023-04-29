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
            
      -- Video output
      video_ce_o              : out std_logic;
      video_ce_ovl_o          : out std_logic;
      video_retro15kHz_o      : out std_logic;
      video_red_o             : out std_logic_vector(2 downto 0);
      video_green_o           : out std_logic_vector(2 downto 0);
      video_blue_o            : out std_logic_vector(1 downto 0);
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
    
    clock_18   => clk_main_i,
    reset      => reset_soft_i,
    
    video_r    => video_red_o,
    video_g    => video_green_o,
    video_b    => video_blue_o,
    
    --video_csync => open,
    video_hs    => video_hs_o,
    video_vs    => video_vs_o,
    blank_h     => video_hblank_o,
    blank_v     => video_vblank_o,
    
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
    hs_write   => hs_write_enable,
    
    -- @TODO: ROM loading. For now we will hardcode the ROMs
    dn_addr    => (others => '0'),
    dn_data    => (others => '0'),
    dn_wr      => '0'
 );

   -- @TODO: Keyboard mapping and keyboard behavior
   -- Each core is treating the keyboard in a different way: Some need low-active "matrices", some
   -- might need small high-active keyboard memories, etc. This is why the MiSTer2MEGA65 framework
   -- lets you define literally everything and only provides a minimal abstraction layer to the keyboard.
   -- You need to adjust keyboard.vhd to your needs
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

