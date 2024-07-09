(* mach_cg.sml the signature *)
(*
$Log: mach_cg.sml,v $
Revision 1.1  1993/12/17 10:29:50  io
Initial revision

Revision 1.24  1993/03/12  11:51:26  matthew
Signature revisions

Revision 1.23  1993/03/04  14:48:42  matthew
Options & Info changes

Revision 1.22  1993/01/04  15:36:59  jont
Modified to return final machine code in an easily printed form
,

Revision 1.21  1992/12/08  19:50:10  jont
Removed a number of duplicated signatures and structures

Revision 1.20  1992/12/01  14:53:01  daveb
Changes to propagate compiler options as parameters instead of references.

Revision 1.19  1992/11/17  14:30:24  matthew
Changed Error structure to Info

Revision 1.18  1992/11/12  17:40:34  clive
Made the generate_tracing flag available

Revision 1.17  1992/11/03  10:34:48  jont
Reworked in terms of mononewmap

Revision 1.16  1992/09/10  09:39:31  richard
Created a type `information' which wraps up the debugger information
needed in so many parts of the compiler.

Revision 1.15  1992/08/26  15:49:15  jont
Removed some redundant structures and sharing

Revision 1.14  1992/08/24  13:26:10  clive
Added details about leafness to the debug information

Revision 1.13  1992/07/14  16:16:45  richard
Removed obsolete memory profiling code.

Revision 1.12  1992/07/07  10:42:01  clive
Added call point information recording

Revision 1.11  1992/05/11  15:00:07  clive
Added memory profiling

Revision 1.10  1992/05/08  11:41:05  jont
Added bool ref do_timings to control printing of timings for various stages

Revision 1.9  1992/02/27  16:03:43  richard
Changed the way virtual registers are handled.  See MirTypes.

Revision 1.8  1992/02/07  11:01:34  richard
Changed Table to Map to reflect changes in MirRegisters.

Revision 1.7  1992/02/03  11:06:48  clive
added the printing of the size of the resultant code

Revision 1.6  1992/01/09  15:03:38  clive
Added diagnostic structure

Revision 1.5  1991/11/14  10:56:28  richard
Removed references to fp_double registers.

Revision 1.4  91/11/08  17:46:59  jont
Added show_mach for controlling opcode lsiting

Revision 1.3  91/10/22  15:42:56  jont
Added do_fall_through bool ref to control whether branch elimination was
done for debugging and measuring

Revision 1.2  91/10/07  12:03:53  richard
Changed dependencies on MachRegisters to MachSpec.

Revision 1.1  91/10/04  16:14:08  jont
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

require "../utils/diagnostic";
require "../main/info";
require "../main/options";
require "../mir/mirtypes";
(*require "machspec";*)

signature MACH_CG = sig
  structure MachSpec		: sig eqtype register end
  structure Diagnostic          : DIAGNOSTIC
  structure Info                : INFO
  structure Options             : OPTIONS
  structure MirTypes            : MIRTYPES

  type Module
  type Opcode

  val mach_cg :
    Info.options ->
    Options.options *
    MirTypes.mir_code *
    ((MachSpec.register) MirTypes.GC.Map.T *
     (MachSpec.register) MirTypes.NonGC.Map.T *
     (MachSpec.register) MirTypes.FP.Map.T) *
    MirTypes.Debugger_Types.information ->
    (Module *
     MirTypes.Debugger_Types.information) *
    (((MirTypes.tag * (Opcode * string) list) * string) list list)

  val print_code_size : bool ref
  val do_timings : bool ref
end
