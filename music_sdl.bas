'OHRRPGCE - music_sdl and music_sdl2 audio backends
'(C) Copyright 1997-2020 James Paige, Ralph Versteegen, and the OHRRPGCE Developers
'Dual licensed under the GNU GPL v2+ and MIT Licenses. Read LICENSE.txt for terms and disclaimer of liability.
'
' music_sdl.bas - This compiles to both music_sdl and music_sdl2 audio backends,
'  music_sdl: SDL 1.2 + SDL_mixer 1.2 (when SDL_MIXER2 not defined)
'  music_sdl2: SDL 2 + SDL_mixer 2 (when SDL_MIXER2 defined, ie when included from music_sdl2.bas)
' It isn't possible to link both backends into the engine at once.

#include "config.bi"

#ifdef __FB_WIN32__
	'In FB >= 1.04 SDL.bi includes windows.bi; we have to include it first to do the necessary conflict prevention
	include_windows_bi()
#endif

#include "music.bi"
#include "gfx.bi"
#include "util.bi"
#include "common.bi"
#include "backendinfo.bi"
'warning: due to a FB bug, overloaded functions must be declared before SDL.bi is included

#ifdef __FB_UNIX__
	'In FB >= 1.04 SDL.bi includes Xlib.bi; fix a conflict
	#undef font
#endif

#ifdef SDL_MIXER2
	#include "SDL2\SDL.bi"
	#include "SDL2\SDL_mixer.bi"
#else
	#include "SDL\SDL.bi"
	#include "SDL\SDL_mixer.bi"
#endif

#ifndef Mix_ClearError
	'Missing from SDL_mixer 1.2's header
	#define Mix_ClearError  SDL_ClearError
#endif


' External functions

#ifndef SDL_MIXER2
	declare function safe_RWops(byval rw as SDL_RWops ptr) as SDL_RWops ptr
	declare sub safe_RWops_close (byval rw as SDL_RWops ptr)
#endif

extern "C"

declare function SDL_RWFromLump(byval lump as Lump ptr) as SDL_RWops ptr

'The decoder enum functions are only available in SDL_mixer > 1.2.8 which is the version shipped with
'Debian 6.0 Squeeze and hence older Ubuntu. Squeeze was superceded by 7.0 Wheezy in May 2013.
'So don't depend on these functions.
dim shared _Mix_GetNumMusicDecoders as function () as Sint32
dim shared _Mix_GetNumChunkDecoders as function () as Sint32
dim shared _Mix_GetMusicDecoder as function (byval index as Sint32) as zstring ptr
dim shared _Mix_GetChunkDecoder as function (byval index as Sint32) as zstring ptr

'We might not actually link to libmodplug, but want the type/enum declarations.
'Warning: does #inclib "modplug", which we don't actually want.
'Luckily as long as not building with "scons linkgcc=0", #inclibs are ignored.
#include "modplug.bi"

'These are only available if SDL_mixer has been statically linked with libmodplug and
'exports its symbols (as our builds of SDL_mixer for Windows and Mac do)
dim shared _ModPlug_GetSettings as sub (byval settings as ModPlug_Settings ptr)
dim shared _ModPlug_SetSettings as sub (byval settings as const ModPlug_Settings ptr)


#ifndef MIX_INIT_MID
	'Exists in SDL_mixer 2 only (but missing from older FB headers).
	'Equal to MIX_INIT_FLUIDSYNTH in SDL_mixer 1.2.
	#define MIX_INIT_MID &h00000020
#endif

end extern


' Local functions

declare function next_free_slot() as integer
declare function sfx_slot_info (byval slot as integer) as string
declare sub enable_modplug_looping()

enum MusicStatusEnum
  musicError = -1  ' Don't try again
  musicOff = 0
  musicOn = 1
end enum

dim shared mixer_version as integer  'E.g. 1213 for SDL_mixer 1.2.13
dim shared supported_formats as integer
dim shared have_modplug as bool
dim shared tried_enabling_modplug_loops as bool
dim shared modplug_handle as any ptr

dim shared music_status as MusicStatusEnum = musicOff
dim shared music_vol as double       '0 to 1 nominally; values above 1 useful when other multipliers exist
dim shared music_paused as bool      'Always false: we never pause! (see r5406)
dim shared music_song as Mix_Music ptr = NULL
dim shared music_song_rw as SDL_RWops ptr = NULL
dim shared orig_vol as integer = -1
dim shared nonmidi_playing as bool = NO

'The music module needs to manage a list of temporary files to delete when closed
dim shared tempfiles() as string
dim shared callback_set_up as bool = NO

sub quit_sdl_audio()
	'Close libmodplug
	if modplug_handle then
		dylibfree modplug_handle
		modplug_handle = NULL
	end if
	tried_enabling_modplug_loops = NO

	if SDL_WasInit(SDL_INIT_AUDIO) then
		SDL_QuitSubSystem(SDL_INIT_AUDIO)
		if SDL_WasInit(0) = 0 then
			SDL_Quit()
		end if
	end if
end sub

'This is currently called twice: early when read_backend_info is called, and again from setupmusic.
'The first call (music_status = musicOff) will be missing decoder info.
function music_get_info() as string
	#ifdef SDL_MIXER2
		#define sdlX "SDL2"
		' The .dll/.so name is in globals.bas, generated by verprint
		#define SONAME libsdl2_mixer_name
	#else
		#define sdlX "SDL"
		#define SONAME libsdl_mixer_name
	#endif

	dim ret as string = "music_" & lcase(sdlX)
	dim libhandle as any ptr

	#ifdef __FB_DARWIN__
		libhandle = dylib_noload(sdlX "_mixer.framework/" sdlX "_mixer")
	#elseif defined(__FB_WIN32__) or defined(__FB_JS__)
		'Shouldn't need to bother with dylib_noload
		libhandle = dylibload(SONAME)
	#else ' __FB_UNIX__
		'Especially on Linux must make sure we don't load a different (system) .so
		'to the one we're linked to (possibly a library in linux/$arch/)
		'Don't really need to bother with dylib_noload on Windows
		libhandle = dylib_noload(SONAME)
		if libhandle then
			_Mix_GetNumMusicDecoders = dylibsymbol(libhandle, "Mix_GetNumMusicDecoders")
			_Mix_GetNumChunkDecoders = dylibsymbol(libhandle, "Mix_GetNumChunkDecoders")
			_Mix_GetMusicDecoder = dylibsymbol(libhandle, "Mix_GetMusicDecoder")
			_Mix_GetChunkDecoder = dylibsymbol(libhandle, "Mix_GetChunkDecoder")
			_ModPlug_GetSettings = dylibsymbol(libhandle, "ModPlug_GetSettings")
			_ModPlug_SetSettings = dylibsymbol(libhandle, "ModPlug_SetSettings")
		else
			debug "dylib_noload(" & SONAME & ") failed. Continuing"
		end if
	#endif

	dim ver as const SDL_version ptr
	if gfxbackend <> "sdl" andalso gfxbackend <> "sdl2" then
		#ifdef SDL_MIXER2
			dim ver2 as SDL_version
			SDL_GetVersion(@ver2)
			ver = @ver2
		#else
			ver = SDL_Linked_Version()
		#endif
		ret += ", SDL " & ver->major & "." & ver->minor & "." & ver->patch
	end if

	ver = Mix_Linked_Version()
	ret += ", SDL_Mixer " & ver->major & "." & ver->minor & "." & ver->patch
	mixer_version = ver->major * 1000 + ver->minor * 100 + ver->patch

	if music_status = musicOn then
		dim freq as int32, format as ushort, channels as int32
		Mix_QuerySpec(@freq, @format, @channels)
		ret += " (" & freq & "Hz"

		have_modplug = NO
		if _Mix_GetNumMusicDecoders andalso _Mix_GetMusicDecoder then
			ret += ", Music decoders:"
			for i as integer = 0 to _Mix_GetNumMusicDecoders() - 1
				if i > 0 then ret += ","
				dim form as string = *_Mix_GetMusicDecoder(i)
				ret += form

				'SDL2_mixer lists the file formats in the list of decoders,
				'SDL_mixer 1.2 may only list the decoders, such as MIKMOD.
				'Mix_GetChunkDecoder only lists file formats, not decoders.
				if form = "MP3" then
					'Note: SDL_mixer 1.2 reports "MP3" only regardless of which library it's
					'using, 2.x also reports "MPG123", "DRMP3", "SMPEG", or "MAD".
					'SDL_mixer 1.2.13 (unreleased) supports only libmad or libmpg123, not smpeg.
					'smpeg may crash for non-44.1kHz MP3s (bug #372), so don't support them on
					'SDL_mixer <= 1.2.12 Mac/Linux, where it's very probably linked to smpeg.
					'(Latest SDL_mixer 1.2.13 from git, used by some distros, has finally
					'dropped smpeg support)
					#ifdef __FB_WIN32__
						supported_formats or= FORMAT_MP3
					#else
						if mixer_version >= 1213 then
							supported_formats or= FORMAT_MP3
						end if
					#endif
				elseif form = "OGG" then
					supported_formats or= FORMAT_OGG
				elseif form = "FLAC" then
					supported_formats or= FORMAT_FLAC
				elseif form = "WAVE" then
					supported_formats or= FORMAT_WAV
				elseif form = "MOD" then
					supported_formats or= FORMAT_MODULES
				elseif form = "MODPLUG" then
					supported_formats or= FORMAT_MODULES
					have_modplug = YES
				elseif form = "MIKMOD" then
					supported_formats or= FORMAT_MODULES
				elseif form = "MIDI" or form = "TIMIDITY" or form = "FLUIDSYNTH" or form = "NATIVEMIDI" then
					supported_formats or= FORMAT_MIDI or FORMAT_BAM
				end if
			next
		else
			'A very out of date copy of SDL_mixer (1.2). Assume linked to SMPEG
			supported_formats = FORMAT_BAM or FORMAT_MIDI or FORMAT_MODULES or FORMAT_OGG or FORMAT_WAV
		end if

		if _Mix_GetNumChunkDecoders andalso _Mix_GetChunkDecoder then
			'BTW, SDL_mixer 1.2 doesn't support playing .mp3 sound effects (chunks)!
			ret += " Sample decoders:"
			for i as integer = 0 to _Mix_GetNumChunkDecoders() - 1
				if i > 0 then ret += ","
				ret += *_Mix_GetChunkDecoder(i)
			next
		end if

		ret += ")"
	end if

	if libhandle then dylibfree(libhandle)

	return ret
end function

'Note that the backend will still be asked to play files it doesn't report supporting
function music_supported_formats() as integer
	return supported_formats and VALID_MUSIC_FORMAT
end function

function sound_supported_formats() as integer
	return supported_formats and VALID_SFX_FORMAT
end function

sub music_init()
	if music_status = musicOff then
		dim audio_rate as integer
		dim audio_format as Uint16
		dim audio_channels as integer
		dim audio_buffers as integer

		#if defined(__FB_UNIX__) and defined(SDL_MIXER2)
			'SDL2_mixer only looks for soundfonts for its default fluidsynth MIDI backend at
			'/usr/share/sounds/sf2/FluidR3_GM.sf2 but there are a couple other common places for distros
			'to put them; otherwise the user needs to set the SDL_SOUNDFONTS envvar. Mix_SetSoundFonts
			'overrides SDL_SOUNDFONTS, so make sure we don't do that, and the built default is used only
			'if neither of those is available.
			dim soundfonts as zstring ptr = SDL_getenv("SDL_SOUNDFONTS")
			if soundfonts = NULL orelse len(*soundfonts) = 0 then
				'This list based on one from OpenTTD
				dim default_paths(...) as string = { _
					_ ' Debian/Ubuntu/OpenSUSE/Slackware
					"/usr/share/sounds/sf2/FluidR3_GM.sf2", _
					"/usr/share/sounds/sf2/TimGM6mb.sf2", _
					"/usr/share/sounds/sf2/FluidR3_GS.sf2", _
					_ ' RedHat/Fedora/Arch
					"/usr/share/soundfonts/FluidR3_GM.sf2", _
					"/usr/share/soundfonts/FluidR3_GS.sf2" _
				}
				'Only pass on paths that exist, otherwise errors are printed to stderr
				dim paths as string
				for idx as integer = 0 to ubound(default_paths)
					if isfile(default_paths(idx)) then
						if len(paths) then paths &= ":;"
						paths &= default_paths(idx)
					end if
				next
				if len(paths) then
					Mix_SetSoundFonts(strptr(paths))
				else
					debuginfo "Warning: no soundfonts for MIDI playback using fluidsynth found in common " _
						  "locations. Set the SDL_SOUNDFONTS environmental variable if you've installed them."
				end if
			end if
		#endif

		#ifndef SDL_MIXER2
			' MIX_DEFAULT_FREQUENCY is 22050, which slightly worsens sound quality
			' than playing at 44100, but using 44100 causes tracks between 22-44kHz
			' to be sped up, which sounds worse. See https://github.com/ohrrpgce/ohrrpgce/issues/1085
			audio_rate = MIX_DEFAULT_FREQUENCY
			'Despite the documentation, non power of 2 buffer size MAY work depending on the driver, and pygame even does it
			'1024 seems to give much lower delay than 1536 before being played, maybe a non-power of two problem
			audio_buffers = 1024 '1536
		#else
			' SDL_mixer 2: the above problem doesn't apply
			audio_rate = 44100
			audio_buffers = 2048 'Might as well increase to match (effect not investigated)

			'SDL_SetHint("SDL_MIXER_DEBUG_MUSIC_INTERFACES", "1")
		#endif
		audio_format = MIX_DEFAULT_FORMAT
		audio_channels = 2

		if SDL_WasInit(0) = 0 then
			if SDL_Init(SDL_INIT_AUDIO) then
				debug "Can't start SDL (audio): " & *SDL_GetError
				music_status = musicError
				exit sub
			end if
		elseif SDL_WasInit(SDL_INIT_AUDIO) = 0 then
			if SDL_InitSubSystem(SDL_INIT_AUDIO) then
				debug "Can't start SDL audio subsys: " & *SDL_GetError
				music_status = musicError
				quit_sdl_audio()
				exit sub
			end if
		end if

		if (Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers)) <> 0 then
			'if (Mix_OpenAudio(audio_rate, audio_format, audio_channels, 2048)) <> 0 then
				debug "Can't open audio : " & *Mix_GetError
				music_status = musicError
				quit_sdl_audio()
				exit sub
			'end if
		end if

		music_vol = 0.5
		music_status = musicOn
		music_paused = NO

		'Kludge, just for Mix_GetChunkDecoder/Mix_GetMusicDecoder: these don't tell
		'about all supported formats until the dynamic libraries are actually
		'loaded. So force loading them. (SDL_mixer 2.0.2 only, earlier versions always
		'loaded everything from Mix_OpenAudio). Increasing startup time just to get
		'supported_formats is sad, but at least it prevents pauses later.
		Mix_Init(MIX_INIT_MID or MIX_INIT_OGG or MIX_INIT_MP3 or MIX_INIT_MOD)
		'SDL_mixer 1.2.12 bug: if compiled against libmad Mix_Init sets the error "Mixer not built with MP3 support"
		'if Mix_GetError then debug "Mix_Init: " & *Mix_GetError
		Mix_ClearError
	end if
end sub

sub music_close()
	if music_status = musicOn then
		if orig_vol > 0 then
			'restore original volume
			Mix_VolumeMusic(orig_vol)
		else
			'arbitrary medium value
			Mix_VolumeMusic(0.5 * MIX_MAX_VOLUME)
		end if

		music_stop()
		Mix_CloseAudio()
		quit_sdl_audio()

		music_status = musicOff
		callback_set_up = NO	' For SFX

		for i as integer = 0 to ubound(tempfiles)
			safekill tempfiles(i)
		next
		erase tempfiles
	end if
end sub

sub music_play(byval lump as Lump ptr, byval fmt as MusicFormatEnum)

end sub

sub music_play(filename as string, byval fmt as MusicFormatEnum)
	if music_status = musicOn then
		dim songname as string = filename
		if fmt = FORMAT_BAM then
			dim midname as string
			'use last 3 hex digits of length as a kind of hash,
			'to verify that the .bmd does belong to this file
			'(Note that all instances of Custom currently share tmpdir;
			'should fix that)
			dim as integer fhash = filelen(songname) and &h0fff
			midname = tmpdir & trimpath(songname) & "-" & lcase(hex(fhash)) & ".bmd"
			'check if already converted
			if isfile(midname) = NO then
				bam2mid(songname, midname)
				a_append tempfiles(), midname
			end if
			songname = midname
			fmt = FORMAT_MIDI
		end if

		music_stop

		#ifndef __FB_WIN32__
			if getmusictype(songname) and FORMAT_MODULES then
				'Hack. Work around SDL_mixer bug 1499: SDL_mixer (before Jan 2021)
				'and SDL2_mixer (before 2.6.0) did not enable loop points in modplug
				'(nor mikmod), although our Windows builds had it enabled.  In case
				'not using a custom build, try to enable loop points. Must happen
				'before playing.
				enable_modplug_looping
			end if
		#endif

		log_openfile songname

		'Versions of SDL_mixer 1.2 before 1.2.12 (the final release) failed to
		'close the file when playing MOD or WAV music files using Mix_LoadMUS!
		'(Bugs 1021, 1168).
		'So we use Mix_LoadMUS_RW instead.
		'In SDL_mixer 1.2, Mix_LoadMUS_RW does not close the RWops, so we close it
		'after stopping the music using the complicated safe_RWops() wrapper logic.
		'SDL_mixer 2.0.0 fixes this problem, adding an argument to Mix_LoadMUS_RW
		'telling whether to close the RWops.
		#ifdef SDL_MIXER2
			music_song = Mix_LoadMUS(songname)
		#else
			music_song_rw = SDL_RWFromFile(songname, @"rb")
			if music_song_rw = NULL then
				debug "Couldn't SDL_RWFromFile(" + songname + "): " & *SDL_GetError()
				exit sub
			end if
			music_song_rw = safe_RWops(music_song_rw)
			music_song = Mix_LoadMUS_RW(music_song_rw)
		#endif

		if music_song = 0 then
			debug "Could not load song " + songname + " : " & *Mix_GetError
			exit sub
		end if

		music_paused = NO
		if Mix_PlayMusic(music_song, -1) then
			debug "Could not Mix_PlayMusic " + songname + " : " & *Mix_GetError
			music_stop
			exit sub
		end if

		'not really working when songs are being faded in.
		if orig_vol = -1 then
			orig_vol = Mix_VolumeMusic(-1)
		end if

		dim volume_mult as double = 1.

		'SDL_mixer 2.6.0 halves modplug volume (a change first backported to
		'our SDL_mixer.dll 1.2.13 build and then later also officially
		'backported to SDL_mixer 1.2), so we halve the volume when using
		'older versions, for consistency.
		'(Our pre-2.6.0 build of SDL2_mixer.dll identified as 2.0.5)
		if (fmt and FORMAT_MODULES) andalso have_modplug then
			#ifdef SDL_MIXER2
				if mixer_version < 2005 then volume_mult = 0.5
			#else
				if mixer_version < 1213 then volume_mult = 0.5
			#endif
		end if

		Mix_VolumeMusic(music_vol * volume_mult * MIX_MAX_VOLUME)

		if fmt <> FORMAT_MIDI then
			nonmidi_playing = YES
		else
			nonmidi_playing = NO
		end if
	end if
end sub

sub music_pause()
	'Pause is broken in SDL_Mixer, so just stop.
	'A look at the source indicates that it won't work for MIDI
	if music_status = musicOn then
		if music_song > 0 then
			Mix_HaltMusic
			nonmidi_playing = NO
		end if
	end if
end sub

sub music_resume()
	if music_status = musicOn then
		if music_song > 0 then
			Mix_ResumeMusic
			music_paused = NO
		end if
	end if
end sub

sub music_stop()
	if music_song <> 0 then
		Mix_FreeMusic(music_song)
		music_song = 0
		music_paused = NO
		nonmidi_playing = NO
	end if
	#ifndef SDL_MIXER2
		if music_song_rw <> 0 then
			'Is safe even if has already been closed and freed
			safe_RWops_close(music_song_rw)
			music_song_rw = NULL
		end if
	#endif
end sub


' Info on [Bug 843] Sound effects now affected by volume (on Windows)
'
' Note that Mix_VolumeMusic(-1) does not return the system
' MIDI volume level on Windows, it just returns what was set last.
'
' Windows XP:
' In Volume Control is a slider for SW Synth, the MIDI
' synthesizer. Setting the music volume while playing a MIDI
' sends a MIDI event which sets the SW Synth volume level,
' which can be overridden in Volume Control (note that Volume
' Control doesn't update the slider live).
'
' Windows 7+:
' The MIDI volume control is gone. Instead, apparently trying
' to set the MIDI volume (by midiOutSetVolume, which is what
' SDL_mixer does), actually sets the process's volume instead
' (waveOutSetVolume). The process volume is AFAIK not otherwise
' modified by SDL. Meaning sfx can only be quieter than MIDI.
' TODO: does it make sense to reset waveOutSetVolume after
' playing a MIDI?
' Two possible workarounds:
' -Set volume on each MIDI note instead of on the stream
'  (would need to patch SDL_mixer/use music_native)
' -Use a separate process to play MIDI, see code from Eternity Engine here:
'  https://www.doomworld.com/vb/post/1124981
' -Maybe use some new Vista+ API:
'  http://stackoverflow.com/a/19940489/1185152
' See https://www.doomworld.com/vb/source-ports/63861-windows-sound-any-general-fixes/
' for a summary
'
' Also even in old Windows there are problems with the MIDI
' volume if not using the SW Synth.
' http://forums.libsdl.org/viewtopic.php?t=949
'
' See also http://odamex.net/bugs/show_bug.cgi?id=863
' about the midiOutSetVolume volume curve being logarithmic,
' unlike SDL_mixer's internal volume.

' Volume fading: see r2283

sub music_setvolume(byval vol as single)
	'SDL_mixer (unfortunately) internally clamps to MIX_MAX_VOLUME, so we don't need to
	music_vol = large(vol, 0.)
	if music_status = musicOn then
		Mix_VolumeMusic(music_vol * MIX_MAX_VOLUME)
	end if
end sub

function music_getvolume() as single
	'return Mix_VolumeMusic(-1) / MIX_MAX_VOLUME
	return music_vol
end function

'------------ Sound effects --------------

DECLARE sub SDL_done_playing cdecl(byval channel as int32)

' The SDL_Mixer channel number is equal to the SoundEffectSlot index
TYPE SoundEffectSlot EXTENDS SFXCommonData
	used as bool        'whether this slot is free

	playing as bool     'Set to false by a callback when the channel finishes

	buf as Mix_Chunk ptr
END TYPE

'music_sdl has an arbitrary limit of 16 sound effects playing at once:
dim shared sfx_slots(15) as SoundEffectSlot

dim shared sound_inited as bool

sub sound_init
	'if this were called twice, the world would end.
	if sound_inited then exit sub

	'anything that might be initialized here is done in music_init
	'but, I must do it here too
	music_init
	Mix_AllocateChannels(ubound(sfx_slots) + 1)
	if callback_set_up = NO then
		Mix_channelFinished(@SDL_done_playing)
		callback_set_up = YES
	end if
	sound_inited = YES
end sub

sub sound_reset
	'trying to free something that's already freed... bad!
	if sound_inited = NO then exit sub
	for slot as integer = 0 to ubound(sfx_slots)
		sound_unload(slot)
	next
end sub

sub sound_close
	sound_reset()
	sound_inited = NO
end sub


' Returns -1 if too many sounds already playing/loaded
function next_free_slot() as integer
	static retake_slot as integer = 0
	dim i as integer

	'Look for empty slots
	for i = 0 to ubound(sfx_slots)
		if sfx_slots(i).used = NO then
			return i
		end if
	next

	'Look for silent slots
	for i = 0 to ubound(sfx_slots)
		retake_slot = (retake_slot + 1) mod (ubound(sfx_slots)+1)
		with sfx_slots(retake_slot)
			if .playing = NO then
				Mix_FreeChunk(.buf)
				.used = NO
				return retake_slot
			end if
		end with
	next

	return -1 ' no slot found
end function

'Resumes a sfx if it's paused
sub sound_play(slot as integer, loopcount as integer, volume as single = 1.)
	if slot = -1 then exit sub

	' sfx_slots acts like a cache in this backend, since .buf
	' remains loaded after the sound effect has stopped.
	with sfx_slots(slot)
		if .buf = 0 then
			showbug "sound_play: not loaded"
			exit sub
		end if

		if .playing = NO then
			' Note that the i-th sfx slot is played on the i-th SDL_mixer channel,
			' which is just a simplification.
			if Mix_PlayChannel(slot, .buf, loopcount) = -1 then
				showbug "sound_play: Mix_PlayChannel failed:" & *Mix_GetError()
				exit sub
			end if
			.playing = YES
		end if

		if Mix_Paused(slot) then
			' Haven't tested, but it looks like SDL_mixer doesn't clear its paused flag
			' when a channel stops
			Mix_Resume(slot)
		end if

		' SDL_mixer has separate channel and chunk volumes and multiples them.
		' We do the multiplication ourselves, only using channel volumes.
		' Note that the built-in support for fades works by adjust channel
		' volumes, not chunk volumes. And volumes are capped to 100%.
		Mix_Volume(slot, volume * MIX_MAX_VOLUME)
	end with
end sub

sub sound_pause(slot as integer)
	if slot = -1 then exit sub
	with sfx_slots(slot)
		if .playing then
			Mix_Pause(slot)
		end if
	end with
end sub

sub sound_stop(slot as integer)
	if slot = -1 then exit sub
	with sfx_slots(slot)
		if .playing then
			Mix_HaltChannel(slot)
			.playing = NO
		end if
	end with
end sub

sub sound_setvolume(slot as integer, volume as single)
	if slot = -1 then exit sub
	Mix_Volume(slot, volume * MIX_MAX_VOLUME)
end sub

function sound_getvolume(slot as integer) as single
	if slot = -1 then return 0.
	return Mix_Volume(slot, -1) / MIX_MAX_VOLUME
end function

sub sound_free(num as integer)
	for slot as integer = 0 to ubound(sfx_slots)
		with sfx_slots(slot)
			if .effectID = num then sound_unload slot
		end with
	next
end sub

function sound_playing(slot as integer) as bool
	if slot = -1 then return NO
	if sfx_slots(slot).used = NO then return NO

	return sfx_slots(slot).playing
end function

function sound_slotdata(slot as integer) as SFXCommonData ptr
	if slot < 0 or slot > ubound(sfx_slots) then return NULL
	if sfx_slots(slot).used = NO then return NULL
	return @sfx_slots(slot)
end function

function sound_lastslot() as integer
	return ubound(sfx_slots)
end function

' Returns the first sound slot with the given sound effect ID (num);
' if the sound is not loaded, returns -1.
function sound_slot_with_id(num as integer) as integer
	for slot as integer = 0 to ubound(sfx_slots)
		with sfx_slots(slot)
			if .used andalso .effectID = num then return slot
		end with
	next

	return -1
end function

'Loads a sound into a slot, and marks its ID num (equal to OHR sfx number).
'Returns the slot number, or -1 if an error occurs.
function sound_load overload(lump as Lump ptr, num as integer = -1) as integer
	return -1
end function

function sound_load overload(filename as string, num as integer = -1) as integer
	dim slot as integer
	dim sfx as Mix_Chunk ptr

	if filename = "" then return -1
	if not isfile(filename) then return -1

	'File size restriction to stop massive oggs being decompressed
	'into memory.
	'(this check is now only done in browse.bas when importing)
	'if filelen(filename) > 500*1024 then
	'	debug "Sound effect file too large (>500k): " & filename
	'	return -1
	'end if

	log_openfile filename
	sfx = Mix_LoadWAV(@filename[0])
	if sfx = NULL then
		debug "Couldn't Mix_LoadWAV " & filename & " : " & *Mix_GetError()
		return -1
	end if

	slot = next_free_slot()
	'debuginfo "sound_load(" & filename & "," & num & ") in slot " & slot

	if slot = -1 then
		debuginfo "sound_load(""" & filename & """, " & num & ") no more sound slots available"
	else
		with sfx_slots(slot)
			.used = YES
			.effectID = num
			.buf = sfx
			.playing = NO
		end with
	end if

	return slot
end function

'Unloads a sound loaded in a slot. TAKES A CACHE SLOT, NOT AN SFX ID NUMBER!
sub sound_unload(slot as integer)
	with sfx_slots(slot)
		if .used = NO then exit sub
		Mix_FreeChunk(.buf)
		.playing = NO
		.used = NO
		.effectID = 0
		.buf = 0
	end with
end sub

sub SDL_done_playing cdecl(byval channel as int32)
	sfx_slots(channel).playing = NO
end sub

'-- for debugging
function sfx_slot_info (byval slot as integer) as string
	with sfx_slots(slot)
		return strprintf("slot %d used=%d sfx=%d playing=%d paused=%d buf=%x", _
				 slot, .used, .effectID, .playing, Mix_Paused(slot), .buf)
	end with
end function


'================================================================================
'                                    ModPlug settings
'
' This is obsolete since we now use libxmp instead of libmodplug whenever possible.

type ModplugSettingsMenu extends ModularMenu
	settings as ModPlug_Settings

	declare sub update ()
	declare function each_tick () as bool
end type

sub ModplugSettingsMenu.update ()
	_ModPlug_SetSettings(@settings)

	redim menu(4)
	state.last = ubound(menu)

	menu(0) = "Previous Menu..."
	menu(1) = "Noise reduction: " & yesorno(settings.mFlags and MODPLUG_ENABLE_NOISE_REDUCTION)
	menu(2) = "Reverb: " & settings.mReverbDepth & "%"
	menu(3) = "Surround: " & yesorno(settings.mFlags and MODPLUG_ENABLE_SURROUND)
	menu(4) = "Megabass: " & settings.mBassAmount & "%"
end sub

function ModplugSettingsMenu.each_tick () as bool
	dim changed as bool
	select case state.pt
		case 0
			if enter_space_click(state) then return YES
		case 1
			changed = bitgrabber(settings.mFlags, MODPLUG_ENABLE_NOISE_REDUCTION, state)
		case 2
			changed = intgrabber(settings.mReverbDepth, 0, 100)
			setbitmask settings.mFlags, MODPLUG_ENABLE_REVERB, settings.mReverbDepth > 0
		case 3
			changed = bitgrabber(settings.mFlags, MODPLUG_ENABLE_SURROUND, state)
		case 4
			changed = intgrabber(settings.mBassAmount, 0, 100)
			setbitmask settings.mFlags, MODPLUG_ENABLE_MEGABASS, settings.mBassAmount > 0
	end select
	state.need_update or= changed
end function

function modplug_settings_menu () as bool
	if _ModPlug_GetSettings = NULL or _ModPlug_SetSettings = NULL then return NO

	dim menu as ModplugSettingsMenu
	menu.floating = YES
	menu.tooltip = "ModPlug settings (not saved)"
	_ModPlug_GetSettings(@menu.settings)
	menu.run()
	_ModPlug_SetSettings(@menu.settings)
	return YES
end function

function music_settings_menu () as bool
	return modplug_settings_menu()
end function

#ifndef __FB_WIN32__
'Try to override SDL_mixer's disabling of loop points in ModPlug.
'Does not affect any currently playing module.
'Not needed if using our SDL_mixer.dll on Windows.
sub enable_modplug_looping ()
	if tried_enabling_modplug_loops then exit sub
	tried_enabling_modplug_loops = YES

	'When, and only when, SDL_Mixer's modplug backend is first loaded it will call
	'ModPlug_SetSettings, so ensure that has happened so our changes aren't clobbered
	'(currently, we already do this in music_init())
	if Mix_Init(MIX_INIT_MOD) = 0 then exit sub  'Can't play mods

	'Don't go loading modplug if SDL_mixer isn't using it
	if have_modplug = NO then exit sub

	if _ModPlug_GetSettings = NULL orelse _ModPlug_SetSettings = NULL then
		'Using NULL as the module handle doesn't work, as SDL_mixer doesn't
		'load modplug into the global namespace.
		#ifdef __FB_DARWIN__
			modplug_handle = dylibload("modplug.framework/modplug")
		#endif
		if modplug_handle = NULL then
			modplug_handle = dylibload("modplug")
		end if
		if modplug_handle then
			debuginfo "Loaded libmodplug"
			_ModPlug_GetSettings = dylibsymbol(modplug_handle, "ModPlug_GetSettings")
			_ModPlug_SetSettings = dylibsymbol(modplug_handle, "ModPlug_SetSettings")

			if _ModPlug_GetSettings = NULL orelse _ModPlug_SetSettings = NULL then
				debuginfo "ModPlug_Get/SetSettings missing!"
				exit sub
			end if
		else
			debuginfo "Couldn't load libmodplug"
			exit sub
		end if
	end if

	dim settings as ModPlug_Settings
	_ModPlug_GetSettings(@settings)
	if settings.mLoopCount = -1 then
		'debuginfo "ModPlug looping already enabled"
	else
		debuginfo "Enabling ModPlug looping"
		settings.mLoopCount = -1
		_ModPlug_SetSettings(@settings)
	end if
end sub
#endif
