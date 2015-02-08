#!/usr/bin/env python
#
# Collects a random selection of data, saved to gamedata.bin

import os
import sys
import time
import cPickle as pickle
import numpy as np
from nohrio.ohrrpgce import *
from nohrio.dtypes import dt
from nohrio.wrappers import OhrData
from rpgbatch import RPGIterator, RPGInfo, lumpbasename

if len(sys.argv) < 2:
    sys.exit("Specify .rpg files, .rpgdir directories, .zip files, or directories containing any of these as arguments.")
things = sys.argv[1:]

rpgidx = np.ndarray(shape = 0, dtype = RPGInfo)
gen = np.ndarray(shape = 0, dtype = dt['gen'])
mas = np.ndarray(shape = 0, dtype = dt['mas'])
fnt = np.ndarray(shape = 0, dtype = dt['fnt'])

data = []
withscripts = 0

rpgs = RPGIterator(things)
for rpg, gameinfo, zipinfo in rpgs:
    # Let's fetch some useful data and store it
    if zipinfo:
        gameinfo.scripts = zipinfo.scripts
        if len(zipinfo.scripts):
            withscripts += 1
        print "scripts:", zipinfo.scripts
    else:
        gameinfo.scripts = []
    gameinfo.lumplist = [(lumpbasename(name, rpg), os.stat(name).st_size) for name in rpg.manifest]
    gameinfo.archinym = rpg.archinym.prefix
    gameinfo.arch_version = rpg.archinym.version
    rpgidx = np.append(rpgidx, gameinfo)

    # Fixed length lumps -- everything else is harder
    gen = np.append(gen, rpg.general)
    mas = np.append(mas, rpg.data('mas', shape = 1))  # Ignore overlong lumps
    fnt = np.append(fnt, rpg.data('fnt', shape = 1))

    # This is just a dumb example
    print "Processing RPG ", gameinfo.id, "from", gameinfo.src
    print " > ", gameinfo.longname, " --- ", gameinfo.aboutline
    #print "mod time =", time.ctime(gameinfo.mtime)
    #print "maps =", int(rpg.general.maxmap) + 1
    #print "format ver =", int(rpg.general.version)
    #print "say size =", int(rpg.binsize.say)
    data.append((gameinfo.mtime, int(rpg.general.version), gameinfo.id))
rpgs.print_summary()
del rpgs

rpgidx = rpgidx.view(OhrData)
gen = gen.view(OhrData)
mas = mas.view(OhrData)
fnt = fnt.view(OhrData)

with open('gamedata.bin', 'wb') as f:
    pickle.dump({'rpgidx':rpgidx, 'gen':gen, 'mas':mas, 'fnt':fnt}, f, protocol = 2)


# Continuing the dumb example
print withscripts, "games had script source"
print

data.sort()
for t, v, gameid in data:
    print time.ctime(t), " Format", v, gameid
