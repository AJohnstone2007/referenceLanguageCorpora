(*
 *
 * $Log: _scheduler.sml,v $
 * Revision 1.2  1998/06/08 13:10:18  jont
 * Automatic checkin:
 * changed attribute _comment to ' *  '
 *
 *
 *)
(*		Jo: A Concurrent Constraint Programming Language
			(Programming for the 1990s)

			     Andrew Wilson


			   Scheduler for Baby-Jo

			    19th November 1990

                               the functor

Version of July 1996, modified to use Harlequin MLWorks separate
compilation system.
*)


require "scheduler";
require "code";
require "dynamics";
require "tracer";
require "__lowlevel";


functor Scheduler(structure Code: CODE
                  structure Dynamics: DYNAMICS
                  structure Tracer: TRACER
                  sharing type Code.agent = Dynamics.agent
                      and type Code.object = Dynamics.object
                      and type Code.word = Dynamics.word
		      and type Code.word = Tracer.word
                      and type Code.constraint = Dynamics.constraint
                  ) : SCHEDULER =
struct
  open Code
  open Dynamics
  open Tracer
  infix sub

	(* Queue Abstract Data Type: implemented using pointers  *)
	(* and S-expressions.   It is done this way (instead of  *)
	(* say, a simple list) so that queues can be represented *)
	(* as pointers to the front and end of them.  	         *)
	(*   This makes it easy to add elements to the back of   *)
	(* the queue, and also to take them from the front.      *)
	(*    The price to be paid is that one has to be careful *)
	(* in manipulating queues.  Since most of the queue is   *)
	(* held in a chain of pointers, uncareful manipulation   *)
	(* may lead to such niceties as loops....                *)
(*
local

    datatype 'a Sexpression = nowt | S of 'a * 'a Sexpression ref

  in

    abstype 'a queue =  Q of 'a Sexpression ref * 'a Sexpression ref
    with
      exception QueueEmpty
      
      fun newQueue() = 
	  	  let val v = ref nowt
		   in Q(v,v)
		  end
      
      fun addToQ(e,Q(q,qEnd)) =
		  let val temp = ref (!qEnd)
		   in
		      (qEnd:=S(e,temp); Q(q,temp))
		  end


      fun QFront(Q(ref(nowt),_)) = raise QueueEmpty
        | QFront(Q(ref(S(e,_)),_)) = e

      fun removeQ(Q(ref(nowt),_)) = raise QueueEmpty
        | removeQ(Q(ref(S(e,next)),qEnd)) = Q(next,qEnd)


      fun appendQs(Q(ref(nowt),_),q) = q
        | appendQs(q,Q(ref(nowt),_)) = q
        | appendQs(Q(first_1,end_1),Q(first_2,end_2)) =
		(end_1:=(!first_2); Q(first_1,end_2))


     fun QToList(Q(ref(nowt),_)) = []
       | QToList(Q(ref(S(e,next)),q_end)) = e::QToList(Q(next,qEnd))

    end
  end
*)

    abstype 'a queue =  Q of 'a list
    with
      exception QueueEmpty
      
      fun newQueue() = Q([])
      
      fun addToQ(e,Q(q)) = Q(rev(e::(rev q)))

      fun QFront(Q([])) = raise QueueEmpty
        | QFront(Q(a::_)) = a

      fun removeQ(Q([])) = raise QueueEmpty
        | removeQ(Q(a::b))=Q(b)


      fun appendQs(Q(a),Q(b))=Q(a@b)
      fun QToList(Q(a))=a

    end





	(* NOW, for the scheduler itself.  This is fairly easy. *)
	(* it is simply a queue of virtual process descriptions.*)

	(* When running a typical Jo program, A large amount of *)
	(* lightweight processes will be generated.  It is      *)
	(* impractical to boot up a new unix process for each   *)
	(* such, since the overhead in creating and terminating *)
	(* a unix process for such a trivial amount of work is  *)
	(* prohibitive.  Such parallelisation would be slower   *)
	(* than a simple serial implementation! 		*)
	(*   The solution proposed here is to boot up a small   *)
	(* number of unix processes which will then act as      *)
	(* interpreters for `virtual processes'.		*)

	(* The purpose of this scheduler is to ship virtual     *)
	(* processes between virtual processors. (ie unix	*)
	(* processes....)				        *)

	(* NOT sure what is best way: to have a shared structure *)
	(* or an autonomous unix process.....			*)

(***************************************************************************)

	(* PROCESS: specifies the various processes which may be *)
	(* found in the scheduler's process queue and suspensions*)

  datatype process = 
	alternative of bool ref * int ref * agent * context * bool ref

      | guarded of condition * context * agent * bool ref
      | selection of condition * context * agent * bool ref

      | altGuard of bool ref 		(* other branch already going? *)
		   * int ref		(* number alternatives remaining *)
		   * condition
		   * context
		   * agent * bool ref

      | exec of agent * context * bool ref

      | arithWait of object * object list ref * constraint * context
		    * bool ref

      | procAlt of  string		(* proc name *)
		   * bool ref  * int ref * object list * object list
		   * int * agent * context
		   * bool ref

      | procGuard of string * bool ref * int ref * object list
		    * object ref list * object list * object ref list
		    * int * context * agent * bool ref 







  fun processToWords(alternative(switch,counter,a,cntxt,_)) =
	(if !switch 
	 then []
         else agentToWords(instantiateAgent(a,cntxt,nil,nil))
  	)
   


 | processToWords(guarded(cond,cntxt,a,_)) =
	let
	  val condWords = conditionToWords(cond,cntxt,nil,nil)
	  val agentWords = agentToWords(instantiateAgent(a,cntxt,nil,nil))
	 in
	   condWords @ [characters " and then "] @ agentWords
	end
	


 | processToWords(selection(cond,cntxt,a,_)) =
	let
	  val condWords = conditionToWords(cond,cntxt,nil,nil)
	  val agentWords = agentToWords(instantiateAgent(a,cntxt,nil,nil))
	 in
	   (characters "If ")::condWords @ [characters " then "] @ agentWords
	end
	


 | processToWords(altGuard(switch,counter,cond,cntxt,a,_)) =
	let
	  val condWords = conditionToWords(cond,cntxt,nil,nil)
	  val agentWords = agentToWords(instantiateAgent(a,cntxt,nil,nil))
	  val guardWords = condWords @ [characters " then "] @ agentWords
	 in
	    if !switch 
	    then []
	    else (characters ("("^(makeString (!counter)^")ALT ")))::guardWords
	end



 | processToWords(exec(a,cntxt,_)) = 
        (characters "Exec "):: agentToWords(instantiateAgent(a,cntxt,nil,nil))


 | processToWords(arithWait(var,ref(varlist),constr,cntxt,_)) =
	(characters "Fix ")::
	(openParen "(")::
	objectToWords(var)@
	((closeParen ")")::
	objectListToWords(instList(varlist,cntxt)))@
        ((characters " then ")::
	constraintToWords(instantiateConstraint(constr,cntxt,nil,nil)))


 | processToWords(procAlt(name,switch,counter,args,params,numvars,a,cntxt,_)) =
    (if !switch then []
 	        else (characters ("("^makeString(!counter)^")CALL "))::
       		     [(characters name),
		      (openParen "(")]@
		       objectListToWords(params)@
		     [(closeParen ")"),(characters " with ")]@
	 	      objectListToWords(instList(args,cntxt))
    )


 | processToWords(procGuard(name,switch,counter,avars,avals,pvars,pvals,
			    numvars,cntxt,a,_)) =
    (if !switch then []
	else (characters ("("^(makeString (!counter))^")Match "))::
 	     [(characters name),
	      (openParen "(")]@
       objectListToWords(instPList(instRefList(avals,cntxt),pvars,pvals))@
	      [(closeParen ")"),
	       (characters " to "),
	       (openParen "(")]@
       	       objectListToWords(instList(avars,cntxt))@
	      [(closeParen ")")]
    )


  fun beingTraced(alternative(_,_,_,_,t)) = t
    | beingTraced(guarded(_,_,_,t)) = t
    | beingTraced(selection(_,_,_,t)) = t
    | beingTraced(altGuard(_,_,_,_,_,t)) = t
    | beingTraced(arithWait(_,_,_,_,t)) = t
    | beingTraced(exec(_,_,t)) = t
    | beingTraced(procAlt(_,_,_,_,_,_,_,_,t)) = t
    | beingTraced(procGuard(_,_,_,_,_,_,_,_,_,_,t)) = t



   (******* SCHEDULER functions:  the ones that use the queues ******)


  val schedule = ref(newQueue()): process queue ref



  fun take() = 
	let val proc = QFront(!schedule)
	 in
	   (schedule:=removeQ(!schedule);
	    if !(beingTraced(proc)) 
		then let val w = processToWords(proc)
		      in
			if w=[] then ()
			else (Tracer.plainPrint(w,0);
		              Tracer.panel(beingTraced(proc)))
		     end
		else ();
	    proc)
	end

  fun give(proc)   = schedule:=addToQ(proc,!schedule)
  fun giveQ(procQ) = schedule:=appendQs(!schedule,procQ)
  fun wipeSchedule() = schedule:=newQueue()
  


	(* NOW for the suspension queues.				*)
	(*  simpy enough: It will be an array of 100 process queues	*)
	(* It should have the capability of reclaiming emptied spaces   *)
	(* from awakened processes, and also in size expansion if (when)*)
	(* space runs out....						*)


   val suspensions = ref(array(100,(ref(newQueue():process queue))))
   val freed = ref([]): int list ref
   val nextSlot = ref 0
   val maxSuspended = ref 100

  
   fun resize() =
       let
          val temp = array((!maxSuspended)+100,(ref(newQueue():process queue)))
          val count = ref 0
        in
	  (while (!count)<(!maxSuspended) do
		(update(temp,!count,(!suspensions) sub (!count));
	         count:=(!count)+1);
	   maxSuspended:=(!maxSuspended)+100)
       end

	
	
		 


   fun suspend(proc,~1) =
       (
	if !(beingTraced(proc)) then (print "----Suspend: ";
		                  Tracer.plainPrint(processToWords(proc),13))
			        else ();
        case !freed of
	  a::b => (freed:=b; 
                   update(!suspensions,a,
			  ref(addToQ(proc,!((!suspensions) sub a))));
	           a
		  )
	| nil => (if (!nextSlot)=(!maxSuspended) then resize() else ();
	          update(!suspensions,!nextSlot,
			 ref(addToQ(proc,!((!suspensions) sub !nextSlot))));
		  nextSlot:=(!nextSlot)+1;
	          (!nextSlot)-1
	         )
        )


     | suspend(proc,s) =
       (if !(beingTraced(proc)) then (print "----Suspend: ";
				    Tracer.plainPrint(processToWords(proc),13))
			        else ();
        update(!suspensions,s,ref(addToQ(proc,!((!suspensions) sub s))));
	s)





   fun wakeTrace(nil) = ()
     | wakeTrace(a::b) = 
	(if !(beingTraced(a)) then (print "----Wake: ";
				    Tracer.plainPrint(processToWords(a),10))
			      else ();
         wakeTrace(b))



   fun awake(~1) = ()
     | awake(s) =
	 let val x = !(!suspensions sub s)
	  in
	 (giveQ(!(!suspensions sub s));
	  update(!suspensions,s,ref(newQueue()));
          wakeTrace(QToList(x));
	  freed:=s::(!freed)
	 )
       end      

		(* SUSPENDED: returns a list of processes which *)
		(* are on the suspension queue.	  Used when one *)
		(* wishes to check for deadlock.                *)

   fun suspended() =
	let
	   fun inList(x,nil) = false
	     | inList(x,a::b) = if x=a then true else inList(x,b)

	   fun s(x) = if x=(!nextSlot) then nil
		      else if inList(x,!freed) then s(x+1) 
		      else QToList(!(!suspensions sub x))::s(x+1)
         in
	   s(0)
	end



   fun deSuspend() =
       let
	   fun inList(x,nil) = false
	     | inList(x,a::b) = if x=a then true else inList(x,b)

	   fun s(x) = if x=(!nextSlot) then nil
		      else if inList(x,!freed) then s(x+1)
		      else ((!suspensions sub x):=newQueue(); s(x+1))
        in
	  (ignore(s(0));
	   freed:=[];
	   nextSlot:=0
	  )
       end

end
