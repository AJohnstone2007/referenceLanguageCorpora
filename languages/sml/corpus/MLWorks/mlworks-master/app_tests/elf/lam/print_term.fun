(*
 *
 * $Log: print_term.fun,v $
 * Revision 1.2  1998/06/03 12:13:14  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* Copyright (c) 1991 by Carnegie Mellon University *)
(* Author: Frank Pfenning <fp@cs.cmu.edu>           *)

(* Printing, allowing for infix, prefix, postfix operators *)

functor PrintTerm (structure Basic : BASIC
		   structure Term : TERM
		   structure Sb : SB
		      sharing Sb.Term = Term
		   structure Symtab : SYMTAB
		      sharing type Symtab.entry = Term.sign_entry
		   structure Naming : NAMING
		      sharing Naming.Term = Term
		   structure F : FORMATTER
		   structure S : SYMBOLS
		      sharing S.F = F
		   structure PrintVar : PRINT_VAR
		      sharing PrintVar.Term = Term
		   val use_fixity : bool) : PRINT_TERM =
struct

structure Term = Term
structure F = F
structure S = S

local open Term
      open F
in

  val printDepth = ref (NONE:int option)
  val printLength = ref (NONE:int option)

  fun op_name (se as Term.E(ref {Bind = Varbind(x,_), ...})) =
	 let fun shadowed_by (SOME se') = not (se = se')
	       | shadowed_by _ = false
	     val exists_var = (case (Naming.lookup_varname x)
				   of SOME(_) => true
				    | NONE => false)
	  in
	     if exists_var orelse (shadowed_by (Symtab.find_entry x))
		then "%" ^ x ^ "%"
		else x
	 end
    | op_name (Term.Int(n)) = makestring n
    | op_name (Term.String(str)) = "\"" ^ str ^ "\""
    | op_name (Term.IntType) = "int"
    | op_name (Term.StringType) = "string"

  (* se_name quotes infix, prefix, and postfix operators *)

  fun se_name (se as Term.E(ref {Fixity = ref (SOME _), ...})) =
	"'" ^ op_name se ^ "'"   (* always correct? *)
    | se_name se = op_name se

  val se_name = if use_fixity then se_name else op_name

  fun exceeded (_,NONE) = false
    | exceeded (n:int,SOME(m:int)) = n >= m

  datatype ctxt = Ctxt of (fixity * int) * F.format list * int
  datatype opargs = OpArgs of (fixity * int) * F.format list * term list

  val no_ctxt = Ctxt ((Prefix, fixity_min - 4), [], 0)

  (* braces and brackets are a ~3 Prefix *)
  val braces_prec = fixity_min - 3
  val brackets_prec = fixity_min - 3

  fun colon (M,A) =
	 OpArgs((Infix(Left),fixity_min - 2),
		[Break, String S.colon, Space], [M,A])

  fun arrow (A1,A2) =
	 OpArgs((Infix(Right),fixity_min - 1),
		[Break, String S.rightarrow, Space], [A1,A2])

  val appl_prec = fixity_max + 1

  fun appl(M1,M2) =
	 OpArgs((Infix(Left),appl_prec), [Break], [M1,M2])

  fun infixity (Evar(_,_,_,ref (SOME M0))) = infixity M0
    | infixity (Const (se as E(ref {Fixity = ref(SOME(fpr as (Infix _,_))), ...}))) =
	 SOME (fpr, [Break, String(S.const(op_name se)), Space])
    | infixity _ = NONE

  val infixity = if use_fixity then infixity else (fn _ => NONE)

  fun pfixity (Evar(_,_,_,ref (SOME M0))) = pfixity M0
    | pfixity (Const (se as E(ref {Fixity = ref(SOME(fpr as (Prefix,_))), ...}))) =
	  SOME (fpr, [String(S.const(op_name se)), Break])
    | pfixity (Const (se as E(ref {Fixity = ref(SOME(fpr as (Postfix,_))), ...}))) =
	  SOME (fpr, [Break, String(S.const(op_name se))])
    | pfixity _ = NONE

  val pfixity = if use_fixity then pfixity else (fn _ => NONE)

  fun has_fixity (Evar(_,_,_,ref (SOME M0))) = has_fixity M0
    | has_fixity (Const(E(ref {Fixity = ref(SOME _), ...}))) = true
    | has_fixity _ = false

  val has_fixity = if use_fixity then has_fixity else (fn _ => false)

  fun opargs (Evar(_,_,_,ref (SOME M0))) M2 = opargs M0 M2
    | opargs (M1 as Bvar _) M2 = appl(M1,M2)
    | opargs (M1 as Evar _) M2 = appl(M1,M2)
    | opargs (M1 as Uvar _) M2 = appl(M1,M2)
    | opargs (M1 as Fvar _) M2 = appl(M1,M2)
    | opargs (M1 as Pi _) M2 = appl(M1,M2)  (* cannot happen with valid terms *)
    | opargs (M1 as Appl(M11,M12)) M2 =
	 (case infixity(M11)
	    of SOME (fpr,fmts) => OpArgs(fpr, fmts, [M12,M2])
	     | NONE => appl(M1,M2))
    | opargs (M1 as Abst _) M2 = appl(M1,M2)
    | opargs (M1 as Const _) M2 =
	 (case pfixity(M1)
	    of SOME (fpr,fmts) => OpArgs(fpr, fmts, [M2])
	     | NONE => appl(M1,M2))
    | opargs (M1 as Wild) M2 = appl(M1,M2)
    | opargs (M1 as Type) M2 = appl(M1,M2)  (* cannot happen on valid terms *)
    | opargs (M1 as HasType _) M2 = appl(M1,M2)
    | opargs (Mark(_,M1)) M2 = opargs M1 M2

  fun ellide (l) = case !printLength
		     of NONE => false
		      | SOME(l') => (l > l')

  fun addots (l) = case !printLength
		     of NONE => false
		      | SOME(l') => (l = l')

  fun parens (p':int) (p:int) fmt =
	 if p' >= p
	    then Hbox [String S.lparen, fmt, String S.rparen]
	    else fmt

  fun add_accum fmt _ nil = fmt
    | add_accum fmt (Infix(Left)) accum = HVbox ([fmt] @ accum)
    | add_accum fmt (Infix(Right)) accum = HVbox (accum @ [fmt])  (* Expense! *)
    | add_accum fmt (Prefix) accum = HVbox (accum @ [fmt])
    | add_accum fmt (Postfix) accum = HVbox ([fmt] @ accum)
    | add_accum fmt (Infix(None)) accum =
	 raise Basic.Illegal("add_accum: no associativity")

  fun aa (Ctxt ((fixity,p), accum, l)) fmt =
	 if (p = appl_prec) andalso (fixity = Infix(Left))
	        andalso (#2 (Width fmt) < 4)
	    then (* special case: application with `short' operator *)
		 (* first element of accum must be Break *)
		 Hbox [fmt, HVbox0 1 1 1 (Space::tl accum)]
	    else add_accum fmt fixity accum

  fun names_const x =
	(case (Symtab.find_entry x)
	   of NONE => false
	    | SOME _ => true)

  fun names_var x =
        (case (Naming.lookup_varname x)
	   of NONE => false
	    | SOME _ => true)

  fun names_occurring_var x M =
        (case (Naming.lookup_varname x)
	   of NONE => false
            | SOME(y) => Sb.occurs_in y M)

  (* Rename bound variables if they might shadow a constant *)
  fun maybe_rename (xofA_M as (xofA as Varbind(x,A),M)) =
	if (x = anonymous) orelse (names_const x)
	      orelse (names_occurring_var x M)
	   then let val (xofA',sb) = (Sb.rename_sb xofA_M Sb.id_sb)
		 in maybe_rename (xofA',Sb.renaming_apply_sb sb M) end
	   else xofA_M

  fun member x l =
      let fun mem nil = false
	    | mem (y::l) = (x = y) orelse mem l
       in mem l end

  fun varname_conflict vs =
      (fn x => (names_const x) orelse (names_var x) orelse (member x vs))

  fun mst_varbind vs d (Varbind(name,A)) = 
	 HVbox [String(S.var(name)), String S.colon,
		mst_term vs (d+1) no_ctxt A]

  and mst_term vs d ctx (M as Bvar(x)) =
         aa ctx (String(S.var(PrintVar.makestring_var (fn x => false) M)))
    | mst_term vs d ctx (M as Evar(Varbind(x,A),stamp,uvars,ref NONE)) =
         aa ctx (String(S.const(PrintVar.makestring_var
				(varname_conflict vs) M)))
    | mst_term vs d ctx (M as (Evar(_,_,_,ref (SOME M0)))) =
	 mst_term vs d ctx M0
    | mst_term vs d ctx (M as Uvar(Varbind(x,_),stamp)) =
	 aa ctx (String(S.const(PrintVar.makestring_var
				(varname_conflict vs) M)))
    | mst_term vs d ctx (M as Fvar(Varbind(x,_))) =
         aa ctx (String(S.const(PrintVar.makestring_var (fn x => false) M)))
    | mst_term vs d ctx (Pi((xofA as Varbind(x,A),B),occ)) =
	 if (occ = Maybe) andalso (Sb.free_in xofA B)
	    then let val (xofA_B' as (Varbind(x',A'), B')) =
		             maybe_rename (xofA,B)
		  in mst_level (x'::vs) d ctx (braces vs d xofA_B') end
	    else mst_level vs d ctx (arrow(A,B))
    | mst_term vs d ctx (M as Appl(Const _,Abst _)) =
         bind_prefix vs d ctx M
    | mst_term vs d ctx (M as Appl(M1,M2)) =
	 mst_level vs d ctx (opargs M1 M2)
    | mst_term vs d ctx (Const se) = aa ctx (String (S.const(se_name se)))
    | mst_term vs d ctx (Abst(xofA,M)) = 
         let val (xofA_M' as (Varbind(x',A'), M')) = maybe_rename (xofA,M)
	  in mst_level (x'::vs) d ctx (brackets vs d xofA_M') end
    | mst_term vs d ctx (Wild) = aa ctx (String S.underscore)
    | mst_term vs d ctx (Type) = aa ctx (String (S.const("type")))
    | mst_term vs d ctx (HasType(M,A)) =
	 mst_level vs d ctx (colon(M,A))
    | mst_term vs d ctx (Mark(_,M)) = mst_term vs d ctx M

  and mst_term' vs d ctx M =
	 if exceeded(d,!printDepth)
	    then String S.pctpct
	    else mst_term vs d ctx M

  and mst_level vs d (Ctxt ((fixity',p'), accum, l))
		  (OpArgs (fixity as (Infix(Left),p), fmts, [M1,M2])) =
	 let val acc_more = (fixity' = Infix(Left)) andalso (p = p')
	     val rhs = if acc_more andalso ellide(l) then []
		       else if acc_more andalso addots(l) then fmts @ [String S.ldots]
		       else fmts @ [mst_term' vs (d+1) (Ctxt ((Infix(None),p),nil,0)) M2]
	  in
	     if acc_more
		then mst_term' vs d (Ctxt (fixity, rhs @ accum, l+1)) M1
		else let val both = mst_term' vs d (Ctxt (fixity, rhs, 0)) M1
		      in add_accum (parens p' p both) fixity' accum end
	 end

    | mst_level vs d (Ctxt ((fixity',p'), accum, l))
		  (OpArgs (fixity as (Infix(Right), p), fmts, [M1,M2])) =
	 let val acc_more = (fixity' = Infix(Right)) andalso (p = p')
	     val lhs = if acc_more andalso ellide(l) then []
		       else if acc_more andalso addots(l) then [String S.ldots] @ fmts
		       else [mst_term' vs (d+1) (Ctxt ((Infix(None),p),nil,0)) M1] @ fmts
	  in
	     if acc_more
		then mst_term' vs d (Ctxt (fixity, accum @ lhs, l+1)) M2
		else let val both = mst_term' vs d (Ctxt (fixity, lhs, 0)) M2
		      in add_accum (parens p' p both) fixity' accum end
	 end

    | mst_level vs d (Ctxt ((fixity',p'), accum, l))
		  (OpArgs (fixity as (Infix(None), p), fmts, [M1,M2])) =
	 let val lhs = mst_term' vs (d+1) (Ctxt (fixity, nil, 0)) M1
	     val rhs = mst_term' vs (d+1) (Ctxt (fixity, nil, 0)) M2
	  in
	     add_accum (parens p' p (HVbox ([lhs] @ fmts @ [rhs]))) fixity' accum
	 end

    | mst_level vs d (Ctxt ((fixity',p'), accum, l))
		  (OpArgs (fixity as (Prefix, p), fmts, [M])) =
	 let val acc_more = (fixity' = Prefix) andalso (p = p')
	     val pfx = if acc_more andalso ellide(l) then []
		       else if acc_more andalso addots(l) then [String S.ldots, Break]
		       else fmts
	  in
	     if acc_more
		then mst_term' vs d (Ctxt (fixity, accum @ pfx, l+1)) M
		else let val whole = mst_term' vs d (Ctxt (fixity, pfx, 0)) M
		      in add_accum (parens p' p whole) fixity' accum end
	 end

    | mst_level vs d (Ctxt ((fixity',p'), accum, l))
		  (OpArgs (fixity as (Postfix,p), fmts, [M])) =
	 let val acc_more = (fixity' = Postfix) andalso (p = p')
	     val pfx = if acc_more andalso ellide(l) then []
		       else if acc_more andalso addots(l) then [Break, String S.ldots]
		       else fmts
	  in
	     if acc_more
		then mst_term' vs d (Ctxt (fixity, pfx @ accum, l+1)) M
		else let val whole = mst_term' vs d (Ctxt (fixity, pfx, 0)) M
		      in add_accum (parens p' p whole) fixity' accum end
	 end

    | mst_level vs d (Ctxt _) (OpArgs _) = 
	 raise Basic.Illegal("mst_level: inconsistent arguments")

  (* special cases: binding prefixes *)
  and braces vs d (xofA,B) =
	 OpArgs((Prefix,braces_prec),
		S.pi_quant (mst_varbind vs d xofA) @ [Break], [B])

  and brackets vs d (xofA,M) =
	 OpArgs((Prefix,brackets_prec),
		S.lam_abs (mst_varbind vs d xofA) @ [Break], [M])

  (* user-defined binders, e.g. (forall [x:i] exists [y:i] F) *)
  (* similar let-binder (let E1 [x] let E2 [y] E3) not treated right now *)
  and bind_prefix vs d (ctx as Ctxt((fixity,p),_,_))
         (Appl(c as Const(se),N as Abst(xofA as Varbind(x,A),M))) =
         (if ((p = appl_prec) andalso (fixity = Infix(Left)))
	      orelse (has_fixity c)
	     then mst_level vs d ctx (opargs c N)
             else mst_level (x::vs) d ctx
		     (OpArgs((Prefix,brackets_prec),
			     [String(S.const(op_name se)), Space]
			       @ S.lam_abs (mst_varbind vs d xofA)
			       @ [Break],
			     [M])))
    | bind_prefix vs d ctx M =
         raise Basic.Illegal("bind_prefix: unexpected arguments")

  fun makeformat_term M = mst_term nil 0 no_ctxt M
  fun makeformat_const (Const se) = String (S.const (se_name se))
    | makeformat_const _ = raise Basic.Illegal("makeformat_const: not a constant")

end  (* local ... *)
end  (* functor PrintFixity *)
