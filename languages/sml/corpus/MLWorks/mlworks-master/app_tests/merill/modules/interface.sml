(*
 *
 * $Log: interface.sml,v $
 * Revision 1.2  1998/06/08 17:31:46  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* 

interface.sml

This module aims to collect together in one place those
rather peripatetic functions accumulated during the implementation 
which do a lot of the basic interface control.  A bit more high level than
the t_input and t_output structures - but not necessarily a lot!!

MERILL  -  Equational Reasoning System in Standard ML.
Brian Matthews				     27/07/90
Glasgow University and Rutherford Appleton Laboratory.

*)

structure Interface = 
   struct 

datatype Justify = Left | Right | Centre 

fun pad Left n s = 
	let val sn = size s in
	if n < sn then truncate n s
	else s^(nchars " " (n-sn)) 
	end 
  | pad Right n s = 
	let val sn = size s in
	if n < sn then truncate n s
	else (nchars " " (n-sn))^s 
	end 
  | pad Centre n s = 
	let val sn = size s in
	if n < sn then truncate n s
	else let val p = (n - sn)
	         val padding = nchars " " (p div 2)
	     in if even p then padding^s^padding
	        else padding^s^padding^" " 
	     end 
	end 

fun prompt string = 
	(Termcap.clear_line () ;
	 write_terminal string ;
	 get_next_line () ) 

val Prompt1 = ">>  " 

fun prompt1 s = write_terminal (s^Prompt1) 
fun prompt_reply s = let val d = prompt1 s in get_next_chars () end 
fun prompt_line s = (prompt1 s ; get_next_line ()) 

fun wait_on_user () = (ignore(read_terminal 1);())
fun message_and_wait () = (ignore(prompt_reply "Press Enter/Return to continue. ") ; ())

fun display_in_field just n s = write_terminal (pad just n s) ;

(*
fun display_two_cols just (t1,l1,t2,l2) = 
	let val (mr,mc) = get_window_size ()
	    val maxleft = maximum (map size (t1::l1)) + 2
	    val maxright = maximum (map size (t2::l2)) + 2
	    val half = mc div 2
	    val noleft = length l1
	    val noright = length l2 
	    val longest = max (noleft,noright) + 1
	    fun lefts [] = ()
	      | lefts (s1::ss) = (display_in_field just maxleft s1 ;
	      			  newline ();
	      			  lefts ss )
	    fun rights [] = () 
	      | rights (s1::ss) = (display_in_field just maxright s1 ;
	      			   left maxright ; 
	      			   down 1 ;
	      			   rights ss )
	in (display_in_field just maxleft t1 ; 
	    right (half - maxleft) ;
	    display_in_field just maxright t2 ;
	    newline () ; newline () ;
	    lefts l1 ; up noleft ; right half ;
	    rights l2 ; up noright ; down longest ;
	    newline () ; up 1 )
	end     
*)

fun display_two_cols just (t1,l1,t2,l2) = 
	let val (mr,mc) = get_window_size ()
	    val maxleft = maximum (map size (t1::l1)) + 2
	    val maxright = maximum (map size (t2::l2)) + 2
	    val half = mc div 2
	    val halfline = spaces half
	    val right = spaces (half - maxleft)
	    fun disp2 [] [] = ()
	      | disp2 [] (r::rs) = (write_terminal halfline ; 
	                            display_in_field just maxright r ; 
	                            newline () ; disp2 [] rs) 
	      | disp2 (l::ls) [] = (display_in_field just maxleft l  ; newline () ; disp2 ls [])
	      | disp2 (l::ls) (r::rs) = (display_in_field just maxleft l  ; 
	                                 write_terminal right ; 
	                                 display_in_field just maxright r ; 
	                                 newline () ; disp2 ls rs) 
	in disp2 (t1::l1) (t2::l2)
	end

fun title_line s = 
    let val (mr,mc) = get_window_size ()
        val sn = size s 
        val h  = mc div 2 - sn div 2
        val line = if odd sn then nchars "-" (h - 1)
                   else nchars "-" h
    in  if odd sn then line ^ s ^ "-" ^ line else line ^ s ^ line
    end 

fun clear_title title = 
    (clear_screen (); write_terminal (title_line title ^ "\n")) 

fun print_line () = write_terminal (title_line "")

fun act_on_no_input f = if no_current_input () then f () else ()

fun act_and_get f = if no_current_input () then f () else get_next_chars () 

fun act_with_message s = act_and_get (write_terminal s;get_next_chars) 

fun confirm s =
    (write_terminal (s^" (y/n) ? ");
     let val reply = (hd (explode (read_line std_in))
			handle Hd => "")
     in reply = "y" orelse reply = "Y"
     end)
(* 
read_n_times : int -> string -> int list
Reads a list of n integers from the screen giving the string prompt each time.
If the string entered is not an integer the error message results.
*)

fun read_n_times 0 s = []
  | read_n_times n s = (write_terminal s ;
  		  case (stringtoint o drop_last o read_line_terminal) () of
  		  OK m => m :: read_n_times (n - 1) s
  		  | Error _ => (write_terminal "Only enter integers\n" ;
  		                read_n_times n s)
  		 ) ;

end (* of structure Interface *) ;
