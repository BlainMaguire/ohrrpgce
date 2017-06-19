'OHRRPGCE CUSTOM - Main module
'(C) Copyright 1997-2005 James Paige and Hamster Republic Productions
'Please read LICENSE.txt for GPL License details and disclaimer of liability
'See README.txt for code docs and apologies for crappyness of this code ;)
'
#include "config.bi"
#include "datetime.bi"  'for date serials
#include "string.bi"  'for date serials
#include "ver.txt"
#include "udts.bi"
#include "const.bi"
#include "allmodex.bi"
#include "matrixMath.bi"
#include "common.bi"
#include "loading.bi"
#include "customsubs.bi"
#include "flexmenu.bi"
#include "slices.bi"
#include "cglobals.bi"
#include "uiconst.bi"
#include "scrconst.bi"
#include "sliceedit.bi"
#include "reloadedit.bi"
#include "editedit.bi"
#include "os.bi"
#include "distribmenu.bi"
#include "custom.bi"


'''' Local function and type declarations

' Stores information about a previous or ongoing Custom editing session
TYPE SessionInfo
 workingdir as string              'The directory containing this session's files
 partial_rpg as bool               '__danger.tmp exists: is unlumping or deleting lumps
 info_file_exists as bool          'session_info.txt.tmp exists. If not, everything in this UDT below this point is unknown.
 pid as integer                    'Process ID or 0
 running as bool                   'That process is still running
 sourcerpg as string               'May be blank
 'The following are represented as native FB DateSerials, not Unix mtimes. 0.0 means N/A
 sourcerpg_old_mtime as double     'mtime of the sourcerpg when was opened/last saved by that copy of Custom
 sourcerpg_current_mtime as double 'mtime of the sourcerpg right now, as seen by us
 session_start_time as double      'When the game was last unlumped/saved (or if none, when Custom was launched)
 last_lump_mtime as double         'mtime of the most recently modified lump
END TYPE

DECLARE FUNCTION newRPGfile (templatefile as string, newrpg as string) as bool
DECLARE SUB setup_workingdir ()
DECLARE SUB check_for_crashed_workingdirs ()
DECLARE FUNCTION empty_workingdir (workdir as string) as bool
DECLARE FUNCTION handle_dirty_workingdir (sessinfo as SessionInfo) as bool
DECLARE FUNCTION check_ok_to_open (filename as string) as bool
DECLARE FUNCTION get_previous_session_info (workdir as string) as SessionInfo

DECLARE SUB secret_menu ()
DECLARE SUB condition_test_menu ()
DECLARE SUB quad_transforms_menu ()
DECLARE SUB arbitrary_sprite_editor ()
DECLARE SUB text_test_menu ()
DECLARE SUB font_test_menu ()
DECLARE SUB new_graphics_tests ()

DECLARE SUB shop_editor ()
DECLARE SUB shop_stuff_edit (byval shop_id as integer, byref thing_last_id as integer)
DECLARE SUB shop_save_stf (byval shop_id as integer, byref stuf as ShopStuffState, stufbuf() as integer)
DECLARE SUB shop_load_stf (byval shop_id as integer, byref stuf as ShopStuffState, stufbuf() as integer)
DECLARE SUB shop_swap_stf (shop_id as integer, thing_id1 as integer, thing_id2 as integer)
DECLARE SUB update_shop_stuff_menu (byref stuf as ShopStuffState, stufbuf() as integer, byval thing_last_id as integer)
DECLARE SUB update_shop_stuff_type(byref stuf as ShopStuffState, stufbuf() as integer, byval reset_name_and_price as integer=NO)
DECLARE SUB shop_menu_update(byref shopst as ShopEditState, shopbuf() as integer)
DECLARE SUB shop_save (byref shopst as ShopEditState, shopbuf() as integer)
DECLARE SUB shop_load (byref shopst as ShopEditState, shopbuf() as integer)
DECLARE SUB shop_add_new (shopst as ShopEditState)

DECLARE SUB cleanup_and_terminate (show_quit_msg as bool = YES)
DECLARE SUB import_scripts_and_terminate (scriptfile as string)

DECLARE SUB prompt_for_password()
DECLARE SUB prompt_for_save_and_quit()
DECLARE SUB choose_rpg_to_open (rpg_browse_default as string)
DECLARE SUB main_editor_menu()
DECLARE SUB gfx_editor_menu()


'=================================== Globals ==================================

REDIM gen(499)
DIM gen_reld_doc as DocPtr
REDIM buffer(16384)
REDIM master(255) as RGBcolor
REDIM uilook(uiColorLast) as integer
REDIM boxlook(uiBoxLast) as BoxStyle
DIM statnames() as string
REDIM herotags(maxMaxHero) as HeroTagsCache
REDIM itemtags(maxMaxItems) as ItemTagsCache
DIM joy(4) as integer
DIM vpage as integer = 0
DIM dpage as integer = 1
DIM activepalette as integer = -1
DIM fadestate as bool
DIM auto_distrib as string

DIM editing_a_game as bool
DIM game as string
DIM sourcerpg as string
DIM exename as string
DIM documents_dir as string
DIM workingdir as string
DIM app_dir as string

DIM slave_channel as IPCChannel = NULL_CHANNEL
DIM slave_process as ProcessHandle = 0

EXTERN running_as_slave as integer
DIM running_as_slave as integer = NO  'This is just for the benefit of gfx_sdl

'Should we delete workingdir when quitting normally?
'False if relumping workingdir failed.
DIM cleanup_workingdir_on_exit as bool = YES

'Affects show/fatalerror: have we started editing (ie. finished upgrades and other startup)?
'If not, we should cleanup working.tmp instead of preserving it
DIM cleanup_workingdir_on_error as bool = YES


'======================== Setup directories & debug log =======================
' This is almost identical to startup code in Game; please don't unnecessarily diverge.

'Note: On Android exename is "sdl" and exepath is "" (currently unimplemented in FB and meaningless for an app anyway)

orig_dir = CURDIR
'Note: debug log messages go in CURDIR until log_dir set below

app_dir = EXEPATH  'FreeBasic builtin

#IFDEF __FB_DARWIN__
 'Bundled apps have starting current directory equal to the location of the bundle, but exepath points inside
 IF RIGHT(exepath, 19) = ".app/Contents/MacOS" THEN
  app_resources_dir = parentdir(exepath, 1) + "Resources"
  app_dir = parentdir(exepath, 3)
 END IF
 'FIXME: why are we changing app_dir??
 IF app_dir = "/Applications/" THEN
  'Equal to documents_dir (not set yet)
  app_dir = ENVIRON("HOME") & SLASH & "Documents"
  CHDIR app_dir
 END IF
#ENDIF

'temporarily set current directory, will be changed to game directory later if writable
'(This is where new .rpg files go by default)
'(This change in working directory is done only by Custom, not Game)
IF diriswriteable(app_dir) THEN
 'When CUSTOM is installed read-write, work in CUSTOM's folder
 CHDIR app_dir
ELSE
 'If CUSTOM is installed read-only, use your Documents dir as the default
 CHDIR get_documents_dir()
END IF

#IFDEF __FB_ANDROID__
 'Prevent log_dir from being changed to the .rpg directory
 '(But why? If it's on external storage, that seems like great place to put it)
 log_dir = orig_dir & SLASH
 overrode_log_dir = YES
#ELSE
 log_dir = CURDIR & SLASH
#ENDIF

'Once log_dir is set, can create debug log.
start_new_debug "Starting OHRRPGCE Custom"
debuginfo DATE & " " & TIME
debuginfo long_version & build_info
debuginfo "exepath: " & EXEPATH & ", exe: " & COMMAND(0)
' Load these three strings with info collectable before backend initialisation
read_backend_info()
debuginfo "Runtime info: " & gfxbackendinfo & "  " & musicbackendinfo & "  " & systeminfo

settings_dir = get_settings_dir()
documents_dir = get_documents_dir()  'may depend on app_dir
debuginfo "documents_dir: " & documents_dir
'FIXME: why do we use different temp dirs in game and custom?
'Plus, tmpdir is shared between all running copies of Custom, which could cause problems.
tmpdir = settings_dir & SLASH
IF NOT isdir(tmpdir) THEN fatalerror "Unable to create temp directory " & tmpdir



'========================== Process commandline flags =========================

exename = trimextension(trimpath(COMMAND(0)))

REDIM cmdline_args() as string
' This can modify log_dir and restart the debug log
processcommandline cmdline_args(), @gamecustom_setoption, orig_dir & SLASH & "ohrrpgce_arguments.txt"


'======================= Initialise backends/graphics =========================

load_default_master_palette master()
DefaultUIColors uilook(), boxlook()
REDIM current_font(1023) as integer
getdefaultfont current_font()

setmodex
debuginfo musicbackendinfo  'Preliminary info before initialising backend
setwindowtitle "O.H.R.RPG.C.E"
unlock_resolution 320, 200   'Minimum window size
setpal master()
setfont current_font()
textcolor uilook(uiText), 0

setupmusic

'seed the random number generator
mersenne_twister TIMER

'Cleanups/recovers any working.tmp for any crashed copies of Custom; requires graphics up and running
check_for_crashed_workingdirs

'This also calls write_session_info
setup_workingdir


'=============================== Select a game ================================

DIM scriptfile as string
DIM rpg_browse_default as string

FOR i as integer = 0 TO UBOUND(cmdline_args)
 DIM arg as string
 arg = absolute_with_orig_path(cmdline_args(i))
 DIM extn as string = LCASE(justextension(arg))

 IF (extn = "hs" OR extn = "hss" OR extn = "txt") AND isfile(arg) THEN
  scriptfile = arg
  CONTINUE FOR
 ELSEIF extn = "rpg" AND isfile(arg) THEN
  sourcerpg = arg
  game = trimextension(trimpath(sourcerpg))
 ELSEIF isdir(arg) THEN
  IF isfile(arg + SLASH + "archinym.lmp") THEN 'ok, accept it
   sourcerpg = trim_trailing_slashes(arg)
   game = trimextension(trimpath(sourcerpg))
  ELSE
   rpg_browse_default = arg
  END IF
 ELSE
  visible_debug !"File not found/invalid option:\n" & cmdline_args(i)
 END IF
NEXT
IF game = "" THEN
 scriptfile = ""
 choose_rpg_to_open(rpg_browse_default)
END IF

IF NOT is_absolute_path(sourcerpg) THEN sourcerpg = absolute_path(sourcerpg)

IF check_ok_to_open(sourcerpg) = NO THEN
 cleanup_and_terminate NO
END IF

write_session_info

DIM dir_to_change_into as string = trimfilename(sourcerpg)

end_debug
IF dir_to_change_into <> "" ANDALSO diriswriteable(dir_to_change_into) THEN
 CHDIR dir_to_change_into
 IF overrode_log_dir = NO THEN log_dir = dir_to_change_into & SLASH
END IF
'otherwise, keep current directory as it was (FIXME: ideally would now be the same as in Game)
'Final log_dir set, no more need to remember.
remember_debug_messages = NO

start_new_debug "Loading a game"
debuginfo DATE & " " & TIME
debuginfo "curdir: " & CURDIR
debuginfo "tmpdir: " & tmpdir
debuginfo "settings_dir: " & settings_dir


'============================= Unlump, Upgrade, Load ==========================

'For getdisplayname
copylump sourcerpg, "archinym.lmp", workingdir, YES

debuginfo "Editing game " & sourcerpg & " (" & getdisplayname(" ") & ")"
setwindowtitle "O.H.R.RPG.C.E - " + trimpath(sourcerpg)

'--set game according to the archinym
copylump sourcerpg, "archinym.lmp", workingdir, YES
DIM archinym as string
archinym = readarchinym(workingdir, sourcerpg)
game = workingdir + SLASH + archinym

copylump sourcerpg, archinym + ".gen", workingdir
xbload game + ".gen", gen(), "general data is missing: RPG file appears to be corrupt"

IF gen(genVersion) > CURRENT_RPG_VERSION THEN
 debug "genVersion = " & gen(genVersion)
 future_rpg_warning
END IF

prompt_for_password

clearpage vpage
textcolor uilook(uiText), 0
printstr "UNLUMPING DATA: please wait.", 0, 0, vpage
setvispage vpage, NO

touchfile workingdir + SLASH + "__danger.tmp"
IF isdir(sourcerpg) THEN
 'work on an unlumped RPG file. Don't take hidden files
 copyfiles sourcerpg, workingdir
ELSE
 unlump sourcerpg, workingdir + SLASH
END IF
safekill workingdir + SLASH + "__danger.tmp"

'Perform additional checks for future rpg files or corruption
rpg_sanity_checks

'upgrade obsolete RPG files
upgrade YES

set_music_volume 0.01 * gen(genMusicVolume)
set_global_sfx_volume 0.01 * gen(genSFXVolume)

'Unload any default graphics (from data/defaultgfx) that might have been cached
sprite_empty_cache
palette16_empty_cache

'Load the game's palette, uicolors, font
activepalette = gen(genMasterPal)
loadpalette master(), activepalette
setpal master()
LoadUIColors uilook(), boxlook(), activepalette
clearpage dpage
clearpage vpage
xbload game + ".fnt", current_font(), "Font not loaded"
setfont current_font()

loadglobalstrings
getstatnames statnames()
load_special_tag_caches
load_script_triggers_and_names

IF scriptfile <> "" THEN import_scripts_and_terminate scriptfile

IF auto_distrib <> "" THEN
 auto_export_distribs auto_distrib
 cleanup_workingdir_on_exit = YES
 cleanup_and_terminate NO
END IF

'Reset start of session to after upgrades (to see which lumps are edited)
write_session_info

'From here on, preserve working.tmp if something goes wrong
cleanup_workingdir_on_error = NO

'debuginfo "mem usage " & memory_usage_string()

editing_a_game = YES
main_editor_menu
'Execution ends inside main_editor_menu

'=======================================================================

SUB main_editor_menu()
 DIM menu(21) as string
 DIM menu_display(UBOUND(menu)) as string
 
 menu(0) = "Edit Graphics"
 menu(1) = "Edit Map Data"
 menu(2) = "Edit Global Text Strings"
 menu(3) = "Edit Heroes"
 menu(4) = "Edit Enemies"
 menu(5) = "Edit Attacks"
 menu(6) = "Edit Items"
 menu(7) = "Edit Shops"
 menu(8) = "Edit Battle Formations"
 menu(9) = "Edit Text Boxes"
 menu(10) = "Edit Menus"
 menu(11) = "Edit Vehicles"
 menu(12) = "Edit Tag Names"
 menu(13) = "Import Music"
 menu(14) = "Import Sound Effects"
 menu(15) = "Edit Font"
 menu(16) = "Edit General Game Data"
 menu(17) = "Script Management"
 menu(18) = "Edit Slice Collections"
 menu(19) = "Distribute Game"
 menu(20) = "Test Game"
 menu(21) = "Quit Editing"
 
 DIM selectst as SelectTypeState
 DIM state as MenuState
 state.last = UBOUND(menu)
 state.autosize = YES
 state.autosize_ignore_pixels = 24
 DIM menuopts as MenuOptions
 menuopts.scrollbar = YES
 
 setkeys YES
 DO
  setwait 55
  setkeys YES

  usemenu state
  IF keyval(scEsc) > 1 THEN
   prompt_for_save_and_quit
  END IF
  IF keyval(scF1) > 1 THEN
   show_help "main"
  END IF

  IF keyval(scF5) > 1 THEN   'Redundant, but for people with muscle memory
   reimport_previous_scripts
  END IF

  IF select_by_typing(selectst) THEN
   IF RIGHT(selectst.buffer, 4) = "spam" THEN
    select_clear selectst
    secret_menu
   ELSE
    select_on_word_boundary_excluding menu(), selectst, state, "edit"
   END IF
  END IF

  IF enter_space_click(state) THEN
   IF state.pt = 0 THEN gfx_editor_menu
   IF state.pt = 1 THEN map_picker
   IF state.pt = 2 THEN edit_global_text_strings
   IF state.pt = 3 THEN hero_editor
   IF state.pt = 4 THEN enemy_editor
   IF state.pt = 5 THEN attack_editor
   IF state.pt = 6 THEN item_editor
   IF state.pt = 7 THEN shop_editor
   IF state.pt = 8 THEN formation_editor
   IF state.pt = 9 THEN text_box_editor
   IF state.pt = 10 THEN menu_editor
   IF state.pt = 11 THEN vehicles
   IF state.pt = 12 THEN tags_menu
   IF state.pt = 13 THEN importsong
   IF state.pt = 14 THEN importsfx
   IF state.pt = 15 THEN fontedit current_font()
   IF state.pt = 16 THEN general_data_editor
   IF state.pt = 17 THEN scriptman
   IF state.pt = 18 THEN slice_editor
   IF state.pt = 19 THEN distribute_game
   IF state.pt = 20 THEN spawn_game_menu(keyval(scShift) > 0)
   IF state.pt = 21 THEN prompt_for_save_and_quit
   '--always resave the .GEN lump after any menu
   xbsave game + ".gen", gen(), 1000
  END IF
 
  clearpage dpage
  highlight_menu_typing_selection menu(), menu_display(), selectst, state
  standardmenu menu_display(), state, 0, 0, dpage, menuopts

  textcolor uilook(uiSelectedDisabled), 0
  DIM footer_y as integer = vpages(dpage)->h - 24
  printstr version_code, 0, footer_y, dpage
  printstr version_build, 0, footer_y + 8, dpage
  textcolor uilook(uiText), 0
  printstr "Press F1 for help on any menu!", 0, footer_y + 16, dpage
 
  SWAP vpage, dpage
  setvispage vpage
  dowait
 LOOP
END SUB

SUB gfx_editor_menu()
 DIM menu(14) as string
 DIM menu_display(UBOUND(menu)) as string

 menu(0) = "Back to the main menu"
 menu(1) = "Edit Maptiles"
 menu(2) = "Draw Walkabout Graphics"
 menu(3) = "Draw Hero Graphics"
 menu(4) = "Draw Small Enemy Graphics  34x34"
 menu(5) = "Draw Medium Enemy Graphics 50x50"
 menu(6) = "Draw Big Enemy Graphics    80x80"
 menu(7) = "Draw Attacks"
 menu(8) = "Draw Weapons"
 menu(9) = "Draw Box Edges"
 menu(10) = "Draw Portrait Graphics"
 menu(11) = "Import/Export Screens"
 menu(12) = "Import/Export Full Maptile Sets"
 menu(13) = "Change User-Interface Colors"
 menu(14) = "Change Box Styles"

 DIM selectst as SelectTypeState
 DIM state as MenuState
 state.size = 24
 state.last = UBOUND(menu)

 DIM walkabout_frame_captions(7) as string = {"Up A","Up B","Right A","Right B","Down A","Down B","Left A","Left B"}
 DIM hero_frame_captions(7) as string = {"Standing","Stepping","Attack A","Attack B","Cast/Use","Hurt","Weak","Dead"}
 DIM enemy_frame_captions(0) as string = {"Enemy (facing right)"}
 DIM weapon_frame_captions(1) as string = {"Frame 1","Frame 2"}
 DIM attack_frame_captions(2) as string = {"First Frame","Middle Frame","Last Frame"}
 DIM box_border_captions(15) as string = {"Top Left Corner","Top Edge Left","Top Edge","Top Edge Right","Top Right Corner","Left Edge Top","Right Edge Top","Left Edge","Right Edge","Left Edge Bottom","Right Edge Bottom","Bottom Left Corner","Bottom Edge Left","Bottom Edge","Bottom Edge Right","Bottom Right Corner"}
 DIM portrait_captions(0) as string = {"Character Portrait"}

 setkeys YES
 DO
  setwait 55
  setkeys YES
  IF keyval(scEsc) > 1 THEN
   EXIT DO
  END IF
  IF keyval(scF1) > 1 THEN
   show_help "gfxmain"
  END IF
  usemenu state

  IF select_by_typing(selectst) THEN
   select_on_word_boundary menu(), selectst, state
  END IF

  IF enter_space_click(state) THEN
   IF state.pt = 0 THEN
    EXIT DO
   END IF
   IF state.pt = 1 THEN maptile
   IF state.pt = 2 THEN spriteset_editor 20, 20, gen(genMaxNPCPic),    8, walkabout_frame_captions(), 4
   IF state.pt = 3 THEN spriteset_editor 32, 40, gen(genMaxHeroPic),   8, hero_frame_captions(), 0
   IF state.pt = 4 THEN spriteset_editor 34, 34, gen(genMaxEnemy1Pic), 1, enemy_frame_captions(), 1
   IF state.pt = 5 THEN spriteset_editor 50, 50, gen(genMaxEnemy2Pic), 1, enemy_frame_captions(), 2
   IF state.pt = 6 THEN spriteset_editor 80, 80, gen(genMaxEnemy3Pic), 1, enemy_frame_captions(), 3
   IF state.pt = 7 THEN spriteset_editor 50, 50, gen(genMaxAttackPic), 3, attack_frame_captions(), 6
   IF state.pt = 8 THEN spriteset_editor 24, 24, gen(genMaxWeaponPic), 2, weapon_frame_captions(), 5
   IF state.pt = 9 THEN spriteset_editor 16, 16, gen(genMaxBoxBorder), 16, box_border_captions(), 7
   IF state.pt = 10 THEN spriteset_editor 50, 50, gen(genMaxPortrait), 1, portrait_captions(), 8
   IF state.pt = 11 THEN importbmp ".mxs", "screen", gen(genNumBackdrops), sprTypeBackdrop
   IF state.pt = 12 THEN
    gen(genMaxTile) = gen(genMaxTile) + 1
    importbmp ".til", "tileset", gen(genMaxTile), sprTypeTileset
    gen(genMaxTile) = gen(genMaxTile) - 1
   END IF
   IF state.pt = 13 THEN ui_color_editor(activepalette)
   IF state.pt = 14 THEN ui_boxstyle_editor(activepalette)
   '--always resave the .GEN lump after any menu
   xbsave game + ".gen", gen(), 1000
  END IF
 
  clearpage dpage
  highlight_menu_typing_selection menu(), menu_display(), selectst, state
  standardmenu menu_display(), state, 0, 0, dpage
 
  SWAP vpage, dpage
  setvispage vpage
  dowait
 LOOP

END SUB

SUB choose_rpg_to_open (rpg_browse_default as string)
 'This sub sets the globals: game and sourcerpg

 DIM state as MenuState
 state.pt = 1
 state.last = 2
 state.size = 20

 'DIM logo as Frame ptr = frame_import_bmp_as_8bit(finddatafile("logo50%.bmp"), master())
 DIM root as Slice ptr
 root = NewSliceOfType(slContainer)
 SliceLoadFromFile root, finddatafile("choose_rpg.slice")
 DIM menusl as Slice ptr = LookupSlice(-100, root)  'Editor lookup codes not implemented yet
 IF menusl = 0 THEN menusl = NewSliceOfType(slContainer, root)
 
 DIM chooserpg_menu(2) as string
 chooserpg_menu(0) = "CREATE NEW GAME"
 chooserpg_menu(1) = "LOAD EXISTING GAME"
 chooserpg_menu(2) = "EXIT PROGRAM"
 DIM opts as MenuOptions
 opts.edged = YES

 setkeys
 DO
  setwait 55
  setkeys
  IF keyval(scEsc) > 1 THEN cleanup_and_terminate
  IF keyval(scF1) > 1 THEN show_help "choose_rpg"

  usemenu state
  IF enter_space_click(state) THEN
   SELECT CASE state.pt
    CASE 0
     game = inputfilename("Filename of New Game?", ".rpg", rpg_browse_default, "input_file_new_game", , NO)
     IF game <> "" THEN
       IF NOT newRPGfile(finddatafile("ohrrpgce.new"), game & ".rpg") THEN cleanup_and_terminate
       sourcerpg = game & ".rpg"
       game = trimpath(game)
       EXIT DO
     END IF
    CASE 1
     sourcerpg = browse(7, rpg_browse_default, "*.rpg", "custom_browse_rpg")
     game = trimextension(trimpath(sourcerpg))
     IF game <> "" THEN EXIT DO
    CASE 2
     cleanup_and_terminate
   END SELECT
  END IF
 
  clearpage dpage
  DrawSlice root, dpage
  'frame_draw logo, , pCentered, 20, , , dpage
  standardmenu chooserpg_menu(), state, menusl->ScreenX, menusl->ScreenY, dpage, opts
  wrapprint version & " " & gfxbackend & "/" & musicbackend, 8, pBottom - 14, uilook(uiMenuItem), dpage
  edgeprint "Press F1 for help on any menu!", 8, pBottom - 4, uilook(uiText), dpage

  SWAP vpage, dpage
  setvispage vpage
  dowait
 LOOP
 DeleteSlice @root
END SUB

SUB prompt_for_save_and_quit()
 xbsave game & ".gen", gen(), 1000

 DIM quit_menu(3) as string
 quit_menu(0) = "Continue editing"
 quit_menu(1) = "Save changes and continue editing"
 quit_menu(2) = "Save changes and quit"
 quit_menu(3) = "Discard changes and quit"
 setquitflag NO  'Stop firing esc's, if the user asked to quit the program
 
 DIM quitnow as integer
 quitnow = sublist(quit_menu(), "quit_and_save")
 IF getquitflag() THEN '2nd quit request? Right away!
  DIM basename as string = trimextension(sourcerpg)
  DIM lumpfile as string
  DIM i as integer = 0
  DO
   lumpfile = basename & ".rpg_" & i & ".bak"
   i += 1
  LOOP WHILE isfile(lumpfile)
  clearpage 0
  printstr "Saving as " & lumpfile, 0, 0, 0
  printstr "LUMPING DATA: please wait...", 0, 10, 0
  setvispage 0, NO
  write_rpg_or_rpgdir workingdir, lumpfile
  cleanup_and_terminate
  EXIT SUB
 END IF 

 IF (quitnow = 2 OR quitnow = 3) AND slave_channel <> NULL_CHANNEL THEN
  'Prod the channel to see whether it's still up (send ping)
  channel_write_line(slave_channel, "P ")

  IF slave_channel <> NULL_CHANNEL THEN
   IF yesno("You are still running a copy of this game. Quitting will force " & GAMEEXE & " to quit as well. Really quit?") = NO THEN quitnow = 0
  END IF
 END IF
 IF quitnow = 1 OR quitnow = 2 THEN
  save_current_game
 END IF
 IF quitnow = 3 THEN
  DIM quit_confirm(1) as string
  quit_confirm(0) = "I changed my mind! Don't quit!"
  quit_confirm(1) = "I am sure I don't want to save."
  IF sublist(quit_confirm()) <= 0 THEN quitnow = 0
  cleanup_workingdir_on_exit = YES  'This only makes a difference if a previous attempt to save failed
 END IF
 setkeys YES
 IF quitnow > 1 THEN cleanup_and_terminate

END SUB

SUB prompt_for_password()
 '--Is a password set?
 IF checkpassword("") THEN EXIT SUB
 
 '--Input password
 DIM pas as string = ""
 DIM passcomment as string = ""
 DIM tog as integer
 passcomment = "If you've forgotten your password, don't panic! It can be easily removed. " _
               "Contact the OHRRPGCE developers, or learn to compile the source code yourself."
 'Uncomment to display the/a password
 'passcomment = getpassword
 setkeys YES
 DO
  setwait 55
  setkeys YES
  tog = tog XOR 1
  IF keyval(scEsc) > 0 THEN cleanup_and_terminate
  IF keyval(scEnter) > 1 THEN
   IF checkpassword(pas) THEN
    EXIT SUB
   ELSE
    cleanup_and_terminate
   END IF
  END IF
  strgrabber pas, 17
  clearpage dpage
  wrapprint "This game requires a password to edit. Type it in and press ENTER", 10, 10, uilook(uiText), dpage
  textcolor uilook(uiSelectedItem + tog), 1
  printstr STRING(LEN(pas), "*"), 20, 40, dpage
  wrapprint passcomment, 15, pBottom - 15, uilook(uiText), dpage, rWidth - 30
  SWAP vpage, dpage
  setvispage vpage
  dowait
 LOOP
END SUB

SUB import_scripts_and_terminate (scriptfile as string)
 debuginfo "Importing scripts from " & scriptfile
 compile_andor_import_scripts absolute_with_orig_path(scriptfile)
 xbsave game & ".gen", gen(), 1000
 save_current_game
 cleanup_workingdir_on_exit = YES  'Cleanup even if saving the .rpg failed: no loss
 cleanup_and_terminate NO
END SUB

SUB cleanup_and_terminate (show_quit_msg as bool = YES)
 IF slave_channel <> NULL_CHANNEL THEN
  channel_write_line(slave_channel, "Q ")
  #IFDEF __FB_WIN32__
   'On windows, can't delete workingdir until Game has closed the music. Not too serious though
   basic_textbox "Waiting for " & GAMEEXE & " to clean up...", uilook(uiText), vpage
   setvispage vpage, NO
   IF channel_wait_for_msg(slave_channel, "Q", "", 2000) = 0 THEN
    basic_textbox "Waiting for " & GAMEEXE & " to clean up... giving up.", uilook(uiText), vpage
    setvispage vpage, NO
    sleep 700
   END IF
  #ENDIF
  channel_close(slave_channel)
 END IF
 IF slave_process <> 0 THEN
  basic_textbox "Waiting for " & GAMEEXE & " to quit...", uilook(uiText), vpage
  setvispage vpage, NO
  'Under GNU/Linux this calls pclose which will block until Game has quit.
  cleanup_process @slave_process
 END IF
 closemusic
 'catch sprite leaks
 sprite_empty_cache
 palette16_empty_cache
 cleanup_global_reload_doc
 clear_binsize_cache
 IF show_quit_msg ANDALSO getquitflag() = NO THEN
  clearpage vpage
  ' Don't let Spoonweaver's cat near your power cord!
  pop_warning "Don't forget to keep backup copies of your work! You never know when an unknown bug or a cat-induced hard-drive crash or a little brother might delete your files!", YES
 END IF
 IF cleanup_workingdir_on_exit THEN
  empty_workingdir workingdir
 END IF
 end_debug
 restoremode
 SYSTEM
END SUB


'==========================================================================================
'                                       Global menus
'==========================================================================================


PRIVATE FUNCTION volume_controls_callback(menu as MenuDef, state as MenuState, dataptr as any ptr) as bool
 ' This code is duplicated from player_menu_keys :(
 IF keyval(scF1) > 1 THEN show_help("editor_volume")
 DIM BYREF mi as MenuDefItem = *menu.items[state.pt]
 IF mi.t = mtypeSpecial AND (mi.sub_t = spMusicVolume OR mi.sub_t = spVolumeMenu) THEN
  IF keyval(scLeft) > 1 THEN set_music_volume large(get_music_volume - 1/16, 0.0)
  IF keyval(scRight) > 1 THEN set_music_volume small(get_music_volume + 1/16, 1.0)
 END IF
 IF mi.t = mtypeSpecial AND mi.sub_t = spSoundVolume THEN
  IF keyval(scLeft) > 1 THEN set_global_sfx_volume large(get_global_sfx_volume - 1/16, 0.0)
  IF keyval(scRight) > 1 THEN set_global_sfx_volume small(get_global_sfx_volume + 1/16, 1.0)
 END IF
 RETURN NO
END FUNCTION

' Allow changing the in-editor volume
SUB Custom_volume_menu
 DIM menu as MenuDef
 create_volume_menu menu
 run_MenuDef menu, @volume_controls_callback
 ClearMenuData menu
END SUB

' Accessible with F8 if we are editing a game
SUB Custom_global_menu
 REDIM menu(6) as string
 menu(0) = "Reimport scripts"
 menu(1) = "Test Game"
 menu(2) = "Volume"
 menu(3) = "Macro record/replay (Ctrl-F11)"
 menu(4) = "Zoom 1x"
 menu(5) = "Zoom 2x"
 menu(6) = "Zoom 3x"
 IF editing_a_game = NO THEN
  str_array_pop menu(), 1
  str_array_pop menu(), 0
 END IF

 DIM choice as integer = multichoice("Global Editor Options (F9)", menu())
 IF editing_a_game = NO AND choice >= 0 THEN choice += 2
 IF choice = 0 THEN
  reimport_previous_scripts
 ELSEIF choice = 1 THEN
  spawn_game_menu(keyval(scShift) > 0)
 ' ELSEIF choice = 2 THEN
 '  'Warning: data in the current menu may not be saved! So figured it better to avoid this.
 '  save_current_game
 ELSEIF choice = 2 THEN
  Custom_volume_menu
 ELSEIF choice = 3 THEN
  macro_controls
 ELSEIF choice = 4 THEN
  set_scale_factor 1
 ELSEIF choice = 5 THEN
  set_scale_factor 2
 ELSEIF choice = 6 THEN
  set_scale_factor 3
 END IF
END SUB

' This is called after every setkeys unless we're already inside global_setkeys_hook
' It should be fine to call any allmodex function in here, but beware we might
' not have loaded a game yet!
SUB global_setkeys_hook
 IF keyval(scF9) > 1 THEN Custom_global_menu
END SUB


'==========================================================================================
'                                          Shops
'==========================================================================================


SUB shop_editor ()
 DIM shopbuf(20) as integer

 DIM sbit(-1 TO 7) as string
 sbit(0) = "Buy"
 sbit(1) = "Sell"
 sbit(2) = "Hire"
 sbit(3) = "Inn"
 sbit(4) = "Equip"
 sbit(5) = "Save"
 sbit(6) = "Map"
 sbit(7) = "Team"

 DIM shopst as ShopEditState
 shopst.havestuf = NO

 shop_load shopst, shopbuf()
 shopst.st.last = 6
 shopst.st.size = 24

 DIM new_shop_id as integer
 
 setkeys YES
 DO
  setwait 55
  setkeys YES
  IF keyval(scEsc) > 1 THEN EXIT DO
  IF keyval(scF1) > 1 THEN show_help "shop_main"
  IF cropafter_keycombo(shopst.st.pt = 1) THEN cropafter shopst.id, gen(genMaxShop), 0, game + ".sho", 40
  usemenu shopst.st
  IF shopst.st.pt = 1 THEN
   '--only allow adding shops up to 99
   'FIXME: This is because of the limitation on remembering shop stock in the SAV format
   '       when the SAV format has changed, this limit can easily be lifted.
   'FIXME: SAV is gone, someone please increase this now :)
   new_shop_id = shopst.id
   IF intgrabber_with_addset(new_shop_id, 0, gen(genMaxShop), 99, "Shop") THEN
    shop_save shopst, shopbuf()
    shopst.id = new_shop_id
    IF shopst.id > gen(genMaxShop) THEN
     shop_add_new shopst
    END IF
    shop_load shopst, shopbuf()
   END IF
  END IF
  IF shopst.st.pt = 2 THEN
   strgrabber shopst.name, 15
   shopst.st.need_update = YES
  END IF
  IF enter_space_click(shopst.st) THEN
   IF shopst.st.pt = 0 THEN EXIT DO
   IF shopst.st.pt = 3 AND shopst.havestuf THEN
    shop_stuff_edit shopst.id, shopbuf(16)
   END IF
   IF shopst.st.pt = 4 THEN editbitset shopbuf(), 17, 7, sbit(): shopst.st.need_update = YES
   IF shopst.st.pt = 6 THEN
    shopst.menu(6) = "Inn Script: " & scriptbrowse(shopbuf(19), plottrigger, "Inn Plotscript")
   END IF
  END IF
  IF shopst.st.pt = 5 THEN
   IF intgrabber(shopbuf(18), 0, 32767) THEN shopst.st.need_update = YES
  END IF
  IF shopst.st.pt = 6 THEN
   IF scrintgrabber(shopbuf(19), 0, 0, scLeft, scRight, 1, plottrigger) THEN shopst.st.need_update = YES
  END IF
  
  IF shopst.st.need_update THEN
   shopst.st.need_update = NO
   shop_menu_update shopst, shopbuf()
  END IF
  
  clearpage dpage
  standardmenu shopst.menu(), shopst.st, shopst.shaded(), 0, 0, dpage 
  SWAP vpage, dpage
  setvispage vpage
  dowait
 LOOP
 shop_save shopst, shopbuf()

END SUB

SUB shop_load (byref shopst as ShopEditState, shopbuf() as integer)
 loadrecord shopbuf(), game & ".sho", 40 \ 2, shopst.id
 shopst.name = readbadbinstring(shopbuf(), 0, 15)
 shopst.st.need_update = YES
END SUB

SUB shop_save (byref shopst as ShopEditState, shopbuf() as integer)
 shopbuf(16) = small(shopbuf(16), 49)
 writebadbinstring shopst.name, shopbuf(), 0, 15
 storerecord shopbuf(), game & ".sho", 40 \ 2, shopst.id
END SUB

SUB shop_menu_update(byref shopst as ShopEditState, shopbuf() as integer)
 shopst.menu(0) = "Return to Main Menu"
 shopst.menu(1) = CHR(27) & " Shop " & shopst.id & " of " & gen(genMaxShop) & CHR(26)
 shopst.menu(2) = "Name: " & shopst.name
 shopst.menu(3) = "Edit Available Stuff..."
 shopst.menu(4) = "Select Shop Menu Items..."
 shopst.menu(5) = "Inn Price: " & shopbuf(18)
 IF readbit(shopbuf(), 17, 3) = 0 THEN shopst.menu(5) = "Inn Price: N/A"
 shopst.menu(6) = "Inn Script: " & scriptname(shopbuf(19))
 IF readbit(shopbuf(), 17, 0) ORELSE readbit(shopbuf(), 17, 1) ORELSE readbit(shopbuf(), 17, 2) THEN
  shopst.havestuf = YES
  shopst.shaded(3) = NO
 ELSE
  shopst.havestuf = NO
  ' Grey out "Edit available stuff"
  shopst.shaded(3) = YES
 END IF
END SUB

SUB shop_add_new (shopst as ShopEditState)
  DIM menu(2) as string
  DIM shoptocopy as integer = 0
  DIM state as MenuState
  state.last = UBOUND(menu)
  state.size = 24
  state.pt = 1

  state.need_update = YES
  setkeys
  DO
    setwait 55
    setkeys
    IF keyval(scESC) > 1 THEN  'cancel
      shopst.id -= 1
      EXIT DO
    END IF
    IF keyval(scF1) > 1 THEN show_help "shop_new"
    usemenu state
    IF state.pt = 2 THEN
      IF intgrabber(shoptocopy, 0, gen(genMaxShop)) THEN state.need_update = YES
    END IF
    IF state.need_update THEN
      state.need_update = NO
      menu(0) = "Cancel"
      menu(1) = "New Blank Shop"
      menu(2) = "Copy of Shop " & shoptocopy & " " & readshopname(shoptocopy) 'readbadbinstring(shopbuf(), 0, 15, 0)
    END IF
    IF enter_space_click(state) THEN
      DIM shopbuf(19) as integer
      DIM stufbuf(50 * curbinsize(binSTF) \ 2 - 1) as integer
      SELECT CASE state.pt
        CASE 0 ' cancel
          shopst.id -= 1
          EXIT DO
        CASE 1 ' blank
          gen(genMaxShop) += 1
          '--Create a new shop record
          flusharray shopbuf()
          '--Create a new shop stuff record
          flusharray stufbuf()
          'FIXME: load the name and price for first shop item
          stufbuf(19) = -1  'Default in-stock to infinite (first item only!)
        CASE 2 ' copy
          gen(genMaxShop) += 1
          loadrecord shopbuf(), game + ".sho", 20, shoptocopy
          loadrecord stufbuf(), game + ".stf", 50 * getbinsize(binSTF) \ 2, shoptocopy
      END SELECT
      storerecord shopbuf(), game + ".sho", 20, shopst.id
      'Save all 50 shop stock items at once
      storerecord stufbuf(), game + ".stf", 50 * getbinsize(binSTF) \ 2, shopst.id
      EXIT DO
    END IF

    clearpage vpage
    standardmenu menu(), state, 0, 0, vpage
    setvispage vpage
    dowait
  LOOP
END SUB

SUB shop_stuff_edit (byval shop_id as integer, byref thing_last_id as integer)
 DIM stuf as ShopStuffState

 stuf.max(3) = 1
 stuf.min(5) = -1
 stuf.max(5) = 9999
 FOR i as integer = 6 TO 9
  stuf.min(i) = -max_tag()
  stuf.max(i) = max_tag()
 NEXT i
 stuf.min(10) = -32767
 stuf.max(10) = 32767
 FOR i as integer = 11 TO 17 STEP 2
  stuf.max(i) = gen(genMaxItem)
  stuf.min(i) = -1
  stuf.max(i + 1) = 999
  stuf.min(i + 1) = 1
 NEXT

 stuf.min(20) = -32767
 stuf.max(20) = 32767
 stuf.max(21) = gen(genMaxItem)
 stuf.min(21) = -1
 stuf.max(22) = 999
 stuf.min(22) = 1

 stuf.thing = 0
 stuf.default_thingname = "" 'FIXME: this isn't updated anywhere yet
 stuf.thingname = ""
 
 stuf.st.pt = 0
 stuf.st.last = 2
 stuf.st.size = 24
 
 DIM stufbuf(curbinsize(binSTF) \ 2 - 1) as integer
 shop_load_stf shop_id, stuf, stufbuf()
 
 update_shop_stuff_type stuf, stufbuf()
 update_shop_stuff_menu stuf, stufbuf(), thing_last_id
 
 setkeys YES
 DO
  setwait 55
  setkeys YES

  IF keyval(scEsc) > 1 THEN EXIT DO
  IF keyval(scF1) > 1 THEN show_help "shop_stuff"
  IF stuf.st.pt = 0 ANDALSO enter_space_click(stuf.st) THEN EXIT DO

  SELECT CASE stuf.st.pt
   CASE 1 'browse shop stuff
    DIM newthing as integer = stuf.thing
    IF keyval(scShift) > 0 THEN
     ' While holding Shift, can swap a thing with the one before/after it.
     IF keyval(scLeft) > 1 OR keyval(scRight) > 1 THEN
      IF keyval(scLeft) > 1 AND stuf.thing > 0 THEN newthing -= 1
      IF keyval(scRight) > 1 AND stuf.thing < thing_last_id THEN newthing += 1
      shop_save_stf shop_id, stuf, stufbuf()
      shop_swap_stf shop_id, stuf.thing, newthing
      stuf.thing = newthing
      stuf.st.need_update = YES
     END IF
    ELSE
     IF intgrabber_with_addset(newthing, 0, thing_last_id, 49, "Shop Thing") THEN
      shop_save_stf shop_id, stuf, stufbuf()
      stuf.thing = newthing
      IF stuf.thing > thing_last_id THEN
       thing_last_id = stuf.thing
       flusharray stufbuf(), dimbinsize(binSTF), 0
       stufbuf(19) = -1 ' When adding new stuff, default in-stock to infinite
       stufbuf(37) = 1 + stuf.thing  'Set stockidx to next unused stock slot
       update_shop_stuff_type stuf, stufbuf(), YES  ' load the name and price
       shop_save_stf shop_id, stuf, stufbuf()
      END IF
      shop_load_stf shop_id, stuf, stufbuf()
      update_shop_stuff_type stuf, stufbuf()
      stuf.st.need_update = YES
     END IF
    END IF
   CASE 2 'name
    IF strgrabber(stuf.thingname, 16) THEN stuf.st.need_update = YES
   CASE 3 TO 4 'type and ID
    IF intgrabber(stufbuf(17 + stuf.st.pt - 3), stuf.min(stuf.st.pt), stuf.max(stuf.st.pt)) THEN
     stuf.st.need_update = YES
     update_shop_stuff_type stuf, stufbuf(), YES
    END IF
   CASE 6 TO 7 '--condition tags
    IF tag_grabber(stufbuf(17 + stuf.st.pt - 3), , , YES) THEN stuf.st.need_update = YES
   CASE 8 TO 9 '--set tags
    IF tag_grabber(stufbuf(17 + stuf.st.pt - 3), , , NO) THEN stuf.st.need_update = YES
   CASE 11 '--must trade in item 1 type
    IF zintgrabber(stufbuf(25), stuf.min(stuf.st.pt), stuf.max(stuf.st.pt)) THEN stuf.st.need_update = YES
   CASE 13, 15, 17 '--must trade in item 2+ types
    IF zintgrabber(stufbuf(18 + stuf.st.pt), stuf.min(stuf.st.pt), stuf.max(stuf.st.pt)) THEN stuf.st.need_update = YES
   CASE 12, 14, 16, 18 '--trade in item amounts
    stufbuf(18 + stuf.st.pt) += 1
    IF intgrabber(stufbuf(18 + stuf.st.pt), stuf.min(stuf.st.pt), stuf.max(stuf.st.pt)) THEN stuf.st.need_update = YES
    stufbuf(18 + stuf.st.pt) -= 1
   CASE 19, 20 '--sell type, price
    IF intgrabber(stufbuf(7 + stuf.st.pt), stuf.min(stuf.st.pt), stuf.max(stuf.st.pt)) THEN stuf.st.need_update = YES
    IF (stufbuf(26) < 0 OR stufbuf(26) > 3) AND stufbuf(17) <> 1 THEN stufbuf(26) = 0
   CASE 21 '--trade in for
    IF zintgrabber(stufbuf(7 + stuf.st.pt), stuf.min(stuf.st.pt), stuf.max(stuf.st.pt)) THEN stuf.st.need_update = YES
   CASE 22 '--trade in for amount
    stufbuf(7 + stuf.st.pt) += 1
    IF intgrabber(stufbuf(7 + stuf.st.pt), stuf.min(stuf.st.pt), stuf.max(stuf.st.pt)) THEN stuf.st.need_update = YES
    stufbuf(7 + stuf.st.pt) -= 1
   CASE ELSE
    IF intgrabber(stufbuf(17 + stuf.st.pt - 3), stuf.min(stuf.st.pt), stuf.max(stuf.st.pt)) THEN
     stuf.st.need_update = YES
    END IF
  END SELECT

  usemenu stuf.st

  IF stuf.st.need_update THEN
   update_shop_stuff_menu stuf, stufbuf(), thing_last_id
  END IF

  clearpage dpage
  standardmenu stuf.menu(), stuf.st, 0, 0, dpage

  IF stuf.st.pt = 1 THEN  'thing ID selection
   textcolor uilook(uiDisabledItem), 0
   printstr "SHIFT + Left/Right to reorder", pRight, pBottom, dpage
  END IF
 
  SWAP vpage, dpage
  setvispage vpage
  dowait
 LOOP

 shop_save_stf shop_id, stuf, stufbuf()

END SUB

SUB update_shop_stuff_type(byref stuf as ShopStuffState, stufbuf() as integer, byval reset_name_and_price as integer=NO)
 '--Re-load default names and default prices
 SELECT CASE stufbuf(17)
  CASE 0' This is an item
   DIM item_tmp(dimbinsize(binITM)) as integer
   loaditemdata item_tmp(), stufbuf(18)
   stuf.item_value = item_tmp(46)
   IF reset_name_and_price THEN
    stuf.thingname = load_item_name(stufbuf(18),1,1)
    stufbuf(24) = stuf.item_value ' default buy price
    stufbuf(27) = stuf.item_value \ 2 ' default sell price
   END IF
   stuf.st.last = 22
   stuf.max(4) = gen(genMaxItem)
   IF stufbuf(18) > stuf.max(4) THEN stufbuf(18) = 0
   stuf.min(19) = 0
   stuf.max(19) = 3 ' Item sell-type
  CASE 1
   DIM her as HeroDef
   IF reset_name_and_price THEN
    loadherodata her, stufbuf(18)
    stuf.thingname = her.name
    stufbuf(24) = 0 ' default buy price
    stufbuf(27) = 0 ' default sell price
   END IF
   stuf.item_value = 0
   stuf.st.last = 19
   stuf.max(4) = gen(genMaxHero)
   IF stufbuf(18) > gen(genMaxHero) THEN stufbuf(18) = 0
   stuf.min(19) = -1
   stuf.max(19) = gen(genMaxLevel) ' Hero experience level
  CASE ELSE
   'Type 2 was script which was never supported but was allowed for data entry in some ancient versions
   stuf.thingname = "Unsupported"
 END SELECT
END SUB

SUB update_shop_stuff_menu (byref stuf as ShopStuffState, stufbuf() as integer, byval thing_last_id as integer)

 stuf.menu(0) = "Previous Menu"
 ' This is inaccurate; if there are 11 things we write "X of 10".
 stuf.menu(1) = CHR(27) & "Shop Thing " & stuf.thing & " of " & thing_last_id & CHR(26)
 stuf.menu(2) = "Name: " & stuf.thingname
 stuf.menu(3) = "Type: "

 DIM typename as string
 SELECT CASE stufbuf(17)
  CASE 0: typename = "Item"
  CASE 1: typename = "Hero"
  CASE ELSE: typename = "???"
 END SELECT
 stuf.menu(3) &= typename

 stuf.menu(4) = typename & " ID: " & stufbuf(18) & " " & stuf.default_thingname
 
 SELECT CASE stufbuf(19)
  CASE IS > 0: stuf.menu(5) = "In Stock: " & stufbuf(19)
  CASE 0: stuf.menu(5) = "In Stock: None"
  CASE -1: stuf.menu(5) = "In Stock: Infinite"
  CASE ELSE: stuf.menu(5) = stufbuf(19) & " ???" 
 END SELECT

 stuf.menu(6) = tag_condition_caption(stufbuf(20), "Buy Require Tag", "Always")
 stuf.menu(7) = tag_condition_caption(stufbuf(21), "Sell Require Tag", "Always")
 stuf.menu(8) = tag_set_caption(stufbuf(22), "Buy Set Tag")
 stuf.menu(9) = tag_set_caption(stufbuf(23), "Sell Set Tag")
 stuf.menu(10) = "Cost: " & stufbuf(24) & " " & readglobalstring(32, "Money")
 IF stufbuf(17) = 0 AND stuf.item_value THEN  'item
  stuf.menu(10) &= " (" & CINT(100.0 * stufbuf(24) / stuf.item_value) & "% of Value)"
 END IF
 stuf.menu(11) = "Must Trade in " & (stufbuf(30) + 1) & " of: " & load_item_name(stufbuf(25),0,0)
 stuf.menu(12) = " (Change Amount)"
 stuf.menu(13) = "Must Trade in " & (stufbuf(32) + 1) & " of: " & load_item_name(stufbuf(31),0,0)
 stuf.menu(14) = " (Change Amount)"
 stuf.menu(15) = "Must Trade in " & (stufbuf(34) + 1) & " of: " & load_item_name(stufbuf(33),0,0)
 stuf.menu(16) = " (Change Amount)"
 stuf.menu(17) = "Must Trade in " & (stufbuf(36) + 1) & " of: " & load_item_name(stufbuf(35),0,0)
 stuf.menu(18) = " (Change Amount)"

 IF stufbuf(17) = 0 THEN

  SELECT CASE stufbuf(26)
   CASE 0: stuf.menu(19) = "Sell type: Don't Change Stock"
   CASE 1: stuf.menu(19) = "Sell type: Acquire Infinite Stock"
   CASE 2:
    stuf.menu(19) = "Sell type: Increment Stock"
    IF stufbuf(19) = -1 THEN
     stuf.menu(19) = "Sell type: Inc Stock (does nothing)"
    END IF
   CASE 3: stuf.menu(19) = "Sell type: Refuse to Buy"
   CASE ELSE: stuf.menu(19) = "Sell type: " & stufbuf(26) & " ???"
  END SELECT

  stuf.menu(20) = "Sell for: " & stufbuf(27) & " " & readglobalstring(32, "Money")
  IF stuf.item_value THEN
   stuf.menu(20) &= " (" & CINT(100.0 * stufbuf(27) / stuf.item_value) & "% of Value)"
  END IF
  stuf.menu(21) = "  and " & (stufbuf(29) + 1) & " of: " & load_item_name(stufbuf(28),0,0)
  stuf.menu(22) = " (Change Amount)"
 ELSE
  stuf.menu(19) = "Experience Level: "
  IF stufbuf(26) = -1 THEN
   stuf.menu(19) &= "default"
  ELSE
   stuf.menu(19) &= stufbuf(26)
  END IF
 END IF
 
 stuf.st.need_update = NO
END SUB

' Read the selected shop thing record from .stf, with error checking
SUB shop_load_stf (byval shop_id as integer, byref stuf as ShopStuffState, stufbuf() as integer)
 flusharray stufbuf(), dimbinsize(binSTF), 0
 loadrecord stufbuf(), game & ".stf", getbinsize(binSTF) \ 2, shop_id * 50 + stuf.thing
 stuf.thingname = readbadbinstring(stufbuf(), 0, 16, 0)
 '---check for invalid data
 IF stufbuf(17) < 0 OR stufbuf(17) > 2 THEN stufbuf(17) = 0
 IF stufbuf(19) < -1 THEN stufbuf(19) = 0
 IF (stufbuf(26) < 0 OR stufbuf(26) > 3) AND stufbuf(17) <> 1 THEN stufbuf(26) = 0
 '--WIP Serendipity custom builds didn't flush shop records when upgrading properly
 FOR i as integer = 32 TO 41
  stufbuf(i) = large(stufbuf(i), 0)
 NEXT
 '--Upgrades
 IF stufbuf(37) = 0 THEN stufbuf(37) = stuf.thing + 1  'Initialise stockidx
END SUB

' Write the selected shop thing record to .stf
SUB shop_save_stf (byval shop_id as integer, byref stuf as ShopStuffState, stufbuf() as integer)
 writebadbinstring stuf.thingname, stufbuf(), 0, 16
 storerecord stufbuf(), game & ".stf", getbinsize(binSTF) \ 2, shop_id * 50 + stuf.thing
END SUB

' Swap two shop thing records
SUB shop_swap_stf (shop_id as integer, thing_id1 as integer, thing_id2 as integer)
 DIM size as integer = getbinsize(binSTF) \ 2
 DIM as integer stufbuf1(size), stufbuf2(size)
 loadrecord stufbuf1(), game & ".stf", size, shop_id * 50 + thing_id1
 loadrecord stufbuf2(), game & ".stf", size, shop_id * 50 + thing_id2
 storerecord stufbuf1(), game & ".stf", size, shop_id * 50 + thing_id2
 storerecord stufbuf2(), game & ".stf", size, shop_id * 50 + thing_id1
END SUB


'==========================================================================================
'                    Creating/cleaning working.tmp and creating games
'==========================================================================================


' Returns true for success
FUNCTION newRPGfile (templatefile as string, newrpg as string) as bool
 IF newrpg = "" THEN RETURN NO
 ' Error already shown if missing
 IF NOT isfile(templatefile) THEN RETURN NO
 textcolor uilook(uiSelectedDisabled), 0
 printstr "Please Wait...", 0, 100, vpage
 printstr "Creating RPG File", 0, 110, vpage
 setvispage vpage, NO
 writeablecopyfile templatefile, newrpg
 printstr "Unlumping", 0, 120, vpage
 setvispage vpage, NO
 unlump newrpg, workingdir + SLASH
 '--create archinym information lump
 DIM fh as integer = FREEFILE
 OPENFILE(workingdir + SLASH + "archinym.lmp", FOR_OUTPUT, fh)
 PRINT #fh, "ohrrpgce"
 PRINT #fh, version
 CLOSE #fh
 printstr "Finalumping", 0, 130, vpage
 setvispage vpage, NO
 '--re-lump files as NEW rpg file
 RETURN write_rpg_or_rpgdir(workingdir, newrpg)
END FUNCTION

' Argument is a timeserial
FUNCTION format_date(timeser as double) as string
 RETURN FORMAT(timeser, "yyyy mmm dd hh:mm:ss")
END FUNCTION

' Write workingdir/session_info.txt.tmp
' Note: we assume that whenever this is called (and sourcerpg is set) that we are
' loading or saving the game.
SUB write_session_info ()
 DIM text(11) as string
 text(0) = version
 text(1) = get_process_path(get_process_id())  'May not match COMMAND(0)
 text(2) = "# Custom pid:"
 text(3) = STR(get_process_id())
 text(4) = "# Editing start (load/save) time:"
 text(5) = format_date(NOW)
 text(6) = STR(NOW)
 text(7) = "# Game path:"
 'sourcerpg may be blank if we're not yet editing a game
 IF LEN(sourcerpg) THEN
  text(8) = absolute_path(sourcerpg)
  text(9) = "# Last modified time of game:"
  DIM modified as double = FILEDATETIME(sourcerpg)
  text(10) = format_date(modified)
  text(11) = STR(modified)
 END IF
 lines_to_file text(), workingdir + SLASH + "session_info.txt.tmp"
END SUB

' Collect data about a previous (or ongoing) editing session from a dirty working.tmp
FUNCTION get_previous_session_info (workdir as string) as SessionInfo
 DIM ret as SessionInfo
 DIM exe as string
 DIM sessionfile as string
 sessionfile = workdir + SLASH + "session_info.txt.tmp"
 ret.workingdir = workdir
 IF isfile(sessionfile) THEN
  ret.info_file_exists = YES
  DIM text() as string
  lines_from_file text(), sessionfile
  'The metadata file's mtime should be nearly the same, but in future maybe we will want to write it
  'without saving the game.
  'ret.session_start_time = FILEDATETIME(sessionfile)
  ret.session_start_time = VAL(text(6))

  IF UBOUND(text) >= 8 ANDALSO LEN(text(8)) > 0 THEN
   ret.sourcerpg = text(8)
   IF isfile(ret.sourcerpg) THEN
    ret.sourcerpg_current_mtime = FILEDATETIME(ret.sourcerpg)
    IF UBOUND(text) >= 11 THEN ret.sourcerpg_old_mtime = VAL(text(11))
   END IF
  END IF
  ret.pid = VAL(text(3))
  exe = text(1)
  ' It's possible that this copy of Custom crashed and another copy was run with the same pid,
  ' but it's incredibly unlikely
  DIM pid_current_exe as string = get_process_path(ret.pid)
  debuginfo "pid_current_exe = " & pid_current_exe
  ret.running = (LEN(exe) ANDALSO pid_current_exe = exe)
 ELSE
  'We don't know anything, except that we could work out session_start_time by looking at working.tmp mtimes.
 END IF

 ' When was a lump last modified?
 ret.last_lump_mtime = 0
 DIM filelist() as string
 findfiles workdir, ALLFILES, fileTypeFile, NO, filelist()
 FOR i as integer = 0 TO UBOUND(filelist)
  IF RIGHT(filelist(i), 4) <> ".tmp" THEN
   ret.last_lump_mtime = large(ret.last_lump_mtime, FILEDATETIME(workdir + SLASH + filelist(i)))
  END IF
 NEXT

 ret.partial_rpg = isfile(workdir + SLASH + "__danger.tmp")

 debuginfo "prev_session.workingdir = " & ret.workingdir
 debuginfo "prev_session.info_file_exists = " & ret.info_file_exists
 debuginfo "prev_session.pid = " & ret.pid & " (exe = " & exe & ")"
 debuginfo "prev_session.running = " & ret.running
 debuginfo "prev_session.partial_rpg = " & ret.partial_rpg
 debuginfo "prev_session.sourcerpg = " & ret.sourcerpg
 debuginfo "prev_session.sourcerpg_old_mtime = " & format_date(ret.sourcerpg_old_mtime)
 debuginfo "prev_session.sourcerpg_current_mtime = " & format_date(ret.sourcerpg_current_mtime)
 debuginfo "prev_session.session_start_time = " & format_date(ret.session_start_time)
 debuginfo "prev_session.last_lump_mtime = " & format_date(ret.last_lump_mtime)

 RETURN ret
END FUNCTION

' Try to delete everything in the given directory in a race-condition-safe order. Returns true if succeeded.
' (This is overkill now, I guess)
FUNCTION empty_workingdir (workdir as string) as bool
 touchfile workdir + SLASH + "__danger.tmp"
 DIM filelist() as string
 findfiles workdir, ALLFILES, fileTypeFile, NO, filelist()
 ' Delete these metadata files last
 array_shuffle_to_end filelist(), str_array_findcasei(filelist(), "__danger.tmp")
 array_shuffle_to_end filelist(), str_array_findcasei(filelist(), "session_info.txt.tmp")
 FOR i as integer = 0 TO UBOUND(filelist)
  DIM fname as string = workdir + SLASH + filelist(i)
  IF NOT safekill(fname) THEN
   'notification "Could not clean up " & workdir & !"\nYou may have to manually delete its contents."
   RETURN NO
  END IF
 NEXT
 killdir workdir
 RETURN YES
END FUNCTION

' Selects an unused workingdir path and creates it
SUB setup_workingdir ()
 ' This can't pick "working.tmp", so old versions of Custom won't see and clobber it.
 DIM idx as integer = 0
 DO
  workingdir = tmpdir & "working" & idx & ".tmp"
  IF NOT isdir(workingdir) THEN EXIT DO
  idx += 1
 LOOP

 debuginfo "Working in " & workingdir
 IF makedir(workingdir) <> 0 THEN
  fatalerror "Couldn't create " & workingdir & !"\nCheck c_debug.txt"
 END IF
 write_session_info
END SUB

' Check whether any other copy of Custom is already editing sourcerpg
FUNCTION check_ok_to_open (filename as string) as bool
 debuginfo "check_ok_to_open..."
 DIM olddirs() as string
 findfiles tmpdir, "working*.tmp", fileTypeDirectory, NO, olddirs()

 FOR idx as integer = 0 TO UBOUND(olddirs)
  DIM sessinfo as SessionInfo = get_previous_session_info(tmpdir & olddirs(idx))

  IF sessinfo.sourcerpg = filename THEN
   IF NOT sessinfo.running THEN
    notification "Found a copy of Custom which was editing this game, but crashed. Run Custom again to do a cleanup or recovery."
   ELSE
    notification "Another copy of " CUSTOMEXE " is already editing " & decode_filename(sourcerpg) & _
                 !".\nYou can't open the same game twice at once! " _
                 "(Make a copy first if you really want to.)"
   END IF
   RETURN NO
  END IF
 NEXT
 RETURN YES
END FUNCTION

SUB check_for_crashed_workingdirs ()

 'This also finds working.tmp, which belongs to old versions
 DIM olddirs() as string
 findfiles tmpdir, "working*.tmp", fileTypeDirectory, NO, olddirs()

 FOR idx as integer = 0 TO UBOUND(olddirs)
  DIM sessinfo as SessionInfo = get_previous_session_info(tmpdir & olddirs(idx))

  IF sessinfo.info_file_exists THEN
   IF sessinfo.running THEN
    ' Not crashed, so ignore
    CONTINUE FOR
   END IF
   debuginfo "Found workingtmp for crashed Custom"

   IF sessinfo.partial_rpg THEN
    debuginfo "...crashed while unlumping/deleting temp files, silent cleanup"
    ' In either case, safe to delete files.
    empty_workingdir(sessinfo.workingdir)
    CONTINUE FOR
   END IF

   IF LEN(sessinfo.sourcerpg) = 0 THEN
    debuginfo "...crashed before opening a game, silent cleanup"
    empty_workingdir(sessinfo.workingdir)
    CONTINUE FOR
   END IF

  END IF

  ' Does this look like a game, or should we just delete it?
  IF NOT sessinfo.partial_rpg THEN
   DIM filelist() as string
   findfiles sessinfo.workingdir, ALLFILES, fileTypeFile, NO, filelist()

   IF UBOUND(filelist) <= 5 THEN
    'Just some stray files that refused to delete last time,
    'or possibly an old copy of Custom running but no game opened yet no way to handle that
    debuginfo (UBOUND(filelist) + 1) & " files in working.tmp, silent cleanup"
    empty_workingdir(sessinfo.workingdir)
    CONTINUE FOR
   END IF
  END IF

  'Auto-handling failed, ask user what to do
  handle_dirty_workingdir(sessinfo)
 NEXT
END SUB

' When recovering an rpg from working.tmp, pick an unused destination filename.
FUNCTION pick_recovered_rpg_filename(old_sourcerpg as string) as string
 DIM destdir as string
 DIM destfile_basename as string
 destfile_basename = "crash-recovered"
 IF LEN(old_sourcerpg) THEN
  ' Put next to original file
  destdir = trimfilename(old_sourcerpg) & SLASH
  IF NOT diriswriteable(destdir) THEN destdir = ""
  destfile_basename = trimpath(trimextension(old_sourcerpg)) & " crash-recovered "
 END IF
 IF NOT diriswriteable(destdir) THEN destdir = documents_dir & SLASH

 DIM index as integer = 0
 DO
  DIM destfile as string = destdir & destfile_basename & index & ".rpg"
  IF NOT isfile(destfile) THEN RETURN destfile
  index += 1
 LOOP
END FUNCTION

'Returns true if we can continue, false to cleanup_and_terminate
FUNCTION recover_workingdir (sessinfo as SessionInfo) as bool
 DIM origname as string
 IF LEN(sessinfo.sourcerpg) THEN
  origname = trimpath(sessinfo.sourcerpg)
 ELSE
  origname = "gamename.rpg"
 END IF
 DIM destfile as string
 destfile = pick_recovered_rpg_filename(sessinfo.sourcerpg)

 printstr "Saving as " + decode_filename(destfile), 0, 180, vpage
 printstr "LUMPING DATA: please wait...", 0, 190, vpage
 setvispage vpage, NO
 '--re-lump recovered files as RPG file
 IF write_rpg_or_rpgdir(sessinfo.workingdir, destfile) = NO THEN
  RETURN NO
 END IF
 clearpage vpage

 DIM msg as string
 msg = "The recovered game has been saved as " & decode_filename(destfile) & !"\n" _
       "You can rename it to " & origname & ", but ALWAYS keep the previous copy " _
       !"as a backup because some data in the recovered file might be corrupt!\n" _
       "If you have questions, ask ohrrpgce-crash@HamsterRepublic.com"
 basic_textbox msg, uilook(uiText), vpage
 setvispage vpage
 waitforanykey
 RETURN empty_workingdir(sessinfo.workingdir)
END FUNCTION

'Called when a partial or complete copy of a game exists
'Returns true if cleaned away, false if not cleaned up
FUNCTION handle_dirty_workingdir (sessinfo as SessionInfo) as bool
 clearpage vpage

 IF isfile(sessinfo.workingdir + SLASH + "__danger.tmp") THEN
  ' Don't provide option to recover, as this looks like garbage.
  ' If we've reached this point, then already checked whether it's a modern Custom
  ' However, maybe another copy of custom is busy unlumping a big game, so ask before deleting.
  DIM choice as integer
  choice = twochoice("Found a partial temporary copy of a game.\n" _
                     "It looks like an old version of " + CUSTOMEXE + " was in the process of " _
                     "either unlumping a game or deleting its temporary files. " _
                     "It might have crashed, or still be running. What do you want to do?", _
                     "Ignore", _
                     "Erase temporary files (crashed)", _
                     0, 0)
  IF choice = 0 THEN
   RETURN NO
  ELSE
   RETURN empty_workingdir(sessinfo.workingdir)
  END IF
 END IF

 DIM msg as string
 DIM helpfile as string
 IF sessinfo.info_file_exists THEN
  ' We already checked Custom isn't still running

  msg = CUSTOMEXE " crashed while editing a game, but the temp unsaved modified copy of the game still exists." LINE_END
  msg &= decode_filename(sessinfo.sourcerpg) & LINE_END

  IF sessinfo.sourcerpg_current_mtime < sessinfo.session_start_time THEN
   ' It's a bit confusing to tell the user 4 last-mod times, so skip this one.
   msg &= "Modified " & format_date(sessinfo.sourcerpg_old_mtime) & LINE_END
  END IF

  ' The }'s get replaced with either | or a space.
  msg &=  "}|" LINE_END _
          "}+>Loaded or last saved by Custom " LINE_END _
          "}  at:        " & format_date(sessinfo.session_start_time) & LINE_END _
          "}  Last edit: " & format_date(sessinfo.last_lump_mtime)

  IF sessinfo.sourcerpg_current_mtime > sessinfo.session_start_time THEN
   msg &= LINE_END "|" LINE_END _
          "+-> WARNING: " & decode_filename(trimpath(sessinfo.sourcerpg)) & " modified since it was loaded or saved!" _
          " Modified " & format_date(sessinfo.sourcerpg_current_mtime) ' & LINE_END

   replacestr(msg, LINE_END "}", LINE_END "|")
   helpfile = "recover_unlumped_rpg_outdated"
  ELSE
   replacestr(msg, LINE_END "}", LINE_END " ")
   helpfile = "recover_unlumped_rpg"
  END IF

 ELSE
  msg = !"An unknown game was found unlumped.\n" _
        "It appears that an old version of " + CUSTOMEXE + " is either already running, " _
        "or it has crashed."
 END IF

 DIM cleanup_menu(2) as string
 cleanup_menu(0) = "DO NOTHING (ask again later)"
 cleanup_menu(1) = "RECOVER temp files as a .rpg"
 cleanup_menu(2) = "ERASE temp files"
 DIM choice as integer
 choice = multichoice(msg, cleanup_menu(), 0, 0, helpfile, NO)  'Left justified

 IF choice = 0 THEN RETURN NO
 IF choice = 1 THEN RETURN recover_workingdir(sessinfo)
 IF choice = 2 THEN RETURN empty_workingdir(sessinfo.workingdir)  'erase
END FUNCTION


'==========================================================================================
'                               Secret/testing/debug menus
'==========================================================================================


SUB secret_menu ()
 DIM menu(...) as string = { _
     "Reload Editor", _
     "Editor Editor", _
     "Conditions and More Tests", _
     "Transformed Quads", _
     "Sprite editor with arbitrary sizes", _
     "Text tests", _
     "Font tests", _
     "Stat Growth Chart", _
     "Resolution Menu", _
     "Edit Status Screen", _
     "Edit Status Screen Stat Plank", _
     "Edit Item Screen", _
     "Edit Item Screen Item Plank", _
     "Edit Spell Screen", _
     "Edit Spell Screen Spell List Plank", _
     "Edit Spell Screen Spell Plank", _
     "Edit Virtual Keyboard Screen", _
     "Editor Slice Editor", _
     "New Spriteset/Animation Editor", _
     "New backdrop browser", _
     "RGFX tests", _
     "Test Game under GDB" _
 }
 DIM st as MenuState
 st.autosize = YES
 st.last = UBOUND(menu)

 DO
  setwait 55
  setkeys
  IF keyval(scEsc) > 1 THEN EXIT DO
  IF enter_space_click(st) THEN
   IF st.pt = 0 THEN reload_editor
   IF st.pt = 1 THEN editor_editor
   IF st.pt = 2 THEN condition_test_menu
   IF st.pt = 3 THEN quad_transforms_menu
   IF st.pt = 4 THEN arbitrary_sprite_editor
   IF st.pt = 5 THEN text_test_menu
   IF st.pt = 6 THEN font_test_menu
   IF st.pt = 7 THEN stat_growth_chart
   IF st.pt = 8 THEN resolution_menu YES
   IF st.pt = 9 THEN slice_editor SL_COLLECT_STATUSSCREEN
   IF st.pt = 10 THEN slice_editor SL_COLLECT_STATUSSTATPLANK
   IF st.pt = 11 THEN slice_editor SL_COLLECT_ITEMSCREEN
   IF st.pt = 12 THEN slice_editor SL_COLLECT_ITEMPLANK
   IF st.pt = 13 THEN slice_editor SL_COLLECT_SPELLSCREEN
   IF st.pt = 14 THEN slice_editor SL_COLLECT_SPELLLISTPLANK
   IF st.pt = 15 THEN slice_editor SL_COLLECT_SPELLPLANK
   IF st.pt = 16 THEN slice_editor SL_COLLECT_VIRTUALKEYBOARDSCREEN
   IF st.pt = 17 THEN slice_editor SL_COLLECT_EDITOR, get_data_dir() & SLASH "blank.slice"
   IF st.pt = 18 THEN new_spriteset_editor
   IF st.pt = 19 THEN backdrop_browser
   IF st.pt = 20 THEN new_graphics_tests
   IF st.pt = 21 THEN spawn_game_menu YES
  END IF
  usemenu st
  clearpage vpage
  standardmenu menu(), st, 0, 0, vpage
  setvispage vpage
  dowait
 LOOP
 setkeys
END SUB

FUNCTION window_size_description(scale as integer) as string
 IF scale >= 11 THEN
  ' Not implemented yet.
  RETURN "maximize"
 ELSE
  RETURN "~" & (10 * scale) & "% screen width"
 END IF
END FUNCTION

SUB resolution_menu (secret_options as bool)
 DIM menu(6) as string
 DIM st as MenuState
 st.size = 24
 st.last = IIF(secret_options, UBOUND(menu), 4)

 'FIXME: selecting a resolution other than 320x200 causes the distrib menu
 'to not package gfx_directx.dll; remove that when gfx_directx is updated

 DO
  setwait 55
  setkeys
  DIM quit as bool = (keyval(scEsc) > 1 OR (enter_space_click(st) AND st.pt = 0))
  IF usemenu(st) ORELSE quit THEN
   ' Reinforce limits, because we temporarily allow 0 while typing for convenience
   gen(genResolutionX) = large(10, gen(genResolutionX))
   gen(genResolutionY) = large(10, gen(genResolutionY))
  END IF
  IF quit THEN EXIT DO
  IF keyval(scF1) > 1 THEN
    show_help IIF(secret_options, "window_settings", "window_settings_partial")
  END IF
  SELECT CASE st.pt
   CASE 1: st.need_update OR= intgrabber(gen(genFullscreen), 0, 1)
   CASE 2: st.need_update OR= intgrabber(gen(genWindowSize), 1, 10)
   CASE 3: st.need_update OR= intgrabber(gen(genLivePreviewWindowSize), 1, 10)
   CASE 4: st.need_update OR= intgrabber(gen(genRungameFullscreenIndependent), 0, 1)
   CASE 5: st.need_update OR= intgrabber(gen(genResolutionX), 0, 1280)  'Arbitrary limits
   CASE 6: st.need_update OR= intgrabber(gen(genResolutionY), 0, 960)
  END SELECT
  IF st.need_update THEN
   xbsave game + ".gen", gen(), 1000   'Instant live previewing update
   st.need_update = NO
  END IF
  menu(0) = "Previous Menu"
  menu(1) = "Default to fullscreen: " & yesorno(gen(genFullscreen))
  menu(2) = "Default window size: " & window_size_description(gen(genWindowSize))
  menu(3) = "Test-Game window size: " & window_size_description(gen(genLivePreviewWindowSize))
  menu(4) = "rungame fullscreen state: "
  IF gen(genRungameFullscreenIndependent) THEN
   menu(4) &= "independent"
  ELSE
   menu(4) &= "shared with this game"
  END IF
  menu(5) = "Display Width: " & gen(genResolutionX) & " pixels"
  menu(6) = "Display Height:" & gen(genResolutionY) & " pixels"
  clearpage vpage
  standardmenu menu(), st, 0, 0, vpage
  setvispage vpage
  dowait
 LOOP
 xbsave game + ".gen", gen(), 1000
END SUB

SUB arbitrary_sprite_editor ()
 DIM tempsets as integer = 0
 DIM tempcaptions(15) as string
 FOR i as integer = 0 to UBOUND(tempcaptions)
  tempcaptions(i) = "frame" & i
 NEXT i
 DIM size as XYPair
 size.x = 20
 size.y = 20
 DIM framecount as integer = 8

 DIM menu(...) as string = {"Width=", "Height=", "Framecount=", "Sets=", "Start Editing..."}
 DIM st as MenuState
 st.size = 24
 st.last = UBOUND(menu)
 st.need_update = YES

 DO
  setwait 55
  setkeys
  IF keyval(scEsc) > 1 THEN EXIT DO
  SELECT CASE st.pt
   CASE 0: IF intgrabber(size.x, 0, 160) THEN st.need_update = YES
   CASE 1: IF intgrabber(size.y, 0, 160) THEN st.need_update = YES
   CASE 2: IF intgrabber(framecount, 0, 16) THEN st.need_update = YES
   CASE 3: IF intgrabber(tempsets, 0, 32000) THEN st.need_update = YES
  END SELECT
  IF enter_space_click(st) THEN
   IF st.pt = 4 THEN
    spriteset_editor size.x, size.y, tempsets, framecount, tempcaptions(), sprTypeOther
    IF isfile(game & ".pt-1") THEN
     debug "Leaving behind """ & game & ".pt-1"""
    END IF
   END IF
  END IF
  usemenu st
  IF st.need_update THEN
   menu(0) = "Width: " & size.x
   menu(1) = "Height:" & size.y
   menu(2) = "Framecount: " & framecount
   menu(3) = "Sets: " & tempsets
   st.need_update = NO
  END IF
  clearpage vpage
  standardmenu menu(), st, 0, 0, vpage
  setvispage vpage
  dowait
 LOOP
 setkeys

END SUB

'This menu is for testing experimental Condition UI stuff
SUB condition_test_menu ()
 DIM as Condition cond1, cond2, cond3, cond4
 DIM as AttackElementCondition atkcond
 DIM float as double
 DIM float_repr as string = "0%"
 DIM atkcond_repr as string = ": Never"
 DIM menu(8) as string
 DIM st as MenuState
 st.last = UBOUND(menu)
 st.size = 22
 DIM tmp as integer

 DO
  setwait 55
  setkeys YES
  IF keyval(scEsc) > 1 THEN EXIT DO
  IF keyval(scF1) > 1 THEN show_help "condition_test"
  tmp = 0
  IF st.pt = 0 THEN
   IF enter_space_click(st) THEN EXIT DO
  ELSEIF st.pt = 2 THEN
   tmp = cond_grabber(cond1, YES , NO, st)
  ELSEIF st.pt = 3 THEN
   tmp = cond_grabber(cond2, NO, NO, st)
  ELSEIF st.pt = 5 THEN
   tmp = cond_grabber(cond3, YES, YES, st)
  ELSEIF st.pt = 6 THEN
   tmp = cond_grabber(cond4, NO, YES, st)
  ELSEIF st.pt = 7 THEN
   tmp = percent_cond_grabber(atkcond, atkcond_repr, ": Never", -9.99, 9.99, 5)
  ELSEIF st.pt = 8 THEN
   tmp = percent_grabber(float, float_repr, -9.99, 9.99, 5)
  END IF
  usemenu st

  clearpage vpage
  menu(0) = "Previous menu"
  menu(1) = "Enter goes to tag browser for tag conds:"
  menu(2) = " If " & condition_string(cond1, (st.pt = 2), "Always", 45)
  menu(3) = " If " & condition_string(cond2, (st.pt = 3), "Never", 45)
  menu(4) = "Enter always goes to cond editor:"
  menu(5) = " If " & condition_string(cond3, (st.pt = 5), "Always", 45)
  menu(6) = " If " & condition_string(cond4, (st.pt = 6), "Never", 45)
  menu(7) = "Fail vs damage from <fire>" & atkcond_repr
  menu(8) = "percent_grabber : " & float_repr
  standardmenu menu(), st, 0, 0, vpage
  printstr STR(tmp), 0, 190, vpage
  setvispage vpage
  dowait
 LOOP
 setkeys
END SUB


SUB quad_transforms_menu ()
 DIM menu(...) as string = {"Arrows: scale X and Y", "<, >: change angle", "[, ]: change sprite"}
 DIM st as MenuState
 st.last = 2
 st.size = 22
 st.need_update = YES

 DIM spritemode as integer = -1  ' Not a SpriteType. A .PT# number or -1 to show master palette

 DIM testframe as Frame ptr
 DIM vertices(3) as Float3

 DIM angle as single
 DIM scale as Float2 = (2.0, 2.0)
 DIM position as Float2 = (150, 50)

 switch_to_32bit_vpages()
 DIM vpage8 as integer = allocatepage( , , 8)

 DIM as double drawtime, pagecopytime

 DIM spriteSurface as Surface ptr

 DIM masterPalette as RGBPalette ptr
 gfx_paletteFromRGB(@master(0), @masterPalette)

 DO
  setwait 55

  if st.need_update then
   if spritemode < -1 then spritemode = sprTypeLastPT
   if spritemode > sprTypeLastPT then spritemode = -1

   frame_unload @testframe

   select case spritemode
    case 0 to sprTypeLastPT
     DIM tempsprite as GraphicPair
     load_sprite_and_pal tempsprite, spritemode, 0, -1
     with tempsprite
      testframe = frame_new(.sprite->w, .sprite->h, , YES)
      frame_draw .sprite, .pal, 0, 0, , , testframe
     end with
     unload_sprite_and_pal tempsprite
    case else
     testframe = frame_new(16, 16)
     FOR i as integer = 0 TO 255
      putpixel testframe, (i MOD 16), (i \ 16), i
     NEXT
   end select

   gfx_surfaceDestroy( @spriteSurface )
   gfx_surfaceWithFrame( testframe, @spriteSurface )

   DIM testframesize as Rect
   WITH testframesize
    .top = 0
    .left = 0
    .right = spriteSurface->width - 1
    .bottom = spriteSurface->height - 1
   END WITH
   vec3GenerateCorners @vertices(0), 4, testframesize

   st.need_update = NO
  end if

  setkeys
  IF keyval(scEsc) > 1 THEN EXIT DO
  IF keyval(scLeft)  THEN scale.x -= 0.1
  IF keyval(scRight) THEN scale.x += 0.1
  IF keyval(scUp)    THEN scale.y -= 0.1
  IF keyval(scDown)  THEN scale.y += 0.1
  IF keyval(scLeftCaret)  THEN angle -= 0.1
  IF keyval(scRightCaret) THEN angle += 0.1
  IF keyval(scLeftBracket) > 1 THEN spritemode -= 1: st.need_update = YES
  IF keyval(scRightBracket) > 1 THEN spritemode += 1: st.need_update = YES

  clearpage vpage8
  standardmenu menu(), st, 0, 0, vpage8
  ' We have to draw onto a temp 8-bit Surface, because frame_draw with scale
  ' isn't supported with Surfaces yet
  frame_draw testframe, , 20, 50, 2, , vpages(vpage8)  'drawn at 2x scale

  'Can only display the previous frame's time to draw, since we don't currently
  'have any functions to print text to surfaces
  printstr "Drawn in " & FIX(drawtime * 1000000) & " usec, pagecopytime = " & FIX(pagecopytime * 1000000) & " usec", 0, 190, vpage
  debug "Drawn in " & FIX(drawtime * 1000000) & " usec, pagecopytime = " & FIX(pagecopytime * 1000000) & " usec"

  pagecopytime = TIMER
  'Copy from vpage8 (8 bit Frame) to the render target surface
  frame_draw vpages(vpage8), NULL, 0, 0, , NO, vpage
  pagecopytime = TIMER - pagecopytime

  DIM starttime as double = TIMER

  DIM matrix as Float3x3
  matrixLocalTransform @matrix, angle, scale, position
  DIM trans_vertices(3) as Float3
  vec3Transform @trans_vertices(0), 4, @vertices(0), 4, matrix

  'may have to reorient the tex coordinates
  DIM pt_vertices(3) as VertexPT
  pt_vertices(0).tex.u = 0
  pt_vertices(0).tex.v = 0
  pt_vertices(1).tex.u = 1
  pt_vertices(1).tex.v = 0
  pt_vertices(2).tex.u = 1
  pt_vertices(2).tex.v = 1
  pt_vertices(3).tex.u = 0
  pt_vertices(3).tex.v = 1
  FOR i as integer = 0 TO 3
   pt_vertices(i).pos.x = trans_vertices(i).x
   pt_vertices(i).pos.y = trans_vertices(i).y
  NEXT

  gfx_renderQuadTexture( @pt_vertices(0), spriteSurface, masterPalette, YES, NULL, vpages(vpage)->surf )
  drawtime = TIMER - starttime

  setvispage vpage
  dowait
 LOOP
 setkeys
 frame_unload @testframe
 freepage vpage8
 switch_to_8bit_vpages()
 gfx_surfaceDestroy(@spriteSurface)
 gfx_paletteDestroy(@masterPalette)
END SUB

SUB text_test_menu
 DIM text as string = load_help_file("texttest")
 DIM mouse as MouseInfo
 hidemousecursor
 DO
  setwait 55
  setkeys
  mouse = readmouse
  IF keyval(scEsc) > 1 THEN EXIT DO
  IF keyval(scF1) > 1 THEN
   show_help "texttest"
   text = load_help_file("texttest")
  END IF
  IF keyval(scF2) > 1 THEN
   pop_warning !"Extreemmmely lonngggg Extreemmmely lonngggg Extreemmmely lonngggg Extreemmmely lonngggg Extreemmmely lonngggg Extreemmmely lonngggg Extreemmmely lonngggg \n\ntext\nbox\n\nnargh\nnargh\nnargh\nndargh\nnargh\nnagrgh\nnargh\n\nmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm"
  END IF
  IF keyval(scF3) > 1 THEN
   text = load_help_file("texttest_stress_test")
  END IF

  DIM curspos as StringCharPos
  DIM pos2 as StringSize
  find_point_in_text @curspos, mouse.x - 20, mouse.y - 20, text, 280, 0, 0, 0, YES, YES

  text_layout_dimensions @pos2, text, curspos.charnum, , 280, fonts(0), YES, YES

  clearpage vpage
  edgeboxstyle 10, 10, 300, 185, 0, vpage
  wrapprint text, 20, 20, , vpage, 280, , fontPlain
  rectangle vpages(vpage), 20 + pos2.lastw, 20 + pos2.h - pos2.finalfont->h, 8, pos2.finalfont->h, 5
  printstr CHR(3), mouse.x - 2, mouse.y - 2, vpage
  printstr STR(curspos.charnum), 0, 190, vpage
  setvispage vpage
  dowait
 LOOP
 setkeys
 defaultmousecursor
END SUB

SUB font_test_menu
 DIM menu(...) as string = {"Font 0", "Font 1", "Font 2", "Font 3"}
 DIM st as MenuState
 st.last = UBOUND(menu)
 st.size = 22

 DIM controls as string = "1: import from 'fonttests/testfont/', 2: import from bmp, 3: create edged font, 4: create shadow font"

 DO
  setwait 55
  setkeys
  IF keyval(scEsc) > 1 THEN EXIT DO
  IF keyval(sc1) > 1 THEN
   DIM newfont as Font ptr = font_loadbmps("fonttests/testfont", fonts(st.pt))
   font_unload @fonts(st.pt)
   fonts(st.pt) = newfont
  END IF
  IF keyval(sc2) > 1 THEN
   DIM filen as string
   filen = browse(10, "", "*.bmp")
   IF LEN(filen) THEN
    font_unload @fonts(st.pt)
    fonts(st.pt) = font_loadbmp_16x16(filen)
   END IF
  END IF
  IF keyval(sc3) > 1 THEN
   DIM choice as integer
   choice = multichoice("Create an edged font from which font?", menu())
   IF choice > -1 THEN
    DIM newfont as Font ptr = font_create_edged(fonts(choice))
    font_unload @fonts(st.pt)
    fonts(st.pt) = newfont
   END IF
  END IF
  IF keyval(sc4) > 1 THEN
   DIM choice as integer
   choice = multichoice("Create a drop-shadow font from which font?", menu())
   IF choice > -1 THEN
    DIM newfont as Font ptr = font_create_shadowed(fonts(choice), 2, 2)
    font_unload @fonts(st.pt)
    fonts(st.pt) = newfont
   END IF
  END IF

  usemenu st

  clearpage vpage
  'edgeboxstyle 10, 10, 300, 185, 0, vpage
  standardmenu menu(), st, 0, 0, vpage
  textcolor uilook(uiText), 0
  wrapprint controls, 0, rBottom + ancBottom, , vpage

  FOR i as integer = 0 TO 15
   DIM row as string
   FOR j as integer = i * 16 TO i * 16 + 15
    row &= CHR(j)
   NEXT
   IF fonts(st.pt) THEN
    printstr row, 145, 0 + i * fonts(st.pt)->h, vpage, YES, st.pt
   END IF
  NEXT

  setvispage vpage
  dowait
 LOOP
END SUB

SUB new_graphics_tests
 DIM ofile as string = tmpdir + SLASH + "backdrops.rgfx"
 'Gives notification about time taken
 convert_mxs_to_rgfx(game + ".mxs", ofile)

 'Lets see how long the document takes to load
 DIM doc as DocPtr
 DIM starttime as double = timer
 doc = LoadDocument(ofile, optNoDelay)
 notification "Backdrop .rgfx completely loaded in " & CINT((timer - starttime) * 1000) & "ms"
 FreeDocument doc
 doc = NULL

 DIM fr as Frame ptr
 DIM rgfx_time as double
 FOR i as integer = 0 TO gen(genNumBackdrops) - 1
  starttime = timer
  IF doc = NULL THEN doc = rgfx_open(ofile)
  fr = rgfx_get_frame(doc, i, 0)
  rgfx_time += timer - starttime
  frame_draw fr, , 0, 0, 1, NO, vpage
  setvispage vpage
  ' waitforanykey
  frame_unload @fr
 NEXT
 starttime = timer
 'Load backdrops without caching
 FOR i as integer = 0 TO gen(genNumBackdrops) - 1
  fr = frame_load_mxs(game + ".mxs", i)
  frame_unload @fr
 NEXT
 notification gen(genNumBackdrops) & " backdrops loaded from .rgfx in " & CINT(rgfx_time * 1000) & "ms; " _
     "loaded from mxs in " & CINT((timer - starttime) * 1000) & "ms"
END SUB
