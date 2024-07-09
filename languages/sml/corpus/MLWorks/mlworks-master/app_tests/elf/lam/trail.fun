(*
 *
 * $Log: trail.fun,v $
 * Revision 1.2  1998/06/03 12:04:43  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* Copyright (c) 1991 by Carnegie Mellon University *)
(* Author: Frank Pfenning <fp@cs.cmu.edu>           *)

(* Trailing of the instantiation of logic variables *)

(* This trails all variables, not just the ones introduced since *)
(* the last choice point. *)

functor Trail (structure Basic : BASIC
	       structure Term : TERM) : TRAIL =
struct

structure Term = Term

local open Term
in

  datatype trail =
	   consTrail of term * (trail ref)
	|  nilTrail

  local val global_trail = ref (ref nilTrail)
  in

    fun unwind_trail shorter_trail longer_trail =
	if longer_trail = shorter_trail
	   then (global_trail := shorter_trail; ())
	   else (case !longer_trail of
		      (consTrail (Evar(_,_,_,vslot),rest_trail)) =>
			 (vslot := NONE; unwind_trail shorter_trail rest_trail)
		    | _ => raise Basic.Illegal("unwind_trail: internal error."))

    fun trail func = 
	  let val old_trail = !global_trail
	   in ( ignore(func ()) ; unwind_trail old_trail (!global_trail) ; () ) end

    fun instantiate_evar (s as Evar(_,_,_,vslot)) t =
	   ( vslot := SOME t;
	     global_trail := ref (consTrail(s,!global_trail)) )
      | instantiate_evar s _ =
	   raise Basic.Illegal("instantiate_evar: argument is not an Evar.")

    (* Call this only if all evar's have been dereferenced. *)
    (* Useful for type reconstruction. *)
    fun erase_trail () = global_trail := ref nilTrail

  end  (* local ... *)

end  (* local ... *)
end  (* functor Trail *)
