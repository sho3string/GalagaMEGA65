----------------------------------------------------------------------------------
-- MiSTer2MEGA65 Framework
--
-- Abstraction layer to simplify mega65.vhd
--
-- MiSTer2MEGA65 done by sy2002 and MJoergen in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.qnice_tools.all;

library work;
use work.globals.all;
use work.types_pkg.all;
use work.video_modes_pkg.all;

library xpm;
use xpm.vcomponents.all;

entity av_pipeline is
   generic (
      G_VIDEO_MODE_VECTOR    : video_modes_vector;   -- Desired video format of HDMI output.
      G_AUDIO_CLOCK_RATE     : natural := 30_000_000;
      G_VGA_DX               : natural;              -- Actual format of video from Core (in pixels).
      G_VGA_DY               : natural;
      G_FONT_FILE            : string;
      G_FONT_DX              : natural;
      G_FONT_DY              : natural
   );
   port (
      -- From CORE
      video_clk_i          : in  std_logic;
      video_rst_i          : in  std_logic;
      video_ce_i           : in  std_logic;
      video_ce_ovl_i       : in  std_logic;
      video_red_i          : in  std_logic_vector( 7 downto 0);
      video_green_i        : in  std_logic_vector( 7 downto 0);
      video_blue_i         : in  std_logic_vector( 7 downto 0);
      video_vs_i           : in  std_logic;
      video_hs_i           : in  std_logic;
      video_hblank_i       : in  std_logic;
      video_vblank_i       : in  std_logic;
      audio_clk_i          : in  std_logic;
      audio_rst_i          : in  std_logic;
      audio_left_i         : in  std_logic_vector(15 downto 0);
      audio_right_i        : in  std_logic_vector(15 downto 0);

      -- From QNICE
      qnice_clk_i          : in  std_logic;
      qnice_rst_i          : in  std_logic;
      qnice_retro15kHz_i   : in  std_logic;
      qnice_scandoubler_i  : in  std_logic;
      qnice_csync_i        : in  std_logic;
      qnice_zoom_crop_i    : in  std_logic;
      qnice_audio_filter_i : in  std_logic;
      qnice_audio_mute_i   : in  std_logic;

      -- To QNICE
      qnice_x_vis_o        : out std_logic_vector(15 downto 0);
      qnice_x_tot_o        : out std_logic_vector(15 downto 0);
      qnice_y_vis_o        : out std_logic_vector(15 downto 0);
      qnice_y_tot_o        : out std_logic_vector(15 downto 0);
      qnice_h_freq_o       : out std_logic_vector(15 downto 0);

      -- HyperRAM access for framebuffer
      hr_clk_i             : in  std_logic;
      hr_rst_i             : in  std_logic;
      hr_write_o           : out std_logic;
      hr_read_o            : out std_logic;
      hr_address_o         : out std_logic_vector(31 downto 0);
      hr_writedata_o       : out std_logic_vector(15 downto 0);
      hr_byteenable_o      : out std_logic_vector( 1 downto 0);
      hr_burstcount_o      : out std_logic_vector( 7 downto 0);
      hr_readdata_i        : in  std_logic_vector(15 downto 0);
      hr_readdatavalid_i   : in  std_logic;
      hr_waitrequest_i     : in  std_logic;
      hr_high_o            : out std_logic; -- Core is too fast
      hr_low_o             : out std_logic; -- Core is too slow

      -- I/O to VGA output
      VGA_RED              : out std_logic_vector( 7 downto 0);
      VGA_GREEN            : out std_logic_vector( 7 downto 0);
      VGA_BLUE             : out std_logic_vector( 7 downto 0);
      VGA_HS               : out std_logic;
      VGA_VS               : out std_logic;
      vdac_clk             : out std_logic;
      vdac_sync_n          : out std_logic;
      vdac_blank_n         : out std_logic;

      -- I/O to 3.5mm analog audio jack
      pwm_l                : out std_logic;
      pwm_r                : out std_logic;

      -- I/O to Digital Video (HDMI)
      hdmi_clk_i           : in  std_logic;
      hdmi_rst_i           : in  std_logic;
      tmds_clk_i           : in  std_logic;
      tmds_data_p          : out std_logic_vector( 2 downto 0);
      tmds_data_n          : out std_logic_vector( 2 downto 0);
      tmds_clk_p           : out std_logic;
      tmds_clk_n           : out std_logic
   );
end entity av_pipeline;

architecture synthesis of av_pipeline is

---------------------------------------------------------------------------------------------
-- audio_clk
---------------------------------------------------------------------------------------------

-- signed audio from the core
-- if the core outputs unsigned audio, make sure you convert properly to prevent a loss in audio quality
signal audio_filt_left        : std_logic_vector(15 downto 0);
signal audio_filt_right       : std_logic_vector(15 downto 0);
signal audio_left             : std_logic_vector(15 downto 0);
signal audio_right            : std_logic_vector(15 downto 0);

--- control signals from QNICE
signal audio_filter           : std_logic;
signal audio_mute             : std_logic;

---------------------------------------------------------------------------------------------
-- video_clk
---------------------------------------------------------------------------------------------
signal video_retro15kHz       : std_logic;

signal video_crop_ce          : std_logic;
signal video_crop_red         : std_logic_vector(7 downto 0);
signal video_crop_green       : std_logic_vector(7 downto 0);
signal video_crop_blue        : std_logic_vector(7 downto 0);
signal video_crop_hs          : std_logic;
signal video_crop_vs          : std_logic;
signal video_crop_hblank      : std_logic;
signal video_crop_vblank      : std_logic;

-- On-Screen-Menu (OSM) for VGA
signal video_osm_cfg_enable   : std_logic;
signal video_osm_cfg_xy       : std_logic_vector(15 downto 0);
signal video_osm_cfg_dxdy     : std_logic_vector(15 downto 0);
signal video_osm_vram_addr    : std_logic_vector(15 downto 0);
signal video_osm_vram_data    : std_logic_vector(15 downto 0);
signal video_hdmax            : natural range 0 to 4095;
signal video_vdmax            : natural range 0 to 4095;

signal video_pps              : std_logic;
signal video_x_vis            : std_logic_vector(15 downto 0);
signal video_x_tot            : std_logic_vector(15 downto 0);
signal video_y_vis            : std_logic_vector(15 downto 0);
signal video_y_tot            : std_logic_vector(15 downto 0);
signal video_h_freq           : std_logic_vector(15 downto 0);

---------------------------------------------------------------------------------------------
-- hdmi_clk
---------------------------------------------------------------------------------------------

-- On-Screen-Menu (OSM) for HDMI
signal hdmi_osm_cfg_enable    : std_logic;
signal hdmi_osm_cfg_xy        : std_logic_vector(15 downto 0);
signal hdmi_osm_cfg_dxdy      : std_logic_vector(15 downto 0);
signal hdmi_osm_vram_addr     : std_logic_vector(15 downto 0);
signal hdmi_osm_vram_data     : std_logic_vector(15 downto 0);

signal hdmi_video_mode        : std_logic_vector(1 downto 0);
signal hdmi_zoom_crop         : std_logic;

-- QNICE On Screen Menu selections
signal hdmi_osm_control_m     : std_logic_vector(255 downto 0);

---------------------------------------------------------------------------------------------
-- MiSTer audio filter
---------------------------------------------------------------------------------------------

component audio_out
   generic (
      CLK_RATE : natural
   );
   port (
      reset       : in  std_logic;
      clk         : in  std_logic;

      -- 0 - 48KHz, 1 - 96KHz
      sample_rate : in  std_logic;

      flt_rate    : in  std_logic_vector(31 downto 0);
      cx          : in  std_logic_vector(39 downto 0);
      cx0         : in  std_logic_vector( 7 downto 0);
      cx1         : in  std_logic_vector( 7 downto 0);
      cx2         : in  std_logic_vector( 7 downto 0);
      cy0         : in  std_logic_vector(23 downto 0);
      cy1         : in  std_logic_vector(23 downto 0);
      cy2         : in  std_logic_vector(23 downto 0);

      att         : in  std_logic_vector( 4 downto 0);
      mix         : in  std_logic_vector( 1 downto 0);

      is_signed   : in  std_logic;
      core_l      : in  std_logic_vector(15 downto 0);
      core_r      : in  std_logic_vector(15 downto 0);

      alsa_l      : in  std_logic_vector(15 downto 0);
      alsa_r      : in  std_logic_vector(15 downto 0);

      -- Signed output
      al          : out std_logic_vector(15 downto 0);
      ar          : out std_logic_vector(15 downto 0)
   );
end component audio_out;

begin

   -- Clock domain crossing: QNICE to VGA QNICE-On-Screen-Display
   i_qnice2video: xpm_cdc_array_single
      generic map (
         WIDTH => 36
      )
      port map (
         src_clk                => qnice_clk_i,
         src_in(15 downto 0)    => qnice_osm_cfg_xy_i,
         src_in(31 downto 16)   => qnice_osm_cfg_dxdy_i,
         src_in(32)             => qnice_osm_cfg_enable_i,
         src_in(33)             => qnice_zoom_crop_i,
         src_in(34)             => qnice_scandoubler_i,
         src_in(35)             => qnice_csync_i,
         dest_clk               => video_clk_i,
         dest_out(15 downto 0)  => video_osm_cfg_xy,
         dest_out(31 downto 16) => video_osm_cfg_dxdy,
         dest_out(32)           => video_osm_cfg_enable,
         dest_out(33)           => video_zoom_crop,
         dest_out(34)           => video_scandoubler,
         dest_out(35)           => video_csync
      ); -- i_qnice2video


   i_audio_out : audio_out
      generic map (
         CLK_RATE => G_AUDIO_CLOCK_RATE
      )
      port map (
         reset       => audio_rst_i,
         clk         => audio_clk_i,

         sample_rate => '0', -- 0 - 48KHz, 1 - 96KHz

         flt_rate    => audio_flt_rate,
         cx          => audio_cx,
         cx0         => audio_cx0,
         cx1         => audio_cx1,
         cx2         => audio_cx2,
         cy0         => audio_cy0,
         cy1         => audio_cy1,
         cy2         => audio_cy2,
         att         => audio_att,
         mix         => audio_mix,

         is_signed   => '1',
         core_l      => audio_left_i,
         core_r      => audio_right_i,

         alsa_l      => (others => '0'),
         alsa_r      => (others => '0'),

         -- Signed output
         al          => audio_filt_left,
         ar          => audio_filt_right
      ); -- i_audio_out

   select_or_mute_audio : process(all)
   begin
      if main_audio_mute = '1' then
         audio_left  <= (others => '0');
         audio_right <= (others => '0');
      else
         if main_audio_filter = '0' then
            audio_left  <= audio_left_i;
            audio_right <= audio_right_i;
         else
            audio_left  <= audio_filt_left;
            audio_right <= audio_filt_right;
         end if;
      end if;
   end process select_or_mute_audio;

   i_video_counters : entity work.video_counters
      port map (
         video_clk_i    => video_clk_i,
         video_rst_i    => video_rst_i,
         video_ce_i     => video_ce_i,
         video_vs_i     => video_vs_i,
         video_hs_i     => video_hs_i,
         video_hblank_i => video_hblank_i,
         video_vblank_i => video_vblank_i,
         video_pps_i    => video_pps,
         video_x_vis_o  => video_x_vis,
         video_x_tot_o  => video_x_tot,
         video_y_vis_o  => video_y_vis,
         video_y_tot_o  => video_y_tot,
         video_h_freq_o => video_h_freq
      ); -- i_video_counters

   i_analog_pipeline : entity work.analog_pipeline
      generic map (
         G_VGA_DX               => G_VGA_DX,
         G_VGA_DY               => G_VGA_DY,
         G_FONT_FILE            => G_FONT_FILE,
         G_FONT_DX              => G_FONT_DX,
         G_FONT_DY              => G_FONT_DY
      )
      port map (
         -- Input from Core (video and audio)
         video_clk_i            => video_clk_i,
         video_rst_i            => video_rst_i,
         video_ce_i             => video_ce_i,
         video_ce_ovl_i         => video_ce_ovl_i,
         video_retro15kHz_i     => video_retro15kHz,
         video_red_i            => video_red_i,
         video_green_i          => video_green_i,
         video_blue_i           => video_blue_i,
         video_hs_i             => video_hs_i,
         video_vs_i             => video_vs_i,
         video_hblank_i         => video_hblank_i,
         video_vblank_i         => video_vblank_i,
         audio_clk_i            => audio_clk_i, -- 30 MHz
         audio_rst_i            => audio_rst_i,
         audio_left_i           => signed(audio_left),
         audio_right_i          => signed(audio_right),

         -- Configure the scandoubler: 0=off/1=on
         -- Make sure the signal is in the video_clk clock domain
         video_scandoubler_i    => video_scandoubler_i,

         -- Configure composite sync: 0=off/1=on
         video_csync_i          => video_csync_i,

         -- Analog output (VGA and audio jack)
         vga_red_o              => vga_red,
         vga_green_o            => vga_green,
         vga_blue_o             => vga_blue,
         vga_hs_o               => vga_hs,
         vga_vs_o               => vga_vs,
         vdac_clk_o             => vdac_clk,
         vdac_syncn_o           => vdac_sync_n,
         vdac_blankn_o          => vdac_blank_n,
         pwm_l_o                => pwm_l,
         pwm_r_o                => pwm_r,

         -- Connect to QNICE and Video RAM
         video_osm_cfg_enable_i => video_osm_cfg_enable_i,
         video_osm_cfg_xy_i     => video_osm_cfg_xy_i,
         video_osm_cfg_dxdy_i   => video_osm_cfg_dxdy_i,
         video_osm_vram_addr_o  => video_osm_vram_addr_o,
         video_osm_vram_data_i  => video_osm_vram_data_i
      ); -- i_analog_pipeline

   i_crop : entity work.crop
      port map (
         video_crop_mode_i => video_zoom_crop_i,
         video_clk_i       => video_clk_i,
         video_rst_i       => video_rst_i,
         video_ce_i        => video_ce_i,
         video_red_i       => video_red_i,
         video_green_i     => video_green_i,
         video_blue_i      => video_blue_i,
         video_hs_i        => video_hs_i,
         video_vs_i        => video_vs_i,
         video_hblank_i    => video_hblank_i,
         video_vblank_i    => video_vblank_i,
         video_ce_o        => video_crop_ce,
         video_red_o       => video_crop_red,
         video_green_o     => video_crop_green,
         video_blue_o      => video_crop_blue,
         video_hs_o        => video_crop_hs,
         video_vs_o        => video_crop_vs,
         video_hblank_o    => video_crop_hblank,
         video_vblank_o    => video_crop_vblank
      ); -- i_crop

   i_digital_pipeline : entity work.digital_pipeline
      generic map (
         G_VIDEO_MODE_VECTOR => G_VIDEO_MODE_VECTOR,
         G_VGA_DX            => G_VGA_DX,
         G_VGA_DY            => G_VGA_DY,
         G_FONT_FILE         => G_FONT_FILE,
         G_FONT_DX           => G_FONT_DX,
         G_FONT_DY           => G_FONT_DY
      )
      port map (
         -- Input from Core (video and audio)
         video_clk_i              => video_clk_i,
         video_rst_i              => video_rst_i,
         video_ce_i               => video_crop_ce,
         video_red_i              => video_crop_red,
         video_green_i            => video_crop_green,
         video_blue_i             => video_crop_blue,
         video_hs_i               => video_crop_hs,
         video_vs_i               => video_crop_vs,
         video_hblank_i           => video_crop_hblank,
         video_vblank_i           => video_crop_vblank,
         video_hdmax_o            => video_hdmax,
         video_vdmax_o            => video_vdmax,
         audio_clk_i              => audio_clk_i, -- 30 MHz
         audio_rst_i              => audio_rst_i,
         audio_left_i             => audio_left_i,
         audio_right_i            => audio_right_i,

         -- Digital output (HDMI)
         hdmi_clk_i               => hdmi_clk_i,
         hdmi_rst_i               => hdmi_rst_i,
         tmds_clk_i               => tmds_clk_i,
         tmds_data_p_o            => tmds_data_p_o,
         tmds_data_n_o            => tmds_data_n_o,
         tmds_clk_p_o             => tmds_clk_p_o,
         tmds_clk_n_o             => tmds_clk_n_o,

         -- Connect to QNICE and Video RAM
         hdmi_dvi_i               => qnice_dvi_i, -- proper clock domain crossing for this very signal happens inside vga_to_hdmi.vhd
         hdmi_video_mode_i        => to_integer(unsigned(hdmi_video_mode)),
         hdmi_crop_mode_i         => hdmi_zoom_crop,
         hdmi_osm_cfg_enable_i    => hdmi_osm_cfg_enable,
         hdmi_osm_cfg_xy_i        => hdmi_osm_cfg_xy,
         hdmi_osm_cfg_dxdy_i      => hdmi_osm_cfg_dxdy,
         hdmi_osm_vram_addr_o     => hdmi_osm_vram_addr,
         hdmi_osm_vram_data_i     => hdmi_osm_vram_data,

         -- QNICE connection to ascal's mode register
         qnice_ascal_mode_i       => unsigned(qn_ascal_mode),

         -- QNICE device for interacting with the Polyphase filter coefficients
         qnice_poly_clk_i         => qnice_clk,
         qnice_poly_dw_i          => unsigned(qnice_ramrom_data_out_o(9 downto 0)),
         qnice_poly_a_i           => unsigned(qnice_ramrom_addr_o(6+3 downto 0)),
         qnice_poly_wr_i          => qnice_poly_wr,

         -- Connect to HyperRAM controller
         hr_clk_i                 => hr_clk_i,
         hr_rst_i                 => hr_rst_i,
         hr_write_o               => hr_write_o,
         hr_read_o                => hr_read_o,
         hr_address_o             => hr_address_o,
         hr_writedata_o           => hr_writedata_o,
         hr_byteenable_o          => hr_byteenable_o,
         hr_burstcount_o          => hr_burstcount_o,
         hr_readdata_i            => hr_readdata_i,
         hr_readdatavalid_i       => hr_readdatavalid_i,
         hr_waitrequest_i         => hr_waitrequest_i
      ); -- i_digital_pipeline

   -- Monitor the read and write accesses to the HyperRAM by the ascaler.
   i_hdmi_flicker_free : entity work.hdmi_flicker_free
      generic map (
         G_THRESHOLD_LOW  => X"0000_1000",  -- @TODO: Optimize these threshold values
         G_THRESHOLD_HIGH => X"0000_2000"
      )
      port map (
         hr_clk_i       => hr_clk_i,
         hr_write_i     => hr_write_o,
         hr_read_i      => hr_read_o,
         hr_address_i   => hr_address_o,
         high_o         => hr_high_o,       -- Core is too fast
         low_o          => hr_low_o         -- Core is too slow
      ); -- i_hdmi_flicker_free

end architecture synthesis;
