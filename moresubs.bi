'OHRRPGCE - moresubs.bi
'(C) Copyright 1997-2006 James Paige and Hamster Republic Productions
'Please read LICENSE.txt for GPL License details and disclaimer of liability
'See README.txt for code docs and apologies for crappyness of this code ;)
'Auto-generated by MAKEBI from moresubs.bas

#IFNDEF MORESUBS_BI
#DEFINE MORESUBS_BI

declare sub addhero (who, slot, stat())
declare function atlevel (now, a0, a99)
declare function averagelev (stat())
declare sub calibrate
declare function consumeitem (index)
declare function countitem (it)
declare sub delitem (it, amount)
declare sub doswap (s, d, stat())
declare sub drawsay (txt AS TextBoxState, sayenh(), showsay)
declare sub evalherotag (stat())
declare sub evalitemtag
declare function findhero (who, f, l, d)
declare sub getnames (stat$())
declare sub heroswap (iall%, stat())
declare function howmanyh (f, l)
declare function istag (num, zero)
declare sub loaddoor (map, door())
declare sub loadgame (slot, map, foep, stat(), stock())
declare sub minimap (x, y, tastuf())
declare function movdivis (xygo)
declare function onwho (w$, alone)
declare function range (n, r)
declare function rangel (n&, r)
declare sub readjoysettings
declare function readscriptvar (id)
declare sub renamehero (who)
declare sub resetgame (map, foep, stat(), stock(), showsay, scriptout$, sayenh())
declare sub resetlmp (slot, lev)
declare sub rpgversion (v)
declare function runscript (id, index, newcall, er$, trigger)
declare sub savegame (slot, map, foep, stat(), stock())
declare sub scripterr (e$)
declare sub scriptmath
declare function settingstring (searchee$, setting$, result$)
declare sub shop (id, needf, stock(), stat(), map, foep, tastuf())
declare function useinn (inn, price, needf, stat())
declare sub snapshot
declare sub tagdisplay
declare sub writejoysettings
declare sub writescriptvar (id, newval)
declare function getdisplayname$ (default$)

#ENDIF
