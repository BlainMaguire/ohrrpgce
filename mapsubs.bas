'OHRRPGCE CUSTOM - Miscellaneous unsorted routines
'(C) Copyright 1997-2005 James Paige and Hamster Republic Productions
'Please read LICENSE.txt for GPL License details and disclaimer of liability
'See README.txt for code docs and apologies for crappyness of this code ;)
'
'$DYNAMIC
DEFINT A-Z
'basic subs and functions
DECLARE FUNCTION addmaphow% (general%())
DECLARE FUNCTION filenum$ (n%)
DECLARE FUNCTION animadjust% (tilenum%, tastuf%())
DECLARE SUB setbinsize (id%, size%)
DECLARE SUB flusharray (array%(), size%, value%)
DECLARE FUNCTION readattackname$ (index%)
DECLARE SUB writeglobalstring (index%, s$, maxlen%)
DECLARE FUNCTION readglobalstring$ (index%, default$, maxlen%)
DECLARE SUB importbmp (f$, cap$, count%, general%(), master%())
DECLARE SUB getpal16 (array%(), aoffset%, foffset%)
DECLARE SUB upgrade (general%(), font%())
DECLARE SUB loadpasdefaults (array%(), tilesetnum%)
DECLARE SUB textxbload (f$, array%(), e$)
DECLARE SUB fixorder (f$)
DECLARE FUNCTION unlumpone% (lumpfile$, onelump$, asfile$)
DECLARE SUB standardmenu (menu$(), size%, vis%, ptr%, top%, x%, y%, page%, edge%)
DECLARE SUB vehicles (general%())
DECLARE SUB verifyrpg (game$)
DECLARE SUB xbload (f$, array%(), e$)
DECLARE FUNCTION scriptname$ (num%, f$, gen%())
DECLARE FUNCTION getmapname$ (m%)
DECLARE FUNCTION numbertail$ (s$)
DECLARE SUB cropafter (index%, limit%, flushafter%, lump$, bytes%, prompt%)
DECLARE SUB scriptman (gamedir$, general(), song$())
DECLARE FUNCTION exclude$ (s$, x$)
DECLARE FUNCTION exclusive$ (s$, x$)
DECLARE SUB writescatter (s$, lhold%, array%(), start%)
DECLARE SUB readscatter (s$, lhold%, array%(), start%)
DECLARE SUB fontedit (font%(), gamedir$)
DECLARE SUB savetanim (n%, tastuf%())
DECLARE SUB loadtanim (n%, tastuf%())
DECLARE SUB cycletile (cycle%(), tastuf%(), ptr%(), skip%())
DECLARE SUB testanimpattern (tastuf%(), taset%)
DECLARE FUNCTION usemenu (ptr%, top%, first%, last%, size%)
DECLARE FUNCTION heroname$ (num%, cond%(), a%())
DECLARE FUNCTION bound% (n%, lowest%, highest%)
DECLARE FUNCTION onoroff$ (n%)
DECLARE FUNCTION intstr$ (n%)
DECLARE FUNCTION lmnemonic$ (index%)
DECLARE SUB smnemonic (tagname$, index%)
DECLARE SUB tagnames (general%())
DECLARE SUB sizemar (array%(), wide%, high%, tempx%, tempy%, tempw%, temph%, yout%, page%)
DECLARE SUB drawmini (high%, wide%, cursor%(), page%, tastuf%())
DECLARE FUNCTION rotascii$ (s$, o%)
DECLARE SUB debug (s$)
DECLARE SUB mapmaker (font%(), master%(), map%(), pass%(), emap%(), general%(), doors%(), link%(), npc%(), npcstat%(), song$(), npc$(), unpc%(), lnpc%())
DECLARE SUB npcdef (npc%(), ptr%, general%(), npc$(), unpc%(), lnpc%())
DECLARE SUB bitset (array%(), wof%, last%, name$())
DECLARE SUB sprite (xw%, yw%, sets%, perset%, soff%, foff%, atatime%, info$(), size%, zoom%, file$, master%(), font%())
DECLARE FUNCTION needaddset (ptr%, check%, what$)
DECLARE SUB shopdata (general%())
DECLARE FUNCTION intgrabber (n%, min%, max%, less%, more%)
DECLARE SUB strgrabber (s$, maxl%)
DECLARE SUB importsong (song$(), general%(), master())
DECLARE SUB edgeprint (s$, x%, y%, c%, p%)
DECLARE SUB gendata (general%(), song$())
DECLARE SUB itemdata (general%())
DECLARE SUB formation (general%(), song$())
DECLARE SUB enemydata (general%())
DECLARE SUB herodata (general%())
DECLARE SUB attackdata (atkdat$(), atklim%(), general%())
DECLARE SUB getnames (stat$(), max%)
DECLARE SUB statname (general%())
DECLARE SUB textage (general%(), song$())
DECLARE FUNCTION sublist% (num%, s$())
DECLARE SUB maptile (master%(), font(), general())
DECLARE FUNCTION small% (n1%, n2%)
DECLARE FUNCTION large% (n1%, n2%)
DECLARE FUNCTION loopvar% (var%, min%, max%, inc%)
'assembly subs and functions
DECLARE SUB setmodeX ()
DECLARE SUB restoremode ()
DECLARE SUB setpicstuf (buf(), BYVAL b, BYVAL p)
DECLARE SUB loadset (fil$, BYVAL i, BYVAL l)
DECLARE SUB storeset (fil$, BYVAL i, BYVAL l)
DECLARE SUB copypage (BYVAL page1, BYVAL page2)
DECLARE SUB setvispage (BYVAL page)
DECLARE SUB drawsprite (pic(), BYVAL picoff, pal(), BYVAL po, BYVAL x, BYVAL y, BYVAL page)
DECLARE SUB wardsprite (pic(), BYVAL picoff, pal(), BYVAL po, BYVAL x, BYVAL y, BYVAL page)
DECLARE SUB getsprite (pic(), BYVAL picoff, BYVAL x, BYVAL y, BYVAL w, BYVAL h, BYVAL page)
DECLARE SUB loadsprite (pic(), BYVAL picoff, BYVAL x, BYVAL y, BYVAL w, BYVAL h, BYVAL page)
DECLARE SUB stosprite (pic(), BYVAL picoff, BYVAL x, BYVAL y, BYVAL page)
DECLARE SUB bigsprite (pic(), pal(), BYVAL p, BYVAL x, BYVAL y, BYVAL page)
DECLARE SUB hugesprite (pic(), pal(), BYVAL p, BYVAL x, BYVAL y, BYVAL page)
DECLARE SUB setdiskpages (buf(), BYVAL h, BYVAL l)
DECLARE SUB loadpage (fil$, BYVAL i, BYVAL p)
DECLARE SUB storepage (fil$, BYVAL i, BYVAL p)
DECLARE SUB bitmap2page (temp(), bmp$, BYVAL p)
DECLARE SUB loadbmp (f$, BYVAL x, BYVAL y, buf(), BYVAL p)
DECLARE SUB getbmppal (f$, mpal(), pal(), BYVAL o)
DECLARE FUNCTION bmpinfo (f$, dat())
DECLARE SUB setpal (pal())
DECLARE SUB clearpage (BYVAL page)
DECLARE SUB setkeys ()
DECLARE SUB setfont (f())
DECLARE SUB printstr (s$, BYVAL x, BYVAL y, BYVAL p)
DECLARE SUB textcolor (BYVAL f, BYVAL b)
DECLARE SUB setitup (fil$, buff(), tbuff(), BYVAL p)
DECLARE FUNCTION resetdsp
DECLARE SUB playsnd (BYVAL n, BYVAL f)
DECLARE SUB closefile
DECLARE SUB fuzzyrect (BYVAL x, BYVAL y, BYVAL w, BYVAL h, BYVAL c, BYVAL p)
DECLARE SUB rectangle (BYVAL x, BYVAL y, BYVAL w, BYVAL h, BYVAL c, BYVAL p)
DECLARE SUB drawline (BYVAL x1, BYVAL y1, BYVAL x2, BYVAL y2, BYVAL c, BYVAL p)
DECLARE SUB paintat (BYVAL x, BYVAL y, BYVAL c, BYVAL page, buf(), BYVAL max)
DECLARE SUB putpixel (BYVAL x%, BYVAL y%, BYVAL col%, BYVAL page%)
DECLARE SUB setwait (b(), BYVAL t)
DECLARE SUB dowait ()
DECLARE SUB setmapdata (array(), pas(), BYVAL t, BYVAL b)
DECLARE SUB setmapblock (BYVAL x, BYVAL y, BYVAL v)
DECLARE FUNCTION readmapblock (BYVAL x, BYVAL y)
DECLARE SUB drawmap (BYVAL x, BYVAL y, BYVAL t, BYVAL p)
DECLARE SUB setanim (BYVAL cycle1, BYVAL cycle2)
DECLARE FUNCTION readpixel (BYVAL x, BYVAL y, BYVAL p)
DECLARE SUB setbit (b(), BYVAL w, BYVAL b, BYVAL v)
DECLARE FUNCTION readbit (b(), BYVAL w, BYVAL b)
DECLARE FUNCTION Keyseg ()
DECLARE FUNCTION keyoff ()
DECLARE FUNCTION keyval (BYVAL a)
DECLARE FUNCTION getkey ()
DECLARE SUB copyfile (s$, d$, buf())
DECLARE SUB findfiles (fmask$, BYVAL attrib, outfile$, buf())
DECLARE SUB setupmusic (mbuf())
DECLARE SUB closemusic ()
DECLARE SUB stopsong ()
DECLARE SUB resumesong ()
DECLARE SUB resetfm ()
DECLARE SUB loadsong (f$)
'DECLARE SUB fademusic (BYVAL vol)
DECLARE FUNCTION getfmvol ()
DECLARE SUB setfmvol (BYVAL vol)
DECLARE FUNCTION setmouse (mbuf())
DECLARE SUB readmouse (mbuf())
DECLARE SUB movemouse (BYVAL x, BYVAL y)
DECLARE SUB array2str (arr(), BYVAL o, s$)
DECLARE SUB str2array (s$, arr(), BYVAL o)
DECLARE FUNCTION isfile (n$)
DECLARE FUNCTION LongNameLength (filename$)
'DECLARE FUNCTION ShortNameLength (filename$)

'$INCLUDE: 'cglobals.bi'

REM $STATIC

FUNCTION addmaphow (general())
'--Return values
'  -2  =Cancel
'  -1  =New blank
'  >=0 =Copy


DIM temp$(2)

maptocopy = 0
ptr = 0

GOSUB addmaphowmenu
setkeys
DO
  setwait timing(), 100
  setkeys
  tog = tog XOR 1
  IF keyval(1) > 1 THEN
    '--return cancel
    addmaphow = -2
    EXIT DO
  END IF
  IF usemenu(ptr, 0, 0, 2, 22) THEN
    GOSUB addmaphowmenu
  END IF
  IF ptr = 2 THEN
    IF intgrabber(maptocopy, 0, general(0), 75, 77) THEN
      GOSUB addmaphowmenu
    END IF
  END IF
  IF keyval(28) > 1 OR keyval(56) > 1 THEN
    SELECT CASE ptr
      CASE 0 ' cancel
        addmaphow = -2
      CASE 1 ' blank
        addmaphow = -1
      CASE 2 ' copy
        addmaphow = maptocopy
    END SELECT
    EXIT DO
  END IF
  standardmenu temp$(), 2, 22, ptr, 0, 0, 0, dpage, 0
  SWAP vpage, dpage
  setvispage vpage
  clearpage dpage
  dowait
LOOP
EXIT FUNCTION

addmaphowmenu:
temp$(0) = "Cancel"
temp$(1) = "New Blank Map"
temp$(2) = "Copy of map" + STR$(maptocopy) + " " + getmapname$(maptocopy)
RETURN

END FUNCTION

FUNCTION animadjust (tilenum, tastuf())
  'given a tile number and the tile-animation data,
  'adjusts to make sure the tile is non-animated
  pic = tilenum
  IF pic >= 208 THEN pic = (pic - 208) + tastuf(20)
  IF pic >= 160 THEN pic = (pic - 160) + tastuf(0)
  animadjust = pic
END FUNCTION

SUB mapmaker (font(), master(), map(), pass(), emap(), general(), doors(), link(), npc(), npcstat(), song$(), npc$(), unpc(), lnpc())
DIM menubar(82), cursor(600), mode$(12), list$(12), temp$(12), ulim(4), llim(4), menu$(-1 TO 5), topmenu$(24), gmap(20), gd$(-1 TO 20), gdmax(20), gdmin(20), destdoor(300), tastuf(40), cycle(1), cycptr(1), cycskip(1), sampmap(2), cursorpal(8),  _
defaults(160), pal16(288), gmapscr$(5), gmapscrof(5)

textcolor 15, 0

temp$ = ""
FOR i = 0 TO 15: temp$ = temp$ + CHR$(i): NEXT i
str2array temp$, cursorpal(), 0

'--create cursor
clearpage 2
rectangle 0, 0, 20, 20, 15, 2
rectangle 1, 1, 18, 18, 0, 2
rectangle 2, 2, 16, 16, 7, 2
rectangle 3, 3, 14, 14, 0, 2
getsprite cursor(), 200, 0, 0, 20, 20, 2
clearpage 2
rectangle 0, 0, 20, 20, 15, 2
rectangle 1, 1, 18, 18, 0, 2
rectangle 3, 3, 14, 14, 7, 2
rectangle 4, 4, 12, 12, 0, 2
getsprite cursor(), 400, 0, 0, 20, 20, 2

mode$(0) = "Picture Mode"
mode$(1) = "Passability Mode"
mode$(2) = "Door Placement Mode"
mode$(3) = "NPC Placement Mode"
mode$(4) = "Foe Mapping Mode"
menubar(0) = 160: menubar(1) = 1
sampmap(0) = 1
sampmap(1) = 1
GOSUB loadmenu

maptop = 0
GOSUB maketopmenu
setkeys
DO
setwait timing(), 120
setkeys
IF keyval(1) > 1 THEN GOTO donemapping
oldtop = maptop
dummy = usemenu(ptr, maptop, 0, 2 + general(0), 24)
IF oldtop <> maptop THEN GOSUB maketopmenu
IF keyval(57) > 1 OR keyval(28) > 1 THEN
  IF ptr = 0 THEN GOTO donemapping
  IF ptr > 0 AND ptr <= general(0) + 1 THEN
    '--silly backcompat ptr adjustment
    ptr = ptr - 1
    GOSUB loadmap
    GOSUB whattodo
    ptr = ptr + 1
    GOSUB maketopmenu
  END IF
  IF ptr = general(0) + 2 THEN GOSUB addmap: GOSUB maketopmenu
END IF
tog = tog XOR 1
FOR i = 0 TO 24
 textcolor 7, 0
 IF ptr = maptop + i THEN textcolor 14 + tog, 0
 printstr topmenu$(i), 0, i * 8, dpage
NEXT i
SWAP vpage, dpage
setvispage vpage
clearpage dpage
dowait
LOOP

maketopmenu:
 FOR i = 0 TO 24
   SELECT CASE maptop + i
     CASE 0
       topmenu$(i) = "Return to Main Menu"
     CASE 1 TO general(0) + 1
       topmenu$(i) = "Map " + filenum$((maptop + i) - 1) + ": " + getmapname$((maptop + i) - 1)
     CASE general(0) + 2
       topmenu$(i) = "Add a New Map"
     CASE ELSE
       topmenu$(i) = ""
   END SELECT
 NEXT i
RETURN

whattodo:
x = 0: y = 0: mapx = 0: mapy = 0
list$(0) = "Return to Map Menu"
list$(1) = "Resize Map..."
list$(2) = "Edit NPCs..."
list$(3) = "Edit General Map Data..."
list$(4) = "Erase Map Data"
list$(5) = "Link Doors..."
list$(6) = "Edit Tilemap..."
list$(7) = "Edit Wallmap..."
list$(8) = "Place Doors..."
list$(9) = "Place NPCs..."
list$(10) = "Edit Foemap..."
list$(11) = "Re-load Default Passability"
list$(12) = "Map name:"
setkeys
DO
setwait timing(), 100
setkeys
tog = tog XOR 1
IF keyval(1) > 1 THEN GOSUB savemap: RETURN
dummy = usemenu(csr, 0, 0, 12, 24)
IF keyval(28) > 1 OR keyval(57) > 1 THEN
 IF csr = 0 THEN GOSUB savemap: RETURN
 IF csr = 1 THEN GOSUB sizemap
 IF csr = 2 THEN
  npcdef npcstat(), ptr, general(), npc$(), unpc(), lnpc()
  'xbload game$ + ".n" + filenum$(ptr), npcstat(), "NPCstat lump has dissapeared!"
 END IF
 IF csr = 3 THEN
  GOSUB gmapdata
  loadpage game$ + ".til" + CHR$(0), gmap(0), 3
 END IF
 IF csr = 4 THEN GOSUB delmap
 IF csr = 5 THEN GOSUB linkdoor
 IF csr > 5 AND csr < 11 THEN editmode = csr - 6: GOSUB mapping
 IF csr = 11 THEN
   '--reload default passability
   temp$(0) = "No, Nevermind. No passability changes"
   temp$(1) = "Set default passability for whole map"
   IF sublist(1, temp$()) = 1 THEN
     FOR tx = 0 TO pass(0) - 1
       FOR ty = 0 TO pass(1) - 1
         setmapdata map(), pass(), 0, 0
         n = defaults(animadjust(readmapblock(tx, ty), tastuf()))
         setmapdata pass(), pass(), 0, 0
         setmapblock tx, ty, n
       NEXT ty
     NEXT tx
   END IF
 END IF
END IF
IF csr = 12 THEN strgrabber mapname$, 39
list$(12) = "Map name:" + mapname$
IF LEN(list$(12)) > 40 THEN list$(12) = mapname$

standardmenu list$(), 12, 12, csr, 0, 0, 0, dpage, 0

SWAP vpage, dpage
setvispage vpage
clearpage dpage
dowait
LOOP
                            
gmapdata:
gmapmax = 16
gd = 0
gd$(-1) = "Previous Menu"
gd$(0) = "Map Tileset:"
gd$(1) = "Ambient Music:"
gd$(2) = "Minimap Available:"
gd$(3) = "Save Anywhere:"
gd$(4) = "Display Map Name:"
gd$(5) = "Map Edge Mode:"
gd$(6) = "Default Edge Tile:"
gd$(7) = "Autorun Script: "
gd$(8) = "Script Argument:"
gd$(9) = "Harm-Tile Damage:"
gd$(10) = "Harm-Tile Flash:"
gd$(11) = "Foot Offset:"
gd$(12) = "After-Battle Script:"
gd$(13) = "Instead-of-Battle Script:"
gd$(14) = "Each-Step Script:"
gd$(15) = "On-Keypress Script:"
gd$(16) = "Walkabout Layering:"
gdmax(0) = general(33):  gdmin(0) = 0
gdmax(1) = 100:          gdmin(1) = 0
gdmax(2) = 1:            gdmin(2) = 0
gdmax(3) = 1:            gdmin(3) = 0
gdmax(4) = 255:          gdmin(4) = 0
gdmax(5) = 2:            gdmin(5) = 0
gdmax(6) = 255:          gdmin(6) = 0
gdmax(7) = general(43):  gdmin(7) = 0
gdmax(8) = 32767:        gdmin(8) = -32767
gdmax(9) = 32767:        gdmin(9) = -32767
gdmax(10) = 255:         gdmin(10) = 0
gdmax(11) = 20:          gdmin(11) = -20
gdmax(12) = general(43): gdmin(12) = 0
gdmax(13) = general(43): gdmin(13) = 0
gdmax(14) = general(43): gdmin(14) = 0
gdmax(15) = general(43): gdmin(15) = 0
gdmax(16) = 1:           gdmin(16) = 0

gmapscrof(0) = 7
gmapscrof(1) = 12
gmapscrof(2) = 13
gmapscrof(3) = 14
gmapscrof(4) = 15

IF gmap(16) > 1 THEN gmap(16) = 0
FOR i = 0 TO gmapmax
 gmap(i) = bound(gmap(i), gdmin(i), gdmax(i))
NEXT i
GOSUB setgmapscriptstr
setkeys
DO
setwait timing(), 120
setkeys
tog = tog XOR 1
IF keyval(1) > 1 THEN RETURN
dummy = usemenu(gd, 0, -1, gmapmax, 24)
IF gd = -1 THEN
 IF keyval(57) > 1 OR keyval(28) > 1 THEN RETURN
END IF
IF gd > -1 THEN
 IF intgrabber(gmap(gd), gdmin(gd), gdmax(gd), 75, 77) THEN
   GOSUB setgmapscriptstr
 END IF
END IF
scri = 0
FOR i = -1 TO gmapmax
 temp$ = ""
 SELECT CASE i
 CASE 0, 9
  temp$ = STR$(gmap(i))
 CASE 1
  IF gmap(1) = 0 THEN temp$ = " -none-" ELSE temp$ = STR$(gmap(1) - 1) + " " + song$(gmap(1) - 1)
 CASE 2, 3
  IF gmap(i) = 0 THEN temp$ = " NO" ELSE temp$ = " YES"
 CASE 4
  IF gmap(i) = 0 THEN temp$ = " NO" ELSE temp$ = STR$(gmap(i)) + " ticks"
 CASE 5
  SELECT CASE gmap(i)
  CASE 0
   temp$ = " Crop"
  CASE 1
   temp$ = " Wrap"
  CASE 2
   temp$ = " use default edge tile"
  END SELECT
 CASE 6
  IF gmap(5) = 2 THEN
   temp$ = STR$(gmap(i))
  ELSE
   temp$ = " N/A"
  END IF
 CASE 7, 12 TO 15
  temp$ = gmapscr$(scri)
  scri = scri + 1
 CASE 8
  IF gmap(7) = 0 THEN
   temp$ = " N/A"
  ELSE
   temp$ = STR$(gmap(i))
  END IF
 CASE 10
  IF gmap(i) = 0 THEN
   temp$ = " none"
  ELSE
   temp$ = STR$(gmap(i))
  END IF
 CASE 11
  SELECT CASE gmap(i)
  CASE 0
   temp$ = " none"
  CASE IS < 0
   temp$ = " up" + STR$(ABS(gmap(i))) + " pixels"
  CASE IS > 0
   temp$ = " down" + STR$(gmap(i)) + " pixels"
  END SELECT
 CASE 16
  IF gmap(i) = 1 THEN
    temp$ = " NPCs over Heroes"
  ELSE
    temp$ = " Heroes over NPCs"
  END IF
 END SELECT
 textcolor 7, 0
 IF i = gd THEN textcolor 14 + tog, 0
 printstr gd$(i) + temp$, 0, 8 + (8 * i), dpage
 IF i = 10 THEN rectangle 4 + (8 * LEN(gd$(i) + temp$)), 8 + (8 * i), 8, 8, gmap(i), dpage
NEXT i
IF gmap(5) = 2 THEN
 '--show default edge tile
 setmapdata sampmap(), sampmap(), 180, 0
 setmapblock 0, 0, gmap(6)
 drawmap 0, -180, 0, dpage
 rectangle 20, 180, 300, 20, 240, dpage
END IF
SWAP vpage, dpage
setvispage vpage
clearpage dpage
dowait
LOOP

setgmapscriptstr:
 FOR i = 0 TO 4
  gmapscr$(i) = scriptname$(gmap(gmapscrof(i)), "plotscr.lst", general())
 NEXT i
RETURN

mapping:
clearpage 2
'--load NPC graphics--
FOR i = 0 TO 35
 setpicstuf buffer(), 1600, 2
 loadset game$ + ".pt4" + CHR$(0), npcstat(i * 15 + 0), 5 * i
 getpal16 pal16(), i, npcstat(i * 15 + 1)
NEXT i

setkeys
DO
setwait timing(), 120
setkeys
IF keyval(59) > 1 THEN
 editmode = 0
END IF
IF keyval(60) > 1 THEN
 editmode = 1
END IF
IF keyval(61) > 1 THEN
 editmode = 2
END IF
IF keyval(62) > 1 THEN
 editmode = 3
END IF
IF keyval(63) > 1 THEN
 editmode = 4
END IF
IF keyval(1) > 1 THEN RETURN
IF keyval(15) > 1 THEN tiny = tiny XOR 1
SELECT CASE editmode
'---TILEMODE------
CASE 0
 setmapdata map(), pass(), 20, 0
 IF keyval(33) > 1 AND keyval(29) > 0 THEN
  FOR i = 0 TO 14
   FOR o = 0 TO 8
    setmapblock INT(mapx / 20) + i, INT(mapy / 20) + o, pic
   NEXT o
  NEXT i
  setmapdata map(), pass(), 20, 0
 END IF
 IF keyval(41) > 1 THEN GOSUB minimap
 IF keyval(28) > 1 THEN GOSUB pickblock
 IF keyval(57) > 0 THEN
   setmapdata pass(), pass(), 20, 0
   setmapblock x, y, defaults(pic)
   setmapdata map(), pass(), 20, 0
   setmapblock x, y, pic
 END IF
 IF keyval(58) > 1 THEN 'grab tile
   pic = animadjust(readmapblock(x, y), tastuf())
   menu = small(pic, 145)
   by = INT(pic / 16): bx = pic - (by * 16)
 END IF
 FOR i = 0 TO 1
   IF keyval(2 + i) > 1 THEN
    old = readmapblock(x, y)
    IF old > 159 + (i * 48) THEN
     new = (old - (160 + (i * 48))) + tastuf(i * 20)
    ELSE
     IF old >= tastuf(i * 20) AND old < tastuf(i * 20) + 48 THEN
      new = 160 + (i * 48) + (old - tastuf(i * 20))
     END IF
    END IF
    IF keyval(29) = 0 THEN
     setmapblock x, y, new
    ELSE
     FOR tx = 0 TO map(0)
      FOR ty = 0 TO map(1)
       IF readmapblock(tx, ty) = old THEN setmapblock tx, ty, new
      NEXT ty
     NEXT tx
    END IF
   END IF
 NEXT i
 IF keyval(51) > 0 AND pic > 0 THEN
  pic = pic - 1: bx = bx - 1
  IF bx < 0 THEN bx = 15: by = by - 1
  IF pic - menu < 0 AND pic + menu > 0 THEN menu = menu - 1
 END IF
 IF keyval(52) > 0 AND pic < 159 THEN
  pic = pic + 1: bx = bx + 1
  IF bx > 15 THEN bx = 0: by = by + 1
  IF pic - menu > 14 AND menu < 159 THEN menu = menu + 1
 END IF
'---PASSMODE-------
CASE 1
 setmapdata pass(), pass(), 20, 0
 over = readmapblock(x, y)
 IF keyval(57) > 1 AND (over AND 15) = 0 THEN setmapblock x, y, 15
 IF keyval(57) > 1 AND (over AND 15) = 15 THEN setmapblock x, y, 0
 IF keyval(57) > 1 AND (over AND 15) > 0 AND (over AND 15) < 15 THEN setmapblock x, y, 0
 IF keyval(29) > 0 THEN
  IF keyval(72) > 1 THEN setmapblock x, y, (over XOR 1)
  IF keyval(77) > 1 THEN setmapblock x, y, (over XOR 2)
  IF keyval(80) > 1 THEN setmapblock x, y, (over XOR 4)
  IF keyval(75) > 1 THEN setmapblock x, y, (over XOR 8)
 END IF
 IF keyval(30) > 1 THEN setmapblock x, y, (over XOR 16) 'vehicle A
 IF keyval(48) > 1 THEN setmapblock x, y, (over XOR 32) 'vehicle B
 IF keyval(35) > 1 THEN setmapblock x, y, (over XOR 64) 'harm tile
 IF keyval(24) > 1 THEN setmapblock x, y, (over XOR 128)'overhead
'---DOORMODE-----
CASE 2
 IF keyval(57) > 1 THEN
  temp = 0
  FOR i = 0 TO 99
   IF doors(i) = x AND doors(i + 100) = y + 1 AND doors(i + 200) = 1 THEN temp = 1: doors(i + 200) = 0
  NEXT
  IF temp = 0 THEN
   temp = -1
   FOR i = 99 TO 0 STEP -1
    IF doors(i + 200) = 0 THEN temp = i
   NEXT
   IF temp >= 0 THEN doors(0 + temp) = x: doors(100 + temp) = y + 1: doors(200 + temp) = 1
  END IF
 END IF
'---NPCMODE------
CASE 3
 IF keyval(83) > 1 THEN
  FOR i = 0 TO 299
  IF npc(i + 600) > 0 THEN
   IF npc(i + 0) = x AND npc(i + 300) = y + 1 THEN npc(i + 600) = 0
  END IF
  NEXT i
 END IF
 nd = -1
 IF keyval(72) > 1 THEN nd = 0
 IF keyval(77) > 1 THEN nd = 1
 IF keyval(80) > 1 THEN nd = 2
 IF keyval(75) > 1 THEN nd = 3
 IF keyval(57) > 1 OR (keyval(29) > 0 AND nd > -1) THEN
  temp = 0
  IF nd = -1 THEN
   FOR i = 0 TO 299
   IF npc(i + 600) > 0 THEN
    IF npc(i + 0) = x AND npc(i + 300) = y + 1 THEN npc(i + 600) = 0: temp = 1
   END IF
   NEXT i
  END IF
  IF nd = -1 THEN nd = 2
  IF temp = 0 THEN
   temp = -1
   FOR i = 299 TO 0 STEP -1
   IF npc(i + 600) = 0 THEN temp = i
   NEXT i
   IF temp >= 0 THEN npc(temp + 0) = x: npc(temp + 300) = y + 1: npc(temp + 600) = nptr + 1: npc(temp + 900) = nd
  END IF
 END IF
 IF keyval(51) > 0 THEN nptr = nptr - 1: IF nptr < 0 THEN nptr = 35
 IF keyval(52) > 0 THEN nptr = nptr + 1: IF nptr > 35 THEN nptr = 0
'---FOEMODE--------
CASE 4
 IF keyval(51) > 0 THEN foe = loopvar(foe, 0, 255, -1)
 IF keyval(52) > 0 THEN foe = loopvar(foe, 0, 255, 1)
 IF keyval(57) > 0 THEN setmapdata emap(), pass(), 20, 0: setmapblock x, y, foe: setmapdata map(), pass(), 20, 0
 IF keyval(33) > 1 AND keyval(29) > 0 THEN
  setmapdata emap(), pass(), 20, 0
  FOR i = 0 TO 14
   FOR o = 0 TO 8
    setmapblock INT(mapx / 20) + i, INT(mapy / 20) + o, foe
   NEXT o
  NEXT i
  setmapdata map(), pass(), 20, 0
 END IF
 IF keyval(58) > 1 THEN foe = readmapblock(x, y): menu = pic: by = INT(pic / 15): bx = pic - (by * 16)
'--done input-modes-------
END SELECT

setmapdata map(), pass(), 20, 0

'--general purpose controls----
IF keyval(56) = 0 AND keyval(29) = 0 THEN
 IF keyval(72) > 0 THEN y = large(y - 1, 0): IF y < INT(mapy / 20) AND mapy > 0 THEN mapy = mapy - 20
 IF keyval(80) > 0 THEN y = small(y + 1, high - 1): IF y > INT(mapy / 20) + 8 AND mapy < (high * 20) - 180 THEN mapy = mapy + 20
 IF keyval(75) > 0 THEN x = large(x - 1, 0): IF x < INT(mapx / 20) AND mapx > 0 THEN mapx = mapx - 20
 IF keyval(77) > 0 THEN x = small(x + 1, wide - 1): IF x > INT(mapx / 20) + 14 AND mapx < (wide * 20) - 300 THEN mapx = mapx + 20
END IF
IF keyval(56) > 0 AND keyval(29) = 0 THEN
 IF keyval(72) > 0 AND mapy > 0 THEN mapy = mapy - 20: y = y - 1
 IF keyval(80) > 0 AND mapy < (high * 20) - 180 THEN mapy = mapy + 20: y = y + 1
 IF keyval(75) > 0 AND mapx > 0 THEN mapx = mapx - 20: x = x - 1
 IF keyval(77) > 0 AND mapx < ((wide + 1) * 20) - 320 THEN mapx = mapx + 20: x = x + 1
END IF
tog = tog XOR 1
flash = loopvar(flash, 0, 3, 1)

'--draw menubar
IF editmode = 0 THEN
 setmapdata menubar(), pass(), 0, 180
 drawmap menu * 20, 0, 0, dpage
ELSE
 rectangle 0, 0, 320, 20, 0, dpage
END IF

'--draw map
setmapdata map(), pass(), 20, 0
setanim tastuf(0) + cycle(0), tastuf(20) + cycle(1)
cycletile cycle(), tastuf(), cycptr(), cycskip()
drawmap mapx, mapy - 20, 0, dpage

'--show passmode overlay
IF editmode = 1 THEN
  setmapdata pass(), pass(), 20, 0
  FOR o = 0 TO 8
   FOR i = 0 TO 15
    over = readmapblock(INT(mapx / 20) + i, INT(mapy / 20) + o)
    IF (over AND 1) THEN rectangle i * 20, o * 20 + 20, 20, 3, 7 + tog, dpage
    IF (over AND 2) THEN rectangle i * 20 + 17, o * 20 + 20, 3, 20, 7 + tog, dpage
    IF (over AND 4) THEN rectangle i * 20, o * 20 + 37, 20, 3, 7 + tog, dpage
    IF (over AND 8) THEN rectangle i * 20, o * 20 + 20, 3, 20, 7 + tog, dpage
    textcolor 14 + tog, 0
    IF (over AND 16) THEN printstr "A", i * 20, o * 20 + 20, dpage
    IF (over AND 32) THEN printstr "B", i * 20 + 10, o * 20 + 20, dpage
    IF (over AND 64) THEN printstr "H", i * 20, o * 20 + 30, dpage
    IF (over AND 128) THEN printstr "O", i * 20 + 10, o * 20 + 30, dpage
   NEXT i
  NEXT o
END IF

'--door display--
IF editmode = 2 THEN
 textcolor 240, 0
 FOR i = 0 TO 99
  IF doors(i) >= INT(mapx / 20) AND doors(i) < INT(mapx / 20) + 16 AND doors(i + 100) > INT(mapy / 20) AND doors(i + 100) <= INT(mapy / 20) + 9 AND doors(i + 200) = 1 THEN
   rectangle doors(i) * 20 - mapx, doors(i + 100) * 20 - mapy, 20, 20, 15 - tog, dpage
   printstr intstr$(i), doors(i) * 20 - mapx + 10 - (4 * (LEN(STR$(i)) - 1)), doors(i + 100) * 20 - mapy + 6, dpage
  END IF
 NEXT
END IF

'--npc display--
IF editmode = 3 THEN
 walk = walk + 1: IF walk > 3 THEN walk = 0
 FOR i = 0 TO 299
 IF npc(i + 600) > 0 THEN
  IF npc(i + 0) >= INT(mapx / 20) AND npc(i + 0) < INT(mapx / 20) + 16 AND npc(i + 300) > INT(mapy / 20) AND npc(i + 300) <= INT(mapy / 20) + 9 THEN
   loadsprite cursor(), 0, 400 * npc(i + 900) + (200 * INT(walk / 2)), 5 * (npc(i + 600) - 1), 20, 20, 2
   drawsprite cursor(), 0, pal16(), 16 * (npc(i + 600) - 1), npc(i) * 20 - mapx, npc(i + 300) * 20 - mapy, dpage
   textcolor 14 + tog, 0
   temp$ = intstr$(npc(i + 600) - 1)
   printstr temp$, npc(i) * 20 - mapx, npc(i + 300) * 20 - mapy + 8, dpage
  END IF
 END IF
 NEXT
END IF

'--position finder--
IF tiny = 1 THEN rectangle 0, 20, wide, high, 1, dpage: rectangle mapx / 20, (mapy / 20) + 20, 15, 9, 10, dpage

'--normal cursor--
IF editmode <> 3 THEN
 drawsprite cursor(), 200 * (1 + tog), cursorpal(), 0, (x * 20) - mapx, (y * 20) - mapy + 20, dpage
 IF editmode = 0 THEN drawsprite cursor(), 200 * (1 + tog), cursorpal(), 0, ((pic - menu) * 20), 0, dpage
END IF

'--npc placement cursor--
IF editmode = 3 THEN
 loadsprite cursor(), 0, (walk * 400), nptr * 5, 20, 20, 2
 drawsprite cursor(), 0, pal16(), 16 * nptr, (x * 20) - mapx, (y * 20) - mapy + 20, dpage
 textcolor 14 + tog, 0
 temp$ = intstr$(nptr)
 printstr temp$, (x * 20) - mapx, (y * 20) - mapy + 28, dpage
END IF

'--show foemap--
IF editmode = 4 THEN
 setmapdata emap(), pass(), 20, 0
 textcolor 14 + tog, 0
 FOR i = 0 TO 14
  FOR o = 0 TO 8
   temp = readmapblock(INT(mapx / 20) + i, INT(mapy / 20) + o)
   IF temp > 0 THEN printstr intstr$(temp), i * 20 - ((temp < 10) * 5), o * 20 + 26, dpage
  NEXT o
 NEXT i
END IF

textcolor 14 + tog, 0
printstr "X" + STR$(x) + "   Y" + STR$(y), 0, 192, dpage
setmapdata map(), pass(), 20, 0
rectangle 300, 0, 20, 200, 0, dpage
rectangle 0, 19, 320, 1, 15, dpage
textcolor 15, 0
printstr mode$(editmode), 0, 24, dpage
IF editmode = 4 THEN textcolor 15, 1: printstr "Formation Set:" + STR$(foe), 0, 16, dpage
SWAP vpage, dpage
setvispage vpage
dowait
LOOP


pickblock:
setkeys
DO
setwait timing(), 120
setkeys
IF keyval(28) > 1 OR keyval(1) > 1 THEN menu = pic: RETURN
IF keyval(72) > 0 AND by > 0 THEN by = by - 1: pic = pic - 16
IF keyval(80) > 0 AND by < 9 THEN by = by + 1: pic = pic + 16
IF keyval(75) > 0 AND bx > 0 THEN bx = bx - 1: pic = pic - 1
IF keyval(77) > 0 AND bx < 15 THEN bx = bx + 1: pic = pic + 1
IF keyval(51) > 0 AND pic > 0 THEN pic = pic - 1: bx = bx - 1: IF bx < 0 THEN bx = 15: by = by - 1
IF keyval(52) > 0 AND pic < 159 THEN pic = pic + 1: bx = bx + 1: IF bx > 15 THEN bx = 0: by = by + 1
tog = tog XOR 1
loadsprite cursor(), 0, 0, 0, 20, 20, 2
drawsprite cursor(), 200 * (1 + tog), cursorpal(), 0, bx * 20, by * 20, dpage
copypage dpage, vpage
copypage 3, dpage
dowait
LOOP

sizemap:
clearpage 2
tempx = 0: tempy = 0
tempw = wide: temph = high
setmapdata map(), pass(), 20, 0
drawmini high, wide, cursor(), 2, tastuf()
setkeys
DO
setwait timing(), 100
setkeys
IF keyval(1) > 1 THEN RETURN
IF keyval(28) > 1 THEN GOSUB dosizemap: RETURN
IF keyval(29) THEN
 IF keyval(72) > 0 THEN tempy = tempy - (1 + (keyval(56) * 8)): tempy = large(tempy, 0)
 IF keyval(80) > 0 THEN tempy = tempy + (1 + (keyval(56) * 8)): tempy = small(tempy, high - temph)
 IF keyval(75) > 0 THEN tempx = tempx - (1 + (keyval(56) * 8)): tempx = large(tempx, 0)
 IF keyval(77) > 0 THEN tempx = tempx + (1 + (keyval(56) * 8)): tempx = small(tempx, wide - tempw)
 tempx = large(tempx, 0)
 tempy = large(tempy, 0)
ELSE
 IF keyval(72) > 0 THEN temph = temph - (1 + (keyval(56) * 8)): temph = large(temph, 10)
 IF keyval(80) > 0 THEN temph = temph + (1 + (keyval(56) * 8)): temph = small(temph, 32000): WHILE temph * tempw > 32000: tempw = tempw - 1: WEND
 IF keyval(75) > 0 THEN tempw = tempw - (1 + (keyval(56) * 8)): tempw = large(tempw, 16)
 IF keyval(77) > 0 THEN tempw = tempw + (1 + (keyval(56) * 8)): tempw = small(tempw, 32000): WHILE temph * tempw > 32000: temph = temph - 1: WEND
 th& = temph
 tw& = tempw
 WHILE th& * tw& >= 32000
  temph = large(temph - 1, 10)
  tempw = large(tempw - 1, 16)
  th& = temph
  tw& = tempw
 WEND
END IF
edgeprint "width" + STR$(wide) + CHR$(26) + intstr$(tempw), 1, 1, 7, dpage
edgeprint "height" + STR$(high) + CHR$(26) + intstr$(temph), 1, 11, 7, dpage
edgeprint "area" + STR$(wide * high) + CHR$(26) + intstr$(temph * tempw), 1, 21, 7, dpage
rectangle tempx, tempy, tempw, 1, 14 + tog, dpage
rectangle tempx, tempy, 1, temph, 14 + tog, dpage
rectangle tempx, tempy + temph, tempw, 1, 14 + tog, dpage
rectangle tempx + tempw, tempy, 1, temph, 14 + tog, dpage
copypage dpage, vpage
copypage 2, dpage
dowait
LOOP

dosizemap:
clearpage 0
clearpage 1
yout = 0
edgeprint "TILEMAP", 0, yout * 10, 15, vpage: yout = yout + 1
sizemar map(), wide, high, tempx, tempy, tempw, temph, yout, vpage
edgeprint "PASSMAP", 0, yout * 10, 15, vpage: yout = yout + 1
sizemar pass(), wide, high, tempx, tempy, tempw, temph, yout, vpage
edgeprint "FOEMAP", 0, yout * 10, 15, vpage: yout = yout + 1
sizemar emap(), wide, high, tempx, tempy, tempw, temph, yout, vpage
setmapdata map(), pass(), 20, 0
wide = map(0): high = map(1)
'--reset map scroll position
x = 0: y = 0: mapx = 0: mapy = 0
edgeprint "Aligning and truncating doors", 0, yout * 10, 15, vpage: yout = yout + 1
FOR i = 0 TO 99
 doors(i) = doors(i) - tempx
 doors(i + 100) = doors(i + 100) - tempy
 IF doors(i) < 0 OR doors(i + 100) < 0 OR doors(i) > wide OR doors(i + 100) > high THEN
  doors(i + 200) = 0
 END IF
NEXT
edgeprint "Aligning and truncating NPCs", 0, yout * 10, 15, vpage: yout = yout + 1
FOR i = 0 TO 299
 npc(i + 0) = npc(i + 0) - tempx
 npc(i + 300) = npc(i + 300) - tempy
 IF npc(i + 0) < 0 OR npc(i + 300) < 0 OR npc(i + 0) > wide OR npc(i + 300) > high THEN
  npc(i + 600) = 0
 END IF
NEXT i
GOSUB verifymap
RETURN

minimap:
clearpage vpage
setmapdata map(), pass(), 20, 0
drawmini high, wide, cursor(), vpage, tastuf()
printstr "Press Any Key", 0, 180, vpage
w = getkey
RETURN

delmap:
setvispage vpage
temp$(0) = "Do Not Delete"
temp$(1) = "Delete Map"
yesno = sublist(1, temp$())
IF yesno = 1 THEN
 printstr "Please Wait...", 0, 40, vpage
 map(0) = 32: map(1) = 20
 pass(0) = 32: pass(1) = 20
 emap(0) = 32: emap(1) = 20
 FOR i = 2 TO 16002
  rectangle INT(i * .02), 180, 2, 10, 15, vpage
  map(i) = 0
  pass(i) = 0
  emap(i) = 0
 NEXT i
 '---FLUSH DOOR LINKS---
 FOR i = 0 TO 1000
  link(i) = 0
 NEXT i
 '---FLUSH NPC LOCATIONS---
 FOR i = 0 TO 900
  npc(i) = 0
 NEXT i
 '---FLUSH DOOR LOCATIONS---
 FOR i = 0 TO 99
  doors(i) = 0
  doors(i + 100) = 0
  doors(i + 200) = 0
 NEXT
 DEF SEG = VARSEG(map(0)): BSAVE game$ + ".t" + filenum$(ptr), VARPTR(map(0)), map(0) * map(1) + 4
 DEF SEG = VARSEG(pass(0)): BSAVE game$ + ".p" + filenum$(ptr), VARPTR(pass(0)), pass(0) * pass(1) + 4
 DEF SEG = VARSEG(emap(0)): BSAVE game$ + ".e" + filenum$(ptr), VARPTR(emap(0)), emap(0) * emap(1) + 4
 DEF SEG = VARSEG(link(0)): BSAVE game$ + ".d" + filenum$(ptr), VARPTR(link(0)), 2000
 DEF SEG = VARSEG(npc(0)): BSAVE game$ + ".l" + filenum$(ptr), VARPTR(npc(0)), 3000
 setpicstuf doors(), 600, -1
 storeset game$ + ".dox" + CHR$(0), ptr, 0
END IF
'--reset scroll position
wide = map(0): high = map(1)
x = 0: y = 0: mapx = 0: mapy = 0
RETURN

addmap:
IF general(0) >= 99 THEN RETURN
how = addmaphow(general())
'-- -2  =Cancel
'-- -1  =New blank
'-- >=0 =Copy
IF how = -1 THEN GOSUB newblankmap
IF how >= 0 THEN GOSUB copymap
RETURN

copymap:
'--increment map count
general(0) = general(0) + 1
'--load the source map
ptr = how
GOSUB loadmap
'-- save the new map
ptr = general(0)
GOSUB savemap
RETURN

newblankmap:
'--increment map count
general(0) = general(0) + 1
'--flush map buffers
flusharray map(), 16002, 0
flusharray pass(), 16002, 0
flusharray emap(), 16002, 0
flusharray link(), 1000, 0
flusharray npc(), 900, 0
flusharray npcstat(), 1500, 0
flusharray doors(), 299, 0
'--setup default new map size
map(0) = 64: map(1) = 64
pass(0) = 64: pass(1) = 64
emap(0) = 64: emap(1) = 64
'--save map buffers
DEF SEG = VARSEG(map(0)): BSAVE game$ + ".t" + filenum$(general(0)), VARPTR(map(0)), map(0) * map(1) + 4
DEF SEG = VARSEG(pass(0)): BSAVE game$ + ".p" + filenum$(general(0)), VARPTR(pass(0)), pass(0) * pass(1) + 4
DEF SEG = VARSEG(emap(0)): BSAVE game$ + ".e" + filenum$(general(0)), VARPTR(emap(0)), emap(0) * emap(1) + 4
DEF SEG = VARSEG(link(0)): BSAVE game$ + ".d" + filenum$(general(0)), VARPTR(link(0)), 2000
DEF SEG = VARSEG(npcstat(0)): BSAVE game$ + ".n" + filenum$(general(0)), VARPTR(npcstat(0)), 3000
DEF SEG = VARSEG(npc(0)): BSAVE game$ + ".l" + filenum$(general(0)), VARPTR(npc(0)), 3000
setpicstuf doors(), 600, -1
storeset game$ + ".dox" + CHR$(0), general(0), 0
'--setup map name
buffer(0) = 0
setpicstuf buffer(), 80, -1
storeset game$ + ".mn" + CHR$(0), general(0), 0
RETURN

savemap:
setpicstuf gmap(), 40, -1
storeset game$ + ".map" + CHR$(0), ptr, 0
DEF SEG = VARSEG(map(0)): BSAVE game$ + ".t" + filenum$(ptr), VARPTR(map(0)), map(0) * map(1) + 4
DEF SEG = VARSEG(pass(0)): BSAVE game$ + ".p" + filenum$(ptr), VARPTR(pass(0)), pass(0) * pass(1) + 4
DEF SEG = VARSEG(emap(0)): BSAVE game$ + ".e" + filenum$(ptr), VARPTR(emap(0)), emap(0) * emap(1) + 4
DEF SEG = VARSEG(npc(0)): BSAVE game$ + ".l" + filenum$(ptr), VARPTR(npc(0)), 3000
DEF SEG = VARSEG(link(0)): BSAVE game$ + ".d" + filenum$(ptr), VARPTR(link(0)), 2000
DEF SEG = VARSEG(npcstat(0)): BSAVE game$ + ".n" + filenum$(ptr), VARPTR(npcstat(0)), 3000
setpicstuf doors(), 600, -1
storeset game$ + ".dox" + CHR$(0), ptr, 0
'--save map name
buffer(0) = LEN(mapname$)
str2array LEFT$(mapname$, 39), buffer(), 1
setpicstuf buffer(), 80, -1
storeset game$ + ".mn" + CHR$(0), ptr, 0
RETURN

loadmap:
setpicstuf gmap(), 40, -1
loadset game$ + ".map" + CHR$(0), ptr, 0
loadpage game$ + ".til" + CHR$(0), gmap(0), 3
loadtanim gmap(0), tastuf()
FOR i = 0 TO 1
 cycle(i) = 0
 cycptr(i) = 0
 cycskip(i) = 0
NEXT i
xbload game$ + ".t" + filenum$(ptr), map(), "tilemap lump is missing!"
xbload game$ + ".p" + filenum$(ptr), pass(), "passmap lump is missing!"
xbload game$ + ".e" + filenum$(ptr), emap(), "foemap lump is missing!"
xbload game$ + ".l" + filenum$(ptr), npc(), "npclocation lump is missing!"
xbload game$ + ".n" + filenum$(ptr), npcstat(), "npcstat lump is missing!"
xbload game$ + ".d" + filenum$(ptr), link(), "doorlink lump is missing!"
setpicstuf doors(), 600, -1
loadset game$ + ".dox" + CHR$(0), ptr, 0
wide = map(0): high = map(1)
mapname$ = getmapname$(ptr)
loadpasdefaults defaults(), gmap(0)
GOSUB verifymap
RETURN

verifymap:
IF map(0) <> pass(0) OR map(0) <> emap(0) OR map(1) <> pass(1) OR map(1) <> emap(1) THEN
 '--Map's X and Y do not match
 clearpage vpage
 j = 0
 textcolor 15, 0
 printstr "Map" + filenum$(ptr) + ":" + mapname$, 0, j * 8, vpage: j = j + 1
 j = j + 1
 printstr "this map seems to be corrupted", 0, j * 8, vpage: j = j + 1
 j = j + 1
 printstr " TileMap" + STR$(map(0)) + "*" + LTRIM$(STR$(map(1))) + " tiles", 0, j * 8, vpage: j = j + 1
 printstr " WallMap" + STR$(pass(0)) + "*" + LTRIM$(STR$(pass(1))) + " tiles", 0, j * 8, vpage: j = j + 1
 printstr " FoeMap" + STR$(emap(0)) + "*" + LTRIM$(STR$(emap(1))) + " tiles", 0, j * 8, vpage: j = j + 1
 j = j + 1
 printstr "What is the correct size?", 0, j * 8, vpage: j = j + 1
 DO
  textcolor 14, 240
  setkeys
  DO
   setwait timing(), 100
   setkeys
   IF keyval(1) > 1 OR keyval(28) > 1 THEN EXIT DO
   dummy = intgrabber(wide, 0, 9999, 75, 77)
   printstr "Width:" + STR$(wide) + "   ", 0, j * 8, vpage
   dowait
  LOOP
  j = j + 1
  setkeys
  DO
   setwait timing(), 100
   setkeys
   IF keyval(1) > 1 OR keyval(28) > 1 THEN EXIT DO
   dummy = intgrabber(high, 0, 9999, 75, 77)
   printstr "Height:" + STR$(high) + "    ", 0, j * 8, vpage
   dowait
  LOOP
  textcolor 15, 0
  IF wide * high < 32000 AND wide > 0 AND high > 0 THEN EXIT DO
  j = j - 2
  printstr "What is the correct size? (bad size!)", 0, j * 8, vpage: j = j + 1
 LOOP
 map(0) = wide: map(1) = high
 pass(0) = wide: pass(1) = high
 emap(0) = wide: emap(1) = high
 j = j + 2
 printstr "please report this error to", 0, j * 8, vpage: j = j + 1
 printstr "ohrrpgce@HamsterRepublic.com", 0, j * 8, vpage: j = j + 1
 w = getkey
END IF
RETURN

loadmenu:
setmapdata menubar(), pass(), 180, 0
FOR i = 0 TO 159
setmapblock i, 0, i
NEXT
RETURN

linkdoor:
GOSUB savemap
ulim(0) = 99: llim(0) = 0
ulim(1) = 99: llim(1) = 0
ulim(2) = general(0): llim(2) = 0
ulim(3) = 999: llim(3) = -999
ulim(4) = 999: llim(4) = -999
ttop = 0: cur = 0
setkeys
DO
setwait timing(), 100
setkeys
tog = tog XOR 1
IF keyval(1) > 1 THEN DEF SEG = VARSEG(link(0)): BSAVE game$ + ".d" + filenum$(ptr), VARPTR(link(0)), 2000: RETURN
'IF keyval(72) > 1 AND cur > 0 THEN cur = cur - 1: IF cur < ttop THEN ttop = ttop - 1
'IF keyval(80) > 1 AND cur < 199 THEN cur = cur + 1: IF cur > ttop + 10 THEN ttop = ttop + 1
dummy = usemenu(cur, ttop, 0, 199, 10)
IF keyval(28) > 1 OR keyval(57) > 1 THEN GOSUB seedoors
FOR i = ttop TO ttop + 10
 textcolor 7, 0
 IF cur = i THEN textcolor 14 + tog, 0
 a$ = "Door" + STR$(link(i)) + " leads to door" + STR$(link(i + 200)) + " on map" + STR$(link(i + 400))
 printstr a$, 0, 2 + (i - ttop) * 16, dpage
 a$ = "  only if tag" + STR$(ABS(link(i + 600))) + " =" + STR$(SGN(SGN(link(i + 600)) + 1)) + " and tag" + STR$(ABS(link(i + 800))) + " =" + STR$(SGN(SGN(link(i + 800)) + 1))
 IF link(i + 600) = 0 AND link(i + 800) <> 0 THEN a$ = "  only if tag" + STR$(ABS(link(i + 800))) + " =" + STR$(SGN(SGN(link(i + 800)) + 1))
 IF link(i + 600) <> 0 AND link(i + 800) = 0 THEN a$ = "  only if tag" + STR$(ABS(link(i + 600))) + " =" + STR$(SGN(SGN(link(i + 600)) + 1))
 IF link(i + 600) = 0 AND link(i + 800) = 0 THEN a$ = "  all the time"
 printstr a$, 0, 10 + (i - ttop) * 16, dpage
NEXT i
SWAP vpage, dpage
setvispage vpage
clearpage dpage
dowait
LOOP

seedoors:
DEF SEG = VARSEG(map(0)): BSAVE game$ + ".t" + filenum$(ptr), VARPTR(map(0)), map(0) * map(1) + 4
menu$(-1) = "Go Back"
menu$(0) = "Entrance Door"
menu$(1) = "Exit Door"
menu$(2) = "Exit Map"
menu$(3) = "Require Tag"
menu$(4) = "Require Tag"
cur2 = -1
outmap$ = getmapname$(link(cur + 400))
GOSUB showldoor
setkeys
DO
setwait timing(), 100
setkeys
tog = tog XOR 1
IF sdwait > 0 THEN
 sdwait = sdwait - 1
 IF sdwait = 0 THEN GOSUB showldoor
END IF
IF keyval(1) > 1 THEN RETURN
'IF keyval(72) > 1 THEN cur2 = cur2 - 1: IF cur2 < -1 THEN cur2 = 4
'IF keyval(80) > 1 THEN cur2 = cur2 + 1: IF cur2 > 4 THEN cur2 = -1
dummy = usemenu(cur2, 0, -1, 4, 24)
IF cur2 >= 0 THEN
 IF intgrabber(link(cur + (cur2 * 200)), llim(cur2), ulim(cur2), 75, 77) THEN sdwait = 3: outmap$ = getmapname$(link(cur + 400))
ELSE
 IF keyval(28) > 1 OR keyval(57) > 1 THEN RETURN
END IF
rectangle 0, 100, 320, 2, 1 + tog, dpage
FOR i = -1 TO 4
 temp$ = ""
 IF i >= 0 AND i <= 2 THEN temp$ = STR$(link(cur + (i * 200)))
 IF i > 2 THEN
  IF link(cur + (i * 200)) THEN
   temp$ = STR$(ABS(link(cur + (i * 200)))) + " = " + onoroff$(link(cur + (i * 200))) + " (" + lmnemonic$(ABS(link(cur + (i * 200)))) + ")"
  ELSE
   temp$ = " 0 [N/A]"
  END IF
 END IF
 col = 7: IF cur2 = i THEN col = 14 + tog
 edgeprint menu$(i) + temp$, 1, 1 + (i + 1) * 10, col, dpage
NEXT i
edgeprint "ENTER", 275, 0, 15, dpage
edgeprint "EXIT", 283, 190, 15, dpage
edgeprint outmap$, 0, 190, 15, dpage
SWAP vpage, dpage
setvispage vpage
copypage 2, dpage
dowait
LOOP

showldoor:
clearpage 2
setmapdata map(), pass(), 0, 101
IF doors(link(cur + (0 * 200)) + 200) = 1 THEN
 dmx = doors(link(cur + (0 * 200))) * 20 - 150
 dmy = doors(link(cur + (0 * 200)) + 100) * 20 - 65
 dmx = small(large(dmx, 0), map(0) * 20 - 320)
 dmy = small(large(dmy, 0), map(1) * 20 - 100)
 drawmap dmx, dmy, 0, 2
 rectangle doors(link(cur + (0 * 200))) * 20 - dmx, doors(link(cur + (0 * 200)) + 100) * 20 - dmy - 20, 20, 20, 240, 2
 rectangle 1 + doors(link(cur + (0 * 200))) * 20 - dmx, 1 + doors(link(cur + (0 * 200)) + 100) * 20 - dmy - 20, 18, 18, 7, 2
 textcolor 240, 0
 temp$ = STR$(link(cur + (0 * 200)))
 printstr RIGHT$(temp$, LEN(temp$) - 1), doors(link(cur + (0 * 200))) * 20 - dmx + 10 - (4 * LEN(temp$)), doors(link(cur + (0 * 200)) + 100) * 20 - dmy - 14, 2
END IF
'-----------------EXIT DOOR
setpicstuf destdoor(), 600, -1
loadset game$ + ".dox" + CHR$(0), link(cur + (2 * 200)), 0
xbload game$ + ".t" + filenum$(link(cur + (2 * 200))), map(), "Could not find map" + filenum$(link(cur + (2 * 200)))
setpicstuf buffer(), 40, -1
loadset game$ + ".map" + CHR$(0), link(cur + (2 * 200)), 0
loadpage game$ + ".til" + CHR$(0), buffer(0), 3
setmapdata map(), pass(), 101, 0
IF destdoor(link(cur + (1 * 200)) + 200) = 1 THEN
 dmx = destdoor(link(cur + (1 * 200))) * 20 - 150
 dmy = destdoor(link(cur + (1 * 200)) + 100) * 20 - 65
 dmx = small(large(dmx, 0), map(0) * 20 - 320)
 dmy = small(large(dmy, 0), map(1) * 20 - 100)
 drawmap dmx, dmy - 100, 0, 2
 rectangle destdoor(link(cur + (1 * 200))) * 20 - dmx, destdoor(link(cur + (1 * 200)) + 100) * 20 - dmy + 80, 20, 20, 240, 2
 rectangle 1 + destdoor(link(cur + (1 * 200))) * 20 - dmx, 1 + destdoor(link(cur + (1 * 200)) + 100) * 20 - dmy + 80, 18, 18, 7, 2
 textcolor 240, 0
 temp$ = STR$(link(cur + (1 * 200)))
 printstr RIGHT$(temp$, LEN(temp$) - 1), destdoor(link(cur + (1 * 200))) * 20 - dmx + 10 - (4 * LEN(temp$)), destdoor(link(cur + (1 * 200)) + 100) * 20 - dmy + 86, 2
END IF
'-----------------RESET DATA
loadpage game$ + ".til" + CHR$(0), gmap(0), 3
xbload game$ + ".t" + filenum$(ptr), map(), "Tilemap lump disappeared!"
RETURN

donemapping:
clearpage 0
clearpage 1
clearpage 2
clearpage 3

'----
'gmap(20)
'0=tileset
'1=ambient music
'2=minimap
'3=save anywhere
'4=show map name
'5=map edge mode
'6=default edge tile
'7=autorun script
'8=script argument
'9=harm tile damage
'10=harm tile flash
'11=default foot-offset
'12=afterbattle script
'13=instead-of-battle script
'14=eachstep script
'15=onkeypress script

'tiles
'1   north
'2   east
'4   south
'8   west
'16  vehicle A
'32  vehicle B
'64  harm tile
'128 overhead
END SUB

