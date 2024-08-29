(*
Debug info must be cleared when recompilation
takes place and the debug switches are off.

Result: OK
 
$Log: debug.sml,v $
Revision 1.6  1998/02/06 15:00:46  jont
[Bug #70055]
Modify to use argument in function being traced

 * Revision 1.5  1996/03/27  11:50:57  stephenb
 * Turn on debugging so the breakpoint command actually runs!
 *
 * Revision 1.4  1996/03/26  16:06:45  stephenb
 * Replace the out of date call to MLWorks.Debugger.break with
 * a call to Shell.Trace.breakpoint.
 *
 * Revision 1.3  1996/03/26  14:02:12  jont
 * Fix out of date Shell calls
 *
 * Revision 1.2  1996/02/23  16:28:48  daveb
 * Converted Shell structure to new capitalisation convention.
 *
 * Revision 1.1  1994/06/21  10:57:10  jont
 * new file
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
*)

Shell.Options.set (Shell.Options.Compiler.generateTraceProfileCode, true);
Shell.Options.set(Shell.Options.Compiler.generateVariableDebugInfo,true);
functor F(type t val args:t list val compute:t list -> t) =
  struct
    fun f args =
      let
        val result = compute args
      in
        ()
      end
    val args = args
  end;
structure F1 = F(struct 
                   type t = int
                   val args = [1,2]
                   fun compute args = 
                     let
                       fun compute [] result = result
                         | compute (arg::args) result = compute args (result+arg)
                     in
                       compute args 0
                     end
                            end);
structure F2 = F(struct
                   type t = string
                   val args = ["1","2"]
                   fun compute args = 
                     let
                       fun compute [] result = result
                         | compute (arg::args) result = compute args (result^arg)
                     in
                       compute args ""
                     end
                  end);
Shell.Trace.breakpoint "f";
Shell.Options.set(Shell.Options.Compiler.generateVariableDebugInfo,false);
functor F(type t 
          val args:t list 
          val compute:t list -> t) =
  struct
    fun f args =
      let
        val result = compute args
      in
        ()
      end
    val args = args
  end;

structure F1 = F(struct 
                   type t = int
                   val args = [1,2]
                   fun compute args = 
                     let
                       fun compute [] result = result
                         | compute (arg::args) result = compute args (result+arg)
                     in
                       compute args 0
                     end
                  end);

structure F2 = F(struct
                   type t = string
                   val args = ["1","2"]
                   fun compute args = 
                     let
                       fun compute [] result = result
                         | compute (arg::args) result = compute args (result^arg)
                     in
                       compute args ""
                     end
                  end);
(F1.f F1.args,F2.f F2.args);
