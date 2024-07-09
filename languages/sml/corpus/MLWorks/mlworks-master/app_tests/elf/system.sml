(*
 *
 * $Log: system.sml,v $
 * Revision 1.2  1998/06/03 11:46:41  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
Shell.Options.set(Shell.Options.Language.abstractions,true);

structure System =
  struct
    structure Timer =
      struct
	datatype timer = TIME of {usec:int, sec:int}
	type timer = Timer.cpu_timer
	fun check_timer t =
	  case Timer.checkCPUTimer t of
	    {usr, sys, ...} =>
	      let
		val time = Time.toReal usr + Time.toReal sys
	      in
		TIME {usec=floor(1000000.0*(time - real(floor time))), sec=floor time}
	      end
	fun check_timer_gc t =
	  case Timer.checkCPUTimer t of
	    {gc, ...} =>
	      let
		val time = Time.toReal gc
	      in
		TIME {usec=floor(1000000.0*(time - real(floor time))), sec=floor time}
	      end
	val start_timer = Timer.startCPUTimer
      end
    structure Signals =
      struct
	
      end
  end

val ordof = Char.ord o String.sub
val quot = op div : int * int -> int
infix 7 quot
fun fold f l i = List.foldl f i l
structure List =
  struct
    open List
    val fold = fold
  end
val hd = List.hd
val length = List.length
fun revfold f l i = fold f (rev l) i
val exists = List.exists
val tl = List.tl
(*fun print s = output(std_out, s)*)
fun makestring n =
  let
    fun makeDigit digit =
      if digit >= 10 then chr (ord #"A" + digit - 10)
      else chr (ord #"0" + digit)
    val sign = if n < 0 then "~" else ""
    fun makeDigits (n,acc) =
      let
        val digit = 
          if n >= 0 
            then n mod 10
          else 
            let
              val res = n mod 10
            in
              if res = 0 then 0 else 10 - res
            end
        val n' = 
          if n >= 0 orelse digit = 0 then 
            n div 10
          else 1 + n div 10
        val acc' = makeDigit digit :: acc
      in 
        if n' <> 0
          then makeDigits (n',acc')
        else acc'
      end
  in
    sign^(implode (makeDigits (n,[])))
  end

val print_int = print o makestring
fun max(i:int, j) = if i >= j then i else j
fun min(i:int, j) = if i >= j then j else i
structure Array = MLWorks.Internal.Array
type 'a array = 'a Array.array
val substring = String.substring
structure String =
  struct
    open String
    val length = size
  end
val make_real = MLWorks.Internal.Value.real_to_string
val implode = String.concat
val ord = fn s => Char.ord(String.sub(s, 0))
val chr = fn i => String.implode[Char.chr i]
val explode = fn l => map (chr o Char.ord) (String.explode l)
val substring = String.substring

structure Vector =
struct
  type 'a vector = 'a MLWorks.Internal.Vector.vector
  val maxLen = MLWorks.Internal.Vector.maxLen
  fun check_size n = if n < 0 orelse n > maxLen then raise Size else n
  fun vector l = 
      (ignore(check_size (length l)); MLWorks.Internal.Vector.vector l)
  val sub = MLWorks.Internal.Vector.sub
end

val flush_out = TextIO.flushOut
val input_line = TextIO.inputLine;
val std_err = TextIO.stdErr;
val std_out = TextIO.stdOut;
val std_in = TextIO.stdIn;
val output = TextIO.output
val end_of_stream = TextIO.endOfStream
val open_in = TextIO.openIn
val close_in = TextIO.closeIn
val open_out = TextIO.openOut
val close_out = TextIO.closeOut
type instream = TextIO.instream
type outstream = TextIO.outstream

exception Io = IO.Io
