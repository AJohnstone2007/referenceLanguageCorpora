(*
 *
 * $Log: ACOSmatch.sml,v $
 * Revision 1.2  1998/06/08 17:47:27  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(*

ACOSmatch.sml

MERILL  -  Equational Reasoning System in Standard ML.
Brian Matthews				     24/01/92
Glasgow University and Rutherford Appleton Laboratory.

Produces Order-Sorted AC-Matching substitutions.

This module does all the clever partitioning and generation of 
solutions from a set of solutions to a system of linear equations for 
Associative/Commutative Matching.

Based on some simple analysis of the restrictions to the AC-Unification
algorithm.

The basic algorithm comes from Phillipe le Chenadec, Canonical Forms in
Finitely Presented Algebras, 1986, suitably modified to take into account 
the Order-Substitutions which result.  I am sure that it appears else where
as well, but I shall take it from there.

*)

functor AC_MatchFUN (structure T : TERM
		     structure S : SUBSTITUTION
		     structure A : AC_TOOLS
		     sharing type T.Term = S.Term = A.Term
		     and     type T.OpId = T.Sig.O.OpId = A.OpId
		     and     type S.Variable = T.Sig.V.Variable = T.Variable = A.Variable
		     and     type T.Sort = T.Sig.S.Sort = T.Sig.V.Sort = T.Sig.O.Sort
		     and     type S.Signature = T.Sig.Signature = A.Signature 
		    ) : MATCH =
struct

type Signature = T.Sig.Signature
type Term = T.Term
type Substitution = S.Substitution

open S T T.Sig.O T.Sig.V A

val sort_ordered_reflexive = T.Sig.S.sort_ordered_reflexive
val get_sort_ordering = T.Sig.get_sort_ordering
val get_operators = T.Sig.get_operators

(* 

decompose : Signature -> (Term * Term) list * Substitution 
		-> (Term * Term) list * Substitution 

Does the syntactic decomposition and the merging part of the matching process.
Also checks that the resulting substitutions are Sort Preserving.
Reduces the problem to a list of pairs which are the ones in the equational
theory.

*)

fun decompose Sigma = 
let

fun in_subst S = element VarEq (domain_of_sub S)
val fail = ([],FailSub)
val of_sort = T.of_sort Sigma o (T.Sig.V.variable_sort)
val is_eq_op = ou (C_Operator (get_operators Sigma)) 
                  (AC_Operator (get_operators Sigma)) 
val eq_AC = AC_equivalent Sigma 

fun Msimpl S [] = ([],S)
  | Msimpl S ((s,t)::U) = 
    if variable s
    then let val v = get_Variable s
         in if in_subst S v
            then if eq_AC (applysubtoterm S s) t
                 then Msimpl S U
                 else fail
            else if of_sort v t
                 then Msimpl (addsub S (v,t)) U
                 else fail
         end 
    else if variable t
         then fail
         else if same_root s t
              then if is_eq_op (root_operator s)
                   then apply_fst (cons (s,t)) (Msimpl S U)
                   else Msimpl S (U @ zip (subterms s,subterms t))
                          (* handle Zip => 
	(write_terminal ("Heres the Zip Error "^stringlist (show_term Sigma) (""," ","") (subterms s) ^ " and " ^stringlist (show_term Sigma) (""," ","") (subterms t) ^ "\n") ; raise Zip)*)
              else fail
in
Msimpl
end ;

(*
Now the AC-Mutation algorithm.

Based on some simple analysis of the restrictions to the AC-Unification
algorithm.

*)

(* 

csums : int -> OpId Search -> int list -> OpId Search list -> int -> int list list

this function generates all solutions to the equation:
	c = a1*x1 + ... + an*xn
subject to the constraints on the valid substitutions 
which can be generated in the matching algorithm.
Two constraints are imposed by this function:

If xi represents a compound term with root operator g,
then we can say that:
	1).  xi =< 1 - otherwise we would be matching g with + the AC op.
	2).  root operator of the Matched term must also be g - otherwise
	     symbol clash will occur
*)

fun casums c cc [] [] n = []
  | casums c cc [a] [ac] _ =  
    if c rem a = 0 
    then case ac of
         Match sya => if c = a
		      then case cc of 
		           Match syc => if OpIdeq sya syc
					then [[1]]
					else []
			  | NoMatch => [] 
		      else []
	 | NoMatch => [[c div a]]
    else []
  | casums c cc (a::ais) (ac::acs) n =
    let val a' = n*a
    in if a' > c
       then []
       else case ac of 
            Match sya => if n=1 
			 then (case cc of
			      Match syc => if OpIdeq sya syc
					   then if a' = c
						then [1::copy (length ais) 0]
						else map (cons 1) 
						     (casums (c-a') cc ais acs 0)
					   else []
			     | NoMatch => [])
			 (* added as bug fix bmm 28-04-92 *)
			 else 
			 if n = 0 
			 then map (cons 0) (casums c cc ais acs 0)
                             @
                             casums c cc (a :: ais) (ac::acs) 1
                         (* up to here *)
			 else []
	   | NoMatch => if a' = c
                        then [n:: copy (length ais) 0 ] 
                        else map (cons n) (casums (c-a') cc ais acs 0)
                             @
                             casums c cc (a :: ais) (ac::acs) (n+1)
    end 
  | casums _ _ _ _ _ = failwith "Constraint Mismatch in AC Matching"

(* 
occurence_lists : Term list -> Term list * int list * OpId Search list

Given a list of term, returns the triple of
a) non-repeating list of the same terms,
b) list representing the number of occurences of each term in the same order
c) list of the root-operator of each term, NoMatch if variable, in same order.

*)

local
fun count_and_remove a (b::l) = 
    let val (nas,l') = count_and_remove a l
    in if TermEq a b
       then (nas+1, l')
       else (nas, b :: l')
    end 
  | count_and_remove a [] = (0,[]) 
in
fun occurence_lists (a::l) = 
    let val (nas, l') = count_and_remove a l
        val (ais,nais,sys) = occurence_lists l'
    in  (a::ais,1+nas::nais,
        	((Match(root_operator a)) 
    		  handle Ill_Formed_Term _ => NoMatch)::sys) 
    end 
  | occurence_lists [] = ([],[],[])
end  

(*
mk_subsets : 'a list list -> 'a list list

In practise, 'a is instantiated by int list.

Generates all the valid subsets by taking one element from each 
of the input subsets to form each subset
*)

fun mk_subsets (ss1::sss) = 
  	mapapp (fn l => map (R l o C cons) (mk_subsets sss)) ss1
  | mk_subsets [] = [[]]

(*
check_cons : OpId list -> int list list list -> int list list list

The final constraint checker.

This function goes through all the subsets of the base solutions
to the linear equations, and filters out all those subsets which
have:
	a) a zero sum total for some entry - this means no value for a 
	    variable which cannot be.  
	b) a sum total =/= 1 for some constrained variable - this would
	   mean a clash of symbols, and can be excluded here.
*)

local
fun add_hds ((a::_)::r) 0 = add_hds r a
  | add_hds ((0::_)::r) 1 = add_hds r 1
  | add_hds ((a::_)::r) 1 = false
  | add_hds _ s = s=1
in
fun check_cons (ca::racs) sols = 
    (case ca of
       NoMatch => (* not constrained *)
         exists ((neq 0) o hd) sols
	 andalso
         check_cons racs (map tl sols)
    | Match sy => (* constrained *)
         add_hds sols 0 
         andalso
         check_cons racs (map tl sols)
   )
   | check_cons [] sols = true
end (* of local *)


(*
mk_solution : Term list -> Term list -> int list list -> (Term * Term list) list
For each valid solution set (int list list), we generate the appropriate 
solution from the matched terms (1st arg) and the matching terms (2nd terms)
*)

fun mk_solution f sis (t::tis) sols =
    (t,AC_unflatten f (mapapp2 (copy o hd) sols sis)) :: mk_solution f sis tis (map tl sols)
  | mk_solution _ sis [] sols = []
(*
fun disjoint (s::ss) (t::ts) (dss,dts) =
    if TermEq s t then disjoint  (ss) (ts) (dss,dts)
    else if ord_t s t 
         then disjoint  (s::ss) (ts) (dss,t::dts)
         else disjoint  (ss) (t::ts) (s::dss,dts)
  | disjoint [] [] (dss,dts) = apply_both rev (dss,dts)
  | disjoint [] ts (dss,dts) = (rev dss,(rev dts)@ts)
  | disjoint ss [] (dss,dts) = raise Zip
    
(*  The AC_Match function itself. *)

fun AC_Match Sigma  T1 T2 = 
    (let val Term_List_1 = subterms T1 (* works as already flattened *)
        val Term_List_2 = subterms T2
        
        val (das,dbs) = disjoint Term_List_1 Term_List_2 ([],[])
        
        (* the first thing to do to is to remove all common occurences *)
        val (subts_1, ais, asys) = occurence_lists das
        val (subts_2, bis, bsys) = occurence_lists dbs
  
        val Basis = map2 (fn (p,pc) => casums p pc ais asys 0) bis bsys

        val subsets = mk_subsets Basis

    in mapfilter (check_cons asys) 
                 (mk_solution (root_operator T1) subts_2 subts_1) subsets
    end
    handle Zip => []
    )
*)
fun AC_Match Sigma  T1 T2 = 
    let (*val d = write_terminal ("ACmatch " ^show_term Sigma T1^" onto "^show_term Sigma T2)*)
        val Ts1 = AC_subterms T1 
        val Ts2 = AC_subterms T2
        
    in 
    if length Ts2 < length Ts1  (* if the number of target terms is less than the matching *)
    then []			(* there is not a lot of point carrying on *)
    else 
    let  (* the first thing to do to is to remove all common occurences *)
        val (subts_1, ais, asys) = occurence_lists (bag_difference TermEq Ts1 Ts2)
        val (subts_2, bis, bsys) = occurence_lists (bag_difference TermEq Ts2 Ts1)
  
        val Basis = map2 (fn (p,pc) => casums p pc ais asys 0) bis bsys

        val subsets = mk_subsets Basis

(*        val ms = mapfilter (check_cons asys) 
                 (mk_solution (root_operator T1) subts_2 subts_1) subsets
    in (write_terminal " -- Done\n"; ms)
    end
*)  in mapfilter (check_cons asys) 
                 (mk_solution (root_operator T1) subts_2 subts_1) subsets
    end
    end

fun OSAC_match Sigma T1 T2 = 
let 

(*(* we can rely on the terms being AC-flattened and ordered *)
val T1 = AC_flatten Sigma T1
val T2 = AC_flatten Sigma T2
*)

val opers = get_operators Sigma

(*fun clear_app ((U,s)::Us) V = 
      if isfail s then clear_app Us V else (U@V,s) :: clear_app Us V
  | clear_app [] _ = []*)

fun clear_app Us V = mapfilter (non isfail o snd) (apply_fst (C append V)) Us

val Msimpl = decompose Sigma 

fun mutate ((t,t'),s) = 
	map (Msimpl s) 
	(if C_Operator opers (root_operator t)
	then Cmutate Sigma t t'
	else 
	if AC_Operator opers (root_operator t)
	then AC_Match Sigma t t'
	else []     (** this is a bad failure **)
	)
	
fun merge ((t,t')::V, s) = clear_app (mutate ((t,t'),s)) V
  | merge ([], s) = [([], s)]

fun matcher (U,s) = 
    if null U 
    then [s]
    else mapapp matcher (merge (U,s))

in 
matcher (Msimpl EMPTY [(T1,T2)])
end 

fun all_matches s t1 = filter (not o isfail) o OSAC_match s t1

fun match Sigma T1 T2 = 
let 

(*(* we can rely on the terms being AC-flattened and ordered *)
val T1 = AC_flatten Sigma T1
val T2 = AC_flatten Sigma T2
*)

val opers = get_operators Sigma
val Msimpl = decompose Sigma 
fun mutate ((t,t')::V,s) = 
    let val f= root_operator t
        val acs = (if C_Operator opers f
	           then Cmutate Sigma t t'
	           else 
	           if AC_Operator opers f
	           then AC_Match Sigma t t'
	           else [])     (** this is a *bad* failure **)
    in if null V 
       then let fun filtmap (t1s::ts) acc = 
                    let val (U,s') = Msimpl s t1s
                    in if isfail s' then filtmap ts acc 
                       else if null U 
                            then [([],s')]
                            else filtmap ts ((U,s) :: acc)
                    end
                  | filtmap [] acc = acc
            in filtmap acs []
            end 
       else(* let fun filtmap (t1s::ts) acc =  
                    let val (U,s') = Msimpl s t1s
                    in if isfail s' then filtmap ts acc 
                       else filtmap ts ((U@V,s) :: acc)
                    end
                  | filtmap [] acc = acc
            in filtmap acs []
            end *)
            filtermap (isfail o snd) (Msimpl s) acs
    end
  | mutate ([], s) = [([], s)]

fun matcher (U,s) = 
    if null U 
    then [s]
    else mapapp matcher (mutate (U,s))

in 
matcher (Msimpl EMPTY [(T1,T2)])
end 

fun match s t1 t2 = (*(write_terminal ("Matching "^ show_term s t1 ^" upon "^show_term s t2^"\n");*)
		    hd (OSAC_match s t1 t2)
		    handle Hd => FailSub


(* 
(*
the next bit is from Le Chenedec.  It should make AC-Matching
more efficient.  I don't at present use it and it is commented out.
*)
(* 
the eq_s function finds whether t1 =s t2 where s is a substitution
defined as t1 =s t2 iff exists sequence t1 = s1, ... , sn = t2 s.t.
s(xi) = x(i+1).
*)

fun eq_s s t1 t2 = 
    let val t1' = applysubtoterm s t1
    in if TermEq t1' t2 
       then true
       else if TermEq t1' t1
            then false
            else eq_s s t1' t2
    end 
    ;

fun find_eq_s s ((B,k)::bs) a l1 = 
    if eq_s s B a 
    then Match ((B,k+1)::l1@bs)
    else find_eq_s s bs a ((B,k)::l1)
  | find_eq_s s [] a l1 = NoMatch
  ;

(* 
thus the Dist function finds which terms are really distinct
taking the current substitution into account. 

Dist : Term list -> (Term * int) list -> Substitution -> (Term * int) list

Computes a list of pairs [(Pj,pj)] s.t. in the Ais of the Matching term
f(A1,...,An), Pj occurs pj times modulo the bindings s.

*)

fun Dist [] L s = L
  | Dist (a1::ais) L s = 
    (case find_eq_s s L a1 [] of
       Match L1 => Dist ais L1 s
     | NoMatch  => Dist ais ((a1,1)::L) s
    )
  ;

(* end of commented out section. *)
*)

end (* of functor AC_MatchFUN *)
;
