'Library header - bare QBasic version
'--register type used for direct assembly language calls
TYPE Regtype
 ax AS INTEGER
 bx AS INTEGER
 cx AS INTEGER
 dx AS INTEGER
 bp AS INTEGER
 si AS INTEGER
 di AS INTEGER
 flags AS INTEGER
 ds AS INTEGER
 es AS INTEGER
END TYPE

'Library routines
DECLARE SUB setmodex ()
DECLARE SUB restoremode ()
DECLARE SUB copypage (BYVAL page1, BYVAL page2)
DECLARE SUB clearpage (BYVAL page)
DECLARE SUB setvispage (BYVAL page)
DECLARE SUB setpal (pal())
DECLARE SUB fadeto (palbuff(), BYVAL red, BYVAL green, BYVAL blue)
DECLARE SUB fadetopal (pal(), palbuff())
DECLARE SUB setmapdata (array(), pas(), BYVAL t, BYVAL b)
DECLARE SUB setmapblock (BYVAL x, BYVAL y, BYVAL v)
DECLARE FUNCTION readmapblock (BYVAL x, BYVAL y)
DECLARE SUB setpassblock (BYVAL x, BYVAL y, BYVAL v)
DECLARE FUNCTION readpassblock (BYVAL x, BYVAL y)
DECLARE SUB drawmap (BYVAL x, BYVAL y, BYVAL t, BYVAL p)
DECLARE SUB setanim (BYVAL cycle1, BYVAL cycle2)
DECLARE SUB setoutside (BYVAL defaulttile)
DECLARE SUB drawsprite (pic(), BYVAL picoff, pal(), BYVAL po, BYVAL x, BYVAL y, BYVAL page)
DECLARE SUB wardsprite (pic(), BYVAL picoff, pal(), BYVAL po, BYVAL x, BYVAL y, BYVAL page)
DECLARE SUB getsprite (pic(), BYVAL picoff, BYVAL x, BYVAL y, BYVAL w, BYVAL h, BYVAL page)
DECLARE SUB stosprite (pic(), BYVAL picoff, BYVAL x, BYVAL y, BYVAL page)
DECLARE SUB loadsprite (pic(), BYVAL picoff, BYVAL x, BYVAL y, BYVAL w, BYVAL h, BYVAL page)
DECLARE SUB bigsprite (pic(), pal(), BYVAL p, BYVAL x, BYVAL y, BYVAL page)
DECLARE SUB hugesprite (pic(), pal(), BYVAL p, BYVAL x, BYVAL y, BYVAL page)
'DECLARE SUB INTERRUPTX (intnum AS INTEGER,inreg AS RegType, outreg AS RegType)
DECLARE FUNCTION Keyseg ()
DECLARE FUNCTION keyoff ()
DECLARE FUNCTION keyval (BYVAL a)
DECLARE FUNCTION getkey ()
DECLARE SUB setkeys ()
DECLARE SUB putpixel (BYVAL x, BYVAL y, BYVAL c, BYVAL p)
DECLARE FUNCTION readpixel (BYVAL x, BYVAL y, BYVAL p)
DECLARE SUB rectangle (BYVAL x, BYVAL y, BYVAL w, BYVAL h, BYVAL c, BYVAL p)
DECLARE SUB fuzzyrect (BYVAL x, BYVAL y, BYVAL w, BYVAL h, BYVAL c, BYVAL p)
DECLARE SUB drawline (BYVAL x1, BYVAL y1, BYVAL x2, BYVAL y2, BYVAL c, BYVAL p)
DECLARE SUB paintat (BYVAL x, BYVAL y, BYVAL c, BYVAL page, buf(), BYVAL max)
DECLARE SUB storepage (fil$, BYVAL i, BYVAL p)
DECLARE SUB loadpage (fil$, BYVAL i, BYVAL p)
DECLARE SUB setdiskpages (buf(), BYVAL h, BYVAL l)
DECLARE SUB setwait (b(), BYVAL t)
DECLARE SUB dowait ()
DECLARE SUB printstr (s$, BYVAL x, BYVAL y, BYVAL p)
DECLARE SUB textcolor (BYVAL f, BYVAL b)
DECLARE SUB setfont (f())
DECLARE SUB setbit (b(), BYVAL w, BYVAL b, BYVAL v)
DECLARE FUNCTION readbit (b(), BYVAL w, BYVAL b)
DECLARE SUB storeset (fil$, BYVAL i, BYVAL l)
DECLARE SUB loadset (fil$, BYVAL i, BYVAL l)
DECLARE SUB setpicstuf (buf(), BYVAL b, BYVAL p)
DECLARE SUB bitmap2page (temp(), bmp$, BYVAL p)
DECLARE SUB findfiles (fmask$, BYVAL attrib, outfile$, buf())
DECLARE SUB lumpfiles (listf$, lump$, path$, buffer())
DECLARE SUB unlump (lump$, ulpath$, buffer())
DECLARE SUB unlumpfile (lump$, fmask$, path$, buf())
DECLARE FUNCTION isfile (n$)
DECLARE FUNCTION pathlength ()
DECLARE SUB getstring (p$)
DECLARE FUNCTION drivelist (d())
DECLARE FUNCTION rpathlength ()
DECLARE FUNCTION exenamelength ()
DECLARE SUB setdrive (BYVAL n)
DECLARE FUNCTION envlength (e$)
DECLARE FUNCTION isdir (sDir$)
DECLARE FUNCTION isvirtual (BYVAL d)
DECLARE FUNCTION isremovable (BYVAL d)
DECLARE FUNCTION hasmedia (BYVAL d)
DECLARE FUNCTION LongNameLength (filename$)
DECLARE SUB setupmusic (mbuf())
DECLARE SUB closemusic ()
DECLARE SUB loadsong (f$)
DECLARE SUB stopsong ()
DECLARE SUB resumesong ()
DECLARE SUB fademusic (BYVAL vol)
DECLARE FUNCTION getfmvol ()
DECLARE SUB setfmvol (BYVAL vol)
DECLARE SUB copyfile (s$, d$, buf())
DECLARE SUB screenshot (f$, BYVAL p, maspal(), buf())
DECLARE SUB loadbmp (f$, BYVAL x, BYVAL y, buf(), BYVAL p)
DECLARE SUB getbmppal (f$, mpal(), pal(), BYVAL o)
DECLARE FUNCTION bmpinfo (f$, dat())
DECLARE FUNCTION setmouse (mbuf())
DECLARE SUB readmouse (mbuf())
DECLARE SUB movemouse (BYVAL x, BYVAL y)
DECLARE SUB mouserect (BYVAL xmin, BYVAL xmax, BYVAL ymin, BYVAL ymax)
DECLARE FUNCTION readjoy (joybuf(), BYVAL jnum)
DECLARE SUB array2str (arr(), BYVAL o, s$)
DECLARE SUB str2array (s$, arr(), BYVAL o)
DECLARE SUB setupstack (buffer(), BYVAL size, file$)
DECLARE SUB pushw (BYVAL word)
DECLARE FUNCTION popw ()
DECLARE SUB releasestack ()
DECLARE FUNCTION stackpos ()

