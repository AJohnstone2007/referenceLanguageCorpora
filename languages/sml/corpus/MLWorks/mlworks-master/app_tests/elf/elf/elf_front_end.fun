(*
 *
 * $Log: elf_front_end.fun,v $
 * Revision 1.2  1998/06/03 12:28:32  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* Copyright (c) 1991 by Carnegie Mellon University *)
(* Author: Frank Pfenning <fp@cs.cmu.edu>           *)

(* Puts the pieces of the front end together *)

functor ElfFrontEnd
   (include sig
     structure Basic : BASIC
     structure Term  : TERM
     structure Sb    : SB  sharing Sb.Term = Term
     structure Reduce : REDUCE  sharing Reduce.Term = Term
     structure Print : PRINT  sharing Print.Term = Term
     structure Sign  : SIGN  sharing Sign.Term = Term
     structure Trail : TRAIL sharing Trail.Term = Term
     structure Constraints : CONSTRAINTS  sharing Constraints.Term = Term
     structure TypeRecon : TYPE_RECON 
       sharing TypeRecon.Term = Term
       sharing TypeRecon.Sb = Sb
       sharing TypeRecon.Constraints = Constraints
     structure Interface : INTERFACE
     structure Absyn : ABSYN  sharing Absyn.Term = Term
     structure ElfParse : ELF_PARSE  sharing ElfParse.ElfAbsyn.Term = Term
     structure Symtab : SYMTAB
       sharing type Symtab.entry = Term.sign_entry
     structure Naming : NAMING
       sharing Naming.Term = Term
     structure Redundancy : REDUNDANCY
       sharing Redundancy.Term = Term
   end where type Interface.pos = int) : ELF_FRONT_END =
struct

structure Term = Term
structure Sign = Sign
structure Constraints = Constraints

local open Term
      structure Parse = ElfParse.Parse
      structure ElfAbsyn = ElfParse.ElfAbsyn      
in

  exception FrontEnd of string

  val echo_declarations = ref true
  fun maybe_echo (func : unit -> string) =
         if (!echo_declarations)
	    then print (func ())
	    else ()

  val warn_redeclaration = ref false
  val warn_implicit = ref true

  fun wrap_location filename lrpos msg_type msg =
    let val msg_prefix =
              filename ^ ":" 
	      ^ (Interface.makestring_region (Interface.region lrpos))
	      ^ " " ^ msg_type ^ ": "
     in
        if (size msg_prefix) + (size msg) > 80
	   then msg_prefix ^ "\n" ^ msg
	   else msg_prefix ^ msg
    end

  fun nonempty nil = false
    | nonempty _ = true

  fun sep (s1,s2) = s1 ^ " " ^ s2

  fun store_entry sign (bvars,cofA as Varbind(cname,A)) filename lrpos =
      let fun maybe_warn_redeclaration (oldentry) =
	         if !warn_redeclaration
		    then print (wrap_location filename lrpos "Warning"
				 ("Redeclared constant " ^ cname ^ "\n"))
		    else ()

	  val _ = Naming.reset_varnames ()
	  val A0 = Sb.apply_sb (Sb.new_fvar_sb bvars) A
	  val (A',_,con) = TypeRecon.type_recon_as A0 (Type)

	  val (env,A'') = TypeRecon.abst_over_evars bvars
			     TypeRecon.empty_env
			     (Reduce.beta_norm A')
	  val r = ref {Bind = Varbind("dummy",Wild), Full = Wild,
		       Defn = NONE, Dyn = ref false, Prog = ref NONE,
		       Fixity = ref NONE, NamePref = ref NONE,
		       Inh = nil, Syn = nil}
	  val sigentry = (E(r))
	  val (A''',syndef) = TypeRecon.env_to_pis env A'' (Const(sigentry))

	  (* At this point, all Evar's have been dereferenced. *)
	  val _ = Trail.erase_trail ()

	  val cofA' = Varbind(cname,A''')
	  val _ = maybe_echo (fn () => Print.makestring_conbind cofA' ^ "\n")
	  val ((inh, syn),warnings) = Redundancy.analyze A''' syndef
	  val _ = if (!warn_implicit andalso (nonempty warnings))
	             then print (wrap_location filename lrpos "Warning"
				 ("Implicit arguments cannot be synthesized or inherited for: " 
				  ^ fold sep warnings "\n"))
		     else ()
	  val _ = if Constraints.is_empty_constraint con
		     then ()
		     else print (wrap_location filename lrpos "Error"
				   ("Constraints remaining after type reconstruction on constant " ^ cname ^ " :\n" 
				    ^ (Constraints.makestring_constraint con)
				    ^ "\n"))
       in ( r := {Bind = cofA', Full = syndef, Defn = NONE,
		  Dyn = ref false, Prog = ref NONE,
		  Fixity = ref NONE, NamePref = ref NONE,
		  Inh = inh, Syn = syn} ;
	    Symtab.add_entry' cname sigentry maybe_warn_redeclaration ;
	    Sign.add_sig(sigentry,sign) )
      end

  fun approx_location (SOME(error_lrpos)) _ = error_lrpos
    | approx_location NONE decl_lrpos = decl_lrpos

  fun store_entry' sign (raw_entry as (bvars,Varbind(c,_))) filename lrpos =
         store_entry sign raw_entry filename lrpos
	 handle TypeRecon.TypeCheckFail(error_lrpos,msg) =>
		   raise FrontEnd(wrap_location filename
				  (approx_location error_lrpos lrpos)
				  "Error"
			          ("Type checking failed on declaration of "
				   ^ c ^ "\n" ^ msg))

  fun update_fixity (fix_prec as (fixity,prec))
		    (se as E (ref {Fixity = fpr_ref, ...})) =
	 ( maybe_echo (fn () =>
	      ("%%" ^
		  (case fixity of Infix(Left) => "infix left"
				| Infix(Right) => "infix right"
				| Infix(None) => "infix none"
				| Prefix => "prefix"
				| Postfix => "postfix")
		  ^ " " ^ (makestring prec)
		  ^ " " ^ (Print.makestring_const (Const(se)))
		  ^ "\n")) ;
	  fpr_ref := SOME(fix_prec) )
    | update_fixity _ _ =
         raise Basic.Illegal("update_fixity: arg is basic constant")

  fun update_name_pref (se as E (ref {NamePref = names_ref, ...})) names =
	 ( maybe_echo (fn () => ("%%name " ^ (Print.makestring_const (Const(se)))
		  ^ "  " ^ (fold (fn (x,s) => x ^ " " ^ s) names "") ^ "\n")) ;
	   names_ref := SOME(names) ) 
    | update_name_pref _ _ =
         raise Basic.Illegal("update_name_pref: arg is basic constant")

  fun warn_constraints con =
         if Constraints.is_empty_constraint con
	    then ()
	    else ( print (wrap_location "\nstd_in" (0,0) "Warning"
			 ("Constraints remaining after type reconstruction on the query:\n"
			  ^ Constraints.makestring_constraint con ^ "\n")) )

  fun bvars_to_evars bvars M =
      let val vbds = map (fn x => Varbind(x,Sb.new_evar Sb.generic_type nil))
	                 bvars
	  val _ = Naming.reset_varnames ()
	  val nesb = Sb.new_named_evar_sb vbds nil
       in (Sb.apply_sb nesb M, nesb) end

  fun create_query sign (bvars,HasType(M,A)) =
      let val (M_A',nesb) = bvars_to_evars bvars (HasType(M,A))
	  val (M',A',con) = TypeRecon.type_recon (M_A')
	  val _ = warn_constraints con
       in (map (Sb.apply_sb nesb) (map Bvar bvars),HasType(M',A'),con) end
    | create_query sign (bvars,Mark(_,M)) = create_query sign (bvars,M)
    | create_query sign (bvars,A) =
      let val (A',nesb) = bvars_to_evars bvars A
	  val (A'',_,con) = TypeRecon.type_recon_as A' (Type)
	  val _ = warn_constraints con
       in (map (Sb.apply_sb nesb) (map Bvar bvars),A'',con) end

  fun handle_std_exceptions whereloc (func) =
     func ()
      handle e as TypeRecon.TypeCheckFail(error_lrpos,msg) =>
		( print (wrap_location whereloc 
			 (approx_location error_lrpos (0,0))
			 "Error"
			 "Type checking failed\n" ^ msg ^ "\n") ;
		  raise e )
           | e as FrontEnd(msg) =>
	        ( print (msg ^ "\n") ; raise e )
	   | e as ElfParse.Parse.ParseError(lrpos,msg) =>
		( print (wrap_location whereloc lrpos "Error" (msg ^ "\n")) ;
		  raise e )
	   | e as Absyn.UndeclConst(lrpos,cname) =>
		( print (wrap_location whereloc lrpos "Error"
			    ("Undeclared constant " ^ cname ^ "\n")) ;
		  raise e )
           | e as Absyn.AbsynError(lrpos,msg) =>
	        ( print (wrap_location whereloc lrpos "Error"
			    ("Abstract syntax error: " ^ msg ^ "\n")) ;
		  raise e )
	   | e as Absyn.FixityError(lrpos,msg) =>
		( print (wrap_location whereloc lrpos "Error"
			    ("Parsing error: " ^ msg ^ "\n")) ;
		  raise e )
	   | e as Io{function=msg, ...} =>
		( print (msg ^ "\n") ; raise e )
           | e as Sb.LooseBvar(M) =>
		( print ("Loose Bvar: " ^ Print.makestring_term M ^ "\n") ;
		  raise e )
	   | e as Basic.Illegal(msg) =>
		( print (msg ^ "\n") ; raise e )	 
	   | e as Symtab.Symtab(msg) =>
		( print ("Symbol table : " ^ msg ^ "\n") ; raise e )	 

  fun sig_clean () = Symtab.clean ()

  fun sig_read_fun filename =
      let val (close_func,token_stream) = Parse.file_open filename
	  fun parse_entries token_stream sign =
	      let fun pe (SOME(ElfAbsyn.ParsedSigentry(sigentry,lrpos),rest_stream)) =
			 parse_entries rest_stream (store_entry' sign sigentry filename lrpos)
		    | pe (SOME(ElfAbsyn.ParsedQuery(freevars,A),_)) =
		         raise Parse.ParseError((0,0),"Expected signature entry, found query.")
		    | pe (SOME(ElfAbsyn.ParsedFixity(fix_prec,sigentries),rest_stream)) =
			 ( app (update_fixity fix_prec) sigentries ;
			   parse_entries rest_stream sign )
		    | pe (SOME(ElfAbsyn.ParsedNamePref(sigentry,names),rest_stream)) =
			 ( update_name_pref sigentry names ;
			   parse_entries rest_stream sign )
		    | pe (NONE) = ( close_func () ; sign )
	       in pe (Parse.file_parse token_stream) end
	  val _ = Symtab.checkpoint ()
	  val s = parse_entries token_stream Sign.empty_sig
		  handle exn => ( close_func () ; Symtab.rollback() ; raise exn ) 
	  val _ = Symtab.commit ()
       in s end

  fun file_read filename =
      handle_std_exceptions filename (fn () =>
	sig_read_fun filename)

  fun cq' (SOME(ElfAbsyn.ParsedQuery(result))) =
	    SOME(create_query Sign.empty_sig result)
    | cq' (SOME _) =
	    raise Parse.ParseError((0,0),"Expected query, found signature entry.")
    | cq' NONE = NONE

  fun interactive_read () =
    cq' (Parse.interactive_parse "?- " "   ")

  type token_stream = Parse.token_stream

  fun cq (SOME(ElfAbsyn.ParsedQuery(result),rest_stream)) =
	    SOME(create_query Sign.empty_sig result,rest_stream)
    | cq (SOME _) =
	    raise Parse.ParseError((0,0),"Expected query, found signature entry.")
    | cq NONE = NONE

  fun stream_init instream echofun =
      Parse.stream_init instream echofun
       
  fun stream_read token_stream =
    cq (Parse.stream_parse token_stream)

end  (* local ... *)
end  (* functor ElfFrontEnd *)
