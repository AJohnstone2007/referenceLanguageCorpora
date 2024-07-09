(*
 *
 * $Log: uutils.fun,v $
 * Revision 1.2  1998/06/03 11:55:34  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* Copyright (c) 1991 by Carnegie Mellon University *)
(* Author: Frank Pfenning <fp@cs.cmu.edu>           *)

(* Unification utilities *)

functor UUtils (structure Term : TERM
	        structure Print : PRINT
		   sharing Print.Term = Term
		structure Sb : SB
		   sharing Sb.Term = Term
                structure Trail : TRAIL
                   sharing Trail.Term = Term
	        structure Reduce : REDUCE
		  sharing Reduce.Term = Term) : UUTILS =
struct

structure Term = Term

local open Term
in

  val warn_raising = ref true

  fun global_defn (E (ref {Defn = M_opt,...})) = M_opt
    | global_defn _ = NONE

  (* is_rigid : term -> bool , term must be applicative head normal. *)
  fun is_rigid (Const _) = true
    | is_rigid (Uvar _) = true
    | is_rigid (Evar(_,_,_,ref(SOME M0))) = is_rigid M0
    | is_rigid (Evar _) = false
    | is_rigid (Appl(M,_)) = is_rigid M
    | is_rigid (Type) = true
    | is_rigid (Fvar _) = true
    | is_rigid (Pi _) = true
    | is_rigid M = raise Print.subtype("is_rigid",M,"is not in applicative head normal form")

  (* is_flex : term -> bool , term must be applicative head normal. *)
  fun is_flex (Evar(_,_,_,ref(SOME M0))) = is_flex M0
    | is_flex (Evar _) = true
    | is_flex (Appl(M,_)) = is_flex M
    | is_flex (Const _) = false
    | is_flex (Uvar _) = false
    | is_flex (Fvar _) = false
    | is_flex (Type) = false
    | is_flex (Pi _) = false
    | is_flex M = raise Print.subtype("is_flex",M,"is not in applicative head normal form")

  (* is_defn : term -> term option , term must be applicative head normal. *)
  fun is_defn (Const(se)) = global_defn se
    | is_defn (Uvar _) = NONE
    | is_defn (Evar(_,_,_,ref(SOME M0))) = is_defn M0
    | is_defn (Evar _) = NONE
    | is_defn (Appl(M,_)) = is_defn M
    | is_defn (Type) = NONE
    | is_defn (Fvar _) = NONE
    | is_defn (Pi _) = NONE
    | is_defn M = raise Print.subtype("is_defn",M,"is not in applicative head normal form")

  fun replace_head M H =
      let fun rh (Const _) = H
	    | rh (Evar(_,_,_,ref(SOME M0))) = rh M0
	    | rh (Appl(M,N)) = Appl(rh M,N)
	    | rh _ = raise Print.subtype("replace_head",M,"is not rigid")
       in rh M end

  fun abst_over_uvar ((a as Uvar(Varbind(name,A),stamp)),x) M =
     let fun ao (M as Bvar _) = M
	   | ao (M as Evar(_,_,_,ref(SOME M0))) = ao M0
	   | ao (M as Evar(Varbind(y,B),_,ok_uvars,ref(NONE))) =
		(* In this context we should never have to do raising! *)
		( if (!warn_raising) andalso exists (Sb.eq_uvar stamp) ok_uvars
		  then print
			 ("%WARNING: abst_over_uvar: " ^ Print.makestring_term M
			  ^ " may depend on " ^ Print.makestring_term a ^ ".\n")
		  else () ;
		  M )
	   | ao (M as Uvar(_,stamp0)) = if stamp = stamp0 then Bvar(x) else M
	   | ao (M as Const _) = M
	   | ao (Appl(M1,M2)) = Appl(ao M1,ao M2)
	   | ao (Abst(yofB_M0 as (Varbind(y,B),M0))) =
		if x = y
		   then let val (yofB',rsb) = Sb.rename_sb yofB_M0 Sb.id_sb
			 in ao (Abst(yofB',Sb.renaming_apply_sb rsb M0)) end
		   else Abst(Varbind(y,ao B),ao M0)
	   | ao (M as Type) = M
	   | ao (Pi((yofB_C as (Varbind(y,B),C),occ))) =
		if (occ = Maybe) andalso x = y
		   then let val (yofB',rsb) = Sb.rename_sb yofB_C Sb.id_sb
			 in ao (Pi((yofB',Sb.renaming_apply_sb rsb C),occ)) end
		   else Pi((Varbind(y,ao B),ao C),occ)
	   | ao (M as Fvar _) = M
	   | ao M = raise Print.subtype("abst_over_uvar",M,"unexpected term")
      in (Varbind(x,A),ao M) end
    | abst_over_uvar (N,x) M = raise Print.subtype("abst_over_uvar",N,"is not a Uvar")

  fun revsublist_upto test l =
    let fun se initseg nil = (initseg,nil)
	  | se initseg (x::rest) =
	       if test(x) then (x::initseg,rest) else se (x::initseg) rest
     in se nil l end

  fun abst_over_uvar_raise ((a as Uvar(Varbind(name,A),stamp)),x) M =
     let fun ao (M as Bvar _) = M
	   | ao (M as Evar(_,_,_,ref(SOME M0))) = ao M0
	   | ao (M as Evar(Varbind(y,B),_,ok_uvars,ref(NONE))) =
		if exists (Sb.eq_uvar stamp) ok_uvars
		   then let val (init_uvars,rest_uvars) =
				   revsublist_upto (Sb.eq_uvar stamp) ok_uvars
			    val raised_type = fold pi_over_uv_raise init_uvars B
			    val raised_evar = Sb.new_evar (Varbind(y,raised_type)) rest_uvars
			    val raised_M = revfold (fn (M,N) => Appl(N,M)) init_uvars raised_evar
			 in ( Trail.instantiate_evar M raised_M ;
			      ao raised_M )
			end
		   else M
	   | ao (M as Uvar(_,stamp0)) = if stamp = stamp0 then Bvar(x) else M
	   | ao (M as Const _) = M
	   | ao (Appl(M1,M2)) = Appl(ao M1,ao M2)
	   | ao (Abst(yofB_M0 as (Varbind(y,B),M0))) =
		if x = y
		   then let val (yofB',rsb) = Sb.rename_sb yofB_M0 Sb.id_sb
			 in ao (Abst(yofB',Sb.renaming_apply_sb rsb M0)) end
		   else Abst(Varbind(y,ao B),ao M0)
	   | ao (M as Type) = M
	   | ao (Pi((yofB_C as (Varbind(y,B),C),occ))) =
		if (occ = Maybe) andalso x = y
		   then let val (yofB',rsb) = Sb.rename_sb yofB_C Sb.id_sb
			 in ao (Pi((yofB',Sb.renaming_apply_sb rsb C),occ)) end
		   else Pi((Varbind(y,ao B),ao C),occ)
	   | ao (M as Fvar _) = M
	   | ao M = raise Print.subtype("abst_over_uvar_raise",M,"unexpected term")
      in (Varbind(x,A),ao M) end
    | abst_over_uvar_raise (N,x) M = raise Print.subtype("abst_over_uvar_raise",N,"is not a Uvar")

  and pi_over_uv_raise ((a as Uvar(Varbind(x,_),_)),M) =
	 make_pi(abst_over_uvar_raise (a,x) M)
    | pi_over_uv_raise (M,_) = raise Print.subtype("pi_over_uv_raise",M,"is not a Uvar.")

  fun abst_over_uv_raise ((a as Uvar(Varbind(x,_),_)),M) =
	 Abst(abst_over_uvar_raise (a,x) M)
    | abst_over_uv_raise (Evar(_,_,_,ref(SOME(M0))),M) = abst_over_uv_raise(M0,M)
    | abst_over_uv_raise (M,_) = raise Print.subtype("abst_over_uv_raise",M,"is not a Uvar.")

  (* !!! for now, the opimization of non-raising is disabled *)
  (* val abst_over_uvar = abst_over_uvar_raise *)

  (* abst_over_uv and pi_over_uv are extremely inefficient as used within
     fold, since they will copy the term *)

  fun abst_over_uv ((a as Uvar(Varbind(x,_),_)),M) = Abst(abst_over_uvar (a,x) M)
    | abst_over_uv (M,_) = raise Print.subtype("abst_over_uv",M,"is not a Uvar.")

  fun pi_over_uv ((a as Uvar(Varbind(x,_),_)),M) = make_pi(abst_over_uvar (a,x) M)
    | pi_over_uv (M,_) = raise Print.subtype("pi_over_uv",M,"is not a Uvar.")

  fun init_seg uvars1 uvars2 = length uvars1 <= length uvars2

  fun dest_pi_error (Pi(xofA_B,_)) = xofA_B
    | dest_pi_error A =
	 case (Reduce.renaming_head_norm A)
	   of (Pi(xofA_B,_)) => xofA_B
	    | _ => raise Print.subtype("dest_pi_error",A,"is not a function type")

end  (* local ... *)
end  (* functor UUtils *)
