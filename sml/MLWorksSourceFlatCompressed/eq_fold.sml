val test1 = () = {};
val test2 = (1,2,true,(2,())) = {1 = 1, 2 = 2, 3 = true, 4 = (2,())};
val test3 = #name {used = true, name = "Foo"} = "Foo";
val test4 = 1 = (case true of false => 2 | true => 1 )
andalso (2 = (case true of true => 2 | false => 1));
local
exception A;
exception B = A;
in
val test5 = 1 = (case B of A => 1 | _ => 3);
end;
val test6a = (if true then 1 else 2) = 1;
val test6b = (if false then 1 else 2) = 2;
val test7a = true orelse true;
val test7b = true orelse false;
val test7c = false orelse true;
val test7d = not (false orelse false);
val test8a = true andalso true;
val test8b = not (true andalso false);
val test8c = not (false andalso true);
val test8d = not (false andalso false);
local
exception A;
exception B = A;
in
val test9 = 2 = ( ignore(3+4); ignore(true andalso false); ignore((raise A) handle B => B); 2 );
end;
val test10 = let val y as x = 2 in ( ignore(2); ignore(x); ignore(y*x+2); x*y) end = 4;
local
val VarX = ref 0;
val VarY = ref 1;
val t = while !VarX<6 do (VarX := !VarX+1 ; VarY := !VarY * !VarX );
in
val test11 = 720 = !VarY;
end;
val test12a = 1::2::3::4::nil = [1,2,3,4];
local
datatype color = Red | White | Blue of int;
in
val test12b = Red::White::Red::Blue 2::nil = [Red,White,Red,Blue 2];
end;
val alltrue = test1 andalso test2 andalso test3 andalso
test4 andalso test5 andalso test6a andalso
test6b andalso
test7a andalso test7b andalso test7c andalso
test7d andalso test8a andalso test8b andalso
test8c andalso test8d andalso test9 andalso
test10 andalso test11 andalso test12a andalso
test12b;
