(*
 *
 * $Log: interface.sml,v $
 * Revision 1.2  1998/08/05 17:43:58  jont
 * Automatic checkin:
 * changed attribute _comment to ' *  '
 *
 *
 *)
require "ut1";
require "utils.sml";
require "newtop.sml";
require "modules.sml";
require "base.sml";
require"lego_grm.sml";
require"lego__grm.sml";
require "ut3";
require"lego_lex.sml";
require "^.polyml-compat";
require "__io";

(* The "abstract type" of lexer positions *)
(*
signature POS =
  sig
    type pos
    val lno : pos ref
    val init_lno : unit->unit
    val inc_lno : unit->unit
    val errmsg : string->(string*pos*pos)->unit
  end;
*)

functor Pos() : POS =
  struct
    type pos = int
    val lno = ref 0
    fun init_lno() = lno:=1
    fun inc_lno() = lno:=(!lno)+1
    fun errmsg who (msg,line:pos,_) =
      message(who^"; line "^(int_to_string line)^": "^msg)
  end;

structure Pos:POS = Pos()
structure LegoLrVals:Lego_LRVALS =
    LegoLrValsFun(structure Token = LrParser.Token
	          structure Pos = Pos)
structure LegoLex:LEXER =
    LegoLexFun(structure Tokens = LegoLrVals.Tokens
	       structure Pos = Pos)
structure LegoParser:PARSER =
    Join(structure LrParser = LrParser
         structure ParserData = LegoLrVals.ParserData
         structure Lex = LegoLex)


structure LegoInterface : sig
			    val lego : unit -> unit
			  end =
  struct

    fun open_file_using_path filename =
      let
	fun errmsg s = failwith("cannot open file "^s)
	fun try_open_file pathname =
	  let val (instr,pnam (*,isdir *)) = (open_in pathname,
					pathname (*,
					System.Directory.isDir pathname*)) 
	    handle IO.Io _ => (open_in(pathname^".l"),
			    (pathname^".l") (*,
			    System.Directory.isDir (pathname^".l") *))
	  in  (* if not isdir then *) (instr,pnam)
	      (*
	      else (message("Warning: found directory \""^pnam^
			    "\"\n         while searching for file \""^
			    filename^"\".\n Continuing to search.");
		   raise Io "")
	      *)
	  end
	fun open_file pathname =
	  try_open_file pathname handle IO.Io _ => errmsg pathname
      in
        if (ord filename = ord"/") orelse (ord filename = ord"~")
	  then fn _ => open_file filename
	else fn [] => errmsg filename
              | h::t => try_open_file (h^filename)
		  handle _ => open_file_using_path filename t
      end;


    fun parse (lookahead, reader:int->string, filename) =
      let
        val error = Pos.errmsg "Lego parser"
	val _ = Pos.init_lno()
        val dummyEOF = let val zzz = !Pos.lno
		       in  LegoLrVals.Tokens.EOF(zzz,zzz)
		       end
	fun invoke lexer = 
	   LegoParser.parse(lookahead,lexer,error,filename)
        fun loop lexer =
	  let val (result,lexer) = invoke lexer
	      val (nextToken,lexer) = LegoParser.Stream.get lexer
	  in if LegoParser.sameToken(nextToken,dummyEOF) then ()
	     else loop lexer
	  end
     in loop (LegoParser.makeLexer reader)
     end

(* file parser *)
    fun legof filename =
      let
	val (in_str,name) = open_file_using_path filename (legopath())
	val _ = message ("(* opening file "^name^" *)")
	(*
	val t = start_timer()
	*)
	fun closing() = (message((* "closing file "^
				 name^"; "^(makestring_timer t)^ *)"");
			 close_in in_str)
	fun err_closing s = (message("Error in file: "^s);
			     closing();
			     raise Failure"Unwinding to top-level")
      
	val result = (parse (15,(fn _ => input_line in_str),filename)
	   handle Failure s => err_closing s
		| Bug s => err_closing s
		| IO.Io{function, name, ...} => err_closing(function ^ name)
		| exn => err_closing
                     ("\nLEGO detects unexpected exception named \""
		      ^(exnName exn)^"\""))
      in
        closing();
	result
      end
    val _ = legoFileParser := legof;   (* Used to implement Include *)


(* string parser *)
(* NOTE: exceptions from string parser are thrown to next outer
 * file parser or toplevel *)
    fun legos str =
      let val string_reader = let val next = ref str
			      in  fn _ => let val res = !next in next := ""; res end
			      end
      in parse (0,string_reader,"")
      end
    val _ = legoStringParser := legos;   (* Used to implement Logic *) 


(*****************************************************
    fun preInterruptHandler k (_,resume) =
      let
	fun enq() = 
	  let
	    val _ = print"\n\nEnter R to resume or T for toplevel: "
	    val _ = flush_out std_out
	    val ans = input_line std_in
	  in
	    if ans = "R\n" then resume
	    else if ans = "T\n" then k
		 else enq()
	  end
      in
	enq()
      end
****************************************************)

    local
      (*
      fun catchTopCont() =
	(System.Unsafe.toplevelcont :=
	 callcc (fn k => (callcc (fn k' => (throw k k'));
			  raise Interrupt)))
      *)
    in  
      fun lego() =
	((* catchTopCont(); *)
	 parse (0,(fn _ => (prs "Lego> "; flush_out std_out;
			    input_line std_in)),
		  "")
	 handle Failure s => (message("Error: "^s); lego())
	      | Bug s => (message s; lego())
	      | IO.Io{function, name, ...} => (message(function ^ name); lego())
	      (*
	      | LegoParser.ParseError => lego()
	      *)
(********
	      | LegoLex.LexError => lego()
*********)
	      | exn => (message("\nLEGO detects unexpected exception")(* named \""^
				System.exn_name exn^"\"") *);
			lego()))
	 handle Interrupt => (message"\nInterrupt.. "; lego())
    end;

end;
open LegoInterface;
