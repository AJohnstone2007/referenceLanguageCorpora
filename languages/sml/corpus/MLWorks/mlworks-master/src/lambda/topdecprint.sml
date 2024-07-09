(* topdecprint.sml the signature *)
(*
$Log: topdecprint.sml,v $
Revision 1.8  1996/08/05 18:03:43  andreww
[Bug #1521]
Propagating changes made to typechecker/_types.sml (essentially
just passing options rather than print_options).

 * Revision 1.7  1993/03/04  14:13:41  matthew
 * Options & Info changes
 * ,
 *
Revision 1.6  1993/02/01  16:14:36  matthew
Added sharing constraints

Revision 1.5  1992/11/25  15:05:46  daveb
Changes to make show_id_class and show_eq_info part of Info structure
instead of references.

Revision 1.4  1992/09/24  11:43:19  richard
Added print_sigexp.

Revision 1.3  1992/09/16  08:40:20  daveb
show_id_class controls printing of id classes (VAR, CON or EXCON)

Revision 1.2  1991/07/23  09:56:40  davida
Added print_depth for signature expressions.  Could have a better name.

Revision 1.1  91/07/10  09:18:59  jont
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

require "../basics/absyn";
require "../main/options";

signature TOPDECPRINT =
  sig
    structure Absyn : ABSYN
    structure Options : OPTIONS

    val print_sigexp	: Options.options
              -> ('a * string -> 'a) -> ('a * int * Absyn.SigExp) -> 'a

(*
    val print_strexp	: ('a * string -> 'a) -> ('a * int * Absyn.StrExp) -> 'a
    val print_strdec	: ('a * string -> 'a) -> ('a * int * Absyn.StrDec) -> 'a
    val print_topdec	: ('a * string -> 'a) -> ('a * int * Absyn.TopDec) -> 'a
*)

    val sigexp_to_string : Options.options -> Absyn.SigExp -> string
    val strexp_to_string : Options.options -> Absyn.StrExp -> string
    val strdec_to_string : Options.options -> Absyn.StrDec -> string
    val topdec_to_string : Options.options -> Absyn.TopDec -> string
  end;
