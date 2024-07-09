(*
 *
 * $Log: incKBO.sml,v $
 * Revision 1.2  1998/06/08 18:18:58  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* 
MERILL  -  Equational Reasoning System in Standard ML.
Brian Matthews				     23/11/93
Glasgow University and Rutherford Appleton Laboratory.

incIKBO.sml 

Provides an implementation of the incremental IKBO which deceides on a possible ordering
on operators and weights.

This uses the implementation of Nick Cropper of the algorithm of Martin/Kalmus/Dick
implemented in 1992, and modified to integrate with the MERILL system August 93. 

Coded by Nick Cropper, University of Glasgow, 1992. 
Integrated into MERILL, BMM, 1993.
*)

signature INCKBO =
   sig
   	type Signature
   	type Equality
   	type Environment
   	type ORIENTATION

	val initialiseIKBO : unit -> unit 
     	val incKBO : Signature -> Environment -> Equality -> ORIENTATION * Environment
	
  end (* of signature USERKBO *)
;

functor IncKBOFUN (structure T : TERM
		 structure M : MATRIX
		 structure Eq : EQUALITY
		 structure O : ORDER
		 structure En : ENVIRONMENT
		 sharing type T.OpId = T.Sig.O.OpId
		 and     type T.Variable = T.Sig.V.Variable
		 and     type T.Sig.Signature = Eq.Signature = En.Signature
		 and     type T.Term = Eq.Term 
		 and 	 type O.ORIENTATION = Eq.ORIENTATION = En.ORIENTATION
		 and 	 type Eq.Equality = En.Equality
		) : INCKBO = 
struct

type Signature = T.Sig.Signature
type Equality = Eq.Equality
type Environment = En.Environment
type ORIENTATION = O.ORIENTATION
open T M

val OpIdeq = T.Sig.O.OpIdeq
val ikboname = "Incremental Knuth_Bendix Ordering"

(* the assoc function - local to this file *)

exception Assoc
fun		assoc _ []           x = raise Assoc
|		assoc eqf ((y, z)::bs) x = if eqf y x then z
                                           else assoc eqf bs x
(* this is the tOps code *)

fun funcs t = if variable t then [] 
	      else let val ps = subterms t 
	           in (root_operator t, length ps) :: funcList ps end

and		funcList []      = []
|		funcList (p::ps) = funcs p  revConc  funcList ps

local  
fun vars t = if variable t then [get_Variable t] else varList (subterms t)
and		varList []      = []
|		varList (p::ps) = vars p  revConc  varList ps

fun		tallyup eqf tally x = 
			let val q = assoc eqf tally x
			in (x, q + 1) :: (filter (not o eqf x o fst) tally)
			end
			handle Assoc => (x, 1) :: tally

fun		tallydown eqf tally x =
			let val q = assoc eqf tally x
			in (x, q - 1) :: (filter (not o eqf x o fst) tally)
			end
			handle Assoc => (x, ~1) :: tally

val tallyupFs = foldl (fn tally => (tallyup OpIdeq tally o fst))
val tallydownFs = foldl (fn tally =>  (tallydown OpIdeq tally o fst))
val tallyupVs = foldl (tallyup Sig.V.VarEq)
val tallydownVs = foldl (tallydown Sig.V.VarEq)
in
fun tallyupFuncs tally = tallyupFs tally o funcs
fun tallydownFuncs tally = tallydownFs tally o funcs 
fun tallyupVars tally = tallyupVs tally o vars
fun tallydownVars tally = tallydownVs tally o vars
end (* of local for tOps code *)

(* datatypes from the Global file *)

datatype  Label  = R of Term * Term | F of OpId * int | W;

datatype 'a Order  = Success of 'a | Failure of int;
datatype 'a Orient = Either of ('a * (Term * Term)) * ('a * (Term * Term))
                   | Single of 'a * (Term * Term)
                   | None

type Data = ((int list list * Label list) * 
		       int list list * 
		       OpId list * 
		       (OpId * OpId) list)

exception Fail of int

(* using alphaequiv here means that we will not enter alpha equivalent rules *)
fun LabelEq (R(t1,t2)) (R(s1,s2)) = 
    let val (b,env) = alphaequiv t1 s1 Assoc.Empty_Assoc
    in b andalso fst (alphaequiv t2 s2 env)
    end
  | LabelEq (F(f,n)) (F(g,m)) = OpIdeq f g andalso n = m 
  | LabelEq W W = true
  | LabelEq _ _ = false

local (* this is the code of the space.sml file *)
fun expandIneqs (m, l) (f, a) =
    let	val w      = width m
	val m'     = add0Col m
	val funrow = if a = 0 then 1 :: zeroRow (w - 1) [~1]
		     else 1 :: zeroRow (w - 1) [ 0]
	val label  = F (f, a)
    in (funrow :: m', label :: l)
    end

fun expandSolspace solspace =
    let val w         = width solspace
	val solspace' = add0Col solspace
	val row       = 1 :: zeroRow w []
    in row :: solspace'
    end

fun expand (ineqs, solspace, ops) []           = (ineqs, solspace, ops)
|   expand (ineqs, solspace, ops) ((f, a)::fs) =
    if element OpIdeq ops f then expand (ineqs, solspace, ops)     fs
    else expand (expandIneqs ineqs (f, a), expandSolspace solspace, f :: ops) fs

in 
(* expandOps -- Expand the data for each new *)
(*              operator found in rule       *)
(* expandOps data rule -> data'              *)

fun expandOps data (l, r) = expand data (funcs l revConc funcs r);

(* rule addition *)
(* defines addRule *)

(* addRule -- Add the rule to the system of linear *)
(*            ineqs, according to the operators    *)
(* addRule ineqs ops rule -> ineqs'                *)

fun addRule (m, ls) ops (l, r) =
    if element LabelEq ls (R (l, r)) 
    then raise Fail 10	(* Yukky method of breaking control - but effective *)
    else let val ftally = tallydownFuncs (tallyupFuncs [] l) r
	     val vtally = tallydownVars (tallyupVars [] l) r
	     val nv     = totalVars vtally 0
	     fun nf f   = assoc OpIdeq ftally f
			  handle Assoc => 0
	     val row    = map nf ops @ [nv]
    in (* if member m row 	(* will remove repetitions of inequalities  - not sure its right *)
       then raise Fail 10	(* Yukky method of breaking control - but effective *)
       else *) (row :: m, R (l, r) :: ls)
    end

and totalVars []            tot = tot
|   totalVars ((v, q)::tal) tot = if q < 0 then raise Fail 1
			          else totalVars tal (tot + q);
end (* of local for space *)

local (* Method of Complete Description *)
(* supplies 
val mCD : int list list -> int list list -> int list list
val degenerate : int list list * Label list -> int list list -> int list list * Label list
*)

fun		partition bs = sep bs 1 ([], [], [])

and		sep [] i (ns, zs, ps) = (ns, zs, ps)
|		sep (x::xs) i (ns, zs, ps) =
			if      x < 0 then sep xs (i + 1) (i::ns, zs, ps)
			else if x = 0 then sep xs (i + 1) (ns, i::zs, ps)
			else               sep xs (i + 1) (ns, zs, i::ps)

fun		unitVecs d [] = []
|		unitVecs d (e::es) =
			let val v = zeroRow (e - 1) (1 :: (zeroRow (d - e) []))
			in v :: unitVecs d es
			end

fun		diffVecs d bs [] = []
|		diffVecs d bs ((p, n)::pns) =
			let val ap = nth (bs,p-1)
				val an = ~(nth (bs,n-1))
				val (i, ai) = minIndex (p, an) (n, ap)
				val (j, aj) = maxIndex (p, an) (n, ap)
			in diffV d (i, ai) (j, aj) :: diffVecs d bs pns
			end

and		minIndex (i, ai) (j, aj) = if i < j then (i, ai) else (j, aj)
and		maxIndex (i, ai) (j, aj) = if i > j then (i, ai)  else (j, aj)

and		diffV d (i, x) (j, y) =
			zeroRow (i - 1) 
				(x :: zeroRow (j - i - 1) 
					(y :: zeroRow (d - j) []))

fun		ratio [bs] =
			let val (ns, zs, ps) = partition bs
				val d            = length bs
				val zeroVs       = unitVecs d zs
				val posVs        = unitVecs d ps
				val posNegVs     = diffVecs d bs (crossPair ps ns)
			in zeroVs @ posVs @ posNegVs
			end
  | 		ratio _ = failwith "Ratio in IncKBO"

fun select p []      _       = []
|   select p (q::qs) (x::xs) = if p q then x :: select p qs xs
                               else select p qs xs
|   select _ _ _ 	     = raise Zip

in

(* mCD -- Iterate M of CD for each new inequality   *)
(*        to produce updated matrix of extreme vecs *)
(* mCD solspace newineqs -> solspace'               *)

fun		mCD solspace []      = solspace
|		mCD solspace (r::rs) =
			let val solspace' = matProdT solspace (ratio (matProd [r] solspace))
			in mCD solspace' rs
			end

(* degenerate -- Calculate system of ineqs that are *)
(*               fixed to zero for all solutions    *)
(* degenerate ineqs solspace -> ineqs'              *)

fun		degenerate (m, ls) solspace =
			let val c   = matProd m solspace
				val m'  = select allZero c m
				val ls' = select allZero c ls
			in if element LabelEq ls' W then raise Fail 2
			                 else (m', ls')
			end
end (* of local for the Method of Complete Description *)

local (* Handles the lists of Labels in 'ineqs' and 'subsys'  *)

(* defines unaries, hdPrecs, redPairs *)
(*
val unaries : Label list -> OpId list
val hdPrecs : Label list -> (OpId * OpId) list
val redPairs : Label list -> (Term * Term) list
*)

fun firstDiff (s::ss) (t::ts) =
			if not (TermEq s t) then [(s, t)]
			else firstDiff ss ts
  | firstDiff _ _ = []
in 

(* unaries -- The list of unary operators in subsys *)
(*            ie unary zero-weight operators        *)
(* unaries labels -> unaryops                       *)
fun		unaries []               = []
|  		unaries (F (f, 1) :: ls) = f :: unaries ls
|  		unaries (_::ls)          = unaries ls;


(* hdPrecs -- Local precedences for equal-weight rules *)
(*            with differing root operators            *)
(* hdPrecs labels -> oppairs                           *)
fun hdPrecs []                               = []
|   hdPrecs (R (t1, t2) :: ls) 		     = 
	if variable t1 then raise Fail 5
	else if compound t1 andalso compound t2
	then let val f = root_operator t1 
	         val g = root_operator t2
	     in if not (OpIdeq f g) 
	        then (f, g) :: hdPrecs ls
	        else hdPrecs ls
	     end
	else hdPrecs ls			    
|   hdPrecs (_::ls)                          = hdPrecs ls

(* redPairs -- The list of reduced pairs: from equal-weight *)
(*             rules with same root operators               *)
(* redPairs labels -> redpairs                              *)		          			          
fun		redPairs []     	    = []
|		redPairs (R (t1, t2) :: ls) =
		if variable t1 orelse variable t2 then redPairs ls
		else
		let val f = root_operator t1 
		    val g = root_operator t2
		in if OpIdeq f g  
	           then firstDiff (subterms t1) (subterms t2) @ redPairs ls
		   else redPairs ls
	        end 
|		redPairs (_::ls)     	    = redPairs ls
end (* of local for label *)

local (* precedence.  Handles the operator precedence: *)
(* an irreflexive partial ordering  *)
(* defines unaryPrec, extend *)
(*
val unaryPrec : (Sig.O.OpId * Sig.O.OpId) list 
		  -> Label list 
		    -> Sig.O.OpId list 
		      -> (Sig.O.OpId * Sig.O.OpId) list
val extend : (Sig.O.OpId * Sig.O.OpId) list 
		-> (Sig.O.OpId * Sig.O.OpId) list 
		   -> (Sig.O.OpId * Sig.O.OpId) list
*)

exception	Extend

fun		reachable1s []            f = []
|		reachable1s ((g, h)::ghs) f =
			if OpIdeq g f then h :: reachable1s ghs f
			         else reachable1s ghs f

fun		isReachablePs po []      k = false
|		isReachablePs po (f::fs) k =
			isReachable po f k
			orelse
			isReachablePs po fs k
			
and		isReachable po f k =
			OpIdeq f k
			orelse
			isReachablePs po (reachable1s po f) k
			   
fun		extendP po (f, k) = if isReachable po k f then raise Extend
			                else if isReachable po f k then po
			                else (f, k) :: po

fun		extendPairs po []            = po
|		extendPairs po ((f, k)::fks) = extendPairs (extendP po (f, k)) fks


fun		extendUs po []  ops = po
|		extendUs po [u] ops = (extendPairs po ((map o pair) u (filter (non (OpIdeq u)) ops))
                              handle Extend => raise Fail 4)
|		extendUs po _   ops = raise Fail 3

in
(* unaryPrec -- Extend precedence for a    *)
(*              unary zero-weight operator *)
(* unaryPrec po labels ops -> po'          *)

fun unaryPrec po ls ops = extendUs po (unaries ls) ops


(* extend -- Extend precedence to include *)
(*           the head precedences         *)
(* extend po precs -> po'                 *)

fun		extend po precs = extendPairs po precs
                          handle Extend => raise Fail 6
end (* of local for precedence *)

(* The top level of the program for the  *)
(* Incremental Knuth-Bendix Ordering Alg *)
(* defines iKBO, initialData, kBOrient *)
(*
val iKBO : Data -> T.Term * T.Term -> Data Order
val initialData : Data
val kBOrient :  Data -> T.Term * T.Term  -> Data Orient
*)

(* iKBO -- Try to extend the KB ordering defined *)
(*         in 'data' to order 'rule'             *)
(* iKBO data rule -> Success data' + Failure f   *)

fun	iKBO (ineqs, solspace, ops, po) p =
		let
        (* expand data for any new ops in rule p *)
		    val (ineqs', solspace', ops'') = expandOps (ineqs, solspace, ops) p
	(* add p to inequalities *)
		    val ineqs''                    = addRule ineqs' ops'' p
			
	(* iterate MCD to update soln space *)
		    val solspace''                 = mCD solspace'
			                                     ((rev o take
			                                         (1+length ops''-length ops))
			                                         (fst ineqs''))

	(* calculate degenerate subsystem *)
		    val subsys''                   = degenerate ineqs'' solspace''
			
	(* extend p-order for unary zero-weight op *)
		    val po'                        = unaryPrec  po (snd subsys'') ops''
			
	(* precedence for differing balanced root ops *)
		    val precs''                    = hdPrecs    (snd subsys'')
			
	(* extend p-order *)
		    val po''                       = extend     po' precs''
			
	(* find reduced pairs to be included *)
		    val pairs                      = redPairs   (snd subsys'')
			
		in 
		   if null pairs then (write_terminal "Success \n" ;
		   			Success (ineqs'', solspace'', ops'', po''))
			             else iKBOPairs (ineqs'', solspace'', ops'', po'') pairs
		end
		handle Fail f => Failure f

and 	iKBOPairs data []      = Success data
|   	iKBOPairs data (p::ps) = case iKBO data p of
			                       Failure 10    => iKBOPairs data ps
			                     | Failure f     => Failure f
			                     | Success data' => iKBOPairs data' ps;

val initialData : Data  =
	(([[1]], [W]),    	(* system of linear inequalities *)
            [[1]],           	(* extreme vectors of solution space *)
            [],               	(* vector of operators *)
            []) ;      	  	(* partial order on operators *)

(* kBOrient -- Which ways can term_pair be oriented    *)
(*             in KB ordering of data?                 *)
(* kBOrient data p -> Either ((data1, p), (data2, p')) *)
(*                    + Single (data, p'')             *)
(*                    + None                           *)

fun		kBOrient data (s, t) =
			let val d = write_terminal ("Entering "^ikboname^".\n")
				val try1 = iKBO data (s, t)
				val try2 = iKBO data (t, s)
			in case (try1, try2) of
			     (Success d1, Success d2) =>
			                 Either ((d1, (s, t)), (d2, (t, s)))
			   | (Success d1, Failure _)  => Single (d1, (s, t))
			   | (Failure _,  Success d2) => Single (d2, (t, s))
			   | (Failure 10, _)          => Single (data, (s, t))
			   | (_,          Failure 10) => Single (data, (t, s))
			   | (Failure m,  Failure n)  => None
			end

(* print  Pretty-printing functions for IKBO *)
(* defines printData *)
(* 
type Data
val printData : Sig.Signature -> Data -> unit
*) 

fun showRule S lr =  Eq.unparse_equality S (uncurry Eq.mk_rule lr O.LR)
local 

fun showRow (rs:int list) = stringlist (pad Right 4 o makestring) ("[",""," ]") rs

val showMatrix = stringlist showRow ("","\n","")

local 
open Sig.O
fun format Fs = unform o display_format Fs
in
fun showOps _ []          = "w\n"
|   showOps Fs (f::fs) = "w("^(format Fs f)^")\n" ^showOps Fs fs

fun showPo _ []            = "\n"
|   showPo Fs ((f, g)::fgs) = "("^(format Fs f)^" > "^(format Fs g)^")   " ^ showPo Fs fgs

fun showLabel Sigma (R (s, t)) = "R " ^ showRule Sigma (s, t)
|   showLabel Sigma (F (f, a)) = "F " ^ (format (Sig.get_operators Sigma) f)
|   showLabel _ (W)        = "W"
end (* of local open *)

fun showIneqs Sigma ([], [])       = ""
|   showIneqs Sigma (r::rs, l::ls) = 
			showRow r ^ "      " ^ showLabel Sigma l ^ "\n" ^ showIneqs Sigma (rs, ls)
|   showIneqs Sigma ( _ , _ ) = raise Zip 

in

fun printData Sigma (ineqs, solspace, ops, po) =
		write_terminal( 
			"System of linear inequalities:\n" ^ 
			showIneqs Sigma  ineqs ^ "\n" ^
			"Extreme vectors of solution space:\n" ^
			showMatrix solspace ^ "\n" ^
			"Vector of unknowns of system:\n" ^
			showOps  (Sig.get_operators Sigma)  ops ^ "\n" ^
			"Precedence over operators:\n" ^
			showPo  (Sig.get_operators Sigma)   po ^ "\n")

end (* of local for printing *)

(* this is the global variable which keeps the current state of the IKBO system *)

val IKBODATA = ref initialData
fun initialiseIKBO () = IKBODATA := initialData

(* final Ikbo routines *)

fun		printDirn S data dirn =
			if Display_Level.current_display_level () = Display_Level.full
			then
			(write_terminal ("\nThe KB ordering is extended to data:\n");
			 printData S data;
			 write_terminal ("by orienting the rule:\n" ^
			                 (showRule S dirn) ^ "\n")
			) else ()
			
fun		printFailure S data (s, t) =
			if Display_Level.current_display_level () = Display_Level.full
			then
			(let val (ss,st) = Eq.show_equality S (Eq.mk_equality s t)
			in 
			 write_terminal ("\nWith data:\n");
			 printData S data 
			end 
			) else ()

fun orientation (s,t) (s',t') = if TermEq s s' andalso TermEq t t' then O.LR else O.RL

fun orientEqns S (ordname,locord) data e =
   let val (s, t) = Eq.terms e
   in case kBOrient data (s, t) of
	  Either ((data1, dirn1), (data2, dirn2)) => 
	  	(write_terminal (ikboname^" can orient either way : try local ordering "^ordname^"\n"); 
	  		case locord S e of 
	  		  O.LR => (printDirn S data1 dirn1 ; (O.LR,data1))
	  		| O.RL => (printDirn S data2 dirn2 ; (O.RL,data2))
	  		| O.UNORIENTABLE => 
	  		  (write_terminal 
	  		  ("Unorientable Equation "^Eq.unparse_equality S e^" by Local Ordering ") ;
	  		   (O.UNORIENTABLE, data) )
	  		)
	| Single (data', dirn') => (printDirn S data' dirn';
			             (orientation (s,t) dirn',data'))
	| None => (write_terminal 
	  		  ("Unorientable Equation "^Eq.unparse_equality S e^" by "^ikboname^"\n") ;
	  	   printFailure S data (s, t) ; (O.UNORIENTABLE,data))
   end 

fun incKBO A env e = 
    let val (ori,data) = orientEqns A (En.get_locord env) (!IKBODATA) e
    in (IKBODATA := data; (ori, env) )
    end 

end (* of functor IncKBOFUN *) ;
