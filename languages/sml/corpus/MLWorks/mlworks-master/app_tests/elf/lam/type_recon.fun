(*
 *
 * $Log: type_recon.fun,v $
 * Revision 1.2  1998/06/03 12:04:19  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* Copyright (c) 1991 by Carnegie Mellon University *)
(* Author: Frank Pfenning <fp@cs.cmu.edu>           *)

(* Type and object reconstruction *)
(*
   This no longer requires continuation passing style, since backtracking
   has been eliminated !!!
*)
(* Can the abstraction functions be incorporated with UUtils? *)

functor TypeRecon
  (structure Basic : BASIC
   structure Term : TERM
   structure Print : PRINT  sharing Print.Term = Term
   structure IPrint : PRINT sharing IPrint.Term = Term
                            sharing IPrint.F = Print.F
   structure Sb : SB  sharing Sb.Term = Term
   structure Reduce : REDUCE  sharing Reduce.Term = Term
   structure Constraints : CONSTRAINTS  sharing Constraints.Term = Term
   structure UUtils : UUTILS  sharing UUtils.Term = Term
   structure Unify : UNIFY  sharing Unify.Term = Term
			    sharing Unify.Constraints = Constraints
   structure Equal : EQUAL  sharing Equal.Term = Term
   structure Simplify : UNIFY  sharing Simplify.Term = Term
			       sharing Simplify.Constraints = Constraints
   structure TypeDepend : TYPE_DEPEND  sharing TypeDepend.Term = Term
   structure Naming : NAMING  sharing Naming.Term = Unify.Term)
  : TYPE_RECON =

struct

structure Term = Term
structure Sb = Sb
structure Constraints = Constraints

local open Term
      structure S = Print.S
      structure F = Print.F
      structure C = Constraints
in

  structure Switch =
  struct

    exception UnknownSwitch = Basic.UnknownSwitch

    (* Control *)
    val print_internal = ref false

    fun control "print_internal" = print_internal
      | control s= raise UnknownSwitch("Type_Recon.control",s)

    (* Warning *)
    val warn_constraint = ref false

    fun warn "constraint" = warn_constraint
      | warn s = raise UnknownSwitch("Type_Recon.warn",s)

    fun wprint warnref func = if (!warnref) then print(func():string) else ()

    (* Tracing *)

    val trace_type_recon = ref false

    fun trace "type_recon" = trace_type_recon
      | trace s = raise UnknownSwitch("Type_Recon.trace",s)

    fun tprint traceref func = if (!traceref) then print(func():string) else ()

  end  (* structure Switch *)

  open Switch

  (* the next two function fall back on internal printing when external *)
  (* printing is impossible *)
  fun mkfmt_term M =
      if !print_internal
	 then IPrint.makeformat_term M
	 else Print.makeformat_term M
	      handle _ => F.Hbox[F.String (S.string "\""),
			         IPrint.makeformat_term M,
				 F.String (S.string "\"")]

  fun mkstr_term M =
      if !print_internal
	 then IPrint.makestring_term M
         else Print.makestring_term M
	      handle _ => "\"" ^ IPrint.makestring_term M ^ "\""

  exception TypeCheckFail of (int * int) option * string

  type env = (term * varbind) list

  val empty_env = nil

  fun eq_evar_or_fvar (Evar(_,stamp,_,_)) (Evar(_,stamp',_,_)) =
         (stamp = stamp')
    | eq_evar_or_fvar (Fvar(Varbind(x,_))) (Fvar(Varbind(x',_))) =
         (x = x')
    | eq_evar_or_fvar _ _ = false

  fun env_lookup M nil = NONE
    | env_lookup M ((M',Varbind(x,_))::env') =
	 if eq_evar_or_fvar M M'
	    then SOME(x)
	    else env_lookup M env'

  fun shadows_some x nil = false
    | shadows_some x ((_,Varbind(y,_))::env0) =
	 if x = y then true else shadows_some x env0

  fun member x nil = false
    | member x (y::l) = (x = y) orelse member x l

  fun name_evar M freevars env =
         Naming.name_var
	    (fn x => shadows_some x env orelse member x freevars) M

  (* Add pi's in reverse order *)
  (* Simultaneously construct applications to wildcard *)

  fun env_to_quant quant nil M = M
    | env_to_quant quant ((_,xofA as Varbind(x,A))::env') M =
	 env_to_quant quant env' (Appl(Appl(quant,A), Abst(xofA,M)))

  (* This can be optimized using occurs annotation in Pi !!! *)
  fun env_to_pis nil M syndef = (M,syndef)
    | env_to_pis ((_,xofA)::env') M syndef =
	 env_to_pis env' (make_pi(xofA,M)) (Appl(syndef,Wild))

  (* Add abstractions in reverse order *)
  fun env_to_absts nil M = M
    | env_to_absts ((_,xofA)::env') M =
	 env_to_absts env' (Abst(xofA,M))

  fun abst_over_evars freevars env M =
     let fun ao fvs env (M as Bvar _) = (env,M)
	   | ao fvs env (M as Evar(_,_,_,ref(SOME M0))) = ao fvs env M0
	   | ao fvs env (M as Evar(Varbind(x,A),stamp,_,ref(NONE))) =
		  (case (env_lookup M env)
		     of NONE => let val (env',A') = ao fvs env (Reduce.beta_norm A)
				    val x' = name_evar M fvs env'
				 in ((M,Varbind(x',A'))::env',Bvar(x')) end
		      | SOME(x') => (env,Bvar(x')))
	   | ao fvs env (M as Fvar(Varbind(x,A))) =
	          (case (env_lookup M env)
		     of NONE => let val (env',A') = ao fvs env (Reduce.beta_norm A)
			         in ((M,Varbind(x,A'))::env',Bvar(x)) end
	              | SOME(x') => (env,Bvar(x')))
	   | ao fvs env (M as Uvar _) =
		raise Print.subtype("abst_over_evars",M,"is a Uvar")
	   | ao fvs env (M as Const _) = (env,M)
	   | ao fvs env (M as Type) = (env,M)
	   | ao fvs env (Appl(M1,M2)) =
		let val (env',M1') = ao fvs env M1
		    val (env'',M2') = ao fvs env' M2
		 in (env'',Appl(M1',M2')) end
	   | ao fvs env (Abst yofB_M) =
		let val (env',yofB_M') = aos fvs env yofB_M
		 in (env', Abst(yofB_M')) end
	   | ao fvs env (Pi(yofB_C,occ)) =
		let val (env',yofB_C') = aos fvs env yofB_C
		 in (env', Pi(yofB_C',occ)) end
	   | ao fvs env (HasType(M,A)) =
		let val (env',A') = ao fvs env A
		    val (env'',M') = ao fvs env' M
		 in (env'',HasType(M',A')) end
	   | ao fvs _ (M as Wild) = raise Print.subtype("abst_over_evars",M,"illegal wildcard")
           | ao fvs _ (M as Mark _) = raise Print.subtype("abst_over_evars",M,"illegal marked term")
	 and aos fvs env (yofB as Varbind(y,B),M0) =
	     if shadows_some y env
		then let val (yofB',rsb) = Sb.rename_sb (yofB,M0) Sb.id_sb
		      in aos fvs env (yofB',Sb.renaming_apply_sb rsb M0) end
		else let val (env',B') = ao fvs env B
			 val (env'',M0') = ao (y::fvs) env' M0
		     in (env'',(Varbind(y,B'),M0')) end
      in ao freevars env M end

  fun fail_mismatch M M' A' A func =
         raise TypeCheckFail
	       (Term.location M,
		F.makestring_fmt
		   (F.Vbox0 0 1
		    [F.HOVbox0 1 0 1
		     ([mkfmt_term M', F.Break,
		       F.Space, F.String S.colon, F.Space,
		       mkfmt_term A', F.Break]
		      @ (if Equal.term_eq(A',A)
			    then [F.String (S.string "is inconsistent with other constraints")]
			    else [F.String (S.string "<>"), F.Space,
				  mkfmt_term A])),
		     F.Break,
		     F.String (S.string (func ()))]))

  fun fail_not_fun M M' A' func =
         raise TypeCheckFail
	       (Term.location M,
		F.makestring_fmt
		   (F.HOVbox0 1 0 1
		    [mkfmt_term M', F.Break,
		     F.String S.colon, F.Space,
		     mkfmt_term A', F.Break,
		     F.String (S.string "is not a function")]))

  fun unify_msg M M' con sc fc =
      let val con' = Unify.unify1 M M' con
	             handle C.Nonunifiable (reason) => 
			fc (fn () => C.makestring_unify_failure (reason))
       in sc con' end

  local val trt_tct =
     let fun trt (M as Bvar(cname)) uvars con sc2 = raise Sb.LooseBvar(M)
	   | trt (M as Const(se)) uvars con sc2 = sc2 (se_type se) M con
	   | trt (M as Type) uvars con sc2 = sc2 (Type) M con
	   | trt (M as Uvar(Varbind(_,A),_)) uvars con sc2 = sc2 A M con
	   | trt (M as Fvar(Varbind(_,A))) uvars con sc2 = sc2 A M con
	   | trt (M as Evar(Varbind(_,A),_,_,ref(SOME(M')))) uvars con sc2 =
		sc2 A M con
	   | trt (M as Evar(Varbind(_,A),_,_,ref(NONE))) uvars con sc2 =
		sc2 A M con
	   | trt (Appl(M1,M2)) uvars con sc2 =
		trt' M1 uvars con (fn A => fn M1' => fn con' =>
		    let fun dest_A (Pi((vbd as Varbind(_,B),A'),Maybe)) con'' =
			      ( tct M2 B uvars con'' (fn M2' => fn con''' =>
				      sc2 (Sb.apply_sb (Sb.term_sb vbd M2') A')
					  (Appl(M1',M2'))
					  con'''))
			   | dest_A (Pi((Varbind(_,B),A'),Vacuous)) con'' =
			      ( tct M2 B uvars con'' (fn M2' => fn con''' =>
				      sc2 A' (Appl(M1',M2')) con'''))
			   | dest_A A'' con'' =
			      let val B = Sb.new_evar Sb.generic_type uvars
				  val A' = if TypeDepend.unknown_may_depend
					   then make_pi(Varbind(anonymous,B),
  Appl(Sb.new_evar (Varbind (anonymous, make_arrow(B,Type))) uvars, Bvar(anonymous)))
					   else
  make_arrow(B, Sb.new_evar Sb.generic_type uvars)
			       in unify_msg A'' A' con''
				   (fn con''' => dest_A A' con''')
				   (fn func => fail_not_fun M1 M1' A func)
			      end
		     in dest_A (Reduce.head_norm A) con' end)
	   | trt (Abst((xofA as Varbind(x,A)),M')) uvars con sc2 =
		( tct A Type uvars con (fn A'' => fn con' =>
		  let val may_depend = TypeDepend.known_may_depend A''
		      val xofA' = Varbind(x,A'')
		      val a = Sb.new_uvar xofA'
		   in trt' (Sb.apply_sb (Sb.term_sb xofA a) M')
			  (if may_depend then (a::uvars) else uvars)
			  con'
			  (fn A' => fn M'' => fn con'' =>
			      sc2 (if may_depend
				      then make_pi(UUtils.abst_over_uvar_raise (a,x) A')
				      else make_arrow(A'',A'))
				  (Abst(UUtils.abst_over_uvar_raise (a,x) M''))
				  con'')
		  end ))
	   | trt (Pi((xofA as Varbind(x,A),B),Maybe)) uvars con sc2 =
		( tct A (Type) uvars con (fn A'' => fn con' =>
		  let val may_depend = TypeDepend.known_may_depend A''
		      val xofA'' = Varbind(x,A'')
		      val a = Sb.new_uvar xofA''
		   in tct (Sb.apply_sb (Sb.term_sb xofA a) B)
			  (Type)
			  (if may_depend then (a::uvars) else uvars)
			  con'
			  (fn B' => fn con'' =>
			      sc2 (Type)
				  (Pi(UUtils.abst_over_uvar_raise (a,x) B',Maybe))
				  con'')
		  end ))
	   | trt (Pi((Varbind(x,A),B),Vacuous)) uvars con sc2 =
		( tct A (Type) uvars con (fn A'' => fn con' =>
		     tct B (Type) uvars con'
			 (fn B' => fn con'' =>
			      sc2 (Type)
				  (Pi((Varbind(x,A''),B'),Vacuous))
				  con'')))
	   | trt (HasType(M,A)) uvars con sc2 =
		tct A Type uvars con (fn A' => fn con' =>
		  tct M A' uvars con' (fn M' => fn con'' => sc2 A' M' con''))
	   | trt (Wild) uvars con sc2 =
		let val A = Sb.new_evar Sb.generic_type uvars
		    val M = Sb.new_evar (Varbind(anonymous,A)) uvars
		 in sc2 A M con end
           | trt (Mark(lrpos,M)) uvars con sc2 =
	        trt M uvars con sc2
	 and trt' M uvars con sc2 =
	       trt M uvars con (fn A => fn M' => fn con' =>
		   ( tprint trace_type_recon (fn () =>
		      "|- " ^ mkstr_term M' ^ " : "
		      ^ mkstr_term A ^ "\n") ;
		     sc2 A M' con' ))
	 and tct M A uvars con sc1 =
		trt' M uvars con (fn A' => fn M' => fn con' =>
		  ( tprint trace_type_recon (fn () => 
		      "=?= " ^ mkstr_term A ^ "\n") ;
		    unify_msg A A' con' (fn con'' => sc1 M' con'')
		       (fn func => fail_mismatch M M' A' A func) ))
	 exception Success of term * term * C.constraint
	 fun trecon M =
	       ( ignore(trt' M nil C.empty_constraint (fn A' => fn M' => fn con => 
		    raise Success(M',A',con))) ;
		 raise TypeCheckFail(NONE,"Type checking failed unexpectedly.") )
	       handle Success M'A'con => M'A'con
	 and trecon_as M A =
	       ( ignore(tct M A nil C.empty_constraint (fn M' => fn con =>
		    raise Success(M',A,con))) ;
		 raise TypeCheckFail(NONE,"Type checking failed unexpectedly.") )
	       handle Success M'A'con => M'A'con
      in (trecon,trecon_as) end
  in fun trt M = let val (trecon,_) = trt_tct in trecon M end
     and tct M A = let val (_,trecon_as) = trt_tct in trecon_as M A end
  end

  fun maybe_warn con =
	 if (!warn_constraint)
	       andalso (not (C.is_empty_constraint con))
	 then wprint warn_constraint (fn () =>
	       "Warning: constraint remains after type reconstruction.\n"
	       ^ C.makestring_constraint con ^ "\n")
	 else ()

  fun type_recon M =
      let val (M',A',con) = trt M
	  val con' = Simplify.simplify_constraint1 con
	  val _ = maybe_warn con'
       in (M',A',con') end

  fun type_recon_as M A =
      let val (M',A',con) = tct M A
	  val con' = Simplify.simplify_constraint1 con
	  val _ = maybe_warn con'
       in (M',A',con') end

end  (* local ... *)
end  (* functor TypeRecon *)
