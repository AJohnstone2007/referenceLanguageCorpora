(*
 *
 * $Log: reduce.fun,v $
 * Revision 1.2  1998/06/03 12:11:44  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* Copyright (c) 1991 by Carnegie Mellon University *)
(* Author: Frank Pfenning <fp@cs.cmu.edu>           *)

(* Reduction *)

functor Reduce
   (structure Term    : TERM
    structure Print   : PRINT sharing Print.Term = Term
    structure Sb      : SB    sharing Sb.Term = Term)
   : REDUCE =
struct

structure Term = Term

local open Term
in

  local exception IsNorm
  in

    fun head_norm (Evar(_,_,_,ref (SOME M0))) = head_norm M0
      | head_norm M = hnorm M handle IsNorm => M
    and hnorm (M as (Bvar _)) = raise IsNorm
      | hnorm (M as (Evar(_,_,_,ref NONE))) = raise IsNorm
      | hnorm (M as (Evar(_,_,_,ref (SOME M0)))) = head_norm M0
      | hnorm (M as (Uvar _)) = raise IsNorm
      | hnorm (M as (Const _)) = raise IsNorm
      | hnorm (Appl(M1,M2)) =
	  let val normal_M1 = hnorm M1
	   in case normal_M1
		of (Abst(xofA,M1')) =>
		      head_norm (Sb.apply_sb (Sb.term_sb xofA M2) M1')
		 | _ => Appl(normal_M1,M2)
	  end
      | hnorm (M as Abst _) = M
      | hnorm (M as Pi _) = M
      | hnorm (M as Type) = M
      | hnorm (M as Wild) = M
      | hnorm (HasType(M,A)) = head_norm M
      | hnorm (Mark(_,M)) = head_norm M
      | hnorm (Fvar _) = raise IsNorm

    fun renaming_head_norm M = rhnorm M handle IsNorm => M
    and rhnorm (M as (Bvar _)) = raise IsNorm
      | rhnorm (M as (Evar(_,_,_,ref NONE))) = raise IsNorm
      | rhnorm (M as (Evar(_,_,_,ref (SOME M0)))) = renaming_head_norm M0
      | rhnorm (M as (Uvar _)) = raise IsNorm
      | rhnorm (M as (Const _)) = raise IsNorm
      | rhnorm (Appl(M1,M2)) =
	  let val normal_M1 = rhnorm M1
	   in case normal_M1
		of (Abst(xofA,M1')) =>
		      renaming_head_norm
			 (Sb.renaming_apply_sb (Sb.term_sb xofA M2) M1')
		 | _ => Appl(normal_M1,M2)
	  end
      | rhnorm (M as Abst _) = M
      | rhnorm (M as Pi _) = M
      | rhnorm (M as Type) = M
      | rhnorm (M as Wild) = M
      | rhnorm (HasType(M,A)) = renaming_head_norm M
      | rhnorm (Mark(_,M)) = renaming_head_norm M
      | rhnorm (Fvar _) = raise IsNorm

  end  (* local exception IsNorm *)

  fun head_args_norm (M as (Bvar _)) = M
    | head_args_norm (M as (Evar(_,_,_,ref NONE))) = M
    | head_args_norm (M as (Evar(_,_,_,ref (SOME M0)))) = head_args_norm M0
    | head_args_norm (M as (Uvar _)) = M
    | head_args_norm (M as (Const _)) = M
    | head_args_norm (M as (Type)) = M
    | head_args_norm (M as (Pi _)) = M
    | head_args_norm (Appl(M1,M2)) =
	let val normal_M1 = head_args_norm M1 in
	(case normal_M1
	   of (Abst(xofA,M1')) =>
		 head_args_norm (Sb.renaming_apply_sb (Sb.term_sb xofA M2) M1')
		   (* Invariant of apply_sb would be violated in preceding line,
		      thus calling rename_apply_sb! *)
	    | _ => Appl(normal_M1, head_norm M2))
	end
    | head_args_norm (M as (Abst _)) = M
    | head_args_norm (Wild) = Wild
    | head_args_norm (HasType(M,A)) = head_args_norm M
    | head_args_norm (Mark(_,M)) = head_args_norm M
    | head_args_norm (M as (Fvar _)) = M

  fun beta_norm (M as (Bvar _)) = M
    | beta_norm (M as (Evar(_,_,_,ref NONE))) = M
    | beta_norm (M as (Evar(_,_,_,ref (SOME M0)))) =
	 beta_norm M0
    | beta_norm (M as (Uvar _)) = M
    | beta_norm (M as (Const _)) = M
    | beta_norm (M as (Type)) = M
    | beta_norm (Appl(M1,M2)) =
	let val normal_M1 = beta_norm M1 in
	(case normal_M1
	   of (Abst(xofA,M1')) =>
		 beta_norm (Sb.renaming_apply_sb (Sb.term_sb xofA M2) M1')
		 (* Invariant of apply_sb would be violated above! *)
	    | _ => Appl(normal_M1,beta_norm M2))
	end
    | beta_norm (Abst(Varbind(x,A),M)) =
	 Abst(Varbind(x,beta_norm A),beta_norm M)
    | beta_norm (Pi((Varbind(x,A),B),occ)) =
	 Pi((Varbind(x,beta_norm A),beta_norm B),occ)
    | beta_norm (Wild) = Wild
    | beta_norm (HasType(M,A)) = beta_norm M
    | beta_norm (Mark(_,M)) = beta_norm M
    | beta_norm (M as (Fvar _)) = M

  fun pi_vbds B =
     let fun rev_pi_vbds B rev_Gamma = 
	    let val B' = renaming_head_norm B
	     in case B'
		  of Pi((xofA,B0),_) => rev_pi_vbds B0 (xofA :: rev_Gamma)
		   | _ => (rev rev_Gamma,B')
	    end
      in rev_pi_vbds B nil end

  type head = term

  (* rigid_term_head : term -> term
     term must be applicative head normal and rigid,
     result will be a Const, a Uvar, or Type. *)

  fun rigid_term_head (M as (Const _)) = M
    | rigid_term_head (M as (Uvar _)) = M
    | rigid_term_head (Appl(M,_)) = rigid_term_head M
    | rigid_term_head (Evar(_,_,_,ref (SOME M0))) = rigid_term_head M0
    | rigid_term_head (M as Type) = M
    | rigid_term_head (M as (Fvar _)) = M
    | rigid_term_head M =
         raise Print.subtype("rigid_term_head",M,"is not rigid")

  local
    fun ha (Appl(M,N)) args = ha M (N::args)
      | ha (Evar(_,_,_,ref (SOME M0))) args = ha M0 args
      | ha (M as (Evar _)) args = (M,args)
      | ha (M as (Const _)) args = (M,args)
      | ha (M as (Uvar _)) args = (M,args)
      | ha (M as (Type)) args = (M,args)
      | ha (M as (Fvar _)) args = (M,args)
      | ha M _ =
           raise Print.subtype("head_args",M,"is not applicative head normal")
  in
    fun head_args M = ha M nil
  end

  fun eq_head (Const(cname1),Const(cname2)) = (cname1 = cname2)
    | eq_head (Uvar(_,stamp1),Uvar(_,stamp2)) = (stamp1 = stamp2)
    | eq_head (Evar(_,stamp1,_,ref(NONE)),Evar(_,stamp2,_,ref(NONE))) =
	 (stamp1 = stamp2)
    | eq_head (Type,Type) = true
    | eq_head (Fvar(Varbind(x,_)),Fvar(Varbind(y,_))) = (x = y)
    | eq_head _ = false

end  (* local ... *)
end  (* functor Reduce *)
