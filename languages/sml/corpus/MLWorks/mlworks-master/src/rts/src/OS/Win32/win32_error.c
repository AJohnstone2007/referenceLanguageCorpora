/*  === Win32 Error & String functions ===
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
 *  Revision Log
 *  ------------
 *  $Log: win32_error.c,v $
 *  Revision 1.1  1997/05/22 09:16:14  johnh
 *  new unit
 *  [Bug #01702]
 *  Moved mlw_win32_strerror from being auto generated to this file plus
 *  other functions that were duplicated across a number of files.
 *
 *
 */

#include <windows.h>
#include "exceptions.h"      /* exn_raise_syserr */
#include "allocator.h"       /* ml_string */

/* A note on error codes
 * ---------------------
 * 
 * Most Win32 functions that fail set an error code that can be obtained
 * using GetLastError.  Unfortunately, Win32 doesn't seem to support all
 * the functionallity MLWorks needs and so some use needs to be made of
 * routines that are to be found in the Visual C++ compatability (Unix) 
 * library.  These routines generally set errno when they fail.  This means
 * that there are two types of error codes that needs to be returned by
 * OS.SysErr when a failure occurs.  The simple approach would be to 
 * define syserror as something like :-
 *
 *   datatype syserror = WIN32_ERROR int | UNIX_ERROR int
 *
 * and then just inject the error code into the correct one.  Note that
 * this would be different from the Unix definition which can get by
 * with just
 *
 *   type syserror = int
 * 
 * Unfortunately, due to problems with the rebinding of exceptions, the
 * SysErr exception is defined in MLWorks.Internal.Error and has the type
 * 
 *   type syserror = int
 *   exception SysError of syserror Option.option
 *
 * i.e. it is hardwired to be just an int :-<
 *
 * The solution adopted for Win32 is to squeeze both types of error
 * into the one int by encoding them as :-
 *
 *   Win32 error == (GetLastError()<<1)|0
 *   Unix error  == (errno<<1)|1
 *
 * This is feasible because errno rarely gets above 100 and the error code
 * portion of GetLastError is a 16-bit value.
 *
 */

mlval mlw_win32_strerror(unsigned int error_code)
{
  /* error_code should be the code returned by a call to GetLastError() */
  LPSTR lpMsgBuf;
  mlval error_string;

  FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
		NULL, error_code,
		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
		(LPTSTR) &lpMsgBuf, 0, NULL);

  error_string = ml_string((char*)lpMsgBuf);
  LocalFree(lpMsgBuf);

  return error_string;
}  

void mlw_raise_win32_syserr(int error_code)
{
  exn_raise_syserr(mlw_win32_strerror(error_code), (error_code<<1));
}

void mlw_raise_c_syserr(int errno)
{
  exn_raise_syserr(ml_string(strerror(errno)), (errno<<1)|1);
}




