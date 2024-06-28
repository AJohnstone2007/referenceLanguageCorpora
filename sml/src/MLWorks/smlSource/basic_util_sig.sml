(* ***************************************************************************
 
   $Source: /Users/nb/info.ravenbrook.com/project/mlworks/import/2013-04-25/xanalys-tarball/MLW/smltk/src/RCS/basic_util_sig.sml,v $

   Some utility functions needed for sml_tk. 

   This structure is organized as follows: a few functions (like fst and
   snd) live on its toplevel. All other functions are in structures 
   ListUtil (for functions on lists), StringUtil (for functions on strings),
   and FileUtil (functions for file access). This is in order to allow
   the structure BasicUtil being opened in most of SmlTk's modules, without
   running into danger of hiding existing identifiers. 

   Originally, this module was based on the gofer prelude, but most of the
   functions there are in the new standard basis library.
 
   $Date: 1999/06/16 09:53:24 $
   $Revision: 1.1 $
   Author: bu/cxl (Last modification by $Author: johnh $)

   (C) 1998, Bremen Institute for Safe Systems, Universitaet Bremen
 
  ************************************************************************** *)


require "__text_io";

infix 1 /=

signature BASIC_UTIL =
sig
    val fst  : 'a * 'b -> 'a
    val snd  : 'a * 'b -> 'b
    val pair : ('c-> 'a)*('c-> 'b)-> 'c-> 'a* 'b

    val /=   : ''a * ''a -> bool
    val eq   : ''a-> ''a -> bool

    (* val --        : int * int-> int list  *)

    val inc  : int ref -> int (* increment and return new value *)

    val curry   : ('a * 'b-> 'c)-> 'a-> 'b-> 'c
    val uncurry : ('a-> 'b-> 'c)-> 'a * 'b-> 'c
    val twist   : ('a * 'b-> 'c)-> 'b * 'a-> 'c

    (* The empty action *)
    val K0      : 'a -> unit 
	
    structure ListUtil : 
	sig    
	    val getx      : ('a -> bool) -> 'a list -> exn -> 'a
	    (* val delete    : ('a -> bool) -> 'a list -> 'a list *)
	    val updateVal : ('a -> bool) -> 'a -> 'a list -> 'a list
	    val dropWhile : ('a -> bool) -> 'a list -> 'a list
	    val break     : ('a -> bool) -> 'a list -> 'a list * 'a list
	    val sort      : ('a * 'a -> bool) -> 'a list -> 'a list

	    val prefix    : ''a list -> ''a list -> bool

	 (* no longer needed? -- *)
	 (* val takeWhile : ('a -> bool) -> 'a list -> 'a list *)
	 (* val span      : ('a -> bool) -> 'a list -> 'a list * 'a list *)
	 (* val ELEM      : ''a * ''a list -> bool *)
	 (* val deleteEq  : ''a -> ''a list -> ''a list *)
	end

    structure StringUtil : 
	sig
	    val words       : string -> string list

	    (* specialised utility functions *)
	    val concatWith  : string -> string list-> string
	    val breakAtDot  : string -> string* string
	    val toInt       : string -> int
	    val adaptString : string -> string

	    val all         : (char-> bool)-> string-> bool

	    val isDot       : char -> bool
	    val isComma     : char -> bool
	    val isLinefeed  : char -> bool
	    val isOpenParen : char -> bool
	    val isCloseParen: char -> bool		
	end


    structure FileUtil : 
	sig
	    val execute: string * string list -> TextIO.instream* 
		                                 TextIO.outstream
	    val exec   : string * string list -> bool
	    val cd     : string -> unit
	    val ls     : string -> string list
	    val pwd    : unit -> string
	    val isDir  : string -> bool
	    val getEnv : string -> string option
		
	    val isDirRdAndWr  : string -> bool
	    val isFileRd      : string -> bool
	    val isFileRdAndEx : string -> bool
		
	    val openFile : ( string -> exn) -> string -> TextIO.instream
	end

end













