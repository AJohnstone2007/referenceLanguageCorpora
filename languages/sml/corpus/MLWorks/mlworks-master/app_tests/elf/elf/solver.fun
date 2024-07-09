(*
 *
 * $Log: solver.fun,v $
 * Revision 1.2  1998/06/03 12:24:44  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* Copyright (c) 1991 by Carnegie Mellon University *)
(* Author: Frank Pfenning <fp@cs.cmu.edu>           *)
(* Modified: Spiro Michaylov <spiro@cs.cmu.edu>     *)

(* The solver for Elf *)
(* Needs lots of work *)

functor Solver
   (structure Basic    : BASIC
    structure Term     : TERM
    structure Skeleton : SKELETON sharing Skeleton.Term = Term
    structure Sb       : SB       sharing Sb.Term = Term
    structure Sign     : SIGN     sharing Sign.Term = Term
    structure Constraints : CONSTRAINTS  sharing Constraints.Term = Term
    structure Reduce   : REDUCE   sharing Reduce.Term = Term
    structure Trail    : TRAIL    sharing Trail.Term = Term
    structure Unify    : UNIFY    sharing Unify.Term = Term
			          sharing Unify.Constraints = Constraints
    structure UnifySkeleton : UNIFY_SKELETON
       sharing UnifySkeleton.Term = Term
       sharing UnifySkeleton.Skeleton = Skeleton
       sharing UnifySkeleton.Constraints = Constraints
    structure IPrint   : PRINT    sharing IPrint.Term = Term
    structure Print    : PRINT    sharing Print.Term = Term
    structure Specials : SPECIALS sharing Specials.Term = Term
    structure Progtab  : PROGTAB   sharing Progtab.Term = Term
	                           sharing Progtab.Skeleton = Skeleton
    val enable_stats   : bool
    structure SolverStats  : SOLVER_STATS)
   : SOLVER =
struct

structure Term = Term
structure Sign = Sign
structure Progtab = Progtab
structure Constraints = Constraints

local open Term
in

structure Switch =
struct
  exception UnknownSwitch = Basic.UnknownSwitch

  (* Control *)
  fun control s = raise UnknownSwitch("Solver.control",s)

  (* Warning *)
  fun warn s = raise UnknownSwitch("Solver.warn",s)

  (* Tracing *)

  val trace_type = ref false
  val trace_assume = ref false
  val trace_clause = ref false
  val trace_resolve = ref false
  val trace_goal = ref false
  val trace_open = ref false
  val trace_debug = ref false

  fun trace "type" = trace_type
    | trace "assume" = trace_assume
    | trace "clause" = trace_clause
    | trace "resolve" = trace_resolve
    | trace "goal" = trace_goal
    | trace "open" = trace_open
    | trace "debug" = trace_debug
    | trace s = raise UnknownSwitch("Solver.trace",s)

  fun tprint traceref func = if (!traceref) then print(func():string) else ()

end  (* structure Switch *)

open Switch

fun trace (level) =
      ( trace_type    := (level > 3) ;
        trace_assume  := (level > 0) ;
	trace_clause  := (level > 1) ;
	trace_resolve := (level > 0) ;
	trace_goal    := (level > 0) ;
	trace_open    := (level > 2) ;
	trace_debug   := (level > 4) )

fun untrace () = trace (0)

structure SS = SolverStats
fun inc_skipped_by_indexing dynamic =
    if dynamic 
    then (SS.dynamic_skipped_by_indexing := 
                !SS.dynamic_skipped_by_indexing + 1)
    else (SS.skipped_by_indexing := !SS.skipped_by_indexing + 1)
fun inc_attempted_resolutions dynamic =
    if dynamic 
    then (SS.dynamic_attempted_resolutions := 
                !SS.dynamic_attempted_resolutions + 1)
    else (SS.attempted_resolutions := !SS.attempted_resolutions + 1)
fun inc_successful_resolutions dynamic =
    if dynamic 
    then (SS.dynamic_successful_resolutions := 
                !SS.dynamic_successful_resolutions + 1)
    else (SS.successful_resolutions := !SS.successful_resolutions + 1)

val makestring_head = IPrint.makestring_term

(* first arg must be head-normal! *)
fun solve M build_proof con sc =
let

fun get_arg (Appl(_,A)) = A
  | get_arg A = raise Print.subtype("get_arg",A,"is not of the right form")

fun get_arg1 (Appl(Appl(_,A),_)) = A
  | get_arg1 A = raise Print.subtype("get_arg1",A,"is not of the right form")

fun get_arg2 (Appl(Appl(_,_),B)) = B
  | get_arg2 A = raise Print.subtype("get_arg2",A,"is not of the right form")

fun dest_abst (Abst yofA_B) = yofA_B
  | dest_abst A = raise Print.subtype("dest_abst",A,"is not of the right form")

fun rsolve (e as Evar(Varbind(x,A),_,_,ref(NONE))) prog uvars con build_proof sc =
       rsolve_type e A prog uvars con build_proof sc       
  | rsolve (Uvar _) prog uvars con build_proof sc = sc con
  | rsolve (Const _) prog uvars con build_proof sc = sc con
  | rsolve (Appl(M,N)) prog uvars con build_proof sc = 
       rsolve (Reduce.head_norm N) prog uvars con build_proof (fn con' =>
          rsolve M prog uvars con' build_proof sc)
  | rsolve (Abst(xofA as Varbind(x,A),N)) prog uvars con build_proof sc =
       (* check A for unsolved Evar's? *)
       let val a = Sb.new_uvar xofA
        in 
	   rsolve (Sb.apply_sb (Sb.term_sb xofA a) N) prog (a::uvars) con build_proof sc
       end
  | rsolve (Evar(_,_,_,ref(SOME(M)))) prog uvars con build_proof sc =
       rsolve M prog uvars con build_proof sc
  (* Next two cases can arise only with polymorphism? *)
  | rsolve (M as Type) prog uvars con build_proof sc = sc con
  | rsolve (Pi((xofA as Varbind(x,A),B),occurs)) prog uvars con build_proof sc =
       rsolve (Reduce.head_norm A) prog uvars con build_proof (fn con' =>
          if occurs = Maybe
	  then let val a = Sb.new_uvar xofA
	        in
		  rsolve (Sb.apply_sb (Sb.term_sb xofA a) B) prog (a::uvars) con build_proof sc
	       end
	  else rsolve (Reduce.head_norm B) prog uvars con build_proof sc)

  | rsolve M _ _ _ _ _ = raise Print.subtype("rsolve",M,"is an unexpected argument")

and rsolve' M nil prog uvars con build_proof sc = sc con
  | rsolve' (Appl(M1,M2)) (Progtab.Static::mobl) prog uvars con build_proof sc =
       rsolve' M1 mobl prog uvars con build_proof sc
  | rsolve' (Appl(M1,M2)) (Progtab.Dynamic(occurs)::mobl) prog uvars con build_proof sc =
       rsolve (Reduce.head_norm M2) prog uvars con (build_proof orelse occurs)
          (fn con' => rsolve' M1 mobl prog uvars con' build_proof sc)
  | rsolve' (Appl(M1,M2)) (Progtab.Unknown(occurs)::mobl) prog uvars con build_proof sc =
       rsolve (Reduce.head_norm M2) prog uvars con (build_proof orelse occurs)
          (fn con' => rsolve' M1 mobl prog uvars con' build_proof sc)
  | rsolve' M subgoals prog uvars con build_proof sc =
       raise Print.subtype("rsolve'",M,"does not match subgoal list.")

and rsolve_type M A prog uvars con build_proof sc =
       let val A' = Reduce.head_norm A
	   val _ = tprint trace_type (fn () =>
		    "Looking at " ^ Print.makestring_term A' ^ "\n")
        in case A'
	     of Pi((yofB as Varbind(y,B),C),occ) =>
	           let val _ = tprint trace_goal (fn () =>
			     "Solving goal " ^ Print.makestring_term A' ^ "\n")
		       val b = Sb.new_uvar yofB
		       val C' = if (occ = Maybe)
				   then (Sb.apply_sb (Sb.term_sb yofB b) C)
				   else C
		    in rsolve_pi (Appl(M,b)) C' b prog uvars con build_proof sc end
	      | _ => resolve M A' prog uvars con build_proof sc
       end

and rsolve_pi M C' (a as Uvar(Varbind(_,A),_)) prog uvars con build_proof sc =
    let fun add_dynamic pe prog =
		let val (Progtab.Progentry({Faml=ent,...})) = pe
		    fun ad pe nil = (ent,(pe::nil))::nil
		      | ad pe ((e,l)::t) = 
				(if Reduce.eq_head(e,ent)
				    then ((e,(pe::l))::t)
				    else ((e,l)::(ad pe t)) )
		 in ad pe prog end
	fun assume (NONE) =
	      ( tprint trace_assume (fn () =>
                 "Introducing new parameter " ^ Print.makestring_term a
		 ^ "\n") ;
	        tprint trace_open (fn () =>
	         "Not assuming open " ^ Print.makestring_term a ^ " : "
		 ^ Print.makestring_term A ^ ".\n") ;
		rsolve_type M C' prog (a::uvars) con build_proof sc )
	  | assume (SOME(progentry)) =
	      ( tprint trace_assume (fn () =>
	         "Assuming " ^ Print.makestring_term a ^ " : "
		 ^ Print.makestring_term A ^ ".\n") ;
                if enable_stats
                   then ( SolverStats.assumption_count :=
                               !SolverStats.assumption_count + 1 )
                   else () ;
	        rsolve_type M C' (add_dynamic progentry prog) 
				 (a::uvars) con build_proof sc )
     in assume (Progtab.make_progentry true (a,A)) end
  | rsolve_pi _ _ N _ _ _ _ _ =
       raise Print.subtype("rsolve_pi",M,"is not a Uvar.")

and resolve gevar A prog uvars con build_proof sc =
    (* A atomic and head-normal *)
    let val (A_head,A_args) = Reduce.head_args A
	fun match_sign (index) nil dynamic = ()
	  | match_sign (index)
	      (Progtab.Progentry {Faml = se_head,
				  Name = c,
				  Vars = vars,
				  Head = target,
				  Subg = subgoals,
				  Indx = rule_index,
				  Skln = skeleton}
	       :: sign') dynamic =
             if (Progtab.indexes_match index rule_index) then
        	     let val _ = tprint trace_clause (fn () =>
			       "Trying clause " ^ makestring_head(c)
			       ^ "\n")
			 val _ = if enable_stats
				    then (inc_attempted_resolutions dynamic)
				    else ()
        	         val nesb = Sb.new_evar_sb (rev vars) uvars (* slow !!*)
        	      in ( Trail.trail (fn () =>
			  UnifySkeleton.unify skeleton
			     (Sb.apply_sb nesb target) A con (fn con' =>
			     let val soln = Sb.app_to_evars c nesb
				 val _ = tprint trace_resolve (fn () =>
				          "Resolved with clause "
					  ^ makestring_head(c) ^ "\n")
				 val _ = tprint trace_debug (fn () =>
				          "Subgoal "
					  ^ Print.makestring_term soln ^ "\n")
				 val _ = if enable_stats
				            then inc_successful_resolutions dynamic
					    else ()
			      in rsolve' soln subgoals prog uvars con' build_proof
				  (if (not build_proof)
				      then sc
				      else (fn con'' => Unify.unify gevar soln con'' sc))
			     end)) ;
			  match_sign index sign' dynamic)
        	     end
             else ( if enable_stats 
                       then (inc_skipped_by_indexing dynamic) 
                       else ();
		    match_sign index sign' dynamic)
	fun dynamic_rules faml nil = nil
	  | dynamic_rules faml ((e,l)::t) = 
	       (if Reduce.eq_head(e,faml)
		   then l
		   else dynamic_rules faml t)
        fun match_signs index sign =
	        (let val sign1 = (dynamic_rules A_head sign)
		     val _ = (case sign1 
			        of nil => ()
				 | _ => Trail.trail 
					 (fn () => match_sign index sign1 true))
                     val sign2 = Progtab.get_rules A_head 
                  in Trail.trail (fn () => match_sign index sign2 false) end)
     in 
        if Reduce.eq_head(A_head,Specials.backquote)
        then let val _ = print(Print.makestring_term(A) ^ "\n")
	         val A1 = get_arg A
		 val gevar1 = Sb.new_evar (Varbind(anonymous,A1)) uvars
	      in rsolve_type gevar1 A1 prog uvars con build_proof
		  (fn con' => Unify.unify gevar (Appl (Appl(Specials.bq, A1), gevar1))
		                 con' sc)
	     end
	else if Reduce.eq_head(A_head,Specials.sigma)
	then let val A1 = get_arg1 A
		 val gevar1 = Sb.new_evar (Varbind(anonymous,A1)) uvars
                 val A2 = get_arg2 A
                 val (yofA1,A2') = dest_abst A2
	      in rsolve_type gevar1 A1 prog uvars con (build_proof orelse (Sb.free_in yofA1 A2')) (fn con' =>
	            let val A2A1 = Appl(A2, gevar1)
		        val gevar2 = Sb.new_evar (Varbind(anonymous,A2A1)) uvars
		     in rsolve_type gevar2 A2A1 prog uvars con' build_proof (fn con'' =>
		           Unify.unify gevar
		           (Appl(Appl(Appl(Appl(Specials.pr, A1), A2), gevar1),
				 gevar2))
		           con'' sc)
		    end)
	     end
        else
        if (Progtab.is_dynamic A_head)
	     then if (!trace_goal)
		  then ( tprint trace_goal (fn () =>
		           "[Solving goal " ^ Print.makestring_term A ^ "\n") ;
			 match_signs (Progtab.get_index A_head A_args) prog ;
		         tprint trace_goal (fn () => "]") )
		  else match_signs (Progtab.get_index A_head A_args) prog
	     else ( tprint trace_open (fn () =>
		     "Bypassing open type " ^ makestring_head A_head ^ "\n") ;
		    sc con )
    end

 in

     rsolve M nil nil con build_proof sc

end  (* let fun rsolve ... *)

end  (* local ... *)
end  (* functor Solver *)
