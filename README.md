Galaga for MEGA65
=================

Galaga is an iconic arcade classic that has captivated generations of gamers
with its fast-paced gameplay and vibrant graphics. Originally released in
1981, this space-themed fixed shooter game has stood the test of time, as it
continues to be loved and celebrated by both casual and avid gamers alike.
The simple yet addictive nature of the game, where players control a spaceship
to defend against swarms of alien invaders, has left an indelible mark on the
history of video games.

Now, with the power of the MEGA65, you can experience Galaga in all its glory
with sublime compatibility and accuracy. The MEGA65, a modern recreation of
the legendary Commodore 65, offers a retro gaming experience like no other,
bringing together the nostalgia of classic games with cutting-edge hardware.
Relive the excitement of this cherished classic, as you dive into the world of
Galaga on your MEGA65 and enjoy a gaming experience that's as close to the
original as it gets.

Get ready to embark on an intergalactic adventure, and prepare to be
transported back in time to the golden era of arcade gaming with
Galaga on your MEGA65!

This core is based on the
[MiSTer](https://github.com/MiSTer-devel/Arcade-Galaga_MiSTer)
Galaga core which
itself is based on the work of [many others](AUTHORS).

[Muse aka sho3string](https://github.com/sho3string)
ported the core to the MEGA65 in 2023.

The core uses the [MiSTer2MEGA65](https://github.com/sy2002/MiSTer2MEGA65)
framework and [QNICE-FPGA](https://github.com/sy2002/QNICE-FPGA) for
FAT32 support (loading ROMs, mounting disks) and for the
on-screen-menu.

How to install the Galaga core on your MEGA65
---------------------------------------------

1. **Download ROM**: Download the Galaga ROM ZIP file (do not unzip!) from
  [this link](https://wowroms.com/en/roms/mame-0.139u1/galaga-midway-set-1/3707.html)
  or search the web for "mame galaga midway set 1".

2. **Download the Python script**: Download the provided Python script that
   prepares the ROMs such that the Galaga core is able to use it from
   [Link](https://raw.githubusercontent.com/sho3string/GalagaMEGA65/master/galaga_rom_installer.py).

3. **Run the Python script**: Execute the Python script to create a folder
   with the ROMs. 
   Use the command `python galaga_rom_installer.py <path to the zip file> <output_folder>`.

4. **Copy the ROMs to your MEGA65 SD card**: Copy the generated folder with
   the ROMs to your MEGA65 SD card. You can use either the bottom SD card tray
   of the MEGA65 or the tray at the backside of the computer (the latter has
   precedence over the first).
   The ROMs need to be in the folder `arcade/galaga`.

5. **Download and run the Galaga core**: Follow the instructions on
  [this site](https://sy2002.github.io/m65cores/) to download and run the
  Galaga core on your MEGA65.
