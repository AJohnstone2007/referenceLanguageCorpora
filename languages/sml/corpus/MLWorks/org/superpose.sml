(*
 *
 * $Log: superpose.sml,v $
 * Revision 1.2  1998/06/08 17:54:45  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(*

MERILL  -  Equational Reasoning System in Standard ML.
Brian Matthews				     10/03/90
Glasgow University and Rutherford Appleton Laboratory.

superpose.sml

Some horrible functions developed for the purpose of doing various 
devious variations on the basic superposition algorithm. 

*)

functor SuperposeFUN (structure T : TERM
		      structure S : SUBSTITUTION
		      structure E : ETOOLS
		      structure P : PATH
		      sharing type T.Term = S.Term = E.Term = P.Term
		      and     type S.Substitution = E.Substitution
		      and     type T.Sig.Signature = S.Signature = E.Signature 
		     ) : SUPERPOSE =

struct
   
   type Signature = S.Signature
   type Term = T.Term
   type Substitution = S.Substitution
   type Path = P.Path
   
   open S T


(* 
superpose : Signature -> Term -> Term -> (Substitution * Path) list

finds all the paths and substitutions that the second term superposes on the first.

*)

local open P in
fun superpose Sigma T1 T2 =
    let (*val d = write_terminal ("Superposing "^show_term Sigma T2^" on "^show_term Sigma T1^"\n")*)
        fun traverse p (s,n) hl = (walk hl (deepen p n) s,n+1)

        and walk t1 p subl =
            if compound t1
            then let val subs = (Statistics.inc_unify_attempts () ;
	    		    	   E.unify Sigma t1 T2 )
		     val subl' = map (fn s => ((*write_terminal (show_substitution Sigma s ^"\n");*)
		                               Statistics.inc_unify_success ();
		                           (s,p))) 
		                 subs
                 in fst (foldl (traverse p) (subl',1) (subterms t1))
                 end
            else subl
    in walk T1 root []
    end 
end (* of local open of P *);

(*

superposerep : Signature -> Term -> Term -> Term -> (Substitution * Term) list

This is a variant on superpose which in addition to finding the superpositions of the second
Term argument on the Third, takes a third argument, which should conceptually be the right-hand
side of a rewrite rule, for critical pair computation.   

What this function does is return in addition to the substitution, the term with the
rhs term inserted at place where the superposition took place.  Note that the substitution
is not applied: it will be applied to the whole term (with the rhs as a subterm)
once this function has completed.

superposerep A r t1 t2 = (s , t2[p <- r]) where s(t2|p) = s(t1)

Thus we have an more efficient method of replacing a subterm on superposition than returning a 
path which then has to be traversed to find the right occurence and replacing then.

*)

    fun superposerep Sigma rhs T1 T2 =
        let fun unh Term1 subl =
                if compound Term1 then
(*                (write_terminal ("Superposing "^
                	         (show_term Sigma T2)^" on Subterm "^
                	         (show_term Sigma Term1)^"\n") ;*)
         	let val subs = (Statistics.inc_unify_attempts () ;
	    		    	   E.unify Sigma Term1 T2)
(*		    val d = write_terminal (if null subs then "No Superposition\n" else "Superposes\n")*)
		    val subl' = map (fn s => (Statistics.inc_unify_success ();
		                           (s,rhs))) subs 
           	    fun gg (hl::rl) s done =
	      		let val shl = unh hl []
   	      		in gg rl (s @ map (apply_snd (fn x => done@(x::rl))) shl ) (done@[hl]) 
	      		end
	      	      | gg [] s _ = s
          	in
	        (* this next bit rebuilds the term as we come back up, with the replacing
                   subterm in place. *)

                map (apply_snd (mk_OpTerm (root_operator Term1))) (gg (subterms Term1) [] []) @  subl'
                end
                else subl
      in
        unh T1 []
      end 

(*
supreponsubterms :  Signature -> Term -> Term -> Term -> (Substitution * Term) list

supreponsubterms was defined in response to the observation that superposition at the root is
straight unification, and so only tries to superpose (and do replacement) on subterms.

Returns the whole term though with the superposed portion replaced.
That is what the subfunction gg does.

*)

   fun supreponsubterms Sigma rhs T1 T2 = 
   	let fun gg done (t::todo) = 
   	        (map (apply_snd (fn s => mk_OpTerm (root_operator T1) (done@(s::todo))))
			        (superposerep Sigma rhs t T2 ))
   	            @ (gg (snoc done t) todo)
   	      | gg _ [] = []
   	in gg [] (subterms T1)
   	end 

end (* of functor SuperposeFUN *)
;



