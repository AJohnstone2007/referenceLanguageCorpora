(*
 *
 * $Log: t_input.sml,v $
 * Revision 1.2  1998/06/08 17:29:50  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(*

Some basic input routines

These input routines buffer up the input as it is entered line-by-line.

*)

structure Terminal_Input = 
   struct
   	local
	val Input_Buffer = ref [] : string list ref;	
	in
	fun get_next_character () = (* does not pick up the newline character *)
		(case !Input_Buffer of
		  [] => let val cs = (front o explode) (read_line_terminal ())
		        in (Input_Buffer := tl cs ; hd cs) end 
		| c::ss => (Input_Buffer := ss ; c))

	fun get_next_string charfun () = 
		if !Input_Buffer = [] 
		then let val (cs,rl) = (charfun o front o strip o explode) (read_line_terminal ())
		     in (Input_Buffer := strip rl ; cs) end
		else let val (cs,rl) = charfun (!Input_Buffer)
		     in (Input_Buffer := strip rl ; cs)
		     end ;


	val get_next_chars = get_next_string first_chars ;
	val get_next_word = get_next_string first_word ; 
	val get_next_number = get_next_string first_number ;
	val get_next_ident = get_next_string first_ident;
	val get_next_symbol = get_next_string first_symbol ;
	val get_quoted = get_next_string first_quoted ;


	fun flush_input () = Input_Buffer := [] ;
	fun no_current_input () = (!Input_Buffer = []) ;
	
	val get_next_line = (flush_input (); read_line_terminal)

	end 

end;

