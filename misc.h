/* OHRRPGCE
 * This misc function declarations, mainly from miscc.c
 * Copyright 2011. Please read LICENSE.txt for GNU GPL details and disclaimer of liability
 */

#ifndef COMMON_H
#define COMMON_H

#include "config.h"

#ifdef __cplusplus
extern "C" {
#endif

// in util.bas

// Escape a filename for use in a shell in a way suitable for this OS.
// Returns a malloc'd string buffer
char *escape_filenamec (const char *filename);

// in filelayer.cpp
const char *trimpath(const char *filename);

// in common.rbas (NOTE: also defined separately in gfx_directx.cpp)
void debugc(enum ErrorLevel errorlevel, const char *msg);

// libfb.a
void _noreturn (*fb_ErrorThrowAt(int line_num, const char *mod_name, void *res_label, void *resnext_label))(void);

// in miscc.c (NOTE: _throw_error also defined separately in gfx_directx.cpp)
void _throw_error(enum ErrorLevel errorlevel, const char *srcfile, int linenum, const char *msg, ...) format_chk(4);
extern void (*debug_hook)(enum ErrorLevel errorlevel, const char *msg);
void set_debug_hook(void (*new_debug_hook)(enum ErrorLevel errorlevel, const char *msg));

#define debug(errorlevel, ...) _throw_error(errorlevel, NULL, 0, __VA_ARGS__)
#define debuginfo(...) _throw_error(errInfo, NULL, 0, __VA_ARGS__)
#define throw_error(...) _throw_error(errFatalBug, __FILE__, __LINE__, __VA_ARGS__)
#define fatal_error(...) _throw_error(errFatalError, __FILE__, __LINE__, __VA_ARGS__)

void init_fbstring(FBSTRING *fbstr, const char *cstr);
void init_fbstring_copy(FBSTRING *fbstr, FBSTRING *src);
void set_fbstring(FBSTRING *fbstr, const char *cstr);
FBSTRING *return_fbstring(FBSTRING *fbstr);
FBSTRING *empty_fbstring();
void delete_fbstring(FBSTRING *str);

uint32_t stringhash(const unsigned char *strp, int length);

void disable_extended_precision();

void init_crt();

#ifdef __cplusplus
}
#endif

#endif
