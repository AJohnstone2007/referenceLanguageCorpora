/*  ==== Win32 ANSI COMPATABILITY HEADER ====
 *
 *  Copyright 2013 Ravenbrook Limited <http://www.ravenbrook.com/>.
 *  All rights reserved.
 *  
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 *  
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 *  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 *  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  Description
 *  -----------
 *  This header defines some things which are part of the ANSI standard but
 *  missing from the C compiler / environment.
 * 
 *  See also syscalls.h, which contains prototypes for system calls
 *  which are not prototyped in include files
 * 
 *  $Id: ansi.h,v 1.1 1996/02/19 15:36:24 stephenb Exp $
 *  $Log: ansi.h,v $
 *  Revision 1.1  1996/02/19 15:36:24  stephenb
 *  new unit
 *  This used to be src/rts/src/OS/{NT,Win95}/ansi.h
 *
 * Revision 1.1  1996/02/14  12:06:41  jont
 * new unit
 *
 */

#ifndef win32_ansi_h
#define win32_ansi_h

#include <stdarg.h>
#include <stdio.h>
#include <sys/types.h>
#include <time.h>

/* Gnu C fails to define a bunch of ANSI constant macros */

#if defined(__GNUC__) || defined(OS_NT)
#define EXIT_SUCCESS	0
#define EXIT_FAILURE	1
#define SEEK_SET	0
#define SEEK_CUR	1
#define SEEK_END	2
#endif /* __GNUC__ */

/* the include files in /usr/include do not include declarations for a
large number of ANSI functions. We remedy that here. */

/* stdio.h things */

extern int fclose (FILE *stream);
extern int fflush (FILE *stream);
extern int fgetc (FILE *stream);
extern int ungetc (int c, FILE *stram);
extern int fputc (int c, FILE *stream);
extern int printf (const char *format, ...);
extern int fprintf (FILE *stream, const char *format, ...);
extern int vfprintf (FILE *stream, const char *format, va_list arg);
extern int vsprintf (char *s, const char *format, va_list arg);
extern int fputs (const char *s, FILE *stream);
extern int fscanf (FILE *stream, const char *format, ...);
extern int sscanf (const char *s, const char *format, ...);
extern int fseek (FILE *stream, long int offset, int whence);
extern size_t fread (void *ptr, size_t size, size_t nmemb, FILE *stream);
extern size_t fwrite (const void *ptr, size_t size, size_t nmemb,
		      FILE *stream);

/* This macro should be defined on systems for which the
 * implementations of sprintf and vsprintf do _not_ return the number
 * of characters written. I don't care what they _do_ return */

#define SPRINTF_IS_BROKEN

/* these functions are used in the macro definitions of putc and getc
but not declared in stdio.h */

extern int _filbuf(FILE *stream);

#ifdef __GNUC__
extern int _flsbuf(unsigned char c, FILE *stream);
#endif

/* time.h things */

#ifndef __GNUC__
typedef long clock_t;
#endif
extern size_t strftime (char *s, size_t maxsize, const char *format,
			const struct tm *timeptr);
extern time_t time (time_t *timer);
extern clock_t clock(void);

/* stdlib.h things */

extern int system(const char *string);

#endif /* win32_ansi_h */
