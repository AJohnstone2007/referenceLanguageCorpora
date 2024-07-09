(*
 *
 * $Log: term.sig,v $
 * Revision 1.2  1998/06/08 17:41:46  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* 
Status: R

MERILL  -  Equational Reasoning System in Standard ML.
Brian Matthews				     27/02/90
Glasgow University and Rutherford Appleton Laboratory.

term.sig

This file contains the signature of Term handling functions.

*)

signature TERM = 
   sig

	structure Pretty : PRETTY
	structure Sig : SIGNATURE
	
	type Sort
	type OpId
	type Variable

	type Term 
	
	exception Ill_Formed_Term of string

	val mk_OpTerm : OpId -> Term list -> Term
	val mk_VarTerm  : Variable -> Term

	val compound : Term -> bool
	val variable : Term -> bool
	val constant : Term -> bool
	val subterms : Term -> Term list
	val root_operator : Term -> OpId
	val same_root : Term -> Term -> bool
	val get_Variable : Term -> Variable
	val nth_subterm : Term -> int -> Term 
	val num_ops_in_term : Term -> int
	
	val TermEq : Term -> Term -> bool
	val ord_t  : Term -> Term -> bool

	val termmap : (Term -> Term) -> Term -> Term
	
	val vars_of_term : Term -> Variable list
	val num_of_vars  : Term -> (Variable * int) list
	val issubterm : Term -> Term -> bool
	val linear : Term -> bool

	val occurs : Variable -> Term -> bool
	val occurrences_of : Term -> Term -> int
	
	exception Least_Sort of Sort list
	val of_sort : Sig.Signature-> Sort -> Term -> bool
	val least_sort : Sig.Signature -> Term -> Sort
	 
	val rename_term : Term -> (Variable, Variable) Assoc.Assoc -> 
				  (Variable, Variable) Assoc.Assoc * Term

	val alphaequiv : Term -> Term -> (Variable, Variable) Assoc.Assoc -> 
				 bool *  (Variable, Variable) Assoc.Assoc

	val parse_term : Sig.Signature -> Term TranSys.TranSys -> 
			(string, Variable) Assoc.Assoc -> string list  -> 
			 ((Term * string list) * (string, Variable) Assoc.Assoc) Maybe 
 
	val unparse_term :  Sig.Signature 
		         -> Sig.V.Variable_Print_Env
			 -> Term 
			 -> string * Sig.V.Variable_Print_Env

 	val show_term : Sig.Signature -> Term -> string

	val pretty_term :  Sig.Signature 
		         -> Sig.V.Variable_Print_Env
			 -> Term 
			 -> Pretty.T * Sig.V.Variable_Print_Env

	val show_pretty_term : Sig.Signature  -> Term  -> Pretty.T 

   end ;


