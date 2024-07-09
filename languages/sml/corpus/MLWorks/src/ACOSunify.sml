(*
 *
 * $Log: ACOSunify.sml,v $
 * Revision 1.2  1998/06/08 17:49:15  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(*

ACunify.sml

This module does all the (not so) clever partitioning and generation of 
solutions from a set of solutions to a diophantine equation system for 
Associative/Commutative Unification.

And then in addition does the stuff with the sort resolution.

MERILL  -  Equational Reasoning System in Standard ML.
Brian Matthews                               20/05/91
Glasgow University and Rutherford Appleton Laboratory.


depends on:

(will) depends on:
        library.sml
        commonio.sml
        dio.sml
        term.sml
        variable.sml
        opsymb.sml
        substitution.sml

*)

functor ACUnifyFUN (structure Dio:DIO
		    structure T:TERM
		    structure S:SUBSTITUTION
		    structure A:AC_TOOLS
 		    sharing type S.Term = T.Term = A.Term
		    and     type T.OpId = T.Sig.O.OpId = A.OpId
		    and     type S.Variable = T.Sig.V.Variable = T.Variable = A.Variable
		    and     type T.Sort = T.Sig.S.Sort = 
		    		 T.Sig.V.Sort = T.Sig.O.Sort
		    and     type S.Signature = T.Sig.Signature = A.Signature
		   ) : UNIFY =
struct

type Signature = T.Sig.Signature
type Term = T.Term
type Substitution = S.Substitution

type OpId = T.Sig.O.OpId
val OpIdEq = T.Sig.O.OpIdeq
val VarEq = T.Sig.V.VarEq

open S T A


(*
generate_valid_subsets : (int list * int list) list -> (int list * int list ) list list 

Generates all the valid subsets of the solution sets to a linear diophantine 
equation system.  The criterion is that given a subset of the basis of solutions:

{
(s11, ... , s1m) (s1(m+1), ... , s1(m+n))
       .		    .
       .		    .
       .		    .
(sr1, ... , srm) (sr(m+1), ... , sr(m+n))
}

Then the sum s1i + s2i + ... + sri > 0 for all i
*)

datatype Constraint = None | Con | Sym of OpId ;

fun unconstrained None = true
  | unconstrained Con = false
  | unconstrained (Sym _) = false
  ;

local 

fun filter_left n = Library.filter (curry (op >=) 1 o C (curry nth) n o fst) 
fun filter_right n = Library.filter (curry (op >=) 1 o C (curry nth) n o snd) 

(*
This function goes through the diophantine equation solution base set and
removes 

a). all those solutions which have an entry > 1 in a **constrained**
    position.  Such solutions can never be used to construct meaningful solutions
    and may as well be removed at this stage.
*)

fun remove_cons_dio_sols (a::acons,bcons) n sols = 
    if unconstrained a 
    then remove_cons_dio_sols (acons,bcons) 
                         (if null acons then 0 else n+1) sols 
    else remove_cons_dio_sols (acons,bcons) 
         (if null acons then 0 else n+1) (filter_left n sols) 
  | remove_cons_dio_sols ([],b::bcons) n sols = 
    if unconstrained b
    then remove_cons_dio_sols ([],bcons) (n+1) sols
    else remove_cons_dio_sols ([],bcons) (n+1) 
                              (filter_right n sols)
  | remove_cons_dio_sols (_,[]) _ sols = sols

(*
This function goes through the diophantine equation solution base set and
removes 

b). all those solutions which have an entry >= 1 in two **constrained**
    position, which are either both constant or else of differing root symbol.  
    Such solutions can never be used to construct meaningful solutions
    and may as well be removed at this stage.
*)

local

(* Function to check for a clashing solution.

   These functions return true if there is **no clash**, 
   and false if there is one.
   This is because we want to use the standard filter function
   which removes those which are false to remove clahinf solutions
*)

fun find_clash con (a::acons, bcons) (a1::asols, bsols) = 
    if unconstrained a orelse a1 = 0 
    then find_clash con (acons, bcons) (asols, bsols) 
    else (case (con,a) of
          (Sym f, Sym g) => if OpIdEq f g 
                            then true 
                            (* we are unwilling to say definitely no - they could unify *)
                            else false
          |  ( _ , _ )   => false 
         )
  | find_clash con ([], b::bcons) ([], b1::bsols) = 
    if unconstrained b orelse b1 = 0 
    then find_clash con ([], bcons) ([], bsols) 
    else (case (con,b) of
          (Sym f, Sym g) => if OpIdEq f g 
                            then true 
                            (* we are unwilling to say definitely no - they could unify *)
                            else false
          |  ( _ , _ )   => false 
         )
  | find_clash con ([], []) ([], []) = true
  | find_clash con     _       _     = raise Zip        

fun clash_dio_sol (a::acons, bcons) (a1::asols, bsols) = 
    if unconstrained a orelse a1 = 0 
    then clash_dio_sol (acons, bcons) (asols, bsols) 
    else find_clash a (acons,bcons) (asols, bsols)
         andalso  		(* note the strange logic !! *)
         clash_dio_sol (acons, bcons) (asols, bsols) 
  | clash_dio_sol ([], b::bcons) ([], b1::bsols) = 
    if unconstrained b orelse b1 = 0 
    then clash_dio_sol ([], bcons) ([], bsols) 
    else find_clash b ([],bcons) ([], bsols)
         andalso  		(* note the strange logic !! *)
         clash_dio_sol ([], bcons) ([], bsols) 
  | clash_dio_sol ([], []) ([], []) = true
  | clash_dio_sol     _       _     = raise Zip        

in
fun remove_clashing_sols cons = filter (clash_dio_sol cons)
end (* of local *) ;

fun add_fst_hds ((a::_,_)::r) 0 = add_fst_hds r a
  | add_fst_hds ((0::_,_)::r) 1 = add_fst_hds r 1
  | add_fst_hds ((a::_,_)::r) 1 = 2
  | add_fst_hds [] s = s
  | add_fst_hds _ s = failwith "Fst_Hds"
 
and add_snd_hds ((_,a::_)::r) 0 = add_snd_hds r a
  | add_snd_hds ((_,0::_)::r) 1 = add_snd_hds r 1
  | add_snd_hds ((_,a::_)::r) 1 = 2
  | add_snd_hds [] s = s 
  | add_snd_hds _ s = failwith "Snd_Hds";

fun exist_fst_hd ((a::_,_)::r) = a <> 0 orelse exist_fst_hd r 
  | exist_fst_hd [] = false
  | exist_fst_hd _  = failwith "Fst_Hds"
and exist_snd_hd ((_,a::_)::r) = a <> 0 orelse exist_snd_hd r 
  | exist_snd_hd [] = false 
  | exist_snd_hd _  = failwith "Snd_Hds";


(*
This function goes through all the subsets of the base solutions
to the diophantine equation, and filters out all those subsets which
have a) a zero sum total for some entry - this means no value for a variable
which cannot be.  b) a sum total =/= 1 for some constrained variable - this would
mean a clash of symbols, and can be excluded here.
*)

fun check_cons (ca::racs,bcs) sols = 
    if unconstrained ca		(* not constrained *)
    then exist_fst_hd sols
         andalso
         check_cons (racs,bcs) (map (Library.apply_fst tl) sols)
    else 		(* constrained *)
         add_fst_hds sols 0 = 1
         andalso
         check_cons (racs,bcs) (map (Library.apply_fst tl) sols)
  | check_cons ([],ba::rbcs) sols = 
    if unconstrained ba 	(* not constrained *)
    then exist_snd_hd sols
         andalso
         check_cons ([],rbcs) (map (Library.apply_snd tl) sols)
    else 		(* constrained *)
         add_snd_hds sols 0 = 1
         andalso
         check_cons ([],rbcs) (map (Library.apply_snd tl) sols)
   | check_cons ([],[]) sols = true
   
in

(*
What I want to do is unfold out :

filter p o powerset set

		fun powerset (a::l) = 
		  	let val p = powerset l
		   	in (map (cons a) p) @ p
		   	end 
		  | powerset [] = [[]]

(* this first attempt does no better - it does the same work in a different order.
What should be done, is that a constrained subset should not be allowed to generate
further subsets.  Buts thats trickier!  
*)

fun generate_valid_subsets (acons,bcons) = 
let
fun con_sets (a::l) = 
    let val (p,gs) = con_sets l
        val nps = (map (cons a) p)
    in (nps@p , filter (check_cons (acons,bcons)) nps @ gs)
    end 
  | con_sets [] = ([[]],[])
in
snd o con_sets o
    remove_clashing_sols (acons,bcons) o
    remove_cons_dio_sols (acons,bcons) 0
end 
*)

fun generate_valid_subsets (acons,bcons) = 
    Library.filter (check_cons (acons,bcons)) o 
    Library.powerset o 
    remove_clashing_sols (acons,bcons) o
    remove_cons_dio_sols (acons,bcons) 0
end 

fun count_and_remove eq a (b::l) = 
    let val (nas,l') = count_and_remove eq a l
    in if eq a b
       then (nas+1, l')
       else (nas, b :: l')
    end 
  | count_and_remove eq a [] = (0,[]) 

fun occurence_lists eq (a::l) = 
    let val (nas, l') = count_and_remove eq a l
        val (ais,nais) = occurence_lists eq l'
    in  (a::ais,1+nas::nais) 
    end 
  | occurence_lists eq [] = ([],[])

fun assign_var (a::l) v = (copy a v) :: assign_var l v 
  | assign_var [] v = [] 

(* the sort of this is a hack - we don't want it to be Sort.Top - this has
consequences for the semantics - ultimately we don't want - can we do better?
The trouble is that generate_variable involves a reference - and so if we leave
it unresolved (by passing a function) we will not get the right sharing.
*)

fun resolve_subset [(s1,s2)] = 
    let val newvar = mk_VarTerm (Sig.V.generate_variable Sig.S.Top) (* this is a hack !!! *)
    in (assign_var s1 newvar,assign_var s2 newvar)
    end
  | resolve_subset ((s1,s2)::rss) = 
    let val newvar = mk_VarTerm (Sig.V.generate_variable Sig.S.Top) (* this is a hack !!! *)
        val (sv1,sv2) = (assign_var s1 newvar,assign_var s2 newvar)
        val (rsv1,rsv2) = resolve_subset rss 
    in (map2 (op @) sv1 rsv1,map2 (op @) sv2 rsv2)
    end 
  | resolve_subset [] = ([],[])

fun assign_new_terms ac_op (ais,bis) (asol,bsol) = 
    let  fun pairs (x::xs,s::ss) = (x,AC_unflatten ac_op s)::pairs (xs,ss)
           | pairs ([],[]) = []
           | pairs    _    = raise Zip
    in pairs (ais,asol) @ pairs (bis,bsol)
    end

(* 
generalise : Signature -> Term list -> ((Term * Term) list * (Term list * int list))

generalises AC terms by replacing the subterms with new variables and 
recording the constraint if it is constrained by being a compound term.
*)

fun constraints Ts = map (fn T1 => 
    if compound T1 
    then if constant T1 then Con else Sym (root_operator T1)
    else None (* its a variable *)
    ) Ts

(* 
AC_Unify_Subterms : Signature -> Term list -> Term list 
		       -> ((Term * Term) list * (Term * Term list) list list)

This function is the main control function for doing the nitty-gritty of the 
AC-unification process.  Gives all the possible unifications of the two terms
lists assuming that they are the AC-subterms of some AC-operator.

*)

fun AC_Unify_Subterms ac_op Term_List_1 Term_List_2 = 
    let
        (* the first thing to do to is to remove all common occurences *)

        val Distinct_Terms_1 = bag_difference TermEq Term_List_1 Term_List_2
        val Distinct_Terms_2 = bag_difference TermEq Term_List_2 Term_List_1
        
        
        (* then to count occurences of the subterms in the lists *)
        
        val (subts_1, ais) = occurence_lists TermEq Distinct_Terms_1
        val (subts_2, bis) = occurence_lists TermEq Distinct_Terms_2
        
        (* terms still have compound subterms - generalise and find the constraints *)
        
        val constraints1 = constraints subts_1
        val constraints2 = constraints subts_2

        (* then to solve the diophantine equation *)
        
        val Basis = Dio.solve_dio_equation ais bis 0
        
        (* then to generate all the relevant subsets of the basis *)
        
        val subsets = generate_valid_subsets (constraints1,constraints2) Basis
     
        (* then resolve each subset by generating 
           new variables and assigning appropriately. *)
        
   in  map (assign_new_terms ac_op (subts_1,subts_2) o resolve_subset) subsets
   end 

(*  
ACmutate : Term -> Term -> (Term * Term) list list

The AC-mutation algorithm.  This first flattens and generalises the two terms,
collecting the positions of compound terms, and then resolves the flattened AC terms
(represented as lists of variable terms) using the Pure-AC-unification algorithm
with the compound term positions as a constraint. 
*)

fun ACmutate T1 T2 = AC_Unify_Subterms (root_operator T1) (AC_subterms T1) (AC_subterms T2)

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

fun ACOSunify Sigma t1 t2 = 
let
val V = union VarEq (vars_of_term t1) (vars_of_term t2) 
val newvar = non (element VarEq V)
val LS = least_sort Sigma 
val so = Sig.get_sort_ordering Sigma
val ops = Sig.get_operators Sigma
val is_C = Sig.O.C_Operator ops o root_operator
val is_AC = Sig.O.AC_Operator ops o root_operator
val <<=  = Sig.S.sort_ordered_reflexive so
infix <<= 
val newVarTerm = mk_VarTerm o Sig.V.generate_variable
fun elim_right (v,s) S = if newvar v then var_elim_right (v,s) S
	 		 else (v,s)::(var_elim_right (v,s) S)

fun unifylist ((s,t)::re) S = 
    if AC_equivalent Sigma s t 
    then unifylist re S				(* Rule (3) *)
    else (case (compound s,compound t) of
	   (true,true)   => if same_root s t
	   		    then if is_AC s
                                 then mapapp (C unifylist S o (C append re)) 
                                 	     (ACmutate s t)
                                 else if is_C s
                                      then mapapp (C unifylist S o (C append re)) 
                                      		  (Cmutate Sigma s t)   	(* Rule (5) *)
                                      else unifylist (Decomposition s t @ re) S	(* Rule (1) *)
	  		    else []						(* Rule (2) *)
	 | (true,false)  => let val ss = LS s
	 		        val st = LS t
	 		    in if ss <<= st 
	 		       then (* ss <= st *)	(* Good substitution - (10) Merge *)
	 		    	    let val v = get_Variable t
	 		            in if occurs v s 	
	 		               then []		(* Rule (4) *)
	 		               else unifylist 
	 		                      (var_elim (v,s) re) (elim_right (v,s) S)
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
	 		                                 (elim_right (v,newterm) S)
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
	 		      		 (var_elim (v,s) re) (elim_right (v,s) S)
	 		            end
	 		       else if st <<= ss
	 		            then (* st <= ss *)		(* Rule (6) *)
	 		    	         let val v = get_Variable s 
	 		    	         in unifylist 
	 		      		         (var_elim (v,t) re) (elim_right (v,t) S)
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
	handle (Least_Sort ss) => (error_message "No Unification Possible - Signature not Regular" ; [])
end (* of let for function ACOSunify *)
	
val unify  = ACOSunify 

end (* of functor ACUnifyFUN *)
;
