fun out s = print(s ^ "\n");
fun finish () = out "finished.";
fun k () = out "k.";
fun j () = out "j.";
fun i () = out "i.";
fun h () = out "h.";
fun g () = out "g.";
fun f () = out "f.";
fun e () = out "e.";
fun d () = out "d.";
fun c () = out "c.";
fun b () = out "b.";
fun a () = out "a.";
fun start () = out "starting ...";
OS.Process.atExit finish;
OS.Process.atExit k;
OS.Process.atExit j;
OS.Process.atExit i;
OS.Process.atExit h;
OS.Process.atExit g;
OS.Process.atExit f;
OS.Process.atExit e;
OS.Process.atExit d;
OS.Process.atExit c;
OS.Process.atExit b;
OS.Process.atExit a;
OS.Process.atExit start;
val _ = OS.Process.exit OS.Process.success;
