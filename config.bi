'OHRRPGCE - Configuration/platform specific/important macros
'(C) Copyright 1997-2020 James Paige, Ralph Versteegen, and the OHRRPGCE Developers
'Dual licensed under the GNU GPL v2+ and MIT Licenses. Read LICENSE.txt for terms and disclaimer of liability.
'
'This file is (should be) included everywhere, and is a dumping ground for macros and other global declarations

#IFNDEF CONFIG_BI
#DEFINE CONFIG_BI


'================================== Global namespace cleanup ==============================

#UNDEF name
#UNDEF color
#UNDEF data
#UNDEF draw
#UNDEF out
#UNDEF read
#UNDEF reset
#UNDEF restore
#UNDEF stop
#UNDEF tab
#UNDEF wait
#UNDEF window
#UNDEF width
'#UNDEF palette
#UNDEF pos
#UNDEF pos  ' You need to undef POS twice! Why??
#UNDEF point

'====================================== Build string ======================================

' Build options which can be detected with compiler defines are here; others are generated by verprint()
#IF __FB_DEBUG__
 #DEFINE _GSTR " -g"
#ELSE
 #DEFINE _GSTR
#ENDIF
#IF (__FB_ERR__ AND 7) = 7
 #DEFINE _ESTR " -exx"
#ELSE
 #DEFINE _ESTR
#ENDIF
#IF __FB_GCC__
 #DEFINE _GENSTR " -gen gcc"
#ELSE
 #DEFINE _GENSTR
#ENDIF
#IF     defined( __FB_ANDROID__)
 #DEFINE _PSTR " Android"
#ELSEIF defined( __FB_LINUX__)
 #DEFINE _PSTR " Linux"
#ELSEIF defined(__FB_FREEBSD__)
 #DEFINE _PSTR " FreeBSD"
#ELSEIF defined(__FB_NETBSD__)
 #DEFINE _PSTR " NetBSD"
#ELSEIF defined(__FB_OPENBSD__)
 #DEFINE _PSTR " OpenBSD"
#ELSEIF defined(__FB_DARWIN__)
 #DEFINE _PSTR " Mac OS X/Darwin"
#ELSEIF defined(__FB_WIN32__)
 #DEFINE _PSTR " Win32"
#ELSEIF defined(__FB_DOS__)
 #DEFINE _PSTR " DOS"
#ELSE
 #DEFINE _PSTR " Unknown Platform"
#ENDIF
#IFDEF __FB_64BIT__
 #DEFINE _BSTR " 64-bit"
#ELSE
 #DEFINE _BSTR " 32-bit"
#ENDIF
#DEFINE STRINGIFY(x) #x  'Equivalent to __FB_QUOTE__, which is FB 1.08+
CONST build_info as string = _GSTR _ESTR " FB_ERR=" STRINGIFY(__FB_ERR__) _GENSTR _PSTR _BSTR


'==================================== OS-specific defines =================================

#IFDEF __FB_ANDROID__
 #DEFINE LOWMEM
#ENDIF

' FB's headers check for __FB_LINUX__ but are missing headers for other unices
' as only GNU/Linux is fully supported (although I created some of the more
' important CRT headers for Darwin) so define __FB_LINUX__ so that we get some
' headers.
' So NEVER use __FB_LINUX__! Use __GNU_LINUX__ instead.
#ifdef __FB_LINUX__
 #define __GNU_LINUX__
#endif

'We need to include CRT headers (specifically, just crt/stdio.bi at the moment)
'before we muck with __FB_LINUX__, which will cause wrong OS-specific header to
'be included.
#include once "crt.bi"
#include once "crt/limits.bi"
#undef rand
#include once "crt/stddef.bi"
#include once "crt/sys/types.bi"

#ifdef __FB_UNIX__
 #define __FB_LINUX__
#endif

#ifdef __FB_WIN32__
 'These are broken in msvcrt.dll, use mingw's overrides instead. See config.h.
 #undef snprintf
 #undef vsnprintf
 extern "C"
 declare function __mingw_snprintf (byval as zstring ptr, byval as size_t, byval as zstring ptr, ...) as long
 declare function __mingw_vsnprintf (byval as zstring ptr, byval as size_t, byval as zstring ptr, byval as va_list) as long
 end extern
 #define snprintf __mingw_snprintf
 #define vsnprintf __mingw_vsnprint
#endif

'Universal Windows Platform (Windows Store and XBox One)
'#define UWP

#if defined(__FB_UNIX__) and not (defined(__FB_DARWIN__) or defined(__FB_ANDROID__)) and not defined(NO_X11)
 #define USE_X11
#endif

'' __FB_X86__ was added in FB 1.08. Older versions support x86 and ARM only
#if (__FB_VER_MAJOR__ * 100 + __FB_VER_MINOR__ < 108) and (not defined(__FB_ARM__)) and (not defined(__FB_X86__))
 #define __FB_X86__
#endif

#ifdef __FB_UNIX__
#define SLASH "/"
#define ispathsep(character) (character = ASC("/"))
#define LINE_END !"\n"
#define CUSTOMEXE "ohrrpgce-custom"
#define GAMEEXE "ohrrpgce-game"
#define DOTEXE ""
#define ALLFILES "*"
#else
#define SLASH "\"
#define ispathsep(character) (character = ASC("/") OR character = ASC("\"))
#define LINE_END !"\r\n"
#define CUSTOMEXE "custom.exe"
#define GAMEEXE "game.exe"
#define DOTEXE ".exe"
#define ALLFILES "*.*"
#endif


'======================================= More defines =====================================

'A UTF8 unicode string. This is just for code documentation.
type USTRING as STRING

'This is useful as a prefix in ohrrpgce_config.ini
#ifdef IS_GAME
 #define exe_prefix "game."
#elseif defined(IS_CUSTOM)
 #define exe_prefix "edit."
#else
 #define exe_prefix ""
#endif

'---For some crazy reason TRUE and FALSE don't work well as const even though they are not reserved
'(Postscript: true and false are FB builtin constants, of type 'boolean' rather than 'integer'.
'That may or may not cause problems.)
CONST YES = -1
CONST NO = 0

#IFNDEF NULL
#DEFINE NULL 0
#ENDIF

'Marking a function PRIVATE indicates that the function is internal and
'shouldn't/ can't be called from outside the file. But it also tells the
'compiler not to export that symbol, so that on GNU/Linux backtrace_symbols()
'won't know it, and can also result in .pdb debug symbols not being produced
'when using cv2pdb.  It also encourages the compiler to inline the function.  So
'use LOCAL instead of PRIVATE to indicate the same thing (as documentation only)
'without debug symbol problems.
#UNDEF LOCAL  'LOCAL is a FB keyword used only in ON LOCAL ERROR GOTO
#DEFINE LOCAL


'================================= 32/64 bit differences ==================================


' We put a few declarations in a namespace so that they aren't lost after including
' windows.bi and #undefing. If more include_windows_bi() problems occur we can get
' around them by moving more stuff into this namespace.
NAMESPACE OHR

' TODO: FB 1.04+ has a boolean type, which we ignore for now
' (it's 1 bit in size and compatible with C/C++ bool)
#IFDEF __FB_64BIT__
  TYPE bool as long  '32 bit
#ELSE
  'Tip: Change this to 'long' to cause warnings for inconsistent usage of bool vs integer
  TYPE bool as integer
#ENDIF

' I will use boolint in declarations of C/C++ functions where we would like to use
' bool (C/C++) or boolean (FB), but shouldn't, to support FB pre-1.04. So instead,
' use boolint on both sides, to show intention but prevent accidental C/C++ bool usage.
TYPE boolint as long  '32 bit

'Even though long and integer are the same size on 32 bit platforms,
'fbc considers them different types and throws warnings!
'This is because they get mangled to C long and int types respectively.
'Likewise, integer and longint could be different on 64 bit. See crt/long.bi.
#IFDEF __FB_64BIT__
  #IFNDEF int32
    TYPE int32 as long
  #ENDIF
  #IFNDEF uint32
    TYPE uint32 as ulong
  #ENDIF
  TYPE int64 as integer
  TYPE uint64 as uinteger
  #IFNDEF ssize_t
    TYPE ssize_t as integer
  #ENDIF
#ELSE
  #IFNDEF int32
    TYPE int32 as integer
  #ENDIF
  #IFNDEF uint32
    TYPE uint32 as uinteger
  #ENDIF
  TYPE int64 as longint
  TYPE uint64 as ulongint
  #IFNDEF ssize_t
    TYPE ssize_t as integer
  #ENDIF
#ENDIF

END NAMESPACE

USING OHR

TYPE fb_integer as integer
TYPE fb_uinteger as uinteger

' Use of the following two macros may be needed when including
' certain external headers. Most FB headers have no or almost no
' instances of 'integer'. Strangely there are a few random occurrences.
' To be safe, put 'use_native_integer' before and 'use_32bit_integer'
' after an 'unclean' include.


#MACRO use_native_integer()
# IFDEF __FB_64BIT__
#  UNDEF integer
#  UNDEF uinteger
   TYPE integer as fb_integer
   TYPE uinteger as fb_uinteger
# ENDIF
#ENDMACRO

#MACRO use_32bit_integer()
# IFDEF __FB_64BIT__
#  UNDEF integer
#  UNDEF uinteger
   TYPE integer as int32
   TYPE uinteger as uint32
# ENDIF
#ENDMACRO

#ifndef intptr_t
 ' Old FB headers
 TYPE intptr_t as size_t
#endif

'Needs to be included with native integer. Easiest to just include it here to
'avoid mistakes, since it would otherwise be included a lot, directly or indirectly.
#include "file.bi"

'Note: we already included crt.bi, need to do so before redefining the size of 'integer'
use_32bit_integer()


'======================================== windows.bi ======================================

' include_windows_bi() MUST be used after config.bi is included but before anything else!
#macro include_windows_bi()
# ifndef windows_bi_included
#  define windows_bi_included
#  define _X86_
   use_native_integer()
   ' We DON'T use unicode (UTF16) versions of winapi functions. We're not ready to switch.
   ' But some files (such as SDL_windowsclipboard.c) do use the unicode api.
'#  define UNICODE
#  include once "windows.bi"
' Almost everywhere, the following two headers are enough
' #  include once "win/windef.bi"
' #  include once "win/winbase.bi"
' ' The following two .bi's are in order to undef iswindow so can include SDL.bi, which includes windows.bi
' #  include once "win/wingdi.bi"
' #  include once "win/winuser.bi"
   use_32bit_integer()
#  undef max
#  undef min
#  undef default_palette
#  undef sound_playing
#  undef copyfile
#  undef istag
#  undef ignore
#  undef iswindow
#  undef rectangle
#  undef ellipse
#  undef color_menu
#  undef openfile
   'Needed in music_native2.bas
   type MSG_ as MSG
   const TRANSPARENT_ = TRANSPARENT
#  undef msg
#  undef this
#  undef font
#  undef opaque
#  undef transparent
#  undef bool
# endif
#endmacro


'==================================== TIMER_START/STOP ====================================

'Warning: you may not nest TIMER_STOP/START calls!

'under windows, TIMER uses QueryPerformanceCounter, under unix it uses gettimeofday
#ifdef ACCURATETIMER
 'use a timer which counts CPU time spent by this process (preferably thread) only
 #ifdef __FB_WIN32__
  'only available on win 2000 or later
  include_windows_bi()
  #if defined(GetThreadTimes)
   #define timer_variables  as FILETIME ptr atimer_s, atimer_e, atimer_temp
   extern timer_variables
   #define READ_TIMER(a)  GetThreadTimes(GetCurrentThread, NULL, NULL, NULL, @atimer_temp): a = atimer_temp.dwLowDateTime * 0.0000001
   #define TIMER_START(a)  GetThreadTimes(GetCurrentThread, NULL, NULL, NULL, @atimer_s)
   #define TIMER_STOP(a)  GetThreadTimes(GetCurrentThread, NULL, NULL, NULL, @atimer_e): a += (atimer_e.dwLowDateTime - atimer_s.dwLowDateTime) * 0.0000001
  #else
   #print GetThreadTimes not available; don't define ACCURATETIMER
  #endif
 #else
  'assume anything else is a unix
  'options: clock, times, clock_gettime (with CLOCK_THREAD_CPUTIME_ID) which apparently counts in clock ticks (1ms)
  #define timer_variables as timespec atimer_s, atimer_e, atimer_temp
  extern timer_variables
  #define READ_TIMER(a)  clock_gettime(CLOCK_THREAD_CPUTIME_ID, @atimer_temp): a = atimer_temp.tv_nsec * 0.000000001
  #define TIMER_START(a)  clock_gettime(CLOCK_THREAD_CPUTIME_ID, @atimer_s)
  #define TIMER_STOP(a)  clock_gettime(CLOCK_THREAD_CPUTIME_ID, @atimer_e): a += (atimer_e.tv_nsec - atimer_s.tv_nsec) * 0.000000001
 #endif
#endif
#ifndef TIMER_START
 #define READ_TIMER(a)   a = TIMER
 #define TIMER_START(a) a -= TIMER
 #define TIMER_STOP(a)  a += TIMER
#endif


#ENDIF
