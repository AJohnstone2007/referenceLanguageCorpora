require "../basis/list";
require "../utils/mlworks_exit";
require "../utils/getenv";
require "../basis/os";
require "../basis/__text_io";
require "^.utils.__messages";
require "shell_types";
require "user_context";
require "shell_utils";
require "incremental";
require "../main/info";
require "../main/version";
require "../main/mlworks_io";
require "../main/user_options";
require "../main/preferences";
require "../main/proj_file";
require "../main/license";
require "save_image";
functor SaveImage
(structure Info : INFO
structure Io : MLWORKS_IO
structure Getenv : GETENV
structure OS : OS
structure Preferences : PREFERENCES
structure License : LICENSE
structure UserOptions : USER_OPTIONS
structure UserContext : USER_CONTEXT
structure ShellTypes : SHELL_TYPES
structure Exit : MLWORKS_EXIT
structure Version : VERSION
structure ShellUtils : SHELL_UTILS
structure Incremental : INCREMENTAL
structure List : LIST
structure ProjFile : PROJ_FILE
sharing UserOptions.Options = UserContext.Options = ShellTypes.Options
sharing type ShellUtils.ShellData = ShellTypes.ShellData
sharing type Preferences.preferences = UserContext.preferences
sharing type UserOptions.user_context_options =
UserContext.user_context_options
sharing type UserContext.user_context = ShellTypes.user_context
sharing type UserOptions.user_tool_options = ShellTypes.user_options
sharing type UserContext.Context = ShellTypes.Context
sharing type Preferences.user_preferences = ShellTypes.user_preferences
sharing type Io.Location = Info.Location.T
): SAVE_IMAGE =
struct
type ShellData = ShellTypes.ShellData
fun with_no_update_functions shell_data f x =
let
val UserOptions.USER_CONTEXT_OPTIONS(_, update_ref1) =
UserContext.get_user_options (ShellTypes.get_user_context shell_data)
val Preferences.USER_PREFERENCES (_, update_ref2) =
ShellTypes.get_user_preferences shell_data
val old_option_fns = !update_ref1
val old_preference_fns = !update_ref2
val _ = update_ref1 := [];
val _ = update_ref2 := []
val result =
f x
handle exn =>
(update_ref1 := old_option_fns;
update_ref2 := old_preference_fns;
raise exn)
in
update_ref1 := old_option_fns;
update_ref2 := old_preference_fns;
result
end
fun update_print_messages(shell_data, b) =
let
val UserOptions.USER_CONTEXT_OPTIONS({print_messages, ...}, _) =
UserContext.get_user_options (ShellTypes.get_user_context shell_data)
in
print_messages := b
end
fun select_optimizing shell_data =
let
val user_context_options =
UserContext.get_user_options (ShellTypes.get_user_context shell_data)
in
UserOptions.select_optimizing user_context_options
end
fun select_debugging shell_data =
let
val user_context_options =
UserContext.get_user_options (ShellTypes.get_user_context shell_data)
in
UserOptions.select_debugging user_context_options
end
fun set_user_preference (f, shell_data) =
let val Preferences.USER_PREFERENCES (user_preferences, _) =
ShellTypes.get_user_preferences shell_data
in
(f user_preferences) := true
end
fun clear_user_preference (f, shell_data) =
let val Preferences.USER_PREFERENCES (user_preferences, _) =
ShellTypes.get_user_preferences shell_data
in
(f user_preferences) := false
end
fun get_mk_xinterface_fn (ShellTypes.SHELL_DATA{mk_xinterface_fn,...}) =
mk_xinterface_fn
fun get_x_running (ShellTypes.SHELL_DATA{x_running,...}) = x_running
val gui_message = "The MLWorks GUI is already running\n"
fun startGUI has_controlling_tty shell_data =
if get_x_running shell_data then
print gui_message
else
(get_mk_xinterface_fn shell_data)
(ShellTypes.get_listener_args shell_data)
has_controlling_tty
fun with_standard_streams f =
let
val oldIO = MLWorks.Internal.StandardIO.currentIO()
val _ = MLWorks.Internal.StandardIO.resetIO();
val result = (f() handle exn =>
(MLWorks.Internal.StandardIO.redirectIO oldIO; raise exn))
in
MLWorks.Internal.StandardIO.redirectIO oldIO;
result
end
fun get_mk_tty_listener (ShellTypes.SHELL_DATA{mk_tty_listener,...}) =
mk_tty_listener
fun set_preferences (_, false) = ()
| set_preferences (shell_data as ShellTypes.SHELL_DATA{user_preferences, ...}, _) =
case Getenv.get_preferences_filename () of
NONE => ()
| SOME pathname =>
if OS.FileSys.access (pathname, []) handle OS.SysErr _ => false then
let
val user_options =
UserContext.get_user_options
(ShellTypes.get_user_context shell_data)
val instream = TextIO.openIn pathname
fun parse2 ([],acc) = implode (rev acc)
| parse2 (#"\n" ::rest,acc) = implode (rev acc)
| parse2 (a::rest,acc) = parse2 (rest,a::acc)
fun parse1 ([],acc) = (implode (rev acc),"")
| parse1 (#" " ::rest,acc) =
(implode (rev acc),parse2 (rest,[]))
| parse1 (a::rest,acc) = parse1 (rest,a::acc)
fun loop acc =
let
val line = TextIO.inputLine instream
in
if line = "" then rev acc
else loop (parse1 (explode line,[])::acc)
end
val items = loop []
handle
exn =>
(TextIO.closeIn instream;
raise exn)
in
TextIO.closeIn instream;
Preferences.set_from_list (user_preferences,items);
UserOptions.set_from_list (user_options,items)
end
else
()
val show_banner = ref true
fun showBanner () = !show_banner
local
fun message s =
(Messages.output s;
Messages.output"\n")
val usage =
" Usage:  mlworks [options]\n" ^
" Options:\n" ^
"   -gui  Start the MLWorks Graphical User Interface directly.  This is the\n" ^
"    default.\n" ^
"   -tty    Start MLWorks in text mode.\n" ^
"   -debug-mode\n" ^
"           Start MLWorks with debugging mode on.\n" ^
"   -optimize-mode\n" ^
"           Start MLWorks with optimizing mode on.\n" ^
"   -no-init\n" ^
"           Ignore any .mlworks or .mlworks_preferences files.\n" ^
"   -mono\n" ^
"           Attempt to start for a monochrome display (motif only)\n" ^
"   -silent\n" ^
"           Turn off printing of messages about using, loading or\n" ^
"           compiling files.  Also suppresses the MLWorks prompt.\n" ^
"   -stack n\n" ^
"           Set initial maximum number of stack blocks to n.\n" ^
"   -help   Display this message and exit."
fun parse set_state (shell_data, arguments) =
let
fun parse' ([], r) = r
| parse' ("-tty" :: t, (_, init)) = parse' (t, (true, init))
| parse' ("-gui" :: t, (_, init)) = parse' (t, (false, init))
| parse' ("-no-init" :: t, (tty, _)) = parse' (t, (tty, false))
| parse' ("-full-menus" :: t, r) =
(if set_state then
set_user_preference (#full_menus, shell_data)
else
();
parse' (t, r))
| parse' ("-short-menus" :: t, r) =
(if set_state then
clear_user_preference (#full_menus, shell_data)
else
();
parse' (t, r))
| parse' ("-debug-mode" :: t, r) =
(if set_state then
select_debugging shell_data
else
();
parse' (t, r))
| parse' ("-optimize-mode" :: t, r) =
(if set_state then
select_optimizing shell_data
else
();
parse' (t, r))
| parse'("-source-path" :: path :: rest, r) =
(if set_state then
Io.set_source_path_from_string
(path, Info.Location.FILE "Command Line")
else
();
parse'(rest, r))
| parse'("-object-path" :: path :: rest, r) =
(if set_state then
Io.set_object_path(path, Info.Location.FILE "Command Line")
else
();
parse'(rest, r))
| parse'("-pervasive-dir" :: dir :: rest, r) =
(if set_state then
Io.set_pervasive_dir (dir, Info.Location.FILE "Command Line")
else
();
parse'(rest, r))
| parse'("-silent" :: t, r) =
(if set_state then
update_print_messages(shell_data, false)
else
();
parse'(t, r))
| parse'("-verbose" :: t, r) =
(if set_state then
update_print_messages(shell_data, true)
else
();
parse'(t, r))
| parse' ("-help" :: _, r) =
(message usage;
ignore(Exit.exit Exit.failure);
(false, false) )
| parse' ("-no-banner" :: t, r) =
(show_banner := false;
parse'(t,r))
| parse' (s :: t, r) =
(message
("Invalid argument " ^ s ^ ".\n" ^
"Valid arguments are: -tty -gui -debug-mode -optimize-mode -no-init -mono -silent -stack n -help.");
ignore(Exit.exit Exit.failure);
(false, false) )
in
parse'(arguments, (false, true))
end
fun make_new_shell_data
(ShellTypes.SHELL_DATA
{get_user_context,
user_options,
user_preferences,
prompter,
debugger,
profiler,
exit_fn,
x_running,
mk_xinterface_fn,
mk_tty_listener}) =
ShellTypes.SHELL_DATA
{get_user_context = get_user_context,
user_options = user_options,
user_preferences = user_preferences,
prompter = prompter,
debugger = debugger,
profiler = profiler,
exit_fn = exit_fn,
x_running = false,
mk_xinterface_fn = mk_xinterface_fn,
mk_tty_listener = mk_tty_listener}
fun make_no_prompter_shell_data
(ShellTypes.SHELL_DATA
{get_user_context,
user_options,
user_preferences,
prompter,
debugger,
profiler,
exit_fn,
x_running,
mk_xinterface_fn,
mk_tty_listener}) =
ShellTypes.SHELL_DATA
{get_user_context = get_user_context,
user_options = user_options,
user_preferences = user_preferences,
prompter = fn _ => "",
debugger = debugger,
profiler = profiler,
exit_fn = exit_fn,
x_running = false,
mk_xinterface_fn = mk_xinterface_fn,
mk_tty_listener = mk_tty_listener}
fun main (is_a_tty_image, arguments) =
let
val shell_data = make_new_shell_data (!ShellTypes.shell_data_ref)
val silent = List.exists (fn "-silent" => true | _ => false) arguments
val _ =
let
val _ = Io.set_source_path_from_env
((Info.Location.FILE "<Initialisation code>"), true)
val _ = Io.set_pervasive_dir_from_env
(Info.Location.FILE "<Initialisation code>")
in
()
end
handle Info.Stop _ => Exit.exit Exit.failure
val (_, init) = parse false (shell_data, arguments)
val _ = set_preferences(shell_data, init)
val (tty, _) = parse true (shell_data, arguments)
val tty = tty orelse is_a_tty_image
val shell_data =
if silent andalso tty then
make_no_prompter_shell_data shell_data
else
shell_data
val _ =
if init then
let
val ShellTypes.SHELL_DATA {get_user_context,
user_options,
user_preferences,
debugger,
...} = shell_data
val error_info = Info.make_default_options ()
in
ShellUtils.read_dot_mlworks shell_data
end
else ()
val _ = ShellTypes.shell_data_ref := shell_data
val mk_tty_listener = get_mk_tty_listener shell_data
val listener_args = ShellTypes.get_listener_args shell_data
in
if tty then
(let
val license_status = License.license License.ttyComplain
val default_to_free : unit -> unit =
MLWorks.Internal.Runtime.environment "license set edition"
in
case license_status of
SOME false => default_to_free ()
| _ => ()
end;
if showBanner() then message (Version.versionString ()) else ();
mk_tty_listener listener_args)
else
(startGUI false shell_data;
0 )
end
handle
MLWorks.Interrupt => 0
in
fun saveImage' (is_a_tty_image, handler_fn) (filename, do_exec_save) =
let
val expanded_file =
Getenv.expand_home_dir filename
val save_fn =
if do_exec_save then
MLWorks.Internal.execSave
else
MLWorks.Internal.save
fun restart () =
with_standard_streams
(fn () => main (is_a_tty_image, MLWorks.arguments ()))
val shell_data as
ShellTypes.SHELL_DATA {get_user_context, ...} =
!ShellTypes.shell_data_ref
fun saving_guib() =
let val size = size(filename)
in substring(filename, size - 8, 8) = "guib.img"
andalso ((size = 8)
orelse let val c = substring(filename, size - 9, 1)
in (c = "/" orelse c = "\\") end)
end
handle _ => false
in
Incremental.remove_file_info ();
if (saving_guib())
then
(print"Saving guib.img\n";
UserContext.move_context_history_to_system(get_user_context());
ProjFile.close_proj())
else ();
ignore(
with_no_update_functions
shell_data
(UserContext.with_null_history (get_user_context ()) save_fn)
(expanded_file, restart))
end
handle
MLWorks.Internal.Save msg => handler_fn msg
| Getenv.BadHomeName s =>
handler_fn ("Invalid home name: " ^ s)
val save_image_fn = ref saveImage'
fun add_with_fn withFn =
let val new_save_fn = withFn (!save_image_fn)
in
save_image_fn := new_save_fn
end
fun saveImage arg1 arg2 =
let val save_image = (!save_image_fn)
in
save_image_fn := saveImage';
save_image arg1 arg2 handle exn => (save_image_fn := save_image; raise exn);
save_image_fn := save_image
end
end
end
;
