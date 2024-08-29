(*  ==== Testing ====
 *  This tests the Real.fmt function.
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
 *  Result: OK
 *
 *
 *  Revision Log
 *  ------------
 *  $Log: real_fmt.sml,v $
 *  Revision 1.6  1998/04/23 13:19:56  jont
 *  [Bug #30397]
 *  Remove round to even test as this doesn't really work on either
 *  unix or nt.
 *
 *  Revision 1.5  1998/04/21  12:44:26  mitchell
 *  [Bug #30336]
 *  Fix tests to agree with change in spec of toString and fmt
 *
 *  Revision 1.4  1998/02/18  11:56:01  mitchell
 *  [Bug #30349]
 *  Fix test to avoid non-unit sequence warning
 *
 *  Revision 1.3  1997/11/21  10:48:10  daveb
 *  [Bug #30323]
 *
 *  Revision 1.2  1997/10/09  17:55:03  daveb
 *  Automatic checkin:
 *  changed attribute _comment to ' *  '
 *
 *
*)

val posinf = 1.0/0.0
val neginf = ~1.0/0.0
val nan = 0.0/0.0

fun check_exn (format, arg) =
  (ignore(Real.fmt format arg); "WRONG")
  handle Size => "OK"

fun check_res (format, arg, res) =
  (if Real.fmt format arg = res then
    "OK"
   else
     "WRONG")
  handle _ => "EXN"

(* First check for illegal precisions *)
val test1a = check_exn (StringCvt.GEN (SOME 0), 10.5)
val test1b = check_exn (StringCvt.GEN (SOME ~1), 10.5)
val test1c = check_exn (StringCvt.SCI (SOME ~1), 10.5)
val test1d = check_exn (StringCvt.FIX (SOME ~1), 10.5)

(* Now check the GEN format *)
val test2a = check_res (StringCvt.GEN (SOME 1), 1.5, "2");
val test2b = check_res (StringCvt.GEN (SOME 1), 10.5, "1E01");
val test2c = check_res (StringCvt.GEN (SOME 2), ~1000.0, "~1E03");
val test2d = check_res (StringCvt.GEN (SOME 1), 0.012, "0.01");
val test2e = check_res (StringCvt.GEN (SOME 3), ~0.0123, "~0.0123");
val test2f = check_res (StringCvt.GEN (SOME 3), 0.0000123, "1.23E~05");
val test2g = check_res (StringCvt.GEN NONE, 0.0000123, "1.23E~05");
  
(* Now check the SCI format *)
val test3a = check_res (StringCvt.SCI (SOME 1), 1.5, "1.5E00");
val test3b = check_res (StringCvt.SCI (SOME 0), 10.5, "1E01");
val test3c = check_res (StringCvt.SCI (SOME 2), ~1000.0, "~1.00E03");
val test3d = check_res (StringCvt.SCI (SOME 1), 0.012, "1.2E~02");
val test3e = check_res (StringCvt.SCI (SOME 3), ~0.0123, "~1.230E~02");
val test3f = check_res (StringCvt.SCI (SOME 3), 0.0000123, "1.230E~05");
val test3g = check_res (StringCvt.SCI NONE, 0.0000123, "1.230000E~05");

(* Now check the FIX format *)
val test4a = check_res (StringCvt.FIX (SOME 1), 1.5, "1.5");
val test4c = check_res (StringCvt.FIX (SOME 2), ~1000.0, "~1000.00");
val test4d = check_res (StringCvt.FIX (SOME 1), 0.012, "0.0");
val test4e = check_res (StringCvt.FIX (SOME 3), ~0.0123, "~0.012");
val test4f = check_res (StringCvt.FIX (SOME 3), 0.0000123, "0.000");
val test4g = check_res (StringCvt.FIX NONE, 0.0000123, "0.000012");
  
(* Now check the non-numbers *)
val test5a = check_res (StringCvt.FIX (SOME 1), posinf, "+inf");
val test5b = check_res (StringCvt.FIX (SOME 1), neginf, "-inf");
val test5c = check_res (StringCvt.FIX (SOME 1), nan, "nan");
val test5d = check_res (StringCvt.SCI (SOME 1), posinf, "+inf");
val test5e = check_res (StringCvt.SCI (SOME 1), neginf, "-inf");
val test5f = check_res (StringCvt.SCI (SOME 1), nan, "nan");
val test5g = check_res (StringCvt.GEN (SOME 1), posinf, "+inf");
val test5h = check_res (StringCvt.GEN (SOME 1), neginf, "-inf");
val test5i = check_res (StringCvt.GEN (SOME 1), nan, "nan");

