(*
 *
 * $Log: symtab.fun,v $
 * Revision 1.2  1998/06/03 12:07:30  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* Copyright (c) 1991 by Carnegie Mellon University *)
(* Author: Spiro Michaylov <spiro@cs.cmu.edu>       *)
(* Modified: Amy Felty                              *)

(* Symbol table *)

functor Symtab (type entry
		structure Hash : HASH
                structure Hasher : HASHER) : SYMTAB =
struct

type entry = entry
structure Hash = Hash
structure Hasher = Hasher

exception Symtab of string

local val transactions : (string * string * entry * entry option) list ref
                         = ref nil
in

  val global = "top"

  val modenv = ref [global]

  val symtabs : (string * (string,entry) Hash.table) list ref = ref nil

  fun put_symtab modname table = (symtabs := (modname,table)::(!symtabs))

  fun new_symtab modname =
          put_symtab modname
		     (Hash.create Hash.defaultEqual Hash.defaultSize nil)

  val _ = new_symtab global

  fun get_symtab modname =
	let fun lookup ((modname',table)::symtabs') =
		  if (modname = modname')
		     then table
		     else lookup symtabs'
	      | lookup nil =
                  raise Symtab("Can't find to symbol table for " ^ modname)
	 in lookup (!symtabs) end

  fun use_symtabs modnames = modenv := modnames @ (!modenv)

  fun unuse_symtabs modnames =
        let fun unuse nil mods = mods
	      | unuse (m::rmods) (n::mods) =
		    if (m = n)
		    then unuse rmods mods
		    else raise Symtab("Can't remove " ^ m ^
		      " from module environment beginning with " ^ n)
	      | unuse _ _ = raise
		Symtab("Can't remove from empty module environment")
	 in modenv := unuse modnames (!modenv)
	end

  fun find_entry_from modname key = Hash.lookup (get_symtab modname) key

  fun find_entry name = 
	  let val hashval = Hasher.hashString name
              fun trytables (modname::rest) =
		     (case (find_entry_from modname (name,hashval))
		        of NONE => trytables rest
                         | SOME(r) => SOME(r))
		| trytables nil = NONE
           in trytables (!modenv)
	  end

  fun delete_sym_from modname name =
          let val hashtab = get_symtab modname
	      val hashval = Hasher.hashString name
	      fun extract (SOME(id)) =
		  ( Hash.remove hashtab (name,hashval) ; id)
		| extract NONE = raise Symtab("Can't find to delete")
	   in ignore(extract (Hash.lookup hashtab (name,hashval))) ;
	      ()
	  end

  fun delete_sym name = delete_sym_from global name

  fun add_entry_to' modname name entry conflict_fun =
       let val hashval = Hasher.hashString name 
           val hashtab = get_symtab modname
	   val current = Hash.lookup hashtab (name,hashval)
	in
	   case current 
	     of NONE => ( Hash.enter hashtab (name,hashval) entry ; 
			  transactions :=
			   ((modname,name,entry,NONE)::(!transactions)) ; 
			   () )
	      | SOME(r) => ( ignore(conflict_fun r) ;
			     Hash.remove hashtab (name,hashval) ;
			     Hash.enter hashtab (name,hashval) entry ; 
			     transactions :=
			      ((modname,name,entry,SOME(r))::(!transactions)); 
			      () )
       end

  fun add_entry' name entry conflict_fun = 
       add_entry_to' global name entry conflict_fun

  fun add_entry_to modname name entry =
       add_entry_to' modname name entry (fn _ => ())

  fun add_entry name entry =
       add_entry_to' global name entry (fn _ => ())

  fun clean () =
       let val table = (get_symtab global)
	in (Hash.eliminate table (fn x => fn y => true) ;
	    modenv := [global] ;
	    symtabs := [(global,table)] ;
	    ())
       end

  fun checkpoint () =
         (case !transactions 
	    of (nil) => ()
	     | (_::_) => ( print "%WARNING: Recursive symbol table transactions\n" ;
			   transactions := nil )) 

  fun rollback () =
       let fun rb nil = ()
	     | rb ((modname,name,entry,maybe_shadowed) :: rest) = 
	       let val hashval = Hasher.hashString name 
		   and hashtab = get_symtab modname
	        in 
		    Hash.remove hashtab (name,hashval) ;
		    (case maybe_shadowed
			 of NONE => ()
		          | SOME(r) => Hash.enter hashtab (name,hashval) r ; 
				       () ) ;
		    rb rest
	       end	
        in 
	   rb (!transactions) ; transactions := nil
       end

  fun commit () = transactions := nil
     
end  (* local ... *)
end  (* functor Symtab *)
