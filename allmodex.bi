'Allmodex FreeBasic Library header

#IFNDEF ALLMODEX_BI
#DEFINE ALLMODEX_BI

#include "udts.bi"
#include "compat.bi"
#IFNDEF BITMAP
 'windows.bi may have been included
 #include "bitmap.bi"
#ENDIF
#include "file.bi"   'FB header
#include "lumpfile.bi"


'Library routines
DECLARE SUB modex_init ()
DECLARE SUB setmodex ()
DECLARE SUB modex_quit ()
DECLARE SUB restoremode ()
DECLARE SUB setwindowtitle (title as string)
DECLARE FUNCTION allocatepage(BYVAL w as integer = 320, BYVAL h as integer = 200) as integer
DECLARE SUB freepage (BYVAL page as integer)
DECLARE FUNCTION registerpage (BYVAL spr as Frame ptr) as integer
DECLARE SUB copypage (BYVAL page1 as integer, BYVAL page2 as integer)
DECLARE SUB clearpage (BYVAL page as integer, BYVAL colour as integer = -1)
DECLARE FUNCTION updatepagesize (BYVAL page as integer) as integer
DECLARE SUB unlockresolution (BYVAL min_w as integer = -1, BYVAL min_h as integer = -1)
DECLARE SUB setresolution (BYVAL w as integer, BYVAL h as integer)
DECLARE SUB resetresolution ()
DECLARE SUB setvispage (BYVAL page as integer)
DECLARE SUB setpal (pal() as RGBcolor)
DECLARE SUB fadeto (BYVAL red as integer, BYVAL green as integer, BYVAL blue as integer)
DECLARE SUB fadetopal (pal() as RGBcolor)

DECLARE FUNCTION frame_to_tileset(BYVAL spr as frame ptr) as frame ptr
DECLARE FUNCTION tileset_load(BYVAL num as integer) as Frame ptr

DECLARE FUNCTION readblock (map as TileMap, BYVAL x as integer, BYVAL y as integer) as integer
DECLARE SUB writeblock (map as TileMap, BYVAL x as integer, BYVAL y as integer, BYVAL v as integer)

DECLARE SUB drawmap OVERLOAD (tmap as TileMap, BYVAL x as integer, BYVAL y as integer, BYVAL tileset as TilesetData ptr, BYVAL p as integer, BYVAL trans as integer = 0, BYVAL overheadmode as integer = 0, BYVAL pmapptr as TileMap ptr = NULL, BYVAL ystart as integer = 0, BYVAL yheight as integer = -1)
DECLARE SUB drawmap OVERLOAD (tmap as TileMap, BYVAL x as integer, BYVAL y as integer, BYVAL tilesetsprite as Frame ptr, BYVAL p as integer, BYVAL trans as integer = 0, BYVAL overheadmode as integer = 0, BYVAL pmapptr as TileMap ptr = NULL, BYVAL ystart as integer = 0, BYVAL yheight as integer = -1, BYVAL largetileset as integer = NO)
DECLARE SUB drawmap OVERLOAD (tmap as TileMap, BYVAL x as integer, BYVAL y as integer, BYVAL tilesetsprite as Frame ptr, BYVAL dest as Frame ptr, BYVAL trans as integer = 0, BYVAL overheadmode as integer = 0, BYVAL pmapptr as TileMap ptr = NULL, BYVAL largetileset as integer = NO)

DECLARE SUB setanim (BYVAL cycle1 as integer, BYVAL cycle2 as integer)
DECLARE SUB setoutside (BYVAL defaulttile as integer)

'--box drawing
DECLARE SUB drawbox OVERLOAD (BYVAL x as integer, BYVAL y as integer, BYVAL w as integer, BYVAL h as integer, BYVAL col as integer, BYVAL thick as integer = 1, BYVAL p as integer)
DECLARE SUB drawbox OVERLOAD (BYVAL dest as Frame ptr, BYVAL x as integer, BYVAL y as integer, BYVAL w as integer, BYVAL h as integer, BYVAL col as integer, BYVAL thick as integer = 1)
DECLARE SUB rectangle OVERLOAD (BYVAL x as integer, BYVAL y as integer, BYVAL w as integer, BYVAL h as integer, BYVAL c as integer, BYVAL p as integer)
DECLARE SUB rectangle OVERLOAD (BYVAL fr as Frame Ptr, BYVAL x as integer, BYVAL y as integer, BYVAL w as integer, BYVAL h as integer, BYVAL c as integer)
DECLARE SUB fuzzyrect OVERLOAD (BYVAL x as integer, BYVAL y as integer, BYVAL w as integer, BYVAL h as integer, BYVAL c as integer, BYVAL p as integer, BYVAL fuzzfactor as integer = 50)
DECLARE SUB fuzzyrect OVERLOAD (BYVAL fr as Frame Ptr, BYVAL x as integer, BYVAL y as integer, BYVAL w as integer, BYVAL h as integer, BYVAL c as integer, BYVAL fuzzfactor as integer = 50)

'NOTE: clipping values are global.
DECLARE SUB setclip OVERLOAD (BYVAL l as integer = 0, BYVAL t as integer = 0, BYVAL r as integer = 9999, BYVAL b as integer = 9999, BYVAL fr as Frame ptr = 0)
DECLARE SUB setclip (BYVAL l as integer = 0, BYVAL t as integer = 0, BYVAL r as integer = 9999, BYVAL b as integer = 9999, BYVAL page as integer)
DECLARE SUB shrinkclip(byval l as integer = 0, byval t as integer = 0, byval r as integer = 9999, byval b as integer = 9999, byval fr as Frame ptr)
DECLARE SUB drawspritex (pic() as integer, BYVAL picoff as integer, pal() as integer, BYVAL po as integer, BYVAL x as integer, BYVAL y as integer, BYVAL page as integer, byval scale as integer=1, BYVAL trans as integer = -1)
DECLARE SUB drawsprite (pic() as integer, BYVAL picoff as integer, pal() as integer, BYVAL po as integer, BYVAL x as integer, BYVAL y as integer, BYVAL page as integer, BYVAL trans as integer = -1)
DECLARE SUB wardsprite (pic() as integer, BYVAL picoff as integer, pal() as integer, BYVAL po as integer, BYVAL x as integer, BYVAL y as integer, BYVAL page as integer, BYVAL trans as integer = -1)
DECLARE SUB getsprite (pic() as integer, BYVAL picoff as integer, BYVAL x as integer, BYVAL y as integer, BYVAL w as integer, BYVAL h as integer, BYVAL page as integer)
DECLARE SUB stosprite (pic() as integer, BYVAL picoff as integer, BYVAL x as integer, BYVAL y as integer, BYVAL page as integer)
DECLARE SUB loadsprite (pic() as integer, BYVAL picoff as integer, BYVAL x as integer, BYVAL y as integer, BYVAL w as integer, BYVAL h as integer, BYVAL page as integer)
DECLARE SUB bigsprite  (pic() as integer, pal() as integer, BYVAL p as integer, BYVAL x as integer, BYVAL y as integer, BYVAL page as integer, BYVAL trans as integer = -1)
DECLARE SUB hugesprite (pic() as integer, pal() as integer, BYVAL p as integer, BYVAL x as integer, BYVAL y as integer, BYVAL page as integer, BYVAL trans as integer = -1)
DECLARE SUB putpixel OVERLOAD (BYVAL spr as Frame ptr, BYVAL x as integer, BYVAL y as integer, BYVAL c as integer)
DECLARE SUB putpixel OVERLOAD (BYVAL x as integer, BYVAL y as integer, BYVAL c as integer, BYVAL p as integer)
DECLARE FUNCTION readpixel OVERLOAD (BYVAL spr as Frame ptr, BYVAL x as integer, BYVAL y as integer) as integer
DECLARE FUNCTION readpixel OVERLOAD (BYVAL x as integer, BYVAL y as integer, BYVAL p as integer) as integer
DECLARE SUB drawline OVERLOAD (BYVAL dest as Frame ptr, BYVAL x1 as integer, BYVAL y1 as integer, BYVAL x2 as integer, BYVAL y2 as integer, BYVAL c as integer)
DECLARE SUB drawline OVERLOAD (BYVAL x1 as integer, BYVAL y1 as integer, BYVAL x2 as integer, BYVAL y2 as integer, BYVAL c as integer, BYVAL p as integer)
DECLARE SUB paintat (BYVAL dest as Frame ptr, BYVAL x as integer, BYVAL y as integer, BYVAL c as integer)
DECLARE SUB ellipse (BYVAL fr as Frame ptr, BYVAL x as double, BYVAL y as double, BYVAL radius as double, BYVAL c as integer, BYVAL semiminor as double = 0.0, BYVAL angle as double = 0.0)
DECLARE SUB replacecolor (BYVAL fr as Frame ptr, BYVAL c_old as integer, BYVAL c_new as integer, BYVAL x as integer = -1, BYVAL y as integer = -1, BYVAL w as integer = -1, BYVAL h as integer = -1)
DECLARE SUB storemxs (fil as string, BYVAL record as integer, BYVAL fr as Frame ptr)
DECLARE FUNCTION loadmxs (fil as string, BYVAL record as integer, BYVAL dest as Frame ptr = 0) as Frame ptr

DECLARE SUB setwait (BYVAL t as integer, BYVAL flagt as integer = 0)
DECLARE FUNCTION dowait () as integer

DECLARE SUB printstr OVERLOAD (BYVAL dest as Frame ptr, s as string, BYVAL startx as integer, BYVAL y as integer, BYVAL startfont as Font ptr, BYVAL pal as Palette16 ptr, BYVAL withtags as integer)
DECLARE SUB printstr OVERLOAD (s as string, BYVAL x as integer, BYVAL y as integer, BYVAL p as integer, BYVAL withtags as integer = NO)
DECLARE SUB edgeprint (s as string, BYVAL x as integer, BYVAL y as integer, BYVAL c as integer, BYVAL p as integer, BYVAL withtags as integer = NO)
DECLARE SUB textcolor (BYVAL f as integer, BYVAL b as integer)
DECLARE SUB setfont (f() as integer)

DECLARE SUB storeset (fil as string, BYVAL i as integer, BYVAL l as integer)
DECLARE SUB loadset (fil as string, BYVAL i as integer, BYVAL l as integer)
DECLARE SUB setpicstuf (buf() as integer, BYVAL b as integer, BYVAL p as integer)

DECLARE SUB setupmusic
DECLARE SUB closemusic ()
DECLARE SUB loadsong (f as string)
DECLARE SUB pausesong ()
DECLARE SUB resumesong ()
DECLARE FUNCTION getfmvol () as integer
DECLARE SUB setfmvol (BYVAL vol as integer)

DECLARE SUB screenshot (f as string)
DECLARE SUB frame_export_bmp4 (f$, byval fr as Frame Ptr, maspal() as RGBcolor, byval pal as Palette16 ptr)
DECLARE SUB frame_export_bmp8 (f$, byval fr as Frame Ptr, maspal() as RGBcolor)
DECLARE FUNCTION frame_import_bmp24(bmp as string, pal() as RGBcolor) as Frame ptr
DECLARE FUNCTION frame_import_bmp_raw(bmp as string) as Frame ptr
DECLARE SUB bitmap2pal (bmp as string, pal() as RGBcolor)
DECLARE FUNCTION loadbmppal (f as string, pal() as RGBcolor) as integer
DECLARE SUB convertbmppal (f as string, mpal() as RGBcolor, pal() as integer, BYVAL o as integer)
DECLARE FUNCTION nearcolor(pal() as RGBcolor, byval red as ubyte, byval green as ubyte, byval blue as ubyte) as ubyte
DECLARE FUNCTION bmpinfo (f as string, byref dat as BitmapInfoHeader) as integer

DECLARE FUNCTION isawav(fi as string) as integer

DECLARE FUNCTION keyval (BYVAL a as integer, BYVAL rwait as integer = 0, BYVAL rrate as integer = 0) as integer
DECLARE FUNCTION getkey () as integer
DECLARE FUNCTION getinputtext () as string
DECLARE FUNCTION waitforanykey (modkeys as integer = -1) as integer
DECLARE SUB setkeyrepeat (rwait as integer = 8, rrate as integer = 1)
DECLARE SUB setkeys ()
DECLARE SUB clearkey (byval k as integer)
#DEFINE slowkey(key, fraction) (keyval((key), (fraction), (fraction)) > 1)

DECLARE FUNCTION havemouse () as integer
DECLARE SUB hidemousecursor ()
DECLARE SUB unhidemousecursor ()
DECLARE FUNCTION readmouse () as MouseInfo
DECLARE SUB movemouse (BYVAL x as integer, BYVAL y as integer)
DECLARE SUB mouserect (BYVAL xmin as integer, BYVAL xmax as integer, BYVAL ymin as integer, BYVAL ymax as integer)

DECLARE FUNCTION readjoy OVERLOAD (joybuf() as integer, BYVAL jnum as integer) as integer
DECLARE FUNCTION readjoy (BYVAL joynum as integer, BYREF buttons as integer, BYREF x as integer, BYREF y as integer) as integer

DECLARE SUB resetsfx ()
DECLARE SUB playsfx (BYVAL num as integer, BYVAL l as integer=0) 'l is loop count. -1 for infinite loop
DECLARE SUB stopsfx (BYVAL num as integer)
DECLARE SUB pausesfx (BYVAL num as integer)
DECLARE SUB freesfx (BYVAL num as integer) ' only used by custom's importing interface
DECLARE FUNCTION sfxisplaying (BYVAL num as integer) as integer
DECLARE FUNCTION getmusictype (file as string) as integer
'DECLARE SUB getsfxvol (BYVAL num as integer)
'DECLARE SUB setsfxvol (BYVAL num as integer, BYVAL vol as integer)

'DECLARE FUNCTION getsoundvol () as integer
'DECLARE SUB setsoundvol (BYVAL vol)

'new sprite functions
declare function frame_new(byval w as integer, byval h as integer, byval frames as integer = 1, byval clr as integer = NO, byval wantmask as integer = NO) as Frame ptr
declare function frame_new_view(byval spr as Frame ptr, byval x as integer, byval y as integer, byval w as integer, byval h as integer) as Frame ptr
declare function frame_new_from_buffer(pic() as integer, BYVAL picoff as integer) as Frame ptr
declare function frame_load overload (byval ptno as integer, byval rec as integer) as frame ptr
declare function frame_load(as string, byval as integer, byval as integer , byval as integer, byval as integer) as frame ptr
declare function frame_reference(byval p as frame ptr) as frame ptr
declare sub frame_unload(byval p as frame ptr ptr)
declare sub frame_draw overload (byval src as frame ptr, Byval pal as Palette16 ptr = NULL, Byval x as integer, Byval y as integer, Byval scale as integer = 1, Byval trans as integer = -1, byval page as integer)
declare sub frame_draw(byval src as Frame ptr, Byval pal as Palette16 ptr = NULL, Byval x as integer, Byval y as integer, Byval scale as integer = 1, Byval trans as integer = -1, byval dest as Frame ptr)
declare function frame_dissolved(byval spr as frame ptr, byval tlength as integer, byval t as integer, byval style as integer) as frame ptr
declare sub frame_flip_horiz(byval spr as frame ptr)
declare sub frame_flip_vert(byval spr as frame ptr)
declare function frame_rotated_90(byval spr as Frame ptr) as Frame ptr
declare function frame_rotated_270(byval spr as Frame ptr) as Frame ptr
declare function frame_duplicate(byval p as frame ptr, byval clr as integer = 0, byval addmask as integer = 0) as frame ptr
declare sub frame_clear(byval spr as frame ptr, byval colour as integer = 0)
declare sub sprite_empty_cache()
declare sub tileset_empty_cache()
declare function frame_is_valid(byval p as frame ptr) as integer
declare sub sprite_debug_cache()
declare function frame_describe(byval p as frame ptr) as string

declare function palette16_new() as palette16 ptr
declare function palette16_new_from_buffer(pal() as integer, BYVAL po as integer) as Palette16 ptr
declare function palette16_load overload (byval num as integer, byval autotype as integer = 0, byval spr as integer = 0) as palette16 ptr
declare function palette16_load(fil as string, byval num as integer, byval autotype as integer = 0, byval spr as integer = 0) as palette16 ptr
declare sub palette16_unload(byval p as palette16 ptr ptr)
declare sub palette16_empty_cache()
declare sub palette16_update_cache(fil as string, byval num as integer)


'globals
extern vpages() as Frame ptr
extern vpagesp as Frame ptr ptr
extern key2text(3,53) as string*1

#ENDIF
