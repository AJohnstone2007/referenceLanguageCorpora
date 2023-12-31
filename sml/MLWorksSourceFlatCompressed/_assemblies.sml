require "../basis/__int";
require "../utils/lists";
require "../utils/intnewmap";
require "../utils/print";
require "../utils/crash";
require "../utils/hashset";
require "../utils/hashtable";
require "../basics/identprint";
require "../typechecker/types";
require "../typechecker/strnames";
require "../typechecker/valenv";
require "../typechecker/tyenv";
require "../typechecker/strenv";
require "../typechecker/environment";
require "../typechecker/namehash";
require "../typechecker/basistypes";
require "../typechecker/assemblies";
functor Assemblies(
structure IdentPrint : IDENTPRINT
structure StrnameSet: HASHSET
structure TyfunSet : HASHSET
structure IntMap : INTNEWMAP
structure Lists : LISTS
structure Print : PRINT
structure Crash : CRASH
structure Conenv : VALENV
structure Types : TYPES
structure Strnames : STRNAMES
structure Tyenv : TYENV
structure Strenv : STRENV
structure Env : ENVIRONMENT
structure NameHash : NAMEHASH
structure HashTable : HASHTABLE
structure Basistypes : BASISTYPES
sharing Strnames.Datatypes = Conenv.Datatypes =
Tyenv.Datatypes = Env.Datatypes =
Types.Datatypes = NameHash.Datatypes =
Basistypes.Datatypes = Strenv.Datatypes
sharing Types.Datatypes.Ident = IdentPrint.Ident
sharing type StrnameSet.element = Types.Datatypes.Strname
sharing type TyfunSet.element = Types.Datatypes.Tyfun
) : ASSEMBLIES =
struct
structure IntMap = IntMap
structure Basistypes = Basistypes
val hash_size = 128
structure Datatypes = Types.Datatypes
open Datatypes
type TypeOffspring = (Ident.TyCon,Tyfun * int) NewMap.map
type StrOffspring = (Ident.StrId,Strname * int) NewMap.map
type StrAssembly =
(Strname * (StrOffspring * TypeOffspring)) list
type TypeAssembly = ((Tyfun * (Valenv * int)) list) IntMap.T
datatype 'a Opt = YES of 'a | NO
exception Assoc = IntMap.Undefined
fun rev_app(acc, []) = acc
| rev_app([], acc) = acc
| rev_app(x :: xs, acc) = rev_app(xs, x :: acc)
infix 5 rev_app
fun assoc(tyfun, []) = raise Assoc
| assoc(tyfun, (tyfun', res) :: rest) =
if Types.tyfun_eq(tyfun, tyfun') then
res
else
assoc(tyfun, rest)
fun tryAssoc(tyfun, []) = NO
| tryAssoc(tyfun, (tyfun', res) :: rest) =
if Types.tyfun_eq(tyfun, tyfun') then
YES res
else
tryAssoc(tyfun, rest)
fun lookup(tyfun, amap) =
let
val the_list = IntMap.apply'(amap, NameHash.tyfun_hash tyfun)
in
assoc(tyfun, the_list)
end
fun tryLookup(tyfun, amap) =
case IntMap.tryApply'(amap, NameHash.tyfun_hash tyfun) of
SOME the_list =>
tryAssoc(tyfun, the_list)
| _ => NO
fun lookup_default(tyfun, default, amap) =
case tryLookup(tyfun, amap) of
YES res => res
| _ => default
fun add_new(elem, a_list) = elem :: a_list
fun usub(acc, [], elem) = elem :: acc
| usub(acc, (elem' as (tyfun', _)) :: rest, elem as (tyfun, _)) =
if Types.tyfun_eq(tyfun, tyfun') then
elem :: (acc rev_app rest)
else
usub(elem' :: acc, rest, elem)
fun update(arg as (tyfun, _), amap) =
let
val hash = NameHash.tyfun_hash tyfun
in
case IntMap.tryApply'(amap, hash) of
SOME the_list =>
IntMap.define(amap, hash, usub([], the_list, arg))
| _ => IntMap.define(amap, hash, [arg])
end
fun rsub(acc, [], _) = acc
| rsub(acc, (elem' as (tyfun', _)) :: rest, tyfun) =
if Types.tyfun_eq(tyfun, tyfun') then
acc rev_app rest
else
rsub(elem' :: acc, rest, tyfun)
fun remove(tyfun, amap) =
let
val hash = NameHash.tyfun_hash tyfun
in
case IntMap.tryApply'(amap, hash) of
SOME [] =>
IntMap.undefine(amap, hash)
| SOME the_list =>
IntMap.define(amap, hash, rsub([], the_list, tyfun))
| _ => amap
end
fun strname_hash(Datatypes.STRNAME id) =
Types.stamp_num id
| strname_hash(Datatypes.NULLNAME id) =
Types.stamp_num id
| strname_hash(Datatypes.METASTRNAME(ref s)) = strname_hash s
fun lookup_str'(strname, []) = raise Assoc
| lookup_str'(strname, a_list) =
let
fun lsub [] = raise Assoc
| lsub((x, y) :: xs) =
if Strnames.strname_eq(strname, x) then y
else lsub xs
in
lsub a_list
end
val empty_str_offspring = NewMap.empty (Ident.strid_lt,Ident.strid_eq)
val empty_type_offspring = NewMap.empty (Ident.tycon_lt,Ident.tycon_eq)
val empty_strassembly = fn _ => []
val empty_tyassembly = IntMap.empty
fun lookup_str(strname, []) = (empty_str_offspring, empty_type_offspring)
| lookup_str(strname, a_list) =
let
fun lsub [] = (empty_str_offspring, empty_type_offspring)
| lsub((x, y) :: xs) =
if Strnames.strname_eq(strname, x) then y
else lsub xs
in
lsub a_list
end
fun trylookup_str(strname, []) = NO
| trylookup_str(strname, a_list) =
let
fun lsub [] = NO
| lsub((x, y) :: xs) =
if Strnames.strname_eq(strname, x) then YES y
else lsub xs
in
lsub a_list
end
fun remove_str(strname, []) = []
| remove_str(strname, a_list) =
let
fun rsub(acc, []) = acc
| rsub(acc, (elem as (x, _)) :: xs) =
if Strnames.strname_eq(strname, x)
then acc rev_app xs
else rsub(elem :: acc, xs)
in
rsub([], a_list)
end
val add_new_str = add_new
fun update_str(elem, []) = [elem]
| update_str(elem as (strname, ran), a_list) =
add_new_str(elem, remove_str(strname, a_list))
exception LookupStrname = Assoc
exception LookupStrId = NewMap.Undefined
exception LookupTyCon = NewMap.Undefined
exception LookupTyfun = Assoc
exception Consistency of string
fun printTyfun_int (tyfun,n) =
"(" ^ (Types.string_tyfun tyfun) ^ "," ^
(Int.toString n) ^ ")\n"
fun stringTypeOffspring amap =
let
val map_list = NewMap.to_list amap
in
case map_list of
[] => ""
| _ =>
concat
("\nTYPE_OFFSPRING \n" ::
((map
(fn (tycon, tyfun_i) =>
concat[IdentPrint.printTyCon tycon, " --> ",
printTyfun_int tyfun_i]) map_list) @ ["\n"]))
end
fun printStrname_int (strname,n) =
"(" ^ (Strnames.string_strname strname) ^ "," ^
(Int.toString n) ^ ")\n"
fun stringStrOffspring amap =
let
val map_list = NewMap.to_list amap
in
case map_list of
[] => ""
| _ =>
concat
("\nSTR_OFFSPRING \n" ::
((map
(fn (strid, str_i) =>
concat[IdentPrint.printStrId strid, " --> ",
printStrname_int str_i]) map_list) @ ["\n"]))
end
fun stringOffspring (stroff,tyoff) =
(stringStrOffspring stroff) ^ "\n" ^
(stringTypeOffspring tyoff) ^ "\n"
fun stringStrAssembly [] = ""
| stringStrAssembly a_list =
concat
(((map
(fn (strname, offs) =>
concat[Strnames.string_strname strname, " |--> ",
stringOffspring offs]) a_list) @ ["\n"]))
val tyfun_length = ref 0
fun print_tyfun (tyfun) =
let
val string_tyfun = (Types.string_tyfun tyfun)
val tyfun_size = size string_tyfun
in
(tyfun_length := tyfun_size;
"\n" ^ string_tyfun)
end
fun str_ce (ce) = Conenv.string_valenv (!tyfun_length + 5,ce)
fun get_name_and_env (_,STR(m,_,e)) = (m,e)
| get_name_and_env (error,_) = Crash.impossible error
fun printCE_int (ce,n) =
"(" ^ (str_ce ce) ^ "," ^ (Int.toString n) ^ ")"
fun stringTypeAssembly ty_ass =
concat
(IntMap.fold
(fn (str_list, _, a_list) =>
Lists.reducel
(fn (str_list, (tyfun, r)) =>
print_tyfun tyfun ^ " | --> " ^ printCE_int r :: str_list)
(str_list, a_list))
([], ty_ass))
val empty_str_offspringp = NewMap.is_empty
val empty_type_offspringp = NewMap.is_empty
fun lookupStrId (strid, amap) =
NewMap.apply'(amap, strid)
fun lookupTyCon (tycon, amap) = NewMap.apply'(amap, tycon)
fun lookupTyfun (tyfun, amap) =
lookup_default(tyfun, (empty_valenv, 0), amap)
val getStrIds = NewMap.domain_ordered
fun inStrOffspringDomain(strid, amap) =
case NewMap.tryApply'(amap, strid) of
NONE => false
| _ => true
val getTyCons = NewMap.domain_ordered
fun inTypeOffspringDomain(tycon, amap) =
case NewMap.tryApply'(amap, tycon) of
NONE => false
| _ => true
fun getStrOffspringMap str_offs = str_offs
fun getTypeOffspringMap ty_offs = ty_offs
fun findStrOffspring(strname, amap : StrAssembly) =
#1 (lookup_str(strname,amap))
fun findTypeOffspring (strname, amap : StrAssembly) =
#2 (lookup_str(strname,amap))
fun str_offsunion(amap, amap') =
let
fun strmap_union(amap, strid, ran as (strname', count')) =
case NewMap.tryApply'(amap, strid) of
SOME (strname, count) =>
NewMap.define(amap, strid, (strname', count + count':int))
| _ => NewMap.define(amap, strid, ran)
in
NewMap.fold strmap_union (amap, amap')
end
fun ty_offsunion (amap, amap') =
let
fun tymap_union(amap, tycon, ran as (tyfun', funcount')) =
case NewMap.tryApply'(amap, tycon) of
SOME (tyfun, funcount) =>
NewMap.define(amap, tycon, (tyfun', funcount + funcount':int))
| _ => NewMap.define(amap, tycon, ran)
in
NewMap.fold tymap_union (amap, amap')
end
fun add_to_StrOffspring (strid,strname,num, amap) =
case NewMap.tryApply'(amap, strid) of
SOME (strname',count) =>
NewMap.define(amap, strid, (strname', count + num:int))
| _ => NewMap.define(amap, strid, (strname, num))
fun add_to_TypeOffspring (tycon,tyfun,num, amap) =
case NewMap.tryApply'(amap, tycon) of
SOME (tyfun', count) =>
NewMap.define(amap, tycon, (tyfun', count+num:int))
| _ =>
NewMap.define(amap, tycon, (tyfun, num))
fun lookupStrname(strname, amap) =
let
val strname' = Strnames.strip strname
in
lookup_str(strname',amap)
end
fun add_to_StrAss(strname, str_offspring, type_offspring, str_assembly) =
let
val strname' = Strnames.strip strname
in
if not (empty_str_offspringp str_offspring
andalso
empty_type_offspringp type_offspring) then
((let
val (str_offspring',type_offspring') =
HashTable.lookup(str_assembly, strname')
in
(HashTable.update(str_assembly, strname',
(str_offsunion (str_offspring',
str_offspring),
ty_offsunion(type_offspring',
type_offspring)));
str_assembly)
end) handle HashTable.Lookup =>
(HashTable.update(str_assembly, strname',
(str_offspring, type_offspring));
str_assembly))
else
str_assembly
end
fun add_to_StrAssembly(strname,str_offspring,type_offspring,
str_assembly as amap) =
let
val strname' = Strnames.strip strname
in
if not (empty_str_offspringp str_offspring
andalso
empty_type_offspringp type_offspring) then
(case trylookup_str(strname', amap) of
YES(str_offspring',type_offspring') =>
update_str((strname',
(str_offsunion(str_offspring', str_offspring),
ty_offsunion(type_offspring', type_offspring))), amap)
| _ => update_str((strname', (str_offspring, type_offspring)), amap))
else
str_assembly
end
fun add_to_TypeAss(tyfun,ce,num,ty_ass) =
if Conenv.empty_valenvp ce then
ty_ass
else
let
val (ce',count) = HashTable.lookup(ty_ass, tyfun)
in
if Conenv.dom_valenv_eq (ce,ce') then
(HashTable.update(ty_ass, tyfun, (ce,count+num:int));
ty_ass)
else
raise Consistency "inconsistent value constructors"
end handle HashTable.Lookup =>
(HashTable.update(ty_ass, tyfun, (ce, num));
ty_ass)
fun add_to_TypeAssembly (tyfun,ce,num,ty_assembly as amap) =
if Conenv.empty_valenvp ce then
ty_assembly
else
case tryLookup(tyfun, amap) of
YES(ce', count) =>
if Conenv.dom_valenv_eq (ce,ce') then
update((tyfun ,(ce,count+num:int)), amap)
else
raise Consistency "inconsistent value constructors"
| _ => update((tyfun, (ce, num)), amap)
fun collectStrOffspring (SE amap,str_offspring) =
let
fun collect (str_offspring, strid, STR(m,_,_)) =
add_to_StrOffspring (strid,m,1,str_offspring)
| collect (str_offspring, strid, COPYSTR((smap,tmap),str)) =
collect (str_offspring,strid,Env.str_copy(str,smap,tmap))
in
NewMap.fold collect (str_offspring, amap)
end
fun collectTypeOffspring (TE amap,type_offspring) =
let
fun collect (type_offspring, tycon, TYSTR(tyfun, _)) =
add_to_TypeOffspring (tycon,tyfun,1,type_offspring)
in
NewMap.fold collect (type_offspring, amap)
end
fun remfromStrAssembly (strname, amap) =
remove_str(strname,amap)
fun remfromTypeAssembly (tyfun, amap) =
case tryLookup(tyfun, amap) of
YES (_, count) => (remove(tyfun, amap), count)
|_ => (amap, 0)
fun te_copy(TE amap, tyname_copies) =
let
fun tystr_copy(_, TYSTR(tyfun, conenv)) =
TYSTR(Types.tyfun_copy (tyfun,tyname_copies), conenv)
in
TE(NewMap.map tystr_copy amap)
end
fun se_copy (SE amap,strname_copies,tyname_copies) =
SE(NewMap.map (fn (_, str) => str_copy (str,strname_copies,tyname_copies)) amap)
and env_copy (ENV (se,te,ve),strname_copies,tyname_copies) =
ENV (se_copy (se,strname_copies,tyname_copies),
te_copy (te,tyname_copies),
ve)
and str_copy (STR(name,r,env),strname_copies,tyname_copies) =
STR(Strnames.strname_copy (name,strname_copies),
r,
env_copy (env,strname_copies,tyname_copies))
| str_copy (COPYSTR(maps,str),strname_copies,tyname_copies) =
let
val (smap,tmap) = Env.compose_maps (maps,(strname_copies,tyname_copies))
in
str_copy (str,smap,tmap)
end
fun expand_str str =
let
fun expand (STR (strid,r,env)) =
STR (strid,r,expand_env env)
| expand (COPYSTR((smap,tmap),str)) =
expand (str_copy (str,smap,tmap))
in
expand str
end
and expand_se (SE se) =
SE (NewMap.map (fn (strid,str) => expand_str str) se)
and expand_env (ENV(se,te,ve)) =
ENV (expand_se se,te,ve)
val expand_str_sans_ve = expand_str
fun subTE (ty_ass, type_offspring, TE amap) =
let
fun do_all ((ty_ass, ty_offsmap),
tycon, TYSTR (tyfun',ce')) =
let
val (tyfun,count) = case NewMap.tryApply'(ty_offsmap, tycon) of
SOME res => res
| _ => (NULL_TYFUN (Types.make_stamp (),(ref(TYFUN(NULLTYPE,0)))),0)
val (ce, count') = HashTable.lookup_default(ty_ass, (ce',0), tyfun)
val new_tyoffs =
case count of
0 => ty_offsmap
| 1 =>
NewMap.undefine(ty_offsmap, tycon)
| _ =>
NewMap.define(ty_offsmap, tycon, (tyfun,count-1))
val _ =
if count' = 0 orelse Conenv.empty_valenvp ce' then
()
else
if count' = 1 then
HashTable.delete(ty_ass, tyfun)
else
HashTable.update(ty_ass, tyfun, (ce,count'-1))
in
(ty_ass, new_tyoffs)
end
in
NewMap.fold do_all ((ty_ass, type_offspring), amap)
end
fun internal_subAssemblies (str_ass, ty_ass, STR(m, _,ENV(se,te,_))) =
if not(Strnames.uninstantiated m) then
let
val (str_offs, ty_offs) =
HashTable.lookup_default
(str_ass, (empty_str_offspring, empty_type_offspring), m)
val (str_offsmap, str_assmap', ty_ass') =
subSE(str_ass, ty_ass, str_offs, se)
val (ty_ass'', ty_offsmap) =
subTE (ty_ass',ty_offs,te)
in
if NewMap.is_empty str_offsmap andalso NewMap.is_empty ty_offsmap then
((HashTable.delete(str_assmap', m);
str_assmap'), ty_ass'')
else
((HashTable.update(str_assmap', m, (str_offsmap,ty_offsmap));
str_assmap'), ty_ass'')
end
else
(str_ass, ty_ass)
| internal_subAssemblies (str_ass,ty_ass,str) =
internal_subAssemblies (str_ass,ty_ass, expand_str_sans_ve str)
and subSE (str_ass, ty_ass, str_offspring, SE amap) =
let
fun do_all ((str_offsmap, str_ass, ty_ass), strid, str) =
let
val (strname, count) =
case NewMap.tryApply'(str_offsmap, strid) of
SOME result => result
| _ =>
(NULLNAME (Types.make_stamp ()),0)
val (str_ass', ty_ass') =
case count of
0 =>
let
in
(str_ass, ty_ass)
end
| _ => internal_subAssemblies(str_ass, ty_ass, str)
in
case count of
0 => (str_offsmap, str_ass', ty_ass')
| 1 =>
(NewMap.undefine(str_offsmap, strid), str_ass', ty_ass')
| _ =>
(NewMap.define(str_offsmap, strid, (strname,count-1)),
str_ass',ty_ass')
end
in
NewMap.fold do_all ((str_offspring, str_ass, ty_ass), amap)
end
fun subAssemblies(str_ass, ty_ass, str) =
let
val str_ass' = HashTable.new(hash_size,Strnames.strname_eq,NameHash.strname_hash)
val ty_ass' = HashTable.new(hash_size,Types.tyfun_eq,NameHash.tyfun_hash)
val _ =
Lists.iterate
(fn (str, ran) => HashTable.update(str_ass', str, ran))
str_ass
val _ =
IntMap.iterate
(fn (i, the_list) =>
Lists.iterate
(fn (tyfun, ran) => HashTable.update(ty_ass', tyfun, ran))
the_list)
ty_ass
val (str_ass', ty_ass') =
internal_subAssemblies(str_ass', ty_ass', str)
in
((HashTable.to_list str_ass'),
HashTable.fold
(fn (ty_ass, tyfun, ran) => update((tyfun, ran), ty_ass))
(empty_tyassembly, ty_ass'))
end
fun subTypeAssembly (tyfun,ce,ty_ass as amap) =
if Conenv.empty_valenvp ce then
ty_ass
else
let
val (ce',count) = lookup(tyfun, amap)
in
if count = 1 then
remove(tyfun, amap)
else
update((tyfun, (ce, count - 1)), amap)
end
fun newTypeAssembly (ENV (se,te as TE amap,_),ty_assembly) =
let
val ty_assembly' = seTypeAssembly (se,ty_assembly)
fun teTypeAssembly (ty_assembly, _, TYSTR (tyfun,ce)) =
add_to_TypeAssembly (tyfun,ce,1,ty_assembly)
in
NewMap.fold teTypeAssembly (ty_assembly', amap)
end
and seTypeAssembly (SE amap,ty_assembly) =
let
fun gather (ty_assembly, strid, STR (_,_,env)) =
newTypeAssembly (env,ty_assembly)
| gather (ty_ass, strid,str) =
gather (ty_ass,strid,expand_str_sans_ve str)
in
NewMap.fold gather (ty_assembly, amap)
end
local
local
fun collect((type_offspring,ty_ass), tycon, TYSTR (tyfun,ce)) =
(add_to_TypeOffspring(tycon,tyfun,1,type_offspring),
add_to_TypeAss(tyfun,ce,1,ty_ass))
in
fun collectTypeInfo(TE amap,ty_offs,ty_ass) =
NewMap.fold collect ((ty_offs,ty_ass), amap)
end
in
fun internal_newAssemblies(strname,ENV (se,te,_),str_ass, ty_ass, allow_meta) =
let
val ok = allow_meta orelse (not(Strnames.uninstantiated strname))
val str_offspring =
if ok then
collectStrOffspring(se,empty_str_offspring)
else
empty_str_offspring
val (type_offspring,ty_ass') =
if ok then
collectTypeInfo(te,empty_type_offspring,ty_ass)
else
(empty_type_offspring, ty_ass)
val str_ass' =
if ok then
add_to_StrAss(strname, str_offspring,type_offspring, str_ass)
else
str_ass
in
collectStrInfo(se,str_ass',ty_ass', allow_meta)
end
and collectStrInfo(SE amap, str_ass, ty_ass, allow_meta) =
NewMap.fold collect ((str_ass,ty_ass, allow_meta), amap)
and collect((str_ass,ty_ass, allow_meta), strid, STR (m,_,env)) =
internal_newAssemblies(m,env,str_ass,ty_ass, allow_meta)
| collect(asses,strid,COPYSTR ((smap,tmap),str)) =
collect(asses,strid,Env.str_copy(str,smap,tmap))
fun newAssemblies(strname, env, allow_meta) =
let
val str_ass' = HashTable.new(hash_size,Strnames.strname_eq,NameHash.strname_hash)
val ty_ass' = HashTable.new(hash_size,Types.tyfun_eq,NameHash.tyfun_hash)
val (str_ass', ty_ass', _) =
internal_newAssemblies(strname, env, str_ass', ty_ass', allow_meta)
in
((HashTable.to_list str_ass'),
HashTable.fold
(fn (ty_ass, tyfun, ran) => update((tyfun, ran), ty_ass))
(empty_tyassembly, ty_ass'))
end
end
fun partition P list =
let
fun part (ys,ns,[]) = (ys, ns)
| part (ys,ns,x::xs) =
if P x
then part(x::ys,ns,xs)
else part(ys,x::ns,xs)
in
part ([],[],list)
end
fun split(news, olds) =
let
val strnames =
Lists.reducel
(fn (set, (x, _)) => StrnameSet.add_member(set, x))
(StrnameSet.empty_set(length olds div 4), olds)
in
partition
(fn (strname, _) => StrnameSet.is_member(strnames, strname))
news
end
fun unionStrAssembly (str_ass, amap') =
let
val (ins, outs) = split(str_ass, amap')
fun union([],str_ass) = str_ass
| union((strname, (str_offs,ty_offs))::strnames,str_ass) =
union(strnames, add_to_StrAssembly(strname,str_offs,ty_offs,
str_ass))
in
outs rev_app union(ins, amap')
end
fun split(news, olds) =
let
val tyfuns =
Lists.reducel
(fn (set, (x, _)) => TyfunSet.add_member(set, x))
(TyfunSet.empty_set(length olds div 4), olds)
in
partition
(fn (tyfun, _) => TyfunSet.is_member(tyfuns, tyfun))
news
end
fun union([],ty_ass) = ty_ass
| union((tyfun, (ce',count'))::tyfuns, alist) =
let
val (ce, count : int) = assoc(tyfun, alist)
in
if Conenv.dom_valenv_eq(ce,ce') then
union(tyfuns, usub([], alist, (tyfun, (ce',count' + count))))
else
raise Consistency"inconsistent value constructors"
end
fun unionTypeAssemblyLists(l1, l2) =
let
val (ins, outs) = split(l1, l2)
in
outs rev_app union(ins, l2)
end
fun unionTypeAssembly(ty_ass, amap') =
let
fun unite_lists(ty_ass, i, the_list) =
case IntMap.tryApply'(ty_ass, i) of
SOME the_list' =>
IntMap.define(ty_ass, i,
unionTypeAssemblyLists(the_list, the_list'))
| _ => IntMap.define(ty_ass, i, the_list)
in
IntMap.fold unite_lists (ty_ass, amap')
end
fun updateTypeAssembly (TE amap,ty_ass) =
let
fun do_all (ty_ass, tycon, TYSTR (tyfun,ce)) =
if Conenv.empty_valenvp ce then
ty_ass
else
add_to_TypeAssembly (tyfun,ce,1,ty_ass)
in
NewMap.fold do_all (ty_ass, amap)
end
fun string_assembly(str_ass, ty_ass) =
stringTypeAssembly ty_ass ^ stringStrAssembly str_ass
fun compose_assemblies(new_ass as (str_ass, ty_ass),
old_ass as (str_ass', ty_ass'),
new_basis as
Basistypes.BASIS(_,_, Basistypes.FUNENV fun_map, _,
ENV(SE se, TE te, _)),
old_basis as
Basistypes.BASIS(_,_, Basistypes.FUNENV fun_map', _,
ENV(se', te', _))) =
let
val old_ass' = NewMap.fold
(fn (arg1 as (str_ass, ty_ass), strid, _) =>
(case Strenv.lookup(strid, se') of
SOME str => subAssemblies(str_ass, ty_ass, str)
| _ => arg1))
(old_ass, se)
val (str_ass', ty_ass') = NewMap.fold
(fn (arg1 as (str_ass, ty_ass), funid, _) =>
(let
val Basistypes.PHI(_, (_, Basistypes.SIGMA(_, str))) =
NewMap.apply'(fun_map', funid)
in
subAssemblies(str_ass, ty_ass, str)
end handle NewMap.Undefined => arg1))
(old_ass', fun_map)
val ty_ass' = NewMap.fold
(fn (ty_ass, tycon, _) =>
(let
val TYSTR(tyfun, valenv) = Tyenv.lookup(te', tycon)
in
subTypeAssembly(tyfun, valenv, ty_ass)
end handle Tyenv.LookupTyCon _ => ty_ass))
(ty_ass', te)
val result =
(unionStrAssembly(str_ass', str_ass), unionTypeAssembly(ty_ass', ty_ass))
in
result
end
fun new_assemblies_from_basis
(Basistypes.BASIS(_,_, Basistypes.FUNENV fun_map, _,
env as ENV(Datatypes.SE se, _, _))) =
let
fun new_str((str_ass, ty_ass), _, str) =
let
val (m,env) = get_name_and_env ("expand_str",expand_str_sans_ve str)
val (str_ass', ty_ass') = newAssemblies(m, env, false)
in
(unionStrAssembly(str_ass, str_ass'),
unionTypeAssembly(ty_ass, ty_ass'))
end
fun new_fun_result((str_ass, ty_ass), _,
Basistypes.PHI(_, (_, Basistypes.SIGMA(_, str)))) =
let
val (m,env) = get_name_and_env ("expand_str",expand_str_sans_ve str)
val (str_ass', ty_ass') = newAssemblies(m, env, false)
in
(unionStrAssembly(str_ass, str_ass'),
unionTypeAssembly(ty_ass, ty_ass'))
end
in
NewMap.fold
new_fun_result
(NewMap.fold
new_str
((empty_strassembly(),
newTypeAssembly(env, empty_tyassembly)),
se),
fun_map)
end
fun new_assemblies_from_basis_inc_sig
(Basistypes.BASIS(_,_, Basistypes.FUNENV fun_map, _,
env as ENV(Datatypes.SE se, _, _))) =
let
fun new_str((str_ass, ty_ass), _, str) =
let
val (m,env) = get_name_and_env ("expand_str",expand_str_sans_ve str)
val (str_ass', ty_ass') = newAssemblies(m, env, true)
in
(unionStrAssembly(str_ass, str_ass'),
unionTypeAssembly(ty_ass, ty_ass'))
end
fun new_fun_sig((str_ass, ty_ass), funid, Basistypes.PHI(_, (str, _))) =
let
val (m,env) = get_name_and_env ("expand_str",expand_str_sans_ve str)
val (str_ass', ty_ass') = newAssemblies(m, env, true)
in
(unionStrAssembly(str_ass, str_ass'),
unionTypeAssembly(ty_ass, ty_ass'))
end
in
NewMap.fold
new_fun_sig
(NewMap.fold
new_str
((empty_strassembly(),
newTypeAssembly(env, empty_tyassembly)),
se),
fun_map)
end
val newAssemblies = fn (strname, env) => newAssemblies(strname, env, true)
end
;
