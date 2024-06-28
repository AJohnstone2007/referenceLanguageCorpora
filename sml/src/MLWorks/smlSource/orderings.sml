(*
 *
 * $Log: orderings.sml,v $
 * Revision 1.2  1998/06/08 18:20:01  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* 

MERILL  -  Equational Reasoning System in Standard ML.
Brian Matthews				     23/07/90
Glasgow University and Rutherford Appleton Laboratory.

orderings.sml

Provides an implementation of term orderings.

*)

(* A new implementation of lexicographic RPO from AJJD's work. *)

functor OrderingsFUN(structure En : ENVIRONMENT 
		    structure URpo : USERRPO
		    structure Rpo : RPO 
		    structure UKbo : USERKBO 
		    structure AKbo : USERAKBO 
		    structure IKbo : INCKBO 
		    sharing type En.Signature = URpo.Signature = IKbo.Signature =
		    		 Rpo.Signature = UKbo.Signature = AKbo.Signature
		    and     type En.Equality = URpo.Equality = IKbo.Equality =
		    		 Rpo.Equality = UKbo.Equality = AKbo.Equality
		    and     type En.Environment = URpo.Environment = IKbo.Environment =
		                 Rpo.Environment = UKbo.Environment = AKbo.Environment
		    and     type En.ORIENTATION = URpo.ORIENTATION = IKbo.ORIENTATION =
		                 Rpo.ORIENTATION = UKbo.ORIENTATION = AKbo.ORIENTATION
		   ) : ORDERINGS = 
struct

type Signature = En.Signature
type Equality = En.Equality
type Environment = En.Environment
type ORIENTATION = En.ORIENTATION

val userRPOLeft = URpo.userRPOLeft
val userRPORight = URpo.userRPORight
val userRPOMultiSet = URpo.userRPOMultiSet

val userKBO = UKbo.userKBO
val userAKBO = AKbo.userAKBO
val incKBO = IKbo.incKBO

(* this is a dummy hook for later insertion - note that the functions below
   which offer the user a choice of orderings do not offer this one *)
val KBO = UKbo.userKBO  

val RPO = Rpo.RPO

(* 
   These functions provide the interface with the outside world to give
   term orderings.
*)

(*val GlobOrder_Menu = Menu.build_menu "AVAILABLE GLOBAL ORDERINGS"
[
("1",   "User RPO - Left Status", K ("user-RPO-L",  userRPOLeft )),
("2",   "User RPO - Right Status",K ("user-RPO-R",  userRPORight )),
("3",   "User RPO - Multiset Status",K("user-RPO-M",  userRPOMultiSet )),
("4",   "RPO - Left Status",K("RPO-L",  RPO )),
("5",   "User KBO",K("user-KBO",  userKBO )),
("6",   "User AC-KBO",("user-AKBO",  userAKBO ) ),
("7",   "Int-KBO",("intKBO",  intKBO ) ),
("none","none", K("none",default_global_order)),
] *)
val GlobOrder_Menu = Menu.build_menu "AVAILABLE GLOBAL ORDERINGS"
[
("1",   "User RPO - Left Status", I),
("2",   "User RPO - Right Status",I),
("3",   "User RPO - Multiset Status",I),
("4",   "RPO - Left Status",I),
("5",   "User KBO",I),
("6",   "User AC-KBO",I ),
("7",   "Inc-KBO",I),
("none","none", I)
] 

val default_global_order = En.default_global_order

fun initKBO () = 
    (if confirm "Do you want to reinitialise the Incremental Knuth-Bendix Ordering?"
     then IKbo.initialiseIKBO ()
     else () ) ;
     
fun globalord_options _ = 
  (ignore(Menu.display_menu Left GlobOrder_Menu) ;
	  case act_with_message "Pick Number of Ordering (or \"none\") >>  "
	  of 
	    "1" => ("user-RPO-L",  userRPOLeft ) 
	  | "2" => ("user-RPO-R",  userRPORight ) 
	  | "3" => ("user-RPO-M",  userRPOMultiSet ) 
	  | "4" => ("RPO-L",  RPO ) 
	  | "5" => ("user-KBO",  userKBO ) 
	  | "6" => ("user-AKBO",  userAKBO ) 
	  | "7" => (initKBO () ; ("inc-KBO",  incKBO )) 
          | "user-RPO-L" => ("user-RPO-L",  userRPOLeft )
	  | "user-RPO-R" => ("user-RPO-R",  userRPORight ) 
	  | "user-RPO-M" => ("user-RPO-M",  userRPOMultiSet ) 
	  | "RPO-L" =>      ("RPO-L",  RPO ) 
	  | "user-KBO" =>   ("user-KBO",  userKBO ) 
	  | "user-AKBO" =>  ("user-AKBO",  userAKBO ) 
	  | "inc-KBO" =>   (initKBO () ; ("inc-KBO",  incKBO ) ) 
	  | "none" => ("none",default_global_order)
	  |  _  => ("none",default_global_order) ) ;

fun load_globalord s =
	(case s of
          "user-RPO-L" => ("user-RPO-L",  userRPOLeft ) 
	| "user-RPO-R" => ("user-RPO-L",  userRPORight ) 
	| "user-RPO-M" => ("user-RPO-L",  userRPOMultiSet ) 
	| "RPO-L" =>      ("user-RPO-L",  RPO ) 
	| "user-KBO" =>   ("user-KBO",  userKBO ) 
	| "inc-KBO" =>   (IKbo.initialiseIKBO (); ("inc-KBO",  incKBO ) )
	| "user-AKBO" =>   ("user-AKBO",  userAKBO ) 
        | "none" => ("none",default_global_order)
	| _      => ("none", default_global_order) ) 

end (* of functor OrderingsFUN *)
;
