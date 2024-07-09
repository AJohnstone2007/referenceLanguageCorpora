(*
 * $Log: __capi.sml,v $
 * Revision 1.5  1998/06/11 10:46:49  johnh
 * [Bug #30411]
 * Add support for free edition splash screen.
 *
 * Revision 1.4  1996/10/30  18:27:52  daveb
 * Changed name of Xm_ structure to Xm, because we're giving it to users.
 *
 * Revision 1.3  1996/01/09  13:52:27  matthew
 * Adding Menus structure
 *
 * Revision 1.2  1995/09/27  10:21:16  brianm
 * Adding structure LispUtils_
 *
 * Revision 1.1  1995/07/26  13:56:25  matthew
 * new unit
 * New unit
 *
 *  Revision 1.2  1995/07/04  10:17:06  matthew
 *  Adding FileDialog structure
 *
 *  Revision 1.1  1995/06/29  15:55:28  matthew
 *  new unit
 *  New "window system independent" interface
 *
 *
 * Copyright 2013 Ravenbrook Limited <http://www.ravenbrook.com/>.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *)

require "../motif/__xm";
require "../motif/__file_dialog";
require "../motif/__menus";
require "../utils/__crash";
require "../utils/__lists";
require "^.utils.__lisp";
require "^.unix.__getenv";
require "^.main.__version";
require "_capi";

structure Capi_ = 
  Capi (structure Xm = Xm
        structure FileDialog = FileDialog_
        structure Menus = Menus_
        structure Crash = Crash_
        structure Lists = Lists_
        structure LispUtils = LispUtils_
	structure Getenv = Getenv_
	structure Version = Version_
       )
