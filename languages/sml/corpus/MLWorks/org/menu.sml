(*
 *
 * $Log: menu.sml,v $
 * Revision 1.2  1998/06/08 17:36:14  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(*

An attempt to get menus displayed on the screen.

MERILL  -  Equational Reasoning System in Standard ML.
Brian Matthews			              15-02-91
Rutherford Apppleton Laboratory and Glasgow University.

depends on:
	assoc.sml
	help.sml
	t_input.sml
	interface.sml
*)


(* 

A Menu consists of five fields.

string      -  The Title of the menu
string list -  Items in the menu.
(string * ('a -> 'a)) Assoc - Associates input entries to actions called on that menu item being selected.
int         -  the maximum length of the items in the menu
int 	    -  the number of items in the menu

When building a menu, only the first three fields are given - the others are
calculated from the second field.

*)

structure Menu = 

struct 

abstype 'a Menu = menu of string  *  				(* title *) 
                       string list * 				(* Menu Items *)
                       (string , ('a -> 'a)) Assoc.Assoc * 	(* key and action *)
                       int *  				(* Maximum length of item in menu *)
                       int 					(* number of items *)

with

fun build_menu title items = 
    let fun make_menu (aslist,itlist) (sel, entry, action) =
	    (Assoc.assoc_update eq sel action aslist,
	    snoc itlist (sel^(spaces 3)^entry))
         val (acts, its) = foldl make_menu (Assoc.Empty_Assoc,[]) items
     in menu(title,its,acts,maximum (map size its),length items)
     end 

fun no_menu_items (menu(_,_,_,_,l)) = l 
fun menu_width (menu(_,_,_,w,_)) = w 

fun display_menu side (menu(title,items,actions,maxwidth,menu_length)) =
   let val right = if side = Right then spaces (snd (get_window_size ()) div 2 ) else ""
   in (write_terminal right ; write_highlighted title; newline (); write_terminal right ; 
       app ((fn () => write_terminal right) o newline o 
	 	(display_in_field Left (maxwidth+2))) items ) 
   end

fun display_menu_two_col (menu(title,items,actions,maxwidth,menu_length)) =
	((*up 0*)newline () ;  write_highlighted title ; (*down 1*) newline () ; left (size title);
	 let val (mr,mc) = get_window_size ()
	     val s = maxwidth+2
	     val half = spaces (mc div 2 - s)
	     fun pr2 [] = ()
	       | pr2 (i1::[]) = 
	       		(display_in_field Left s i1 ; newline ()) 
	       | pr2 (i1::i2::ri) = 
	       		(display_in_field Left s i1 ;
	       		 write_terminal half ;
	       		 display_in_field Left s i2 ;
	       		 newline () ; pr2 ri)
	 in pr2 (items @ ["f   Finish","h   Help"]) end )

    
fun menu_screen act arg Menu (Title : string) () = 
    ( clear_title Title ; ignore(act arg) ;
      display_menu_two_col Menu ;
      newline () ; print_line (); newline () ; 
      prompt1 "Select Option: " ) 

fun disp_menu_screen act arg Menu (Title : string) () = 
    ( clear_title Title ; ignore(act arg) ; 
      write_terminal (title_line "(h - help, Control-C - Interrupt)") ; newline () ;
      display_menu Right Menu ;  prompt1 "" ) 

fun disp_screen act  (Title : string) (Prompt : string) = 
    ( clear_title Title ; ignore(act ()) ; print_line (); newline () ;
      prompt_reply Prompt ) 

fun select_from_menu (menu(title,items,actions,i,j)) arg entry =
    let val (action,errmess) = case Assoc.assoc_lookup eq entry actions 
    		     	       of   Match f => (f,"")
    		     	       |    NoMatch => (I,"No Menu entry for "^entry)
    in action arg
    end 

fun display_menu_screen DispSort Menu DisplayFn Title HelpEntry currentarg =
  ( act_on_no_input (
             case DispSort of 
               1 => disp_menu_screen DisplayFn currentarg Menu Title    (* one column display *)
             | 2 => menu_screen DisplayFn currentarg Menu Title         (* two column display *)
             | 3 => (fn () => (display_menu Left Menu  ;			(* simple side display *)
                     		prompt1 Title 	))	(* title is used as a Prompt *)
             | _ => menu_screen DisplayFn currentarg Menu Title         (* two column display *)
             ) ;
    let val selection = get_next_chars () 
    in  (case selection of
    	    "h" => (Help.display_help (if no_current_input ()	(* if nothing on input stream *)
    	    			       then HelpEntry 		(* use default to call help *)
    	    			       else get_next_chars ()	(* otherwise take next input *)
    	    			      );
    	            message_and_wait () ;			(* wait for user to finish *)
    	            display_menu_screen DispSort Menu DisplayFn Title HelpEntry currentarg)
    	|   "f" => currentarg	(* we have now finished this menu call. *)
    	|   ""  => (case DispSort of  1 =>  currentarg	  (* we have now finished this menu call*)
    	            | _  => display_menu_screen DispSort Menu DisplayFn Title HelpEntry currentarg)
    	| selection  => if DispSort = 3 	(* no repetition on menu display sort 3 *)
    			then (select_from_menu Menu currentarg selection)
    			else display_menu_screen DispSort Menu DisplayFn Title HelpEntry 
    			     (select_from_menu Menu currentarg selection))
    handle Interrupt => display_menu_screen DispSort Menu DisplayFn Title HelpEntry currentarg
    end
  )

end (* of abstype Menu *) 

end (* of structure Menu *) ;

