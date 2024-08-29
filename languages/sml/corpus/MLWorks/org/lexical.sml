(*
 *
 * $Log: lexical.sml,v $
 * Revision 1.2  1998/06/08 17:33:08  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* 
lexical.sml

MERILL  -  Equational Reasoning System in Standard ML.
Brian Matthews				     19/02/91
Glasgow University and Rutherford Appleton Laboratory.

This module decides the basic lexical units of the new Eril system.

The basic lexical elements that we can return are:

	NL  -  	We must give parsers the opportunity to handle newlines in 
		their own ways.
	Id  -   Any sequence of A-Za-z0-9 together with underscore "_" and
		prime "'", which must commence with a alphabetic character.
	Digit - any sequence of 0-9.
	Symbol- Symbolics are now matched one at a time !! (bmm 03-12-90 )
	Quote - any sequence of characters delimited by quotes.  The quotes are
		then quietly dropped!
	Other - any other single character - eg parentheses.

*)

structure Lex : LEXICAL =
struct 

datatype Token = Id of string | Num of int | NL

(*  
val get_lexeme : unit -> string

Gets the next lexeme from the input stream.
*)

(* I don't seem to yse this function at the moment. 
fun get_lexeme () = 
    let val c = get_next_character ()
    in  if c = "\n" then c else
	if space c then get_lexeme () else
	if letter c orelse c = "_"  then c^get_next_ident () else
	if digit c then c^get_next_number () else
	if symbolic c then c else
	if c = "\"" then get_quoted () 
	else c
    end 
*)

(*  We may also wish to lexify a list of characters by the same criteria *)
(* as the lexemes above.						 *)

local 
fun next_lexeme (c::ss) = 
    if c = "\n" then (c,ss) else
    if space c then next_lexeme ss else
    if letter c orelse c = "_" then first_ident (c::ss) else
    if digit c then first_number (c::ss) else
    if symbolic c then (c,ss) else
    if c = "\"" then first_quoted ss 
    else (c,ss) 
  | next_lexeme [] = ("",[]) 

fun ff ss =  
    let val (l,ss) = next_lexeme ss
    in if l = "" then [] else l::(ff ss)
    end
in
fun lex str = ff (explode str)
end 

fun lex_line s = let val ls = lex s
		 in if non null ls andalso lastone ls = "\n" 
		    then front ls
		    else ls
		 end

val lex_input = lex o get_next_line

local 

fun next_token (c::ss) = 
    if c = "\n" then (NL,ss) else
    if space c then next_token ss else
    if letter c orelse c = "_" then apply_fst Id (first_ident (c::ss)) else
    if digit c then apply_fst (Num o (fn s => (case stringtoint s of
					OK n => n | 
				Error m => raise (MERILL_ERROR m))) )
    			      (first_number (c::ss)) else
    if symbolic c then (Id c,ss) else
    if c = "\"" then apply_fst Id (first_quoted ss)
    else (Id c,ss) 
  | next_token [] = (Id "",[]) 

fun ff ss =  
    let val (l,ss) = next_token ss
    in if l = Id "" then [] else l::(ff ss)
    end
in
fun scan str = ff (explode str)
end 

fun scan_line s = let val ls = scan s
		  in if non null ls andalso lastone ls = NL 
		     then front ls
		     else ls
		  end

val end_marker = ".\n" 
val end_check1 = ou (eq end_marker) (eq "") 
val end_check2 = ou (ou (eq ["\n"]) null) (eq (lex end_marker)) 


end (* of structure Lex *)
;
