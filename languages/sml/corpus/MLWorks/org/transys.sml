(*
 *
 * $Log: transys.sml,v $
 * Revision 1.2  1998/06/08 17:34:56  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(*
transys.sml

This module contains a specialised data structure used for the incremental 
mixfixed parsing algorithm encoded in structure for terms.  The data type 
is built up by giving the symbol form to be recognised together with the
action on recognition.

The structure currently exports the transistion system datatype together
with its constructors empty- and build- trans_system.  In addition there
is a distinguished element bracket_transys used to provide the parser for
bracketed terms.  

There are more functions in the structure than exported, which could be 
exported if necessary.  There is also no deletion function for restricting
the parsing algorithm, although there is a hook in the code for it to be 
attached to (the integer component of the Trangraph type).

MERILL  -  Equational Reasoning System in Standard ML.
Brian Matthews			              24-04-90
Rutherford Apppleton Laboratory and Glasgow University.

*)

signature TRANSYS =
  sig
	type 'a TranSys 
	val empty_trans_system :'a TranSys
	val bracket_transys : unit -> 'a TranSys
	val build_trans_system : ('a list -> 'a) -> string list ->
					 'a TranSys -> 'a TranSys
	val prune_trans_system : string list -> 'a TranSys 
					 -> 'a TranSys
	val scan_trans_system : string list -> 'a TranSys 
					 -> unit
	val traverse : 'a TranSys -> ('b -> string list -> 
			(('a * string list) * 'b) Maybe) -> 'b -> 'a list -> 
			string list -> (('a * string list) * 'b) Maybe
end ;

functor TranSysFUN () : TRANSYS =
struct 

datatype 'd TranGraph = state of int * 
				(string -> ('d TranGraph Maybe))
		   | endstate of ('d list -> 'd) *
		   		 int * 
		   		 (string -> ('d TranGraph Maybe))
		   | endnode of ('d list -> 'd) 

val error_state = state (0,fn x => K errM x)
val nograph = state (0,fn x => K errM x)

fun addpat f =
  let
    fun addp [] (endnode a) = endnode a
      | addp [] (endstate (a,n,g)) = endstate (a,n,g)  
      | addp [] (state (n,g)) = if n = 0 then endnode f else endstate(f,n,g)
      | addp (c::ss) (endnode a) = 
        endstate(a,1, fn t => if c = t then returnM (addp ss nograph) else errM)
      | addp (c::ss) (endstate (a,n,f')) = 
           (case f' c of 
              OK g => endstate (a,n,fn t => if c = t 
              			then returnM (addp ss g) else f' t )
           |  Error _ => endstate (a,succ n,fn t => if c = t 
         			then returnM (addp ss nograph) else f' t))
      | addp (c::ss) (state (n,f')) = 
  	    (case f' c of 
  	      OK g => state (n,fn t => if c = t then returnM (addp ss g) else f' t)
           |  Error _ => state (succ n,
              fn t => if c = t then returnM (addp ss nograph) else f' t ))
  in
    addp
  end

local 
datatype CUT = Cut | NoCut 
in 
fun delpat s = 
  let 
    fun delp [] (endnode s') = (Cut,nograph) 
      | delp [] (endstate (s',n,f)) = (NoCut,state (n,f)) 
      | delp [] (state (n,f)) = failwith ("state inaccesible to "^(implode s))
      | delp (c::ss) (endnode s') = failwith ("endnode inaccesible to "^(implode s))
      | delp (c::ss) (state (n,f)) = 
             (case f c of 
  	      OK g => let val (cut,ns) = delp ss g
  	                 in if cut = Cut 
  	                    then if n <= 1 then (Cut,nograph)
  	                         else (NoCut,state(pred n,
				 fn t => if t=c then Error"" else f t))
  	                    else (cut,state(n,fn t => if t=c then OK ns
  	                    			      else f t))
  	                 end
           |  Error _ => failwith ("gone down wrong path "^(implode s))
           )
      | delp (c::ss) (endstate (s',n,f)) = 
            (case f c of 
  	      OK g => let val (cut,ns) = delp ss g
  	                 in if cut = Cut 
  	                    then if n <= 1 then (NoCut,endnode s')
  	                         else (NoCut,endstate(s',pred n,
				 fn t => if t=c then Error"" else f t))
  	                    else (cut,state(n,fn t => if t=c then OK ns
  	                    			      else f t))
  	                 end
           |  Error _ => failwith ("gone down wrong path "^(implode s))
           )
    in 
      snd o (delp s)
    end 
end (* of local  *)

fun scan_trans_graph st g =
  let
    fun scan [] (endnode a) = write_terminal "Matched " 
      | scan [] (endstate (a,n,g)) = write_terminal "Matched"
      | scan [] (state _) = write_terminal "Error Matching Part State"
      | scan (c::ss) (endnode a) = 
	    write_terminal "Error Matching End Node Reached Too Early"
      | scan (c::ss) (endstate (a,n,f)) = 
  	    ( case f c of 
  	      OK g => scan ss g
  	    | Error _ => write_terminal ("Error Matching No Valid Transition to "^(implode (c::ss)) ))
      | scan (c::ss) (state (n,f)) = 
  	    ( case f c of 
  	      OK g => scan ss g
  	    | Error _ => write_terminal ("Error Matching No Valid Transition to "^(implode (c::ss)) ) )
  in
    scan st g
  end

type 'c TranSys = 'c TranGraph list 

fun build_trans_system action ss (gs) =
  let fun build (c::ss) (g1::gs) = if c = "" then g1::(build ss gs)
	                         else (addpat action (c::ss) g1)::gs
        | build (c::ss) [] = if c = "" then error_state::(build ss [])
	                   else [addpat action (c::ss) nograph]
        | build [] (g1::gs) = addpat action [] g1 :: gs  (* this should deal with Juxtaposition *)
        | build [] [] = [addpat action [] nograph]   (* this should deal with Juxtaposition *)
  in (build ss gs)
  end

val empty_trans_system = [nograph]

fun scan_trans_system s (gs) =
    let fun scan (c::ss) (g1::gs) = if c = "_" then scan ss gs
	                        else scan_trans_graph (c::ss) g1
          | scan (c::ss) [] = write_terminal ("No Transition graph available for ")
          | scan [] gs = write_terminal ("No String ") ;
    in scan s gs
    end

fun prune_trans_system s (gs) =
  let fun prune (c::ss) (g1::gs) = if c = "" then g1::(prune ss gs)
	                         else (delpat (c::ss) g1)::gs
        | prune (c::ss) [] = failwith (implode s^"  not in trans graph")
        | prune [] gs = gs
  in  (prune s gs)
  end

val bracket_transys = fn () => build_trans_system 
	(fn [x] => x | _ => failwith "More than one term in brackets")
	["(","",")"] empty_trans_system

(* is there an underscore transition? *)
fun underscore_transition f = existsM (f "") 

(* take the underscore transition *)
fun underscore f = 
    (case f "" of
      OK g => g
    | Error _ => failwith "No Transition on Underscore" )

(* take the underscore transition *)

fun traverse (p:'h TranSys) vp = 
let 

  fun parser e (ins as (s::ss)) (state (_,f)) args = 
      nextM (f s) (fn g => parser e ss g args)	(* Is there a transition on the symbol? *)
             (fn _ => (* not next operator component try parsing differently *)
    	  guardM (underscore_transition f) (fn () => 	(* possible argument here *)
    	        (full_parser e [] ins) propM (fn ((newarg,rss),e') =>
    	        parser e' rss (underscore f) (snoc args newarg)))
          "")
    | parser e ss (endnode act) args = returnM ((act args, ss),e)
    | parser e (ins as (s::ss)) (endstate (act,_,f)) args = 
      (* can we continue in this parser for longer operators? *)
      nextM (f s) (fn g => parser e ss g args)  (* yes - then do so - eager consumer - shift > reduce *)
      (fn _ => (* what if there is an "_" transition in the "f" ? - 
                *DANGER* - this will ALWAYS take priority if it
                exists *) 
       if (underscore_transition f) then 	(* possible argument here *)
         nextM (full_parser e [] ins) (fn ((newarg,rss),e') => 
                                       parser e' rss (underscore f) (snoc args newarg))
         (fn _ => returnM ((act args, ins),e))
       else  	(* no such valid transition - reduce and finished parse *)
         returnM ((act args, ins),e))
    | parser e [] (endstate (act,_,f)) args = returnM ((act args, []),e)
    | parser e [] (state f) args = errM
      
  and test lts ts ss e = guardM (lts = 1) (fn () => returnM ((hd ts,ss),e))
    
  and 
    full_parser e ts ss = 
    let
      val lts = length ts
      fun iterate 0 = 
        nextM (parser e ss (hd p) []) (fn ((t,ss'),e') => (* parse at top level *)
                                       nextM (full_parser e' (snoc ts t) ss') returnM
                                       (test lts ts ss e))
        (fn _    => nextM (vp e ss) 
         (fn ((v,ss'),e') => 
          nextM (full_parser e' (snoc ts v) ss') returnM
          (test lts ts ss e))
         (test lts ts ss e))
        | iterate m = 
          nextM (parser e ss (nth(p,m)) (last ts m)) (fn ((t,ss'),e') => 
                                                      nextM (full_parser e' (snoc (take (lts-m) ts) t) ss') returnM
                                                      (test lts ts ss e))
          (fn _ =>  iterate (m-1))
    in
      iterate (min (lts,(length p - 1)))
    end
in
  full_parser
end

end ; (* of structure Transys *)

