----------------------------------------------------------------------------------
-- MiSTer2MEGA65 Framework
--
-- MEGA65 main file that contains the whole machine
--
-- MiSTer2MEGA65 done by sy2002 and MJoergen in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.globals.all;
use work.types_pkg.all;


library xpm;
use xpm.vcomponents.all;

entity MEGA65_Core is
port (
   CLK                     : in std_logic;         -- 100 MHz clock
   RESET_M2M_N             : in std_logic;         -- Debounced system reset in system clock domain

   -- Share clock and reset with the framework
   main_clk_o              : out std_logic;        -- Galaga's 18 MHz main clock
   main_rst_o              : out std_logic;        -- Galaga's reset, synchronized
   
   video_clk_o             : out std_logic;        -- video clock 48 MHz
   video_rst_o             : out std_logic;        -- video reset, synchronized

   --------------------------------------------------------------------------------------------------------
   -- QNICE Clock Domain
   --------------------------------------------------------------------------------------------------------

   -- Get QNICE clock from the framework: for the vdrives as well as for RAMs and ROMs
   qnice_clk_i             : in std_logic;

   -- Video and audio mode control
   qnice_dvi_o             : out std_logic;              -- 0=HDMI (with sound), 1=DVI (no sound)
   qnice_video_mode_o      : out natural range 0 to 3;   -- HDMI 1280x720 @ 50 Hz resolution = mode 0, 1280x720 @ 60 Hz resolution = mode 1, PAL 576p in 4:3 and 5:4 are modes 2 and 3
   qnice_scandoubler_o     : out std_logic;              -- 0 = no scandoubler, 1 = scandoubler
   qnice_audio_mute_o      : out std_logic;
   qnice_audio_filter_o    : out std_logic;
   qnice_zoom_crop_o       : out std_logic;
   qnice_ascal_mode_o      : out std_logic_vector(1 downto 0);
   qnice_ascal_polyphase_o : out std_logic;
   qnice_ascal_triplebuf_o : out std_logic;

   -- Flip joystick ports
   qnice_flip_joyports_o   : out std_logic;

   -- On-Screen-Menu selections
   qnice_osm_control_i     : in std_logic_vector(255 downto 0);

   -- QNICE general purpose register
   qnice_gp_reg_i          : in std_logic_vector(255 downto 0);

   -- Core-specific devices
   qnice_dev_id_i          : in std_logic_vector(15 downto 0);
   qnice_dev_addr_i        : in std_logic_vector(27 downto 0);
   qnice_dev_data_i        : in std_logic_vector(15 downto 0);
   qnice_dev_data_o        : out std_logic_vector(15 downto 0);
   qnice_dev_ce_i          : in std_logic;
   qnice_dev_we_i          : in std_logic;

   --------------------------------------------------------------------------------------------------------
   -- Core Clock Domain
   --------------------------------------------------------------------------------------------------------

   -- M2M's reset manager provides 2 signals:
   --    m2m:   Reset the whole machine: Core and Framework
   --    core:  Only reset the core
   main_reset_m2m_i        : in std_logic;
   main_reset_core_i       : in std_logic;

   main_pause_core_i       : in std_logic;

   -- Video output
   main_video_ce_o         : out std_logic;
   main_video_ce_ovl_o     : out std_logic;
   main_video_retro15kHz_o : out std_logic;
   main_video_red_o        : out std_logic_vector(7 downto 0);
   main_video_green_o      : out std_logic_vector(7 downto 0);
   main_video_blue_o       : out std_logic_vector(7 downto 0);
   main_video_vs_o         : out std_logic;
   main_video_hs_o         : out std_logic;
   main_video_hblank_o     : out std_logic;
   main_video_vblank_o     : out std_logic;
   main_video_de_o         : out std_logic;
   
   -- Audio output (Signed PCM)
   main_audio_left_o       : out signed(15 downto 0);
   main_audio_right_o      : out signed(15 downto 0);

   -- M2M Keyboard interface (incl. drive led)
   main_kb_key_num_i       : in  integer range 0 to 79;    -- cycles through all MEGA65 keys
   main_kb_key_pressed_n_i : in  std_logic;                -- low active: debounced feedback: is kb_key_num_i pressed right now?
   main_drive_led_o        : out std_logic;
   main_drive_led_col_o    : out std_logic_vector(23 downto 0);

   -- Joysticks input
   main_joy_1_up_n_i       : in std_logic;
   main_joy_1_down_n_i     : in std_logic;
   main_joy_1_left_n_i     : in std_logic;
   main_joy_1_right_n_i    : in std_logic;
   main_joy_1_fire_n_i     : in std_logic;

   main_joy_2_up_n_i       : in std_logic;
   main_joy_2_down_n_i     : in std_logic;
   main_joy_2_left_n_i     : in std_logic;
   main_joy_2_right_n_i    : in std_logic;
   main_joy_2_fire_n_i     : in std_logic;
   
   main_pot1_x_i           : in std_logic_vector(7 downto 0);
   main_pot1_y_i           : in std_logic_vector(7 downto 0);
   main_pot2_x_i           : in std_logic_vector(7 downto 0);
   main_pot2_y_i           : in std_logic_vector(7 downto 0);   

   -- On-Screen-Menu selections
   main_osm_control_i     : in std_logic_vector(255 downto 0);
   
   -- QNICE general purpose register converted to main clock domain
   main_qnice_gp_reg_i    : in std_logic_vector(255 downto 0);
   
   --------------------------------------------------------------------------------------------------------
   -- Provide HyperRAM to core (in HyperRAM clock domain)
   --------------------------------------------------------------------------------------------------------   
   
   hr_clk_i                : in  std_logic;
   hr_rst_i                : in  std_logic;
   hr_write_o              : out std_logic := '0'; 
   hr_read_o               : out std_logic := '0';
   hr_address_o            : out std_logic_vector(31 downto 0) := (others => '0');
   hr_writedata_o          : out std_logic_vector(15 downto 0) := (others => '0');
   hr_byteenable_o         : out std_logic_vector(1 downto 0)  := (others => '0');
   hr_burstcount_o         : out std_logic_vector(7 downto 0)  := (others => '0');
   hr_readdata_i           : in  std_logic_vector(15 downto 0) := (others => '0');
   hr_readdatavalid_i      : in  std_logic;
   hr_waitrequest_i        : in  std_logic
);
end entity MEGA65_Core;

architecture synthesis of MEGA65_Core is

---------------------------------------------------------------------------------------------
-- Clocks and active high reset signals for each clock domain
---------------------------------------------------------------------------------------------

signal main_clk            : std_logic;               -- Core main clock
signal main_rst            : std_logic;

signal video_clk           : std_logic;               
signal video_rst           : std_logic;

---------------------------------------------------------------------------------------------
-- main_clk (MiSTer core's clock)
---------------------------------------------------------------------------------------------

-- Unprocessed video output from the Galaga core
signal main_video_red      : std_logic_vector(2 downto 0);   
signal main_video_green    : std_logic_vector(2 downto 0);
signal main_video_blue     : std_logic_vector(1 downto 0);
signal main_video_vs       : std_logic;
signal main_video_hs       : std_logic;
signal main_video_hblank   : std_logic;
signal main_video_vblank   : std_logic;

signal status              : signed(31 downto 0);
signal forced_scandoubler  : std_logic;
signal gamma_bus           : std_logic_vector(21 downto 0);

signal direct_video      : std_logic;
signal flip              : std_logic := '0';
signal video_rotated     : std_logic;
signal flip_screen       : std_logic := status(8);
signal no_rotate         : std_logic := status(2) OR direct_video;
signal rotate_ccw        : std_logic := flip_screen;

---------------------------------------------------------------------------------------------
-- qnice_clk
---------------------------------------------------------------------------------------------

-- @TODO: Change all these democore menu items
constant C_MENU_HDMI_16_9_50  : natural := 9;
constant C_MENU_HDMI_16_9_60  : natural := 10;
constant C_MENU_HDMI_4_3_50   : natural := 11;
constant C_MENU_HDMI_5_4_50   : natural := 12;
constant C_MENU_CRT_EMULATION : natural := 22;
constant C_MENU_HDMI_ZOOM     : natural := 23;
constant C_MENU_IMPROVE_AUDIO : natural := 24;


-- Galaga specific video processing
signal HSync,VSync,HBlank,VBlank : std_logic;
signal rgb_out                   : std_logic_vector(7 downto 0);
signal ce_pix                    : std_logic;
signal div                       : std_logic_vector(2 downto 0);
signal dim_video                 : std_logic;

begin

   -- MMCME2_ADV clock generators:
   --   @TODO YOURCORE:       54 MHz
   clk_gen : entity work.clk
      port map (
         sys_clk_i         => CLK,             -- expects 100 MHz
         sys_rstn_i        => RESET_M2M_N,     -- Asynchronous, asserted low
         
         main_clk_o        => main_clk,        -- Galaga's 18 MHz main clock
         main_rst_o        => main_rst,        -- Galaga's reset, synchronized
         
         video_clk_o       => video_clk,       -- video clock 48 MHz
         video_rst_o       => video_rst        -- video reset, synchronized
      
      ); -- clk_gen

   main_clk_o   <= main_clk;
   main_rst_o   <= main_rst;
   video_clk_o  <= video_clk;
   video_rst_o  <= video_rst;
   
    process (video_clk_o)
        begin
        if rising_edge(video_clk_o) then
             div <= std_logic_vector(unsigned(div) + 1);
             ce_pix <= not (div(0) xor div(1) xor div(2));
             if dim_video = '1' then
                rgb_out <=   std_logic_vector(resize(unsigned(main_video_red) srl 1, 3)) & 
                             std_logic_vector(resize(unsigned(main_video_green) srl 1, 3)) & 
                             std_logic_vector(resize(unsigned(main_video_blue) srl 1, 2));
             else
                rgb_out <= std_logic_vector(main_video_red) & std_logic_vector(main_video_green) & std_logic_vector(main_video_blue);
             end if;    
             
             HSync <= not main_video_hs;
             VSync <= not main_video_vs;
             HBlank <= main_video_hblank;
             VBlank <= main_video_vblank;  
             
        end if;        
    end process;
    
   -- @This here remains a rather complicated TODO. sy2002 and/or MJoergen will support
   -- OLD COMMENT TAKEN FROM ANOTHER FILE, DOES NOT FULLY FIT HERE:
   -- On video_ce_o and video_ce_ovl_o: You have an important @TODO when porting a core:
   -- video_ce_o: You need to make sure that video_ce_o divides clk_main_i such that it transforms clk_main_i
   --             into the pixelclock of the core (means: the core's native output resolution pre-scandoubler)
   -- video_ce_ovl_o: Clock enable for the OSM overlay and for sampling the core's (retro) output in a way that
   --             it is displayed correctly on a "modern" analog input device: Make sure that video_ce_ovl_o
   --             transforms clk_main_o into the post-scandoubler pixelclock that is valid for the target
   --             resolution specified by VGA_DX/VGA_DY (globals.vhd)
   -- video_retro15kHz_o: '1', if the output from the core (post-scandoubler) in the retro 15 kHz analog RGB mode.
   --             Hint: Scandoubler off does not automatically mean retro 15 kHz on.
   main_video_ce_ovl_o     <= '1';
   main_video_retro15kHz_o <= '0';

   ---------------------------------------------------------------------------------------------
   -- main_clk (MiSTer core's clock)
   ---------------------------------------------------------------------------------------------

   -- main.vhd contains the actual MiSTer core
    i_main : entity work.main
      generic map (
         G_VDNUM              => C_VDNUM
      )
      port map (
         clk_main_i           => main_clk,
         reset_soft_i         => main_reset_core_i,
         reset_hard_i         => main_reset_m2m_i,
         pause_i              => main_pause_core_i,

         clk_main_speed_i     => CORE_CLK_SPEED,

         -- Video output
         -- This is PAL 720x576 @ 50 Hz (pixel clock 27 MHz), but synchronized to main_clk (54 MHz).
         video_ce_o           => open,
         video_ce_ovl_o       => open,
         video_retro15kHz_o   => open,
         video_red_o          => main_video_red,
         video_green_o        => main_video_green,
         video_blue_o         => main_video_blue,
         video_vs_o           => main_video_vs,
         video_hs_o           => main_video_hs,
         video_hblank_o       => main_video_hblank,
         video_vblank_o       => main_video_vblank,

         -- Audio output (PCM format, signed values)
         audio_left_o         => main_audio_left_o,
         audio_right_o        => main_audio_right_o,

         -- M2M Keyboard interface
         kb_key_num_i         => main_kb_key_num_i,
         kb_key_pressed_n_i   => main_kb_key_pressed_n_i,

         -- MEGA65 joysticks and paddles/mouse/potentiometers
         joy_1_up_n_i         => main_joy_1_up_n_i ,
         joy_1_down_n_i       => main_joy_1_down_n_i,
         joy_1_left_n_i       => main_joy_1_left_n_i,
         joy_1_right_n_i      => main_joy_1_right_n_i,
         joy_1_fire_n_i       => main_joy_1_fire_n_i,

         joy_2_up_n_i         => main_joy_2_up_n_i,
         joy_2_down_n_i       => main_joy_2_down_n_i,
         joy_2_left_n_i       => main_joy_2_left_n_i,
         joy_2_right_n_i      => main_joy_2_right_n_i,
         joy_2_fire_n_i       => main_joy_2_fire_n_i,
         
         pot1_x_i             => main_pot1_x_i,
         pot1_y_i             => main_pot1_y_i,
         pot2_x_i             => main_pot2_x_i,
         pot2_y_i             => main_pot2_y_i
          
      ); -- i_main

        -- screen rotate

--    i_screen_rotate : entity work.screen_rotate
--    port map (
  
--    --inputs
--    CLK_VIDEO  => video_clk_o,
--    CE_PIXEL   => main_video_ce_o,
--    VGA_R      => main_video_red_o,
--    VGA_G      => main_video_green_o,
--    VGA_B      => main_video_blue_o,
--    VGA_HS     => main_video_hs_o,
--    VGA_VS     => main_video_vs_o,
--    VGA_DE     => main_video_de_o,
--    rotate_ccw => rotate_ccw,
--    no_rotate  => no_rotate,
--    flip       => flip,
--    FB_VBL     => FB_VBL,
--    FB_LL      => FB_LL,
    
--    DDRAM_BUSY => '0', -- set this to 0 for now
--    -- outputs
--    video_rotated => video_rotated,
--    FB_EN        => FB_EN,
    
--    FB_FORMAT    => FB_FORMAT,
--    FB_WIDTH     => FB_WIDTH,
--    FB_HEIGHT    => FB_HEIGHT,
--    FB_BASE      => FB_BASE,     
--    FB_STRIDE    => FB_STRIDE
    
  
--  );

    --arcade video

    i_arcade_video : entity work.arcade_video
        generic map (
        
            WIDTH => 288,   -- screen width in pixels ( ROT90 )
            DW    => 8,     -- each character is 8 pixels x 8 pixels
            GAMMA => 0      -- @TODO: Deactivated to start with; we might need to reactivate later
        )         
     port map (
        clk_video_i         => video_clk,             -- video clock 48 MHz
        ce_pix              => ce_pix,
        RGB_in              => rgb_out,
        HBlank              => HBlank,
        VBlank              => VBlank,
        HSync               => HSync,
        VSync               => VSync,
        CLK_VIDEO_o         => open,                  -- @TODO: need to handle later
        CE_PIXEL            => main_video_ce_o,
        VGA_R               => main_video_red_o,
        VGA_G               => main_video_green_o,
        VGA_B               => main_video_blue_o,
        VGA_HS              => main_video_hs_o,
        VGA_VS              => main_video_vs_o,
        VGA_DE              => main_video_de_o,
        VGA_SL              => open,                  -- @TODO: need to handle later
        fx                  => status(5 downto 3),
        forced_scandoubler  => forced_scandoubler,
        gamma_bus           => gamma_bus
        
     );
       ---------------------------------------------------------------------------------------------
   -- Audio and video settings (QNICE clock domain)
   ---------------------------------------------------------------------------------------------

   -- Due to a discussion on the MEGA65 discord (https://discord.com/channels/719326990221574164/794775503818588200/1039457688020586507)
   -- we decided to choose a naming convention for the PAL modes that might be more intuitive for the end users than it is
   -- for the programmers: "4:3" means "meant to be run on a 4:3 monitor", "5:4 on a 5:4 monitor".
   -- The technical reality is though, that in our "5:4" mode we are actually doing a 4/3 aspect ratio adjustment
   -- while in the 4:3 mode we are outputting a 5:4 image. This is kind of odd, but it seemed that our 4/3 aspect ratio
   -- adjusted image looks best on a 5:4 monitor and the other way round.
   -- Not sure if this will stay forever or if we will come up with a better naming convention.
   qnice_video_mode_o <= 3 when qnice_osm_control_i(C_MENU_HDMI_5_4_50)  = '1' else
                         2 when qnice_osm_control_i(C_MENU_HDMI_4_3_50)  = '1' else
                         1 when qnice_osm_control_i(C_MENU_HDMI_16_9_60) = '1' else
                         0;

   -- Use On-Screen-Menu selections to configure several audio and video settings
   -- Video and audio mode control
   qnice_dvi_o                <= '0';                                         -- 0=HDMI (with sound), 1=DVI (no sound)
   qnice_scandoubler_o        <= '0';                                         -- no scandoubler
   qnice_audio_mute_o         <= '0';                                         -- audio is not muted
   qnice_audio_filter_o       <= qnice_osm_control_i(C_MENU_IMPROVE_AUDIO);   -- 0 = raw audio, 1 = use filters from globals.vhd
   qnice_zoom_crop_o          <= qnice_osm_control_i(C_MENU_HDMI_ZOOM);       -- 0 = no zoom/crop

   -- ascal filters that are applied while processing the input
   -- 00 : Nearest Neighbour
   -- 01 : Bilinear
   -- 10 : Sharp Bilinear
   -- 11 : Bicubic
   qnice_ascal_mode_o         <= "00";

   -- If polyphase is '1' then the ascal filter mode is ignored and polyphase filters are used instead
   -- @TODO: Right now, the filters are hardcoded in the M2M framework, we need to make them changeable inside m2m-rom.asm
   qnice_ascal_polyphase_o    <= qnice_osm_control_i(C_MENU_CRT_EMULATION);

   -- ascal triple-buffering
   -- @TODO: Right now, the M2M framework only supports OFF, so do not touch until the framework is upgraded
   qnice_ascal_triplebuf_o    <= '0';

   -- Flip joystick ports (i.e. the joystick in port 2 is used as joystick 1 and vice versa)
   qnice_flip_joyports_o      <= '0';

   ---------------------------------------------------------------------------------------------
   -- Core specific device handling (QNICE clock domain)
   ---------------------------------------------------------------------------------------------

   core_specific_devices : process(all)
   begin
      -- make sure that this is x"EEEE" by default and avoid a register here by having this default value
      qnice_dev_data_o     <= x"EEEE";

      case qnice_dev_id_i is

         -- @TODO YOUR RAMs or ROMs (e.g. for cartridges) or other devices here
         -- Device numbers need to be >= 0x0100

         when others => null;
      end case;
   end process core_specific_devices;

   ---------------------------------------------------------------------------------------------
   -- Dual Clocks
   ---------------------------------------------------------------------------------------------

   -- Put your dual-clock devices such as RAMs and ROMs here
   --
   -- Use the M2M framework's official RAM/ROM: dualport_2clk_ram
   -- and make sure that the you configure the port that works with QNICE as a falling edge
   -- by setting G_FALLING_A or G_FALLING_B (depending on which port you use) to true.


end architecture synthesis;
