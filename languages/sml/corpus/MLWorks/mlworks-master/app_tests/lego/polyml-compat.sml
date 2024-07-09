(*
 *
 * $Log: polyml-compat.sml,v $
 * Revision 1.2  1998/08/05 17:30:56  jont
 * Automatic checkin:
 * changed attribute _comment to ' *  '
 *
 *
 *)
(*  Title: 	NJ
    Author: 	Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1991  University of Cambridge

Compatibility file for MLWorks.  Modified by Harlequin Ltd 1996.
*)

require "__text_io";

(*** Poly/ML emulation ***)

(*To exit the system -- an alternative to ^D *)
(* MLA *)
val quit = () (* MLWorks.Internal.Debugger.exit; *)

(*To change the current directory*)
val cd = fn _ => ();

(*To limit the printing depth [divided by 2 for comparibility with Poly/ML]*)
fun print_depth n = ();

(*Only works in Poly/ML at present*)
fun install_pp f = ();

val output = fn(s,t) => (TextIO.output(s,t); TextIO.flushOut s);


(*A conditional timing function: applies f to () and, if the flag is true,
  prints its runtime. *)
(* MLA *)
fun cond_timeit flag f =
  f ();
(*
  if flag then
    let 
	val string_of_time = MLWorks.Internal.Timer.makestring
	open MLWorks.Internal.Timer;
	val start = start_timer()
	val result = f();
	val nongc = check_timer(start)
	and gc = check_timer_gc(start);
	val sys = check_timer_sys(start);
    in  print ("Non GC " ^ string_of_time nongc ^
	       "   GC " ^ string_of_time gc ^
	       "  SYS "^ string_of_time sys ^ " secs\n");
	result
    end
  else f();
*)

(*Unconditional timing function*)
val timeit = fn x => cond_timeit true x;

(* Define an easy string.< *)
infix <<;
val op << = MLWorks.String.<;

(* CT Timed use *)
(*
fun timed_use x = (print ("Using " ^ x ^ "\n");
	timeit(fn () => use x));
*)


val ord = MLWorks.String.ord;
val chr = MLWorks.String.chr;
val explode = MLWorks.String.explode;
val implode = MLWorks.String.implode;
structure Array = MLWorks.Internal.Array;
structure Vector = MLWorks.Internal.Vector;
structure Bits = MLWorks.Internal.Bits;
exception Interrupt = MLWorks.Interrupt;
val open_in = TextIO.openIn
val close_in = TextIO.closeIn
val std_in = TextIO.stdIn
val std_out = TextIO.stdOut
