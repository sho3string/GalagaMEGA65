; ****************************************************************************
; MiSTer2MEGA65 (M2M) QNICE ROM
;
; Hardcoded Shell strings that cannot be changed by config.vhd
;
; done by sy2002 in 2022 and licensed under GPL v3
; ****************************************************************************

NEWLINE         .ASCII_W "\n"
SPACE           .ASCII_W " "

; The following line is the maximum string length on a PAL output:
; **********************************************

; ----------------------------------------------------------------------------
; File browser
; ----------------------------------------------------------------------------

FN_ROOT_DIR     .ASCII_W "/"
FN_UPDIR        .ASCII_W ".."
FN_ELLIPSIS     .ASCII_W "..." ; caution: hardcoded to a len. of 3

; ----------------------------------------------------------------------------
; Debug Mode and log messages for the serial terminal
; (Hold "Run/Stop" + "Cursor Up" and then while holding these, press "Help")
; ----------------------------------------------------------------------------

DBG_START1      .ASCII_P "\nEntering MiSTer2MEGA65 debug mode.\nPress H for "
                .ASCII_W "help and press C R "
#ifdef RELEASE
DBG_START2      .ASCII_P " to return to where you left off\n"
                .ASCII_W "and press C R "
DBG_START3
#else
DBG_START2
#endif
                .ASCII_W " to restart the Shell.\n"

LOG_M2M         .ASCII_P "                                                 \n"
                .ASCII_P "MiSTer2MEGA65 Firmware and Shell, "
                .ASCII_P "done by sy2002 & MJoergen in 2022\n"
                .ASCII_P "https://github.com/sy2002/MiSTer2MEGA65\n\n"
                .ASCII_P "Press 'Run/Stop' + 'Cursor Up' and then while "
                .ASCII_P "holding these press 'Help' to enter the debug "
                .ASCII_W "mode.\n\n"
LOG_STR_SD      .ASCII_W "SD card has been changed. Re-reading...\n"
LOG_STR_CD      .ASCII_W "Changing directory to: "
LOG_STR_ITM_AMT .ASCII_W "Items in current directory (in hex): "
LOG_STR_FILE    .ASCII_W "Selected file: "
LOG_STR_LOADOK  .ASCII_W "Successfully loaded disk image to buffer RAM.\n"
LOG_STR_MOUNT   .ASCII_W "Mounted disk image for drive #"
LOG_STR_CONFIG  .ASCII_W "Configuration: Remember settings: "
LOG_STR_CFG_ON  .ASCII_W "ON  "
LOG_STR_CFG_OFF .ASCII_W "OFF  " 
LOG_STR_CFG_E1  .ASCII_W "Unable to mount SD card.  "
LOG_STR_CFG_E2  .ASCII_W "Config file not found: "
LOG_STR_CFG_E3  .ASCII_W "New config file found: "
LOG_STR_CFG_E4  .ASCII_W "Corrupt config file: "
LOG_STR_CFG_SP  .ASCII_W "  "
LOG_STR_CFG_FOK .ASCII_W "Using config file: "
LOG_STR_CFG_STD .ASCII_W "Using factory defaults.\n"
LOG_STR_CFG_SDC .ASCII_P "Configuration: Remember settings: OFF  "
                .ASCII_W "Reason: SD card changed.\n"
LOG_STR_CFG_REM .ASCII_P "Configuration: New settings successfully stored to "
                .ASCII_W "SD card.\n"

; ----------------------------------------------------------------------------
; Infos
; ----------------------------------------------------------------------------

STR_INITWAIT    .ASCII_W "Initializing. Please wait..."

; ----------------------------------------------------------------------------
; Warnings
; ----------------------------------------------------------------------------

WRN_MAXFILES    .ASCII_P "Warning: This directory contains more files\n"
                .ASCII_P "than this core is able to load into memory.\n\n"
                .ASCII_P "Split the files into multiple folders.\n\n"
                .ASCII_P "If you continue by pressing SPACE,\n"
                .ASCII_P "be aware that random files will be missing.\n\n"
                .ASCII_W "Press SPACE to continue.\n"

WRN_EMPTY_BRW   .ASCII_P "The root directory of the SD card contains\n"
                .ASCII_P "no sub-directories that might contain any\n"
                .ASCII_P "files that match the criteria of this core.\n\n"
                .ASCII_P "And the root directory itself also does not\n"
                .ASCII_P "contain any files that match the criteria\n"
                .ASCII_P "of this core.\n\n"
                .ASCII_P "Nothing to browse.\n\n"
                .ASCII_W "Press Space to continue."

WRN_ERROR_CODE  .ASCII_W "Error code: "

; ----------------------------------------------------------------------------
; Error Messages
; ----------------------------------------------------------------------------

ERR_FATAL       .ASCII_W "\nFATAL ERROR:\n\n"
ERR_CODE        .ASCII_W "Error code: "
ERR_FATAL_STOP  .ASCII_W "\nCore stopped. Please reset the machine.\n"

ERR_F_MENUSIZE  .ASCII_P "config.vhd: Illegal menu size (OPTM_SIZE):\n"
                .ASCII_W "Must be between 1 and 254\n"
ERR_F_MENUSTART .ASCII_P "config.vhd: No start menu item tag\n"
                .ASCII_W "(OPTM_G_START) found in OPTM_GROUPS\n"

ERR_MOUNT       .ASCII_W "Error: Cannot mount SD card!\nError code: "
ERR_MOUNT_RET   .ASCII_W "\n\nPress Return to retry"
ERR_BROWSE_UNKN .ASCII_W "SD Card:\nUnknown error while trying to browse.\n"
ERR_FATAL_ITER  .ASCII_W "Corrupt memory structure:\nLinked-list boundary\n"
ERR_FATAL_FNF   .ASCII_W "File selected in the browser not found.\n"
ERR_FATAL_LOAD  .ASCII_W "SD Card:\nUnkown error while loading disk image\n"
ERR_FATAL_HEAP1 .ASCII_W "Heap corruption: Hint: MENU_HEAP_SIZE\n"
ERR_FATAL_HEAP2 .ASCII_W "Heap corruption: Hint: OPTM_HEAP_SIZE\n"
ERR_FATAL_BSTCK .ASCII_W "Stack overflow: Hint: B_STACK_SIZE\n"
ERR_FATAL_VDMAX .ASCII_W "Too many virtual drives: Hint: VDRIVES_MAX\n"
ERR_FATAL_VDBUF .ASCII_W "Not enough buffers for virtual drives.\n"
ERR_FATAL_FZERO .ASCII_W "Write disk: File handle is zero.\n"
ERR_FATAL_SEEK  .ASCII_W "Write disk: Seek failed.\n"
ERR_FATAL_WRITE .ASCII_W "Write disk: Writing failed.\n"
ERR_FATAL_FLUSH .ASCII_W "Write disk:\nFlushing of SD card buffer failed.\n"
ERR_FATAL_ROSMS .ASCII_W "Settings file: Seek failed.\n"
ERR_FATAL_ROSMR .ASCII_W "Settings file: Reading failed.\n"
ERR_FATAL_ROSMW .ASCII_W "Settings file: Writing failed.\n"
ERR_FATAL_ROSMF .ASCII_P "Settings file:\n"
                .ASCII_W "Flushing of SD card buffer failed.\n"
ERR_FATAL_ROSMC .ASCII_W "Settings file:\nCorrupt: Illegal config value.\n"

ERR_FATAL_INST  .ASCII_W "Instable system state.\n"

; Error codes for ERR_FATAL_INST: They will help to debug the situation,
; because we will at least know, where the instable system state occured
ERR_FATAL_INST1 .EQU 1 ; options.asm:   _OPTM_CBS_REPL
ERR_FATAL_INST2 .EQU 2 ; shell.asm:     _HM_MOUNTED
ERR_FATAL_INST3 .EQU 3 ; shell.asm:     _HM_SDMOUNTED2A
ERR_FATAL_INST4 .EQU 4 ; options.asm:   _OPTM_GK_MNT

