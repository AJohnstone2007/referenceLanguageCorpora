(*
 * $Log: __lambdaflow.sml,v $
 * Revision 1.2  1997/04/24 13:30:48  matthew
 * Adding LambdaPrint
 *
 *  Revision 1.1  1997/01/06  10:32:53  matthew
 *  new unit
 *  New optimization stages
 *
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

require "../utils/__inthashtable";
require "../utils/__crash";
require "../debugger/__runtime_env";
require "../machine/__machspec";
require "__simpleutils";
require "__lambdaprint";

require "_lambdaflow";

structure LambdaFlow_ = LambdaFlow  (structure SimpleUtils = SimpleUtils_
                                     structure LambdaPrint = LambdaPrint_
                                     structure MachSpec = MachSpec_
                                     structure Crash = Crash_
                                     structure IntHashTable = IntHashTable_
                                     structure RuntimeEnv = RuntimeEnv_)
