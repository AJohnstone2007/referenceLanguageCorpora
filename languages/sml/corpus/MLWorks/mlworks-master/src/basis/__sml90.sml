(* This structure declares the top-level items in the 1990 Definition Of
 * Standard ML that were removed by the revised basis.  Opening this
 * structure should enable almost any code written for the original
 * Definition to be compiled.
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
 * $Log: __sml90.sml,v $
 * Revision 1.3  1997/09/24 15:48:17  brucem
 * [Bug #30275]
 * Change Char.toString to String.str.
 *
 *  Revision 1.2  1997/09/19  10:03:35  brucem
 *  Automatic checkin:
 *  changed attribute _comment to ' *  '
 *
 *  Revision 1.2  1997/07/18  10:47:10  brucem
 *  [Bug #30090]
 *  Remove references to MLWorks.IO (replacing with TextIO) so that MLWorks.IO can be removed.
 *
 *  Revision 1.1  1996/05/30  16:09:14  daveb
 *  new unit
 *  Backwards compatibility.
 *
 *
 *)

require "sml90";
require "__text_io";
require "__string";
require "__io";

structure SML90: SML90 =
struct

  (* The 1990 definition describes the I/O facilities implemented here. *)
  (* The old in/outstream types should not be the same as TextIO.instream
     as the 1990 definition says,
      ``both these types are abstract, in the sense that streams may only
        be manipulated by the functions provided in BasVal.'' *)
  (* Only two uses of the Io exception are mentioned by the defn, these
     are included here.  Any other exceptions encountered also cause Io to be
     raised but just with the function name as additional data --- this
     prevents the user from being aware of the underlying TextIO calls
     and encountering new basis exceptions. *)

  abstype instream  =  IN_S of TextIO.instream
      and outstream = OUT_S of TextIO.outstream
  with 
 
    exception Io of string

    val std_in = IN_S TextIO.stdIn

    and open_in =
      fn s => IN_S (TextIO.openIn s) handle _ => raise Io ("Cannot open "^s)

    and input =
      fn (IN_S is, n) => TextIO.inputN (is, n)
        handle e => raise Io ("input: "^(exnMessage e))

    and lookahead =
      fn (IN_S is) => case (TextIO.lookahead is) of
                      SOME e => String.str e
                    | NONE => ""
      handle e => raise Io ("lookahead: "^(exnMessage e))

    and close_in = 
      fn (IN_S is) => TextIO.closeIn is
        handle e => raise Io ("close_in: "^(exnMessage e))

    and end_of_stream =
      fn (IN_S is) => TextIO.endOfStream is
        handle e => raise Io ("end_of_stream: "^(exnMessage e))
      (* IMPERATIVE_IO.endOfStream may potentially return true for a stream
         which refills later, but end_of_stream should only return true for
         a stream which never refils.
         This is unlikely to matter in most cases *)

    and std_out = OUT_S TextIO.stdOut

    and open_out =
      fn s => OUT_S (TextIO.openOut s)
        handle _ => raise Io ("Cannot open "^s)

    and output =
      fn (OUT_S os, s) =>  TextIO.output (os, s)
         handle IO.Io {cause = IO.ClosedStream, ...} => 
                  raise Io "Output stream is closed"
              | e => raise Io ("output: "^(exnMessage e))

    and close_out =
      fn (OUT_S os) => TextIO.closeOut os
        handle e => raise Io ("close_out: "^(exnMessage e))

  end

  exception Ord = MLWorks.String.Ord

  (* The following exceptions are all aliases for Overflow *)
  exception Abs = Overflow
  exception Quot = Overflow
  exception Prod = Overflow
  exception Neg = Overflow
  exception Sum = Overflow
  exception Diff = Overflow
  exception Floor = Overflow

  (* The following exceptions never in fact occur *)
  exception Sqrt
  exception Exp
  exception Ln

  (* The following exception is a synonym of Div *)
  exception Mod = Div

  (* The following exception is raised when ... *)
  exception Interrupt = MLWorks.Interrupt

  val env = MLWorks.Internal.Runtime.environment

  val sqrt: real -> real = env "real square root"
  val sin: real -> real = env "real sin"
  val cos: real -> real = env "real cos"
  val arctan: real -> real = env "real arctan"
  val exp: real -> real = env "real exp"
  val ln: real -> real = env "real ln"

  val chr = MLWorks.String.chr
  val ord = MLWorks.String.ord
  val explode = MLWorks.String.explode
  val implode = MLWorks.String.implode

end
