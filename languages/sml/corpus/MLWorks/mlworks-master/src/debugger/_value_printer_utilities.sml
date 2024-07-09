(* _value_printer_utilities.sml the functor *)

(*
$Log: _value_printer_utilities.sml,v $
Revision 1.7  1996/10/31 14:34:11  io
[Bug #1614]
basifying String

 * Revision 1.6  1995/02/06  11:31:56  matthew
 * Change to type lookup exceptions
 *
Revision 1.5  1993/12/09  19:27:32  jont
Added copyright message

Revision 1.4  1993/02/09  10:15:04  matthew
Typechecker structure changes

Revision 1.3  1992/08/17  14:50:15  clive
Tynames now have a slot recording their definition point

Revision 1.2  1992/08/17  14:50:15  clive
Various improvements

Revision 1.1  1992/08/13  16:40:58  clive
Initial revision

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

require "../typechecker/basis";
require "../typechecker/types";
require "value_printer_utilities";

functor ValuePrinterUtilities(
  structure Basis : BASIS
  structure Types : TYPES
  sharing Types.Datatypes = Basis.BasisTypes.Datatypes
 ) : VALUEPRINTERUTILITIES =

struct
  structure BasisTypes = Basis.BasisTypes
  structure Datatypes = Types.Datatypes
  structure Ident = Datatypes.Ident
  structure Symbol = Ident.Symbol
               
  exception FailedToFind

  fun find_tyname (basis,argument) =
    let
      val max_subscript = size argument - 1
        
      fun upto_dot_or_end (from,to) =
        if to >= max_subscript 
          then (substring (* could raise Substring *)(argument,from,to-from+1),to)
          else if MLWorks.String.ordof (argument, to+1) = ord #"." then
	    (substring (* could raise Substring *)(argument,from,to-from+1),to+2)
        else upto_dot_or_end(from,to+1)
          
      fun part_list (from,acc) =
        if from >= max_subscript
          then acc
        else
          let
            val (part,next) = upto_dot_or_end(from,from)
            (* val _ = output(std_out,"next part is " ^ part ^ "\n") *)
          in
            part_list(next,part::acc)
          end

        fun make_path ([],acc) = acc
          | make_path (h::t,acc) = 
            make_path(t,Ident.PATH(Symbol.find_symbol h,acc))

    in
      case part_list (0,[]) of
        [] => raise FailedToFind

      | (final::rest) =>
          let
            val result = 
              Basis.lookup_longtycon(Ident.LONGTYCON(make_path(rest,Ident.NOPATH),Ident.TYCON (Symbol.find_symbol final)),
                                     Basis.basis_to_context basis)
            val Datatypes.TYSTR(function,_) = result
            val arity = Types.arity function
            fun generate_args 0 = []
              | generate_args n = Datatypes.NULLTYPE :: generate_args (n-1)
          in
            case Types.apply(function,generate_args arity) of
              Datatypes.CONSTYPE(_,tyname) => tyname
            | _ => raise FailedToFind
          end
        handle Basis.LookupTyCon _ => raise FailedToFind
             | Basis.LookupStrId _ => raise FailedToFind
    end

end

               
