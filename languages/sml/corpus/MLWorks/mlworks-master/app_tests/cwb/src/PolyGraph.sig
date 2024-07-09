(*
 *
 * $Log: PolyGraph.sig,v $
 * Revision 1.2  1998/06/02 15:30:50  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
RCS "$Id: PolyGraph.sig,v 1.2 1998/06/02 15:30:50 jont Exp $";
(*********************************** Graph ***********************************)
(*                                                                           *)
(* Generation of polygraphs.                          Joachim Parrow June-88 *)
(*                                                                           *)
(* States in a graph are maintained in decreasing order with respect to      *)
(* their id's. This is true also of the suc, taus and newtaus fields, and    *)
(* the suc lists are maintained sorted according to their actions.           *)
(*                                                                           *)
(* reflexcl: takes a graph and adds tau loops to all states.                 *)
(* transcl: Replaces -tau-> with the transitive closure of -tau->.           *)
(* actcl: Adds (-tau->* -a->* -tau->) to -a->. This will only work on a      *)
(*    graph which has been produced by "transcl".                            *)
(* obscl: The three above graph transformations are effected.                *)
(* congrcl: This graph transformation goes with the bisimulation algorithm.  *)
(*    to check for observation congruence. replicates initial state and does *)
(*    NOT add a tau loop on the initial state.                               *)
(* epscl: Adds epsilon loop to the initial state of the graph.               *)
(*                                                                           *)
(*****************************************************************************)

signature POLYGRAPH =
sig
   (* structure Ag : AGENT *)

   type act
   type var
   type 'a env
   type agent

   type vertex
   val table : vertex ref PH.hash_table ref

   val tau     : act
   val eps     : act
   val act_eq  : act * act -> bool
   val act_le  : act * act -> bool

   datatype 'a state =
      S of {keycopy  : agent ref,	
            id       : int,
            suc      : (act * 'a state ref list ref) list ref,
            prdiv    : bool,
            gldiv    : bool ref,
            info     : 'a,
            taus     : 'a state ref list ref,
            newtaus  : 'a state ref list ref,
            tauarr   : bool Array.array ref,
            mark     : bool ref,
            p_id     : int ref}

   exception LookUp

   val mktable : unit -> unit

   val mkgraph     :  
       (agent -> '_a) ->                                  (* poly init     *)
       (agent -> bool) ->                                 (* divergence fn *)
       (agent -> agent) ->                                (* normalform fn *)
       (agent -> (act * agent) list) ->                   (* transition fn *)  
       agent -> '_a state ref * '_a state ref list

   val mkweakgraph :  
       (agent -> '_a) ->                                  (* poly init     *) 
       (agent -> bool) ->                                 (* divergence fn *)
       (agent -> agent) ->                                (* normalform fn *)
       (agent -> (act * agent) list) ->                   (* transition fn *)  
       agent -> '_a state ref * '_a state ref list

   val reflexcl  : '_a state ref * '_a state ref list -> 
                   '_a state ref * '_a state ref list
   val transcl   : '_a state ref * '_a state ref list -> 
                   '_a state ref * '_a state ref list
   val actcl     : '_a state ref * '_a state ref list -> 
                   '_a state ref * '_a state ref list
   val obscl     : '_a state ref * '_a state ref list -> 
                   '_a state ref * '_a state ref list
   val congrcl   : '_a -> '_a state ref * '_a state ref list -> 
                   '_a state ref * '_a state ref list
   val epscl     : '_a state ref * '_a state ref list -> 
                   '_a state ref * '_a state ref list

end

