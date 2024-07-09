(*
 *
 * $Log: store.fun,v $
 * Revision 1.2  1998/06/03 12:22:34  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* Copyright (c) 1992 by Carnegie Mellon University *)
(* Author: Frank Pfenning <fp@cs.cmu.edu>                 *)
(* Modified: Ekkehard Rohwedder <er@cs.cmu.edu>           *)

functor Store
   (structure Basic : BASIC
    structure Term : TERM
    structure Sb : SB  sharing Sb.Term = Term
    structure Sign : SIGN  sharing Sign.Term = Term
    structure Progtab : PROGTAB  sharing Progtab.Term = Term
       sharing Progtab.Sign = Sign
    structure Solver : SOLVER
       sharing Solver.Term = Term
    structure Constraints : CONSTRAINTS  sharing Constraints.Term = Term
    structure TypeRecon : TYPE_RECON
       sharing TypeRecon.Term = Term
       sharing TypeRecon.Constraints = Constraints
    structure Redundancy : REDUNDANCY
       sharing Redundancy.Term = Term
    structure ElfFrontEnd : ELF_FRONT_END
       sharing ElfFrontEnd.Sign = Sign
    structure Reduce : REDUCE sharing Reduce.Term = Term
    structure Symtab : SYMTAB
       sharing type Symtab.entry = Term.sign_entry
   ) : STORE =
struct

  structure Term = Term
  structure Sign = Sign
  structure Progtab = Progtab

  open Term

  structure Switch =
  struct
    exception UnknownSwitch = Basic.UnknownSwitch

    (* Control *)
    fun control s = raise UnknownSwitch("Store.control",s)

    (* Warning *)
    fun warn s = raise UnknownSwitch("Store.warn",s)

    (* Tracing *)
    fun trace s = raise UnknownSwitch("Store.trace",s)
  end  (* structure Switch *)

  open Switch

  local
    val helpers = ref nil : (unit -> unit) list ref
  in
    fun help () = fold (fn (hf,_) => hf()) (!helpers) ()
    fun addhelp hf = helpers := (hf :: (!helpers))
  end

  datatype topdecl
     = Static of Sign.sign
     | Dynamic of Sign.sign * Progtab.progentry list * Term.sign_entry list

  val topenv = ref (nil : (string * int * topdecl) list)

  val timestamp = ref 0

  fun is_ttype (Term.Type) = true
    | is_ttype _           = false

  fun is_kind (A) =
    let val (_,B) = Reduce.pi_vbds A
     in is_ttype B end

  fun collect_fams sign =
    let fun add_fam 
            (SOME(item as (Term.E(ref {Bind = Term.Varbind(_,A),...})),sign'))
            fams =
               if is_kind A
                  then get_fams sign' (item::fams)
                  else get_fams sign' fams
          | add_fam _ fams = fams
        and get_fams sign fams = add_fam (Sign.sig_item sign) fams
     in get_fams sign nil end

  fun enter_top filename topdecl =
      let fun etop nil = (filename,!timestamp,topdecl)::nil
            | etop ((item as (filename',_,_))::topenv') =
                   if filename = filename'
                   then ((filename,!timestamp,topdecl)::topenv')
                   else item::(etop topenv')
      in topenv := etop (!topenv) end

  fun find_top filename =
      let fun ftop nil = NONE
            | ftop ((item as (filename',_,_))::topenv') =
              if filename = filename'
                 then SOME(item)
                 else ftop topenv'
      in ftop (!topenv) end


  exception NotYetLoaded

  fun find_sig filename =
       (case find_top filename
          of NONE => raise NotYetLoaded
           | SOME(_,_,Static(sign)) => sign
           | SOME(_,_,Dynamic(sign,_,_)) => sign)

  fun topsign () =
      let fun f nil = nil
           |  f ((n,_,_)::t) = n::(f t)
          fun g nil = Sign.empty_sig
           |  g (h::t) = Sign.sig_append (find_sig h) (g t)
      in
        g (rev (f (!topenv)))
      end


  fun get_entry c =
      let fun the_entry (SOME(e)) = Term.Const(e)
            | the_entry (NONE) =
           raise Symtab.Symtab("Special constant "^c^" unknown.")
      in the_entry (Symtab.find_entry c) end

  fun dload_one filename =
    let val sign = ElfFrontEnd.file_read filename
        val _ = (timestamp := !timestamp + 1)
        val prog = ElfFrontEnd.handle_std_exceptions
                      filename (fn () => Progtab.sign_to_prog true sign)
        val closeds = collect_fams sign
     in enter_top filename (Dynamic(sign,prog,closeds)) end

  fun sload_one filename =
    let val sign = ElfFrontEnd.file_read filename
        val _ = (timestamp := !timestamp + 1)
	val prog = ElfFrontEnd.handle_std_exceptions
	              filename (fn () => Progtab.sign_to_prog false sign)
     in enter_top filename (Static(sign)) end


end  (* functor Store *)
