signature ARRAY =
sig
eqtype 'a array
eqtype 'a vector
val maxLen : int
val array : (int * '_a) -> '_a array
val fromList : '_a list -> '_a array
val tabulate : (int * (int -> '_a)) -> '_a array
val length : 'a array -> int
val sub : ('a array * int) -> 'a
val update : ('a array * int * 'a) -> unit
val extract : ('a array * int * int option) -> 'a vector
val copy : {src : 'a array, si : int, len : int option, dst : 'a array, di : int} -> unit
val copyVec : {src : 'a vector, si : int, len : int option, dst : 'a array, di : int} -> unit
val appi : ((int * 'a) -> unit) -> ('a array * int * int option) -> unit
val app : ('a -> unit) -> 'a array -> unit
val foldli : ((int * 'a * 'b) -> 'b) -> 'b -> ('a array * int * int option) -> 'b
val foldri : ((int * 'a * 'b) -> 'b) -> 'b -> ('a array * int * int option) -> 'b
val foldl : (('a * 'b) -> 'b) -> 'b -> 'a array -> 'b
val foldr : (('a * 'b) -> 'b) -> 'b -> 'a array -> 'b
val modifyi : ((int * 'a) -> 'a) -> ('a array * int * int option) -> unit
val modify : ('a -> 'a) -> 'a array -> unit
end
;
