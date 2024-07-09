(*
 *
 * $Log: rewrite.sig,v $
 * Revision 1.2  1998/06/08 17:55:39  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(*

MERILL  -  Equational Reasoning System in Standard ML.
Brian Matthews				     03/03/92
Glasgow University and Rutherford Appleton Laboratory.

rewrite.sig

Functions for doing rewriting - by a single equality on a term, or of various 
rewriting functions, of equalities by a set of equalities.

*)

signature REWRITE =
   sig
	
	type Signature
	type Term
	type Equality
	type EqualitySet
	type Path
	type Substitution

   	val matchsubterm : Signature -> Term -> Term -> (Path * Substitution)

   	val matchandapply : Signature -> Term -> Term -> Term -> (Term * Substitution)
	
	val rewrite : Signature -> Equality -> Term ->  Term

	val norm_once : Signature -> Term -> EqualitySet -> (bool * Term)

	val normalise : Signature -> Term -> EqualitySet -> Term

	val normaliseflag : Signature -> Term -> EqualitySet -> (bool * Term)
	
	val normalise_by_sets : Signature -> Term -> EqualitySet list -> Term

	val normToIdentity : Signature -> EqualitySet list -> Equality -> (bool * Equality)

	val normaliseRight : Signature -> (Equality -> Equality -> Order) 
			-> Equality -> EqualitySet list -> EqualitySet -> EqualitySet

	val normaliseLeft : Signature -> (Equality -> Equality -> Order) 
			-> Equality -> EqualitySet list -> EqualitySet -> Equality list * EqualitySet

	val normaliseEquality : Signature -> EqualitySet list -> Equality -> Equality

	val normalisebyNew : Signature -> (Equality -> Equality -> Order) 
				-> Equality -> EqualitySet -> EqualitySet list -> EqualitySet


    end (* of signature REWRITE *)
    ; 


