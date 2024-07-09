(*
 *
 * $Log: load.sml,v $
 * Revision 1.2  1998/06/08 17:25:46  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(*
Status: R

load 				BMM 12-02-91

Loads up eril into New Jersey ML.   

This file is subject to constant update.

*)

use "../nj-compat/nj-compat";

(*Shell.Options.Mode.harlequin();*)

Shell.Options.set(Shell.Options.Language.typeDynamic, false);

local

val SrcDir = "" 

in

fun get_sig s = use (SrcDir^"sigs/"^s);
fun get_module s = use (SrcDir^"modules/"^s);
fun get_experiment s = use (SrcDir^"experiment/"^s);

end ; (* of local *)


get_module "library.sml";

open Library;


(* Input / Output control functions *)

get_module "commonio.sml";

open CommonIO;

get_sig "maybe.sig";
get_module "maybe.sml";
structure Maybe = MaybeFUN () ;
open Maybe ;

get_module "string.sml";
open Strings ;
get_module "termcap.sml";
get_module "t_input.sml";
get_module "t_output.sml";
open Terminal_Output Terminal_Input Termcap ;           

(* Some useful data structures *)

get_module "ordlist.sml";
get_module "assoc.sml";
get_module "interface.sml";

get_module "error.sml";
open Interface Error ;

(* Parsing Tools *)

get_sig "lexical.sig";
get_module "lexical.sml";
get_sig "parser.sig";
get_module "parser.sml";
structure Parse = ParseFUN (Lex);

(* Pretty Printer *)
get_module "prettyprint.sml";

get_module "transys.sml";
structure TranSys = TranSysFUN () ;

get_sig "help.sig";
get_module "help.sml";
structure Help = HelpFUN();

get_module "menu.sml";
get_module "display_level.sml";

get_module "timer.sml";
get_module "statistics.sml";

(* core engine module signatures *)

get_sig "sort.sig";
get_sig "opsymb.sig";
get_sig "variable.sig";
get_sig "signature.sig";

(* core engine modules - the tools of term rewriting *)

get_module "sort.sml"; 
get_module "opsymb.sml" ;
get_module "variable.sml";

get_module "signature.sml";

(* the Term functor *)
get_sig "term.sig";
get_module "term.sml";

(* paths *)
get_sig "path.sig";
get_module "path.sml";

(* some functions for term orderings *)
get_sig "order.sig" ;
get_module "order.sml" ; 

(* Substitutions *)
get_sig "substitution.sig";
get_module "substitution.sml";

(* some useful tools for AC work *)
get_sig "AC_tools.sig";
get_module "AC_tools.sml";

(* Matching routines *)
get_sig "match.sig";
get_module "ACOSmatch.sml";
get_module "match.sml";

(* diophantine equation solver *)
get_module "dio.sml";  

(* unification routines *)
get_sig "unify.sig";
get_module "ACOSunify.sml";
get_module "OSunify.sml";

(* Equalities and Equality Sets *)
get_sig "equality.sig";
get_module "equality.sml"; 
get_sig "equalityset.sig";
get_module "equalityset.sml";

(* these combine the previous *)
get_sig "Etools.sig";
get_module "Empty_theory.sml";
get_module "AC_theory.sml";

(* for testing sort properties of rules *)
get_sig "sort_preserve.sig";
get_module "sort_preserve.sml";

(* superposition routines *)
get_sig "superpose.sig";
get_module "superpose.sml";

(* generating the C/AC theory *)
get_module "CAC_generate.sml";

(* Rewriting *)
get_sig "rewrite.sig";
get_module "rewrite.sml";

(*  Critical Pairs *)
get_sig "criticalpair.sig";
get_module "criticalpair.sml";

(* setting up the environment *)

get_sig "precedence.sig";
get_module "precedence.sml";

get_sig "weights.sig";
get_module "weights.sml";

get_sig "strategies.sig";
get_module "strategies.sml";

get_sig "local_orders.sig";
get_module "local_orders.sml";

get_sig "i_precedence.sig";
get_module "i_precedence.sml";

get_sig "i_weights.sig";
get_module "i_weights.sml";

(* the ERIL enviroment *)

get_sig    "environment.sig";
get_module "environment.sml";

(* the State of MERILL *)

get_sig "state.sig";
get_module "state.sml";

(* Interfacing Modules *)

get_sig "i_sort.sig";
get_module "i_sort.sml";

get_sig "i_opsymb.sig";
get_module "i_opsymb.sml";

get_sig "i_variable.sig";
get_module "i_variable.sml";

(*
get_sig "i_gens.sig";
get_module "i_gens.sml";
*)

get_sig "i_term.sig";
get_module "i_term.sml";

get_sig "i_equality.sig";
get_module "i_equality.sml";

get_sig "i_signature.sig";
get_module "i_signature.sml";

get_sig "i_environment.sig";
get_module "i_environment.sml";

(* some extra tools for completion *)

get_sig "completiontools.sig";
get_module "completiontools.sml";

(* Knuth_Bendix Completion *)

get_sig "kb.sig";
get_module "kb.sml";

(* Huet's Left-Linear Completion *)
get_module "huet.sml";

(* Peterson and Stickel's AC Completion *)
get_module "peterson.sml";

(* Orderings *)

get_module "userRPO.sml";
get_module "userKBO.sml";
get_module "userAKBO.sml"; (* a new implementation for AC-functions *)
get_module "RPO.sml";   (* this is not yet done properly *)
get_module "matrix.sml";  (* needed for IKBO *)
get_module "incKBO.sml";

get_sig "orderings.sig";
get_module "orderings.sml";

(* environment displays *)

get_sig "eq_options.sig";
get_module "eq_options.sml";

(* saving and loading *)

get_sig "save.sig" ;
get_module "save.sml" ;

get_sig "load.sig" ;
get_module "load.sml" ;

(* putting it all together *)

get_sig "system.sig";
get_module "system.sml";

get_module "build.sml";

open MerillSystem ;

(* The End *)

