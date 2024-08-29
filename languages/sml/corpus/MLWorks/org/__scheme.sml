(* __scheme.sml the structure *)
(*
$Log: __scheme.sml,v $
Revision 1.10  1995/12/18 11:47:50  matthew
Adding Info

Revision 1.9  1995/01/30  12:00:01  matthew
Removing redundant debugger structures.

Revision 1.8  1993/12/03  15:50:28  nickh
Removed dead code, removed colons in an error message.

Revision 1.7  1993/05/18  18:12:37  jont
Removed integer parameter

Revision 1.6  1993/02/22  10:52:45  matthew
Added Completion structure

Revision 1.5  1992/08/04  15:46:50  davidt
Took out redundant Array argument and require.

Revision 1.4  1992/07/16  18:59:22  jont
added btree parameter

Revision 1.3  1992/01/27  18:12:30  jont
Added ty_debug parameter

Revision 1.2  1991/11/21  16:40:33  jont
Added copyright message

Revision 1.1  91/06/07  11:21:20  colin
Initial revision

Copyright 2013 Ravenbrook Limited <http://www.ravenbrook.com/>.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

require "../utils/__set";
require "../utils/__print";
require "../utils/__crash";
require "../utils/__lists";
require "../basics/__identprint";
require "../main/__info";
require "__datatypes";
require "__types";
require "__completion";
require "_scheme";

structure Scheme_ = Scheme(
  structure Set        = Set_
  structure Crash      = Crash_
  structure Print      = Print_
  structure Lists      = Lists_
  structure Info       = Info_
  structure IdentPrint = IdentPrint_
  structure Datatypes  = Datatypes_
  structure Types      = Types_
  structure Completion = Completion_
);

