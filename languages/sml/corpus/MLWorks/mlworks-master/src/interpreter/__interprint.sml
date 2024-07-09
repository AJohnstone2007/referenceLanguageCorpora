(*  ==== INTERPRETER PRINTER ====
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
 *  $Log: __interprint.sml,v $
 *  Revision 1.14  1996/10/30 15:13:16  io
 *  [Bug #1614]
 *  removing Lists
 *
 * Revision 1.13  1995/12/27  15:52:22  jont
 * Remove __option
 *
 *  Revision 1.12  1995/03/22  12:29:02  matthew
 *  Adding Sigma structure
 *
 *  Revision 1.11  1995/02/07  14:25:57  matthew
 *  Removing some redundant structures.
 *
 *  Revision 1.9  1994/06/09  16:00:21  nickh
 *  New runtime directory structure.
 *
 *  Revision 1.8  1994/05/06  14:35:37  jont
 *  Add printing of fixity directives
 *
 *  Revision 1.7  1993/03/08  11:11:23  matthew
 *  Added basistypes structure
 *
 *  Revision 1.6  1993/02/01  17:34:35  matthew
 *  Removed Env from parameter.
 *
 *  Revision 1.5  1992/12/18  15:16:40  jont
 *  Added Completion parameter
 *
 *  Revision 1.4  1992/11/03  15:45:27  richard
 *  Added Tags parameter.
 *
 *  Revision 1.3  1992/10/13  14:56:38  richard
 *  Added Diagnostics.
 *
 *  Revision 1.2  1992/10/09  08:54:09  clive
 *  Added printing of the values contained in structures
 *
 *  Revision 1.1  1992/10/01  16:12:58  richard
 *  Initial revision
 *
 *)

require "../utils/__text";
require "../utils/_diagnostic";
require "../lambda/__topdecprint";
require "../basics/__identprint";
require "../debugger/__value_printer";
require "../lambda/__environ";
require "../typechecker/__basis";
require "../typechecker/__environment";
require "../typechecker/__valenv";
require "../typechecker/__strenv";
require "../typechecker/__tyenv";
require "../typechecker/__types";
require "../typechecker/__completion";
require "../typechecker/__sigma";
require "../parser/__parserenv";
require "../rts/gen/__tags";
require "__incremental";
require "_interprint";

structure InterPrint_ =
  InterPrint (structure Incremental = Incremental_
              structure TopdecPrint = TopdecPrint_
              structure IdentPrint = IdentPrint_
              structure ValuePrinter = ValuePrinter_
              structure Basis = Basis_
              structure Valenv = Valenv_
              structure Strenv = Strenv_
              structure Tyenv = Tyenv_
              structure Types = Types_
              structure Completion = Completion_
              structure Sigma = Sigma_
              structure Env = Environment_
	      structure ParserEnv = ParserEnv_
              structure Tags = Tags_
              structure Environ = Environ_
              structure Diagnostic = Diagnostic (structure Text = Text_));


