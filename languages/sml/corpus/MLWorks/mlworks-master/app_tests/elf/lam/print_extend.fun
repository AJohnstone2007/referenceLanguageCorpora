(*
 *
 * $Log: print_extend.fun,v $
 * Revision 1.2  1998/06/03 12:14:13  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* Copyright (c) 1991 by Carnegie Mellon University *)
(* Author: Frank Pfenning <fp@cs.cmu.edu>           *)

(* Extending basic term printing to other data types *)

functor PrintExtend (structure Basic : BASIC
		     structure Term : TERM
		     structure Sb : SB
		        sharing Sb.Term = Term
		     structure Symtab : SYMTAB
			sharing type Symtab.entry = Term.sign_entry
		     structure PrintTerm : PRINT_TERM
			sharing PrintTerm.Term = Term) : PRINT =
struct

structure Term = Term
structure F = PrintTerm.F
structure S = PrintTerm.S

local open Term
      open F
in

  val printDepth = PrintTerm.printDepth
  val printLength = PrintTerm.printLength

  val makeformat_term = PrintTerm.makeformat_term
  val makeformat_const = PrintTerm.makeformat_const
  fun makeformat_varbind (Varbind(x,A)) =
		     HOVbox[ String(S.var(x)), Space, String S.colon,
			     Break, makeformat_term A ]
  fun makeformat_conbind (Varbind(c,A)) =
		     HOVbox[ String(S.const(c)), Space, String S.colon,
			     Break, makeformat_term A,
			     String S.dot ]

  val makestring_term = makestring_fmt o makeformat_term
  val makestring_const = makestring_fmt o makeformat_const
  val makestring_varbind = makestring_fmt o makeformat_varbind
  val makestring_conbind = makestring_fmt o makeformat_conbind

  (* To signal illegal calls *)
  fun subtype(func,M,is_not) =
       Basic.Illegal
	  (makestring_fmt(HOVbox[ String(S.string(func)), String S.colon,
				  Break, (makeformat_term M),
				  Break, String (S.string(is_not)),
				  String S.dot, Newline () ] ))

  fun cvt_substitution (M as Evar(_,_,_,ref NONE)) = (M,M)
    | cvt_substitution (Evar(vbd,stamp,uvars,ref (SOME M0)))
	= (Evar(vbd,stamp,uvars,ref NONE), M0)
    | cvt_substitution M
	= raise subtype("cvt_substitution",M,"is not an Evar")

  fun makeformat_subst nil = [ String S.dot, Newline () ]
    | makeformat_subst ((Evar(Varbind(x,_),_,_,_),M)::rest) =
       [ Break,
	 HOVbox[String(S.var(x)),
	    Space, String S.equal,
	    Break, makeformat_term M,
	    (case rest of nil => Spaces 0 | _ => String S.comma)]
       ] @ (makeformat_subst rest)
    | makeformat_subst ((M,_)::rest) =
         raise subtype("makeformat_subst",M,"is not an Evar")

  fun makestring_vartermlist vtlist =
	 makestring_fmt(Vbox0 0 1 (makeformat_subst vtlist))
  fun makestring_substitution sl = 
	 makestring_fmt(Vbox0 0 1 (makeformat_subst (map cvt_substitution sl)))

end  (* local ... *)
end  (* functor PrintExtend *)
