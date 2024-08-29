(* __mlworks_timer.sml the structure *)

(*
$Log: __mlworks_timer.sml,v $
Revision 1.4  1999/05/12 12:49:01  daveb
[Bug #190554]
The type of Timer.getCPUTimer has changed.

*Revision 1.3  1998/02/06  15:42:19  johnh
*Automatic checkin:
*changed attribute _comment to '*'
*
 *  Revision 1.1.1.2  1997/11/25  20:05:15  daveb
 *  Automatic checkin:
 *  changed attribute _comment to ' *  '
 *
 * Revision 1.15.2.1  1997/09/11  21:11:42  daveb
 * branched from trunk for label MLWorks_workspace_97
 *
 * Revision 1.17  1997/11/13  11:22:12  jont
 * [Bug #30089]
 * Modify TIMER (from utils) to be INTERNAL_TIMER to keep bootstrap happy
 *
 * Revision 1.16  1997/11/08  17:52:06  jont
 * [Bug #30089]
 * Convert to use basis timer
 *
 * Revision 1.15  1997/05/19  13:05:42  jont
 * [Bug #30090]
 * Translate output std_out to print
 *
 * Revision 1.14  1996/11/06  10:53:38  matthew
 * [Bug #1728]
 * __integer becomes __int
 *
 * Revision 1.13  1996/10/28  14:00:20  io
 * [Bug #1614]
 * basifying String
 *
 * Revision 1.12  1996/04/30  17:44:40  jont
 * String functions explode, implode, chr and ord now only available from String
 * io functions and types
 * instream, oustream, open_in, open_out, close_in, close_out, input, output and end_of_stream
 * now only available from MLWorks.IO
 *
 * Revision 1.11  1996/04/29  13:12:15  matthew
 * Removed MLWorks.Integer
 *
 * Revision 1.10  1996/01/16  12:17:20  nickb
 * Change to StorageManager interface.
 *
Revision 1.9  1994/07/15  10:08:11  nickh
Add simple allocation statistics.

Revision 1.8  1994/03/03  15:22:26  nickh
Don't call elapsed if not printing a report.

Revision 1.7  1993/11/15  16:54:58  nickh
New pervasive time structure.
(makes this stuff run faster).

Revision 1.6  1992/10/28  13:00:52  richard
Changes to pervasives and representation of time.

Revision 1.5  1992/08/26  14:55:43  richard
Rationalisation of the MLWorks structure.

Revision 1.4  1992/08/10  15:35:03  davidt
Changed MLworks structure to MLWorks

Revision 1.3  1992/08/07  15:12:28  davidt
Now uses MLworks structure instead of NewJersey structure.

Revision 1.2  1992/05/15  14:08:33  clive
Adjusted to make it work with our system

Revision 1.1  1992/01/31  12:26:58  clive
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

require "mlworks_timer";
require "^.basis.__int";
require "^.basis.__timer";
require "^.system.__time";

structure Timer_ : INTERNAL_TIMER =
  struct

    structure M = MLWorks.Internal.Runtime.Memory
    structure V = MLWorks.Internal.Value

    fun xtime (s, flag, f) =
      if flag then
	let
	  val cpu_timer = Timer.startCPUTimer()
	  val real_timer = Timer.startRealTimer()
	  val (initcollects,initbytes) = M.collections()
	  fun print_time () =
	    let
	      val {usr, sys} = Timer.checkCPUTimer cpu_timer
	      val gc = Timer.checkGCTime cpu_timer
	      val real_elapsed = Timer.checkRealTimer real_timer
	      val (finalcollects, finalbytes) = M.collections()
	      val bytes = finalbytes-initbytes
	      val coll = finalcollects - initcollects
	      val (showcoll,showbytes) =
		if bytes > 0 then (coll,bytes) else
		  (coll-1,bytes+1048576)
	    in
	      print(concat ["Time for ", s, " : ",
			    Time.toString real_elapsed,
			    " (user: ",
			    Time.toString usr,
			    "(gc: ",
			    Time.toString gc,
			    "), system: ",
			    Time.toString sys,
			    ")",
			    " allocated: (",
			    Int.toString showcoll,
			    ", ",
			    Int.toString showbytes,
			    ")\n"])
	    end
	  val result = f () handle exn => (print_time ();
					   raise exn)
	in
	  (print_time ();
	   result)
	end
      else
	f ()

    fun time_it (a, b) = xtime (a, true, b)

  end
