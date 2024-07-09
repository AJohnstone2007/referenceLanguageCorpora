(*
 *
 * $Log: build.sml,v $
 * Revision 1.2  1998/06/08 18:24:09  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
(* 
MERILL  -  Equational Reasoning System in Standard ML.
Brian Matthews				     05/12/91
Glasgow University and Rutherford Appleton Laboratory.

build.sml 

This file builds the final system.

*)

fun buildMerill () = get_module "build.sml";

structure Pretty = PrettyFUN ();

structure Sort = SortFUN ();
structure Ops  = OpSymbFUN (structure S = Sort
			    structure P = Pretty);
structure Vars = VariableFUN (structure S = Sort);

structure Signature = SignatureFUN(structure S = Sort
                                   structure O = Ops
                                   structure V = Vars
                                  ) ;

structure Term = TermFUN(structure Sig = Signature) ;

structure Path = PathFUN(structure T = Term) ;

structure Order = OrderFUN () ;

structure Subst = SubstitutionFUN(structure T = Term) ;

structure Equality = EqualityFUN (structure T = Term
		     		  structure S = Subst
		     		  structure O = Order
		     		 ) ;

structure EqualitySet = EqualitySetFUN  (structure E = Equality
			                 structure T = Term
			 		 structure S = Subst
			 		) ;

structure AC_Tools = AC_ToolsFUN(structure T = Term) ;

structure AC_Match = AC_MatchFUN(structure T = Term
			         structure S = Subst
			         structure A = AC_Tools
			         ) ;

structure Match = MatchFUN(structure T = Term
			   structure S = Subst
			   ) ;


structure AC_Unify = ACUnifyFUN(structure T = Term
			       structure S = Subst
			       structure Dio = Dio
			       structure A = AC_Tools
			       ) ;

structure OS_Unify = OSUnifyFUN(structure T = Term
			       structure S = Subst
			      ) ;

structure Empty_Theory = Empty_TheoryFUN(structure T = Term
			      		 structure M = Match
			      		 structure U = OS_Unify
			      		 structure E = Equality
			      		) ;

structure AC_Theory = AC_TheoryFUN(structure A = AC_Tools
			      	   structure M = AC_Match
			      	   structure U = AC_Unify
			           structure E = Equality
			      	  ) ;

structure Huet_Theory = AC_TheoryFUN(structure A = AC_Tools
			      	     structure M = Match
			      	     structure U = OS_Unify
			             structure E = Equality
			      	    ) ;

structure Sort_Preserve = Sort_PreserveFUN (structure T = Term
			         	    structure S = Subst
			         	   );

structure Superpose = SuperposeFUN (structure T = Term
		      		    structure S = Subst
		      		    structure E = Empty_Theory
		      		    structure P = Path
		      		   );

structure ESuperpose = SuperposeFUN (structure T = Term
		      		    structure S = Subst
		      		    structure E = AC_Theory
		      		    structure P = Path
		      		   );

structure CAC_Theory = CAC_TheoryFUN (structure T = Term
		       		      structure S = Subst
		       		      structure M = Match
				      structure E = Equality
				     ) ;

structure Rewrite = RewriteFUN (structure E = Equality
		       	   	structure Es = EqualitySet
		       	   	structure T = Term
		     		structure S = Subst
		     		structure P = Path
		     		structure M = Empty_Theory
			       ) ;

structure ERewrite = RewriteFUN (structure E = Equality
		       	   	 structure Es = EqualitySet
		       	   	 structure T = Term
		     		 structure S = Subst
		     		 structure P = Path
			 	 structure M = AC_Theory
			       ) ;

structure HuetRewrite = RewriteFUN (structure E = Equality
		       	   	 structure Es = EqualitySet
		       	   	 structure T = Term
		     		 structure S = Subst
		     		 structure P = Path
			 	 structure M = Huet_Theory
			       ) ;

structure CriticalPair = CriticalPairFUN(structure E = Equality
			 		 structure Es = EqualitySet
			 		 structure S = Superpose
			 		 structure U = Empty_Theory
			 	         structure R = Rewrite
		     		 	 structure P = Path
		       	   	 	 structure T = Term
			       		) ;

structure ECriticalPair = CriticalPairFUN(structure E = Equality
			 		  structure Es = EqualitySet
			 		  structure S = ESuperpose
			 		  structure U = AC_Theory
			 	          structure R = ERewrite
		     		 	  structure P = Path
		       	   	 	  structure T = Term
			       		) ;

structure HuetCriticalPair = CriticalPairFUN(structure E = Equality
			 		  structure Es = EqualitySet
			 		  structure S = ESuperpose
			 		  structure U = Huet_Theory
			 	          structure R = HuetRewrite
		     		 	  structure P = Path
		       	   	 	  structure T = Term
			       		) ;
structure Prec = PrecedenceFUN (structure T = Term);

structure Weight = WeightFUN (structure O = Ops) ;

structure Strats = StrategiesFUN (structure EQ = Equality
		       	   	  structure ES = EqualitySet
		       	   	  structure E = Empty_Theory
		       	   	 ) ;

structure AC_Strats = StrategiesFUN (structure EQ = Equality
		       	   	     structure ES = EqualitySet
		       	   	     structure E = AC_Theory
		       	   	 ) ;

structure Local_Order = LocalOrderFUN(structure O = Order
		      		      and       S = Signature
		      		      and       E = Equality
		      		     ) ;

structure I_Precedence = I_PrecedenceFUN (structure P = Prec
			 		  structure S = Signature
			 		 ) ;

structure I_Weights = I_WeightFUN (structure W = Weight
		     		   structure S = Signature
		     		  ) ;

structure Env = EnvironmentFUN (structure Sig = Signature
				structure E = Equality
				structure O = Order
				structure P = Prec
				structure W = Weight
				structure L = Local_Order
				structure Str = Strats
			       ) ;

structure State = StateFUN (structure T = Term
			    structure Eq = EqualitySet
			    structure En = Env
			   ) ;

structure I_Sort = I_SortFUN (structure S = Sort) ;

structure I_Opsymb = I_OpsymbFUN(structure  T = Term
				 structure iS = I_Sort
				) ;

structure I_Variable =  I_Variable (structure S = Sort
		    		    structure V = Vars
		    		    structure iS = I_Sort
		    		   ) ;

structure I_Term = I_TermFUN (structure T = Term);

structure I_Equality = I_EqualityFUN (structure Eq = Equality
		       		      structure Es = EqualitySet
		       		      structure T = Term
		       		      structure O = Order
		       		     ) ;

structure I_Signature = I_SignatureFUN  (structure T = Term
			 	         structure iS = I_Sort
			 		 structure iO = I_Opsymb
			 		 structure iV = I_Variable
					 structure E  = EqualitySet
					 structure N  = Env
					 structure C  = CAC_Theory
					 structure State = State
			 		) ;

structure I_Environment = I_EnvironmentFUN (structure iP = I_Precedence
					    structure iW = I_Weights
					    structure L = Local_Order
					    structure Str = Strats
					    structure Env = Env
					    structure State = State) ;

structure KBTools = CompletionToolsFUN (structure T = Term
					structure S = Subst
					structure Eq = Equality
					structure Es = EqualitySet
					structure iEq = I_Equality
					structure Str = Strats
					structure M = Empty_Theory
					structure R = Rewrite
					) ;

structure KB = KbFUN  (structure T = Term
		       structure Eq = Equality
		       structure Es = EqualitySet
		       structure En = Env
		       structure iEq = I_Equality
		       structure Str = Strats
		       structure Sp = Sort_Preserve
		       structure Ord = Order
		       structure R = Rewrite
		       structure C = CriticalPair
		       structure Ct = KBTools
		       structure State = State
		      ) ;

structure HuetTools = CompletionToolsFUN (structure T = Term
					structure S = Subst
					structure Eq = Equality
					structure Es = EqualitySet
					structure iEq = I_Equality
					structure Str = AC_Strats
					structure M = Huet_Theory
					structure R = HuetRewrite
					) ;

structure HuetCompletion = 
	     HuetFUN  (structure T = Term
		       structure Eq = Equality
		       structure Es = EqualitySet
		       structure En = Env
		       structure iEq = I_Equality
		       structure Str = AC_Strats
		       structure Sp = Sort_Preserve
		       structure Ord = Order
		       structure R = HuetRewrite
		       structure C = HuetCriticalPair
		       structure Ct = HuetTools
		       structure State = State
		      ) ;

structure PetersonTools = CompletionToolsFUN (structure T = Term
					structure S = Subst
					structure Eq = Equality
					structure Es = EqualitySet
					structure iEq = I_Equality
					structure Str = AC_Strats
					structure M = AC_Theory
					structure R = ERewrite
					) ;

structure PetersonCompletion = 
	 PetersonFUN  (structure T = Term
		       structure S = Subst
		       structure Eq = Equality
		       structure Es = EqualitySet
		       structure En = Env
		       structure iEq = I_Equality
		       structure Str = AC_Strats
		       structure M = AC_Theory
		       structure Sp = Sort_Preserve
		       structure Ord = Order
		       structure R = ERewrite
		       structure C = ECriticalPair
		       structure Ct = PetersonTools
		       structure State = State
		      ) ;

structure UserRPO = UserRPOFUN (structure T = Term
		           	structure Eq = Equality
		            	structure O = Order
		            	structure En = Env
		            	structure P = Prec
		               ) ;

structure RPO = RPOFUN (structure T = Term
		        structure Eq = Equality
		        structure O = Order
		        structure En = Env
		        structure P = Prec
		       ) ;

structure UserKBO = UserKBOFUN (structure T = Term
		           	structure Eq = Equality
		            	structure O = Order
		            	structure En = Env
		            	structure P = Prec
		            	structure W = Weight
		               ) ;

structure UserAKBO = UserAKBOFUN (structure T = Term
		           	structure Eq = Equality
		            	structure O = Order
		            	structure En = Env
		    		structure A = AC_Tools
		            	structure P = Prec
		            	structure W = Weight
		               ) ;

structure Matrix = MatrixFUN();

structure IncKBO = IncKBOFUN (structure T = Term
				structure M = Matrix
		           	structure Eq = Equality
		            	structure O = Order
		            	structure En = Env
		               ) ;

structure Orderings = OrderingsFUN(structure En = Env 
		    		   structure URpo = UserRPO
		    		   structure Rpo = RPO 
		    		   structure UKbo = UserKBO
		    		   structure AKbo = UserAKBO
		    		   structure IKbo = IncKBO
		    		  ) ;

structure Eq_Options = Eq_OptionsFUN (structure T = Term
		    		      structure Eq = Equality
		    		      structure Es = EqualitySet
		    		      structure En = Env
		    		      structure iT = I_Term
		    		      structure iE = I_Equality
		    		      structure EU = AC_Unify
		    		      structure S = Subst
		    		      structure Str = Strats
		    		      structure ER = ERewrite
		    		      structure ECP = ECriticalPair
		    		      structure K = KB
		    		      structure H = HuetCompletion
		    		      structure P = PetersonCompletion
		    		      structure State = State
		    		     ) ;

structure Save =  SaveFUN (structure iS = I_Sort
		 	   structure iO = I_Opsymb
		 	   structure iV = I_Variable
			   structure iE = I_Equality
			   structure iP = I_Precedence
		 	   structure Sig = Signature
			   structure Es = EqualitySet
		 	   structure iEn = I_Environment
		 	   structure State = State
		 	  ) ;

structure Load =  LoadFUN (structure iS = I_Sort
		 	   structure iO = I_Opsymb
		 	   structure iV = I_Variable
			   structure iE = I_Equality
			   structure iP = I_Precedence
			   structure Sig = Signature
			   structure CAC = CAC_Theory
			   structure Es = EqualitySet
		 	   structure En = Env
		 	   structure iEn = I_Environment
		 	   structure Ord = Orderings
		 	   structure State = State
		 	  ) ;

structure MerillSystem = SystemFUN (structure EO = Eq_Options
                  	      structure iSig = I_Signature
                   	      structure En = I_Environment
                   	      structure Ord = Orderings
                  	      structure L = Load
		   	      structure S = Save
		   	      structure State = State
		   	     ) ;

