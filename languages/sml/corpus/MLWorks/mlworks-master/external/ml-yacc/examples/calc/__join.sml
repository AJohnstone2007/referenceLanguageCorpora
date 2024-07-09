require "_calc_grm";
require "calc_lex";
require "$.lib.base";
require "$.lib.join";
require "$.lib.parser2";
require "$.basis.__text_io";
require "$.basis.__int";
require "$.basis.__string";

structure Calc : sig
	           val parse : unit -> unit
                 end = 
 struct
  structure CalcLrVals = CalcLrValsFun(structure Token = LrParser.Token)
  structure CalcLex = CalcLexFun(structure Tokens = CalcLrVals.Tokens);
  structure CalcParser = Join(structure LrParser = LrParser
		            structure ParserData = CalcLrVals.ParserData
		            structure Lex = CalcLex)

  val invoke = fn lexstream =>
    let val print_error = fn (s,i:int,_) =>
         TextIO.output(TextIO.stdOut,"Error, line " ^ (Int.toString i) ^ 
                       ", " ^ s ^ "\n")
    in CalcParser.parse(0,lexstream,print_error,())
    end

  (* note: some implementations of ML, such as SML of NJ,
     have more efficient versions of input_line in their built-in
     environment
   *)

  val input_line = fn f =>
    let fun loop result =
          let val c = TextIO.inputN (f,1)
	      val result = c :: result
          in if String.size c = 0 orelse c = "\n" then
		String.concat (rev result)
	     else loop result
	  end
    in loop nil
    end

  val parse = fn () => 
    let val _ = TextIO.print "type \"()\" to quit\n"
        val lexer = CalcParser.makeLexer (fn _ => input_line TextIO.stdIn)
        val dummyEOF = CalcLrVals.Tokens.EOF(0,0)
	val dummySEMI = CalcLrVals.Tokens.SEMI(0,0)
        fun loop lexer =
	   let val (result,lexer) = invoke lexer
	       val (nextToken,lexer) = CalcParser.Stream.get lexer
	       val _ = case result
		  of SOME r => TextIO.output(TextIO.stdOut,
                                   ("result = " ^ (Int.toString r) ^ "\n"))
		   | NONE => ()
	   in if CalcParser.sameToken(nextToken,dummyEOF) then ()
	      else loop lexer
	   end
     in loop lexer
     end handle CalcLex.LexError => ()
end
