(* ***********************************************************************

   Project: sml/Tk: an Tk Toolkit for sml
   Author: Stefan Westmeier, University of Bremen
  $Date: 1999/06/16 10:06:32 $
  $Revision: 1.1 $
   Purpose of this file: Functions related to TkEvents

   *********************************************************************** *)

require "__string";

require "basic_util";
require "basic_types";
require "tk_event_sig";

structure TkEvent : TK_EVENT = 
struct

local open BasicTypes BasicUtil in


fun selButton   (TkEvent(b,_,_,_,_,_)) = b

fun selState    (TkEvent(_,s,_,_,_,_)) = s

fun selXPos     (TkEvent(_,_,x,_,_,_)) = x

fun selYPos     (TkEvent(_,_,_,y,_,_)) = y

fun selXRootPos (TkEvent(_,_,_,_,x,_)) = x

fun selYRootPos (TkEvent(_,_,_,_,_,y)) = y

fun show () = "(%b,%s,%x,%y,%X,%Y)"

fun unparse ev_v = 
    let
	open StringUtil
	val ev_v' = String.translate 
	            (fn c => if (isOpenParen c) orelse (isCloseParen c)
		             then "" else str c) ev_v
	val bs::st::xs::ys::xrs::yrs::_ = String.fields isComma ev_v'
	val b     = toInt bs
	val x     = toInt xs
	val y     = toInt ys
	val x_root= toInt xrs
	val y_root= toInt yrs
    in
	TkEvent(b,st,x,y,x_root,y_root)
    end handle Bind => TkEvent(0, "", 0, 0, 0, 0) 

end

end



