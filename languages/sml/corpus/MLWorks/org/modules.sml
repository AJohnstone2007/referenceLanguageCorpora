(*
 *
 * $Log: modules.sml,v $
 * Revision 1.2  1998/08/05 17:32:53  jont
 * Automatic checkin:
 * changed attribute _comment to ' *  '
 *
 *
 *)
require "utils.sml";
require "term.sml";
require "namespace.sml";
require "synt.sml";
require "toplevel.sml";
require "^.polyml-compat";
(* modules.sml *)

(* "foward referencing" so the actions of the grammar can
 * parse files (e.g. 'Include') and strings (e.g. 'Logic')
 *)
val legoFileParser = ref (fn (filename: string) => ())
val legoStringParser = ref (fn (str: string) => ());


(** commands to support Luca's 'mock modules' **)

fun definedMrk mrk = exists (fn br => sameMrk br mrk) (!NSP)
fun isNewMrk mrk = not (definedMrk mrk);

fun Mark mrk =
  if activeProofState() then failwith"no marking in proof state"
  else if isNewMrk mrk
	 then (message("Creating mark \""^mrk^"\"");
	       NSP:= (Bd{ts=timestamp(),frz=(ref false),param=Global,
			 deps=[],kind=Mrk mrk,bd=((Sig,VBot),"",Bot,Bot)})
	       ::(!NSP))
       else failwith("mark \""^mrk^"\" already in namespace");


(* NOTE: KillRef works even if forget fails: this protects
 * against forgetting marks in the current refinement *)
fun ForgetMrk mrk = 
  let
    fun forget (br::rest) = if sameMrk br mrk then rest else forget rest
      | forget [] = failwith("mark \""^mrk^"\" not in namespace")
  in
    (killRef(); NSP:= forget (!NSP);
     message("forgot back through Mark \""^mrk^"\""))
  end;


fun Include nam = (killRef(); (!legoFileParser) nam)
local
  val findMrk =
    let
      fun no_dotl re = if hd re = "l" andalso hd (tl re) = "."
			 then tl (tl re)
		       else re
      fun to_frst_slash so_far [] = so_far
	| to_frst_slash so_far (h::t) =
	  if h = "/" then so_far else h::(to_frst_slash so_far t)
    in
      implode o rev o (to_frst_slash []) o no_dotl o rev o  explode
    end
in
  fun Load filnam =
    let
      val nam = findMrk filnam
    in
      if definedMrk nam
	then message("module \""^nam^"\" already loaded: no action")
      else Include filnam
    end
  fun ReloadFrom loadFilnam forgetFilnam =
    let
      val forgetNam = findMrk forgetFilnam
    in
      (if definedMrk forgetNam then ForgetMrk forgetNam else ();
       Load loadFilnam)
    end
  fun ModuleImport nam filenam imports =
    (if definedMrk nam
       then failwith("Trying to Include module \""^nam^
		     "\" which already exists.  Use Load or Reload")
     else ();
     if filenam=""
       then message"Warning: interactive use of Module command"
     else if nam<>findMrk filenam
	    then message("Warning: module name \""^nam
			 ^"\" does not equal filename \""^filenam^"\"!")
	  else ();
     do_list Load imports;
     Mark nam);
end;



(*****************
to "compile" into concrete format 

print_expand



*******************)
