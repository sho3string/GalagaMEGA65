; ****************************************************************************
; MiSTer2MEGA65 (M2M) QNICE ROM
;
; Variables for shell.asm and its direct includes:
; options.asm
;
; done by sy2002 in 2022 and licensed under GPL v3
; ****************************************************************************


#include "dirbrowse_vars.asm"
#include "keyboard_vars.asm"
#include "screen_vars.asm"

#include "menu_vars.asm"

; reset handling
WELCOME_SHOWN   .BLOCK 1                        ; we need to trust that this
                                                ; is 0 on system coldstart

; option menu
OPTM_ICOUNT     .BLOCK 1                        ; amount of menu items
OPTM_START      .BLOCK 1                        ; initially selected menu item
OPTM_SELECTED   .BLOCK 1                        ; last options menu selection
OPTM_MNT_STATUS .BLOCK 1                        ; drive mount status; all drvs
OPTM_DTY_STATUS .BLOCK 1                        ; cache dirty status; all drvs

; OPTM_HEAP is used by the option menu to save the modified filenames of
; disk images used by mounted drives: Filenames need to be abbreviated by
; "..." if they are too long. See also HELP_MENU and HANDLE_MOUNTING.
;
; OPTM_HEAP_LAST points to a scratch buffer that can hold a modified filename
; for saving/restoring while the cache dirty "Saving" message is shown.
; See also OPTM_CB_SHOW. 
OPTM_HEAP       .BLOCK 1
OPTM_HEAP_LAST  .BLOCK 1
OPTM_HEAP_SIZE  .BLOCK 1                        ; size of this scratch buffer

SCRATCH_HEX     .BLOCK 5

; SD card device handle and array of pointers to file handles for disk images
HANDLE_DEV      .BLOCK  FAT32$DEV_STRUCT_SIZE

; Important: Make sure you have as many ".BLOCK FAT32$FDH_STRUCT_SIZE"
; statements listed one after another as the .EQU VDRIVES_MAX (below) demands
; and make sure that the HANDLES_FILES array in shell.asm points 
; to all of them, i.e. you need to edit shell.asm
HANDLE_FILE1    .BLOCK  FAT32$FDH_STRUCT_SIZE
HANDLE_FILE2    .BLOCK  FAT32$FDH_STRUCT_SIZE
HANDLE_FILE3    .BLOCK  FAT32$FDH_STRUCT_SIZE

; Remember configuration handling:
; * We are using a separate device handle because some logic around SD card
;   switching in shell.asm is tied to the status of HANDLE_DEV.
; * File-handle for config file (saving/loading OSM settings) is valid (i.e.
;   not null) when SAVE_SETTINGS (config.vhd) is true and when the file
;   specified by CFG_FILE (config.vhd) exists and has exactly the size of
;   OPTM_SIZE (config.vhd). The convention "checking CONFIG_FILE for not null"
;   can be used as a trigger for various actions in the shell.
; * OLD_SETTINGS is used to determine changes in the 256-bit (16-word)
;   M2M$CFM_DATA register so that we can implement a smart saving mechanism:
;   When pressing "Help" to close the on-screen-menu, we only save the
;   settings to the SD card when the settings changed.
; * Initially (upon core start time) active SD card: Used for protecting the
;   data integrity: see comment for ROSM_INTEGRITY in options.asm
CONFIG_DEVH     .BLOCK  FAT32$DEV_STRUCT_SIZE
CONFIG_FILE     .BLOCK  FAT32$FDH_STRUCT_SIZE
OLD_SETTINGS    .BLOCK  16
INITIAL_SD      .BLOCK  1

SD_ACTIVE       .BLOCK 1                        ; currently active SD card
SD_CHANGED      .BLOCK 1                        ; SD card (briefly) changed?

; SD card "stability" workaround
SD_WAIT         .EQU   0x05F6                   ; 2 seconds @ 50 MHz
SD_CYC_MID      .BLOCK 1                        ; cycle counter for SD card..
SD_CYC_HI       .BLOCK 1                        ; .."stability workaround"
SD_WAIT_DONE    .BLOCK 1                        ; initial waiting done

; file browser persistent status
FB_HEAP         .BLOCK 1                        ; heap used by file browser
FB_STACK        .BLOCK 1                        ; local stack used by  browser
FB_STACK_INIT   .BLOCK 1                        ; initial local browser stack
FB_MAINSTACK    .BLOCK 1                        ; stack of main program
FB_HEAD         .BLOCK 1                        ; lnkd list: curr. disp. head

; context variables (see CTX_* constants in sysdef.asm)
SF_CONTEXT      .BLOCK 1                        ; context for SELECT_FILE

; Virtual drive system (aka mounting disk/module/tape images):
; VDRIVES_NUM:      Amount of virtual, mountable drives; needs to correlate
;                   with the actual hardware in vdrives.vhd and the menu items
;                   tagged with OPTM_G_MOUNT_DRV in config.vhd
;                   VDRIVES_MAX must be equal or larger than the value stored
;                   in this variable
;                   Variable is initialized in VD_INIT in vdrives.asm
;
; VDRIVES_MAX:      Maximum amount of supported virtual drives.
;                   VD_INIT expects an .EQU and also the assembler does not
;                   allow this value to be a variable. Do not forget to
;                   adjust the file handles (see above) accordingly.
;                   Try to keep small for RAM preservation reasons.
;
; VDRIVES_DEVICE:   Device ID of the IEC bridge in vdrives.vhd
;
; VDRIVES_BUFS:     Array of device IDs of size VDRIVES_NUM that contains the
;                   RAM buffer-devices that will hold the mounted drives
;
; VDRIVES_FLUSH_*:  Array of high/low words of the amount of bytes that still
;                   need to be flushed to ensure that the cache is written
;                   completely to the SD card
;
; VDRIVES_ITERSIZ   Array of amount of bytes stored in one iteration of the
;                   background saving (buffer flushing) process
;
; VDRIVES_FL_*:     Array of current 4k window and offset within window of the
;                   disk image buffer in RAM
VDRIVES_NUM     .BLOCK  1
VDRIVES_MAX     .EQU    3
VDRIVES_DEVICE  .BLOCK  1
VDRIVES_BUFS    .BLOCK  VDRIVES_MAX
VDRIVES_FLUSH_H .BLOCK  VDRIVES_MAX
VDRIVES_FLUSH_L .BLOCK  VDRIVES_MAX
VDRIVES_ITERSIZ .BLOCK  VDRIVES_MAX
VDRIVES_FL_4K   .BLOCK  VDRIVES_MAX
VDRIVES_FL_OFS  .BLOCK  VDRIVES_MAX
