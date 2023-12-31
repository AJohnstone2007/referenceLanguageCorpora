signature LIST_PAIR =
sig
val zip : ('a list * 'b list) -> ('a * 'b) list
val unzip : ('a * 'b) list -> ('a list * 'b list)
val map : ('a * 'b -> 'c) -> ('a list * 'b list) -> 'c list
val app : ('a * 'b -> unit) -> ('a list * 'b list) -> unit
val foldl : (('a * 'b * 'c) -> 'c) -> 'c -> ('a list * 'b list) -> 'c
val foldr : (('a * 'b * 'c) -> 'c) -> 'c -> ('a list * 'b list) -> 'c
val all : ('a * 'b -> bool) -> ('a list * 'b list) -> bool
val exists : ('a * 'b -> bool) -> ('a list * 'b list) -> bool
end
;
