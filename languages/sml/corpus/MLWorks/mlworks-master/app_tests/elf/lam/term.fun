(*
 *
 * $Log: term.fun,v $
 * Revision 1.2  1998/06/03 12:05:09  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* Copyright (c) 1991 by Carnegie Mellon University *)
(* Author: Frank Pfenning <fp@cs.cmu.edu>           *)

(* Basic term representation *)

functor Term (val fixity_min : int
	      val fixity_max : int) : TERM =
struct

  datatype occurs = Maybe | Vacuous

  datatype associativity = Left | Right | None
  datatype fixity = Infix of associativity | Prefix | Postfix

  datatype term
    =  Bvar of string             (* Bound variable: name *)
    |  Evar of varbind * int * term list * (term option) ref
			          (* Logic variable: *)
				  (* name/type, stamp, depends on, bound to *)
    |  Uvar of varbind * int	  (* Parameter: name/type, stamp *)
    |  Fvar of varbind            (* Free variable: name/type *)
    |  Const of sign_entry  	  (* Constant *)
    |  Appl of term * term        (* Application *)
    |  Abst of varbind * term	  (* Abstraction *)
    |  Pi of (varbind * term) * occurs
                                  (* Pi quantification *)
    |  Type                       (* Type *)
    |  HasType of term * term     (* Explicit type annotation *)
    |  Mark of (int * int) * term (* Marked term *)
    |  Wild			  (* Omitted term *)

  and varbind = Varbind of string * term  (* Variable binder: name, type *)

  and sign_entry		  (* signature entry, compared for equality *)
    = E of
	{
        Bind : varbind,		  (* the constant and its type *)
        Full : term,		  (* syntactic expansion *)
        Defn : term option, 	  (* optional definition *)
        Prog : int option ref,    (* progtable entry index *)
	Dyn  : bool ref,          (* dynamic? *)
	Fixity : (fixity * int) option ref,  
				  (* optional fixity and precedence *)
	NamePref : string list option ref,
			          (* optional prefered names *)
	Inh  : bool list,         (* for each argument: is it inherited? *)
	Syn  : bool list          (* for each argument: is it synthesized? *)
  	} ref
    | Int of int		  (* integers *)
    | String of string		  (* strings *)
    | IntType			  (* type of integers *)
    | StringType		  (* type of strings *)

  val fixity_min = fixity_min
  val fixity_max = fixity_max

  val anonymous = "_"

  fun make_pi xofA_M = Pi(xofA_M,Maybe)

  fun make_arrow (A1,A2) = Pi((Varbind(anonymous, A1), A2), Vacuous)

  val int_type = Const(IntType)
  val string_type = Const(StringType)

  fun se_type (E (ref {Bind = Varbind(_,A), ...})) = A
    | se_type (Int _) = int_type
    | se_type (String _) = string_type
    | se_type (IntType) = Type
    | se_type (StringType) = Type

  fun eq_var (Uvar(_,stamp1), Uvar(_,stamp2)) = (stamp1 = stamp2)
    | eq_var (Evar(_,stamp1,_,_), Evar(_,stamp2,_,_)) = (stamp1 = stamp2)
    | eq_var (Fvar(Varbind(x1,_)), Fvar(Varbind(x2,_))) = (x1 = x2)
    | eq_var (Bvar(x1), Bvar(x2)) = (x1 = x2)
    | eq_var _ = false

  (* 
     location tries to skip over implicit arguments to find the location
     of the head of a term, if available.  This is only a heuristic and
     there are no guarantees about the returned location!
   *)
  fun left_location (Mark((left,_),_)) = SOME(left)
    | left_location (Appl(M1,M2)) = left_location M1
    | left_location _ = NONE

  fun right_location (Mark((_,right),_)) = SOME(right)
    | right_location (Appl(M1,M2)) = right_location M2
    | right_location _ = NONE

  fun location (Mark(lrpos,_)) = SOME(lrpos)
    | location M = (case (left_location M, right_location M)
		      of (NONE,NONE) => NONE
		       | (SOME(left),NONE) => SOME(left,left)
		       | (NONE,SOME(right)) => SOME(right,right)
		       | (SOME(left), SOME(right)) => SOME(left,right))

end  (* functor Term *)
