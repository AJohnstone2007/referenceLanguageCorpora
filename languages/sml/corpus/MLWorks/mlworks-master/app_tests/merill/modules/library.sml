(*
 *
 * $Log: library.sml,v $
 * Revision 1.2  1998/06/08 17:26:18  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(*
Library					bmm. 03/05/89

The module Library contains some of the basic functions and types used throughout 
the system, for New Jersey ML.

More definitions can be found in the file /u/bmm/ML/prelude.ml

*)

infix 0 before
infix 3 oo
infix 3 fby 

structure Library = 
   struct

datatype 'a Search = Match of 'a | NoMatch
datatype Order = LT | EQ | GT
	
exception Fail  
fun failwith s = (output (std_out,s^"\n");raise Fail)

structure Combinator = 
 struct
	fun curry f a b = f(a,b)
	fun uncurry f (a,b) = f a b
	fun I x = x
	fun K x y = x
	fun S f g x = f x (g x) 
	fun SS f g x y = f x (g y) 
	fun C f x y = f y x
	fun W f x = f x x
	val B = fn x => curry (op o) x
	fun eq s  = fn x => curry (op =) s x
	fun neq s  = fn x => curry (op <>) s x
        fun itfun f 0 = I
	  | itfun f n = if n < 0 then I else f o itfun f (n-1)
	val R = fn x => C I x (* the reverse application combinator \x.\f.fx *)
	val CK = fn x => C K x
	fun (f oo g) x y = f (g x y)
	fun (f fby g) a = (ignore(f a) ; g a) handle _ => g a
	fun side f a = (ignore(f a) ; a) handle _ => a
	fun x before y = x
	fun seq (f::fs) a = (ignore(f a); seq fs a)
	  | seq [] a = a
 end  (* of Combinator *)
open Combinator

structure Pair = 
   struct
 	fun pair a b = (a,b)
   	fun fst (a,b) = a
   	fun snd (a,b) = b 
	fun swap (a,b) = (b,a)
   	fun dup a = (a,a)
   	fun apply_pair (f,g) (a,b) = (f a, g b)
   	fun apply_fst f = apply_pair (f,I)
   	fun apply_snd f = apply_pair (I,f)
   	fun apply_both f = apply_pair (f,f)
   	fun tee (f,g) a = (f a, g a)  (* apply_pair (f,g) (dup a) *)
   end (* of Pair *)
open Pair

structure Boolean = 
   struct
	fun non p = not o p;
	fun ou p q x = p x orelse q x;
	fun et p q x = p x andalso q x
	fun conj a b = a andalso b 
	fun disj a b = a orelse b
   end  (* of Boolean *)
open Boolean

structure ListExt = 
   struct
   	val cons = fn x => curry (op ::) x
  	val append = fn x => curry (op @) x
   	fun snoc l a = l@[a]
   	fun singleton x = [x]

   	fun is_singleton [x] = true
   	  | is_singleton  _  = false

  	(* null : 'a list -> bool  Built in *)

  	(* could do a lot with the next function *)

   	fun mapfold f g b []     = b
   	  | mapfold f g b (a::l) = mapfold f g (f b (g a)) l

	(* val foldl = C mapfold I *)

	fun foldl f = let fun foldf a (b::x) = foldf (f a b) x 
      			    | foldf a []     = a 
             	      in foldf end

        fun foldr f = let fun foldf a (b::x) = f (foldf b x ) a
            		    | foldf a [] = a 
    		      in foldf end

	(* hd : 'a list -> 'a  Built in *)
	(* tl : 'a list -> 'a list  Built in *)
	(* exists : ('a -> bool ) -> 'a list -> bool  Built in *)

	fun forall p = 
	    let fun allp (a::x) = if p a then allp x else false
          	  | allp [] = true
      	    in allp end
               	
	(* fun member l a = mapfold disj (eq a) false l 
	            - but less efficient as disj strict *)

	fun member (x::l) a = (x=a) orelse member l a
	  | member [] a = false

	(* length : 'a list -> int  Built in *)

	fun initial_sublist (a::l) (b::s) = a=b andalso initial_sublist l s
	  | initial_sublist l [] = true	  
	  | initial_sublist [] l = false

	(* nth : 'a list * int -> 'a  Built in *)

	val flatten = fn x => foldl append [] x

	exception Zip 

	fun zip (x::xs , y::ys) = (x,y)::zip (xs,ys)
	  | zip ([],[]) = []
	  | zip _  = (output(std_out," zip ") ; raise Zip)

(* 
map2 : ( ('a * 'b) -> 'c) -> 'a list -> 'b list -> 'c list

Maps a function which takes a pair over two lists simultaneously.

This is equivalent to :      map2 f l1 l2 = map f (zip (l1,l2))

If the lists are not the same length, then the exception Zip is raised -
the same exception as the zip function raises.
*)

	fun map2 f (a::l1) (b::l2) = f(a,b) :: map2 f l1 l2
	  | map2 f [] [] = []
	  | map2 f _ _ =  (output(std_out," map2 ") ; raise Zip)

	fun mapapp2 f (a::l1) (b::l2) = f a b @ mapapp2 f l1 l2
	  | mapapp2 f [] [] = []
	  | mapapp2 f _ _ =  (output(std_out," mapapp2 ") ; raise Zip)

(* 
forall_pairs : ('a -> 'b -> bool) -> 'a list -> 'b list -> bool
similar to map2 is the following forall_pairs which passes a predicate over 
the pairs in order of two lists.
This can be specified as  "forall_pairs p l1 l2 = forall (uncurry p) (zip (l1,l2))"
*)

	fun forall_pairs p =    
            let fun check [] [] = true
                  | check (a::l1) (b::l2) = p a b andalso check l1 l2
                  | check  _ _ = ((*output(std_out," forall_pairs ") ;*) raise Zip)
            in check
            end

	fun foldl2 f = let fun foldf a (b::x) (c::y) = foldf (f a b c) x y
        		     | foldf a [] []    = a 
        		     | foldf a _ _      = (output(std_out," foldl2 ") ; raise Zip)
   		       in foldf end

(* 
mapapp : ('a -> 'b list) -> 'a list -> 'b list

like map except it appends the results together
*)
	(* fun mapapp f = mapfold append f [] *)

	fun mapapp f (a::l) = f a @ mapapp f l
	  | mapapp f [] = []

	fun filter p (a::l) = if p a then a::filter p l else filter p l
	  | filter p [] = []

	(* mapfilter = map f o filter p *)
	fun mapfilter p f [] = []
	  | mapfilter p f (a::l) = if p a then f a :: mapfilter p f l
	  			   else  mapfilter p f l

	(* filtermap = filter p o map f *)
	fun filtermap p f [] = []
	  | filtermap p f (a::l) = 
	    let val b = f a 
	    in if p b then b :: filtermap p f l else filtermap p f l
	    end 

	fun findone p (a::l) = if p a then Match a else findone p l
	  | findone p [] = NoMatch

	fun take n []      = []
         | take n (x::xs) =  if n>0 then x::take (n-1) xs else [];

	fun drop _ []      = []
  	  | drop n (x::xs) = if n>0 then drop (n-1) xs else x::xs;

	fun takewhile p l = 
	    let fun f (x::l) xs = 
	    	    if p x then f l (x::xs) else (rev xs, x::l)
	    	  | f [] xs = (rev xs, [])
	    in f l []
	    end 

	fun lastone l = hd (rev l)

		(* last - finds the last n elements of a list *)
	fun last l n = rev ((take n o rev) l) 

	val front = fn x => (rev o tl o rev) x
                     (* drops the last element of a list *)

	fun occurences p = 
	    let fun count n (c::ss) = 
	        if p c then count (n+1) ss else count n ss
	          | count n [] = n 
	    in count 0 
	    end


	(* all_seqs forms all sequences formed by picking one out of a list of lists in order *)

	local
	fun cons_all (a::l) l2 = (map (cons a) l2) @ cons_all l l2 
	  | cons_all [] l2 = [] 
	in 
	fun all_seqs [sl] = map singleton sl
	  | all_seqs (l::rs) = 
	    let val alls = all_seqs rs
	    in cons_all l alls
	    end
	  | all_seqs [] = []
	end (* of local *)

	(* copy - produce a list of n copies of item i *)
	fun copy n i = itfun (cons i) n [] 

	(* exchange - replaces the nth member of a list with a   *)
	(*  - raises Nth if out of range.  Like Nth starts at 0. *)

	fun exchange (b::l) 0 a = a::l
	  | exchange (b::l) n a = b :: exchange l (n-1) a
	  | exchange [] n a = raise Nth 
  
	fun interleave (a::l) (b::k) = a::b::interleave l k 
	  | interleave  l [] = l
	  | interleave  [] k = k

	fun interleave3 (a::l) (b::k) (c::j) = a::b::c::interleave3 l k j
	  | interleave3  l k [] = interleave l k
	  | interleave3  l [] j = interleave l j
	  | interleave3  [] k j = interleave k j

	fun quicksort _   []   = []
	  | quicksort _  [a]   = [a]
	  | quicksort p [a, b] = if p a b then [a, b] else [b, a]
	  | quicksort p (a::l) = 
	  	(quicksort p (filter (fn b => (not (p a b))) l)) @ 
		[a] @
		(quicksort p (filter (p a) l))

   end  (* of ListExt *)
open ListExt

structure ListAsSets = 
   struct
        local 
        exception NotEq
        in 
        fun seteq eq (x::xs) l =
            let fun f (y::ys) = if eq x y then ys else y::f ys
                  | f [] = raise NotEq
            in seteq eq xs (f l)
            	handle NotEq => false
            end
          | seteq eq [] [] = true
          | seteq _  [] _  = false
        end (* of local *)

        fun element equ = 
   	    let fun f (b::l) a =  equ a b orelse f l a
          	  | f [] a = false
            in f
            end 

        fun insert equ = 
   	    let fun f (b::l) a =  if equ a b then (b::l) else b:: f l a
          	  | f [] a = [a]
            in f
            end 

	fun remove equ =
   	    let fun f (b::l) a =  if equ a b then l else b:: f l a
          	  | f [] a = []
            in f
            end 

   	fun union equ = 
   	    let fun f (b::l) a = if equ a b then  (b::l)
          			 else b::f l a
            	  | f [] a = [a]
             in foldl f
             end

        fun intersection equ l1 = 
            let fun f (b::l) a = if equ a b then [b]
          			 else f l a
          	  | f [] a = []
   	    in flatten o (map (f l1))
    	    end

        fun difference equ = 
            let fun f (b::l) a = if equ a b then f l a
          			 else b::f l a
          	  | f [] a = []
    	    in foldl f
   	    end


	fun disjoint eq a = forall (not o element eq a) 

	val cross_product = fn x => 
	    let fun f (a::l) L = map (pair a) L @ f l L 
	          | f [] _ = []
	    in f 
	    end x

	fun allpairs X = cross_product X X

	fun powerset (a::l) = 
	  	let val p = powerset l
	   	in (map (cons a) p) @ p
	   	end 
	  | powerset [] = [[]]

   end (* of ListAsSets *)
open ListAsSets

structure ListAsBags =
   struct
	fun bag_difference equ = 
	    let fun f (b::l) a = if equ a b then l
		          	 else b::f l a
		  | f [] a = []
	    in foldl f
	    end 
   end (* of ListAsBags *)

open ListAsBags

structure Int = 
   struct
   	fun succ n = n+1
   	fun pred n = n-1

	val (plus:int * int -> int) = op +
   	val (add:int -> int -> int) = curry (op +)
   	val (subtract:int * int -> int) = op -
   	val (minus:int -> int -> int) = curry (op -)
   	val (mult:int * int -> int) = op *
   	val (times:int -> int -> int) = curry (op * )
   	val sum = foldl add 0
   	val product = foldl times 1
   	fun hasfactor n i = i mod n = 0
   	val even = hasfactor 2
   	val odd = not o even
   	infixr 8 **
   	exception Power 
   	fun i ** n = if n < 0 then raise Power
   	             else if n=0 then 1 
   	             else let val k = i ** (n div 2) 
  	                  in if even n then k * k
   	                     else i * k * k end 
		
	(* max : int * int -> int   Built in *)
	(* min : int * int -> int   Built in *)

	local val bignum = 2 ** 28
	in val Maxint = bignum + (bignum - 1)	(* Implementation Dependent *)
	   val Minint = (~bignum) - (bignum -1)		(* Implementation Dependent *)
	end 
	val maximum = foldl (curry max) Minint
	val minimum = foldl (curry min) Maxint
	fun intorder (n:int) m = if n < m then LT else 
			         if n > m then GT else EQ

	(* generates all the integers in a range *)
	fun ints n m = 
	    if n = m 
	    then [n]
	    else if n < m
	         then n :: ints (n+1) m
	         else n :: ints (n-1) m

   end  (* of Int *)
open Int

structure String = 
   struct
        val con = fn x => curry (op ^) x (* curried string concatenation *)
        val noc = C con                  (* this function cons 2nd before 1st*)
        val concat = foldl con ""

	fun initial_substring s subs =  
	    initial_sublist (explode s) (explode subs)

	fun stringorder (n:string) m = if n < m then LT else 
			         if n > m then GT else EQ

   end (* of String *)
open String

	(* inc : int ref -> unit  Built in *)
	(* dec : int ref -> unit  Built in *)

end; (* of struct Library *)




