(*
 *
 * $Log: string.sml,v $
 * Revision 1.2  1998/06/08 17:28:40  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* 
string.sml

MERILL  -  Equational Reasoning System in Standard ML.
Brian Matthews				     23/04/90
Glasgow University and Rutherford Appleton Laboratory.

This file contains the basic routines for string handling.

That is, it does such things as recognise characters, numbers, quoted strings, identifiers, 
symbolics etc.

*)

structure Strings = 
   struct

	fun stringlist p (front,sep,rear) l = 
	    let fun prl [] = rear
	          | prl [c] = p c ^ rear
	          | prl (h::t) = (p h ^ sep ^ prl t)
	    in (front ^ prl l) 
	    end 
	
	val stringwith = stringlist I
	
	fun stringpair f (a,b) = "("^f a^","^f b^")"

	fun nchars c n = if n = 0 then "" else c^nchars c (n-1)
		
	val spaces = nchars " "

	fun digit c = (c >= "0" andalso c <= "9")
	fun upper c = (c >= "A" andalso c <= "Z")
	fun lower c = (c >= "a" andalso c <= "z")
		
	val letter = ou upper lower
	val num_element = ou  digit (eq "." )
	val id_element = ou (ou (ou  digit letter) (eq "'")) (eq "_")
	val symbolic = member ["!","#","%","&","$","+","-","/",":",".",
			       "<","=",">","?","\\","|","~","`","^","*","{","}"
			       ,"[","]"] 
	val space = member [" ","\t"] 
	val nl = member ["\n"]
	val whitespace = ou space nl

	fun alls f = forall f o explode
	
	fun apps f = implode o f o explode

	fun chartoint s = ord s - ord "0";

	fun stringtoint s = 
	    let fun f (c::t) n = if digit c then f t (10 * n + chartoint c) 
	        		 else Error ("Non-Digit Character "^c)
	          | f   []   n = OK n
	    in if s = ""
	       then Error "Empty String Entered"
	       else f (explode s) 0
	    end

	fun mk_upper c = if lower c then chr(ord(c) - 32) else c
	fun mk_lower c = if upper c then chr(ord(c) + 32) else c

	val capitalise = 
	    apps (fn (c::cs) => mk_upper c :: map mk_lower cs | [] => [])

	val strip = snd o takewhile space
	  
	val strips = apps strip
	
	val clear_ends = rev o strip o (fn (c::ss) => if nl c then ss else ss | [] => []) o rev o strip

	fun first_string p = apply_fst implode o takewhile p
		
	val first_chars = first_string (non whitespace)
	val first_number = first_string num_element
	val first_word = first_string letter
	val first_ident = first_string id_element
	val first_symbol = first_string symbolic

(* first_quoted collects the rest of a string upto the first quote character *)
(* It then discards that quote character.  Thus this should be called after  *)
(* detecting the first quote " to collect the rest of the quote up to the 2nd*)
(* quote character " .							     *)
(* If no quote appears before the end of the input string, then the current  *)
(* string is returned up to the end, together with an empty continuation.    *)

	fun first_quoted s = let val (s,ss) = first_string (non (eq "\"")) s
			     in if ss = [] then (s,ss) else (s,tl ss) end 
		
	fun divide_string strfun (c::sl) = 
	    let val (s1,sr) = strfun (c::sl)
		in if s1 = "" then []
		   else s1 :: divide_string strfun sr end
	  | divide_string strfun [] = []

	fun drop_last s = apps front s
			  handle Tl => ""

(* 
truncate :  int -> string -> string
Truncates a string to the first n characters.
*)

	fun truncate n = apps (take n)

   end ;

