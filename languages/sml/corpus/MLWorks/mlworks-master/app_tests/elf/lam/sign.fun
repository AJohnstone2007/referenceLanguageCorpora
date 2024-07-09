(*
 *
 * $Log: sign.fun,v $
 * Revision 1.2  1998/06/03 12:09:44  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* Copyright (c) 1991 by Carnegie Mellon University *)
(* Author: Frank Pfenning <fp@cs.cmu.edu>           *)

(* Signatures *)

functor Sign (structure Basic : BASIC
	      structure Term : TERM
	      structure IPrint : PRINT
	         sharing IPrint.Term = Term
	      structure Print : PRINT
	         sharing Print.Term = Term
		 sharing Print.F = IPrint.F
		 sharing Print.S = IPrint.S) : SIGN =
struct

structure Term = Term

local open Term
    structure F = IPrint.F
    structure S = IPrint.S
in

  type sign = sign_entry list

  val empty_sig = nil
  fun add_sig (se,sign) = se::sign
  fun sig_append sign1 sign2 = sign1 @ sign2

  fun ellide_pis (Appl(c_',Wild)) (Pi((_,A'),_)) =
	         ellide_pis c_' A'
    | ellide_pis _ A = A

  fun makeformat_sigentry_full (E (ref {Bind = cofA, Defn = SOME(defn), ...})) =
	 F.HOVbox [IPrint.makeformat_varbind(cofA), F.Break,
	     F.String S.equal, F.Space,
	     IPrint.makeformat_term(defn), F.String S.dot]
    | makeformat_sigentry_full (E (ref {Bind = cofA, Defn = NONE, ...})) =
	 IPrint.makeformat_conbind(cofA)
    | makeformat_sigentry_full _ =
         raise Basic.Illegal("makeformat_sigentry: basic const in signature")

  fun makeformat_sigentry (E (ref {Bind = Varbind(c,A),
				   Defn = NONE,
				   Full = c_, ...})) =
         F.HOVbox [F.String(S.const(c)), F.Space, F.String S.colon,
		   F.Break, Print.makeformat_term (ellide_pis c_ A),
		   F.String S.dot]
    | makeformat_sigentry _ =
         raise Basic.Illegal("makeformat_sigentry: basic const in signature")

  fun makeformat_sig format_entry_func sign =
      F.Vbox0 0 1
	(revfold (fn (sigentry,fmtlist) =>
		    format_entry_func sigentry :: F.Break :: fmtlist)
		 (sign) [])

  val sig_print_full = F.print_fmt o
                       (makeformat_sig makeformat_sigentry_full)

  val sig_print = F.print_fmt o (makeformat_sig makeformat_sigentry)

  (*
  fun sig_print_file filename sign =
    F.with_open_fmt filename (fn fmtstream =>
       F.output_fmt (fmtstream, makeformat_sig makeformat_sigentry_full sign))
  *)

  fun sig_item nil = NONE
    | sig_item (se :: sign') = SOME(se,sign')

  fun sig_to_list sign = rev sign

end (* local ... *)
end (* functor Sign *)
