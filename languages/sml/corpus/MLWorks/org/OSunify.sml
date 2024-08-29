(*
 *
 * $Log: OSunify.sml,v $
 * Revision 1.2  1998/06/08 17:49:43  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(*

OSunify.sml

This module does syntactic unification in a pretty conventional fashion
while all along interleaving the unification process with the sort resolution
to form order-sorted unifications

MERILL  -  Equational Reasoning System in Standard ML.
Brian Matthews                               20/05/91
Glasgow University and Rutherford Appleton Laboratory.


*)

functor OSUnifyFUN (structure T:TERM
		    structure S:SUBSTITUTION
 		    sharing type S.Term = T.Term
		    and     type T.OpId = T.Sig.O.OpId
		    and     type S.Variable = T.Sig.V.Variable = T.Variable
		    and     type T.Sort = T.Sig.S.Sort = 
		    		 T.Sig.V.Sort = T.Sig.O.Sort
		    and     type S.Signature = T.Sig.Signature
		   ) : UNIFY =
struct

type Signature = T.Sig.Signature
type Term = T.Term
type Substitution = S.Substitution

type OpId = T.Sig.O.OpId
val OpIdEq = T.Sig.O.OpIdeq
val VarEq = T.Sig.V.VarEq

open S T


(* 

An implementation of the naive, non-deterministic algorithm of Martelli and Montenari.
with a modification to make it handle Commutative and AC operators.

It is made deterministic by considering the first element which has not yet been converted 
into a (variable,term) pair.

It uses ../experiment/{term.ml,substitution.ml}

bmm  16 - 01 - 90
*)

fun Decomposition t1 t2 = zip (subterms t1,subterms t2) 

(* 
variable_elimination : Variable * Term -> (Term * Term) list -> (Term * Term) list

removes all occurences of a variable from the terms on both sides of the pairs in the
following list, by replacing with the term.
*)

fun var_elim (v,t) = map (apply_both (applysubtoterm (addsub EMPTY (v,t))))

(* 
var_elim_right : Variable * Term -> Variable * Term list -> Variable * Term list

This is already away from the pure naive algorithm.  It stems from the observation that when
carrying out variable-elimination on a list of (variable,term) pairs, we do not need to do
variable-elimination on the left hand side as there will be no match.
*)

fun var_elim_right (v,t) = map (apply_snd (applysubtoterm (addsub EMPTY (v,t))))

(* some extra auxiliary functions to deal with the resolution of the sort ordering. *)

fun max_common_subsorts Sigma s1 s2 = 
    let val so = Sig.get_sort_ordering Sigma 
    in Sig.S.maximal_sorts so 
            (intersection Sig.S.SortEq
                          (s1::Sig.S.subsorts so s1)
                          (s2::Sig.S.subsorts so s2)
            )
    end

(* strict sort-ordering lifted to sequences *)

fun strict_sol so sl sl' = (not (forall_pairs Sig.S.SortEq sl sl') 
                            handle Zip => false)
			   andalso 
			   Sig.S.sort_ordered_list so sl sl' 

(*
maximal_sort_lists : Sort_Order -> OpSig list -> Sort -> Sort list list

finds all the OpSigs, s1,...,sn -> s' such that s' < s and, and returns those
s1,...,sn which are maximal.

*)
(*
fun maximal_sort_lists so opsiglist s =
    let fun less_sorts [] = []
          | less_sorts (opsig::rops) = 
            if Sig.S.sort_ordered_reflexive so (Sig.O.get_result_sort opsig,s) 
            then Sig.O.get_arg_sorts opsig :: less_sorts rops
            else less_sorts rops
        fun max_lists all  = filter (not o C exists all o strict_sol so) 
        val lessigs = less_sorts opsiglist
    in max_lists lessigs lessigs 
    end ;
*)
fun maximal_sort_lists so opsiglist s =
    let val test = (C (curry (Sig.S.sort_ordered_reflexive so)) s) o Sig.O.get_result_sort
        fun max_lists all  = filter (not o C exists all o strict_sol so) 
        val lessigs = mapfilter test Sig.O.get_arg_sorts opsiglist
    in max_lists lessigs lessigs 
    end ;

fun get_opsigs Sigma = Sig.O.get_OpSigs o Sig.O.operator_sig (Sig.get_operators Sigma) o root_operator ;

 
(*

Rules to apply - This is a mixture of rules from Kirchners papers. I must check them!

(1) Decomposition.  

f(t1,...,tn) == f(t1',...,tn')   
------------------------------     if f \in Fd
{t1 == t1' & ... & tn == tn'}  

(2) Conflict. 

f(t1,...,tn) == g(t1',...,tn')   
------------------------------     if f,g \in Fd
             F

(3) Trivial Equation. 

t == t  &  U   
-------------
      U      

(4) Occurs. 

x == t[x]|p  &  U   
-------------	   if x \in Vars and p =\= []
      F      

(5)  Mutation. 

    t1 == t2 & U
---------------------	if t1, t2 \in E (in some sense )
  MUT(E)(t1 == t2 & U)

(6)  Coalesce.

 x:s == y:s' & U
------------------	if x,y \in Var(U) and s' <= s
 x == y &  U{x -> y} 

(7)  Intersect.

		x:s == y:s' & U
--------------------------------------------------	if x,y \in Var(U) and s' |><| s
 \/(s'' \(in s & s')(x == z:s'' & y == z:s'' &  U)

(8)  Remove.

 x:s == y:s' & U
-----------------	if x,y \in Var(U) and s' |><| s and s & s = {}
	F

(9)  Abstract.

 x:s == f(t1,...,tn):s' & U	if Least_Sort(f(t1,...,tn)) </= s and 
----------------------------	SIG(f,s) = {s1,...,sn -> s'| f:s1,...,sn -> s' \in \SIGMA and s'<= s and s1,...,sn maximal }
\/ (s1,...,sn -> s' \in SIG(f,s)) (z1:s1 == t1 & ... & zn:sn == tn & x == f(z1,...,zn))	


(10)  Merge - there is a merge operation - which I have yet to properly formulate

*)

fun OSunify Sigma t1 t2 = 
let
val V = union VarEq (vars_of_term t1) (vars_of_term t2) 
val newvar = non (element VarEq V)
val LS = least_sort Sigma 
val so = Sig.get_sort_ordering Sigma
val ops = Sig.get_operators Sigma
val <<=  = Sig.S.sort_ordered_reflexive so
infix <<= 
val newVarTerm = mk_VarTerm o Sig.V.generate_variable

fun unifylist ((s,t)::re) S = 
    if TermEq s t 
    then unifylist re S				(* Rule (3) *)
    else (case (compound s,compound t) of
	   (true,true)   => if same_root s t
	   		    then unifylist (Decomposition s t @ re) S	(* Rule (1) *)
	  		    else []						(* Rule (2) *)
	 | (true,false)  => let val ss = LS s
	 		        val st = LS t
	 		    in if ss <<= st 
	 		       then (* ss <= st *)	(* Good substitution - (10) Merge *)
	 		    	    let val v = get_Variable t
	 		            in if occurs v s 	
	 		               then []		(* Rule (4) *)
	 		               else unifylist 
	 		                      (var_elim (v,s) re) 
	 		      		      (if newvar v then var_elim_right (v,s) S
	 		                       else (v,s)::(var_elim_right (v,s) S))
	 		    	    end 
	 		        else  	(* Rules (9) *)
	 		             let val SIGS = maximal_sort_lists so (get_opsigs Sigma s) st
	 		             in if null SIGS 
	 		                then [] 
	 		                else let val v = get_Variable t
	 		                         val st = subterms s
	 		                         val f = root_operator s
	 		                         fun merge sl = 
	 		                             let val nvars = map newVarTerm sl 
	 		                                 val newterm = mk_OpTerm f nvars
	 		                                 val newpairs = zip (nvars,st)
	 		                             in unifylist 
	 		                                 (newpairs@(var_elim (v,newterm) re))
	 		                                 (if newvar v then var_elim_right (v,s) S
	 		                                  else (v,newterm)::(var_elim_right (v,newterm) S))
	 		                             end
	 		                      in mapapp merge SIGS
	 		                      end 
	 		            end 
	 		    end 
	 | (false,true)  => unifylist ((t,s)::re) S   (* doing this this way will save a lot of problems *) 
	 | (false,false) => (* The case of both being variables *)
	 		    let val ss = LS s
	 		        val st = LS t
	 		    in if ss <<= st
	 		       then (* ss <= st *)	(* Rule (6) *)
	 		    	    let val v = get_Variable t 
	 		    	    in unifylist 
	 		      		 (var_elim (v,s) re) 
	 		      		 (if newvar v then var_elim_right (v,s) S
	 		                  else (v,s)::(var_elim_right (v,s) S))
	 		            end
	 		       else if st <<= ss
	 		            then (* st <= ss *)		(* Rule (6) *)
	 		    	         let val v = get_Variable s 
	 		    	         in unifylist 
	 		      		         (var_elim (v,t) re) 
	 		      		         (if newvar v then var_elim_right (v,t) S
	 		                          else (v,t)::(var_elim_right (v,t) S))
	 		                 end
	 		            else (* incomparable sorts ss |><| st *)
	 		                 let val sbsrts = max_common_subsorts Sigma ss st
	 		                 in if null sbsrts
	 		                    then []  	(* Rule (8) *)
	 		                    else 	(* Rule (7) *)
	 		                         let val newvars = map newVarTerm sbsrts
	 		                             val v = get_Variable s 
	 		    	         	     val u = get_Variable t 
	 		                             fun merge z = unifylist 
	 		                             	(var_elim (v,z) (var_elim (u,z) re)) 
	 		        		        ((u,z)::(v,z)::(var_elim_right (v,z) 
	 		        		                        (var_elim_right (u,z) S)))
	 		                 
	 		                         in mapapp merge newvars
	 		                         end
	 		                end
	 		    end
       )
  | unifylist [] S = [foldl addsub EMPTY S]  ;
in
unifylist [(t1,t2)] [] 
end (* of let for function OSunify *)
	
val unify  = OSunify 

end (* of functor OSUnifyFUN *)
;
