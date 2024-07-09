(*
 *
 * $Log: _parser.sml,v $
 * Revision 1.2  1998/06/08 13:09:09  jont
 * Automatic checkin:
 * changed attribute _comment to ' *  '
 *
 *
 *)
(*           Jo: A concurrent constraint programming language
 	                (Programming for the 1990s)

			   Andrew Wilson


		     Recursive Descent Parser
			6th November 1990

			   the functor

Version of July 1996, modified to use Harlequin MLWorks separate 
compilation system.
*)


require "parser";
require "lexer";
require "code";
require "__lowlevel";


functor Parser(structure Lexer: LEXER
	       structure Code: CODE): PARSER =
struct

   open Code
   open Lexer

   exception ParseError of token

   fun isNil nil = true
     | isNil _ = false


   local (*----------------------------------------------------------------*)

	fun putTokenList nil = ()
	  | putTokenList (a::b) = (putToken(a); putTokenList(b))

 

	(* PART ONE: THE error reporting functions:
	 *
	 *  	o error: reports errors within agent expressions.
	 *	o bigerror: reports errors without agent expressions.
	 *
	 *	The action of both is to report the error, and then
	 * 	to skip along to the next stable symbol (&<|,.,EOF)
 	 *	(Yes, | is a little unstable, since it is overloaded.)
	 *	In short, the error procedure is PANIC!
	 *
	 *  	They also set a variable clean_parse to false, to prevent
	 *	a faulty definition being saved to store.
	 ****************************************************************)

     val cleanParse = ref true

     local
	fun tokenToString(AMPERSAND) = "\"&\""
	  | tokenToString(ARROW) = "\"->\""
	  | tokenToString(ATOM "")  = "an atom"
	  | tokenToString(ATOM x) = x
	  | tokenToString(BACKSLASH) = "\"\\\""
	  | tokenToString(BAR) = "\"|\""
	  | tokenToString(COMMA) = "\",\""
	  | tokenToString(COMMAND x) = "\"%"^x^"\""
	  | tokenToString(CONSISTENT) = "\"con\""
	  | tokenToString(DIVOP) = "\"/\""
	  | tokenToString(EOF) = "EOF"
	  | tokenToString(EQ) = "\"=\""
	  | tokenToString(FALSE) = "\"false\""
	  | tokenToString(FIXED) = "\"fixed\""
	  | tokenToString(GT) = "\">\""
	  | tokenToString(GTE) = "\">=\""
	  | tokenToString(IS) = "\"is\""
	  | tokenToString(KNOWN) = "\"known\""
	  | tokenToString(LPAREN) = "\"(\""
	  | tokenToString(LT) = "\"<\""
	  | tokenToString(LTE) = "\"<=\""
	  | tokenToString(MINUSOP) = "\"-\""
	  | tokenToString(NIL) = "\"nil\""
	  | tokenToString(NOT) = "\"not\""
	  | tokenToString(NUMERIC _) = "a number"
	  | tokenToString(PLUSOP) = "\"+\""
	  | tokenToString(QUERY) = "\"?\""
	  | tokenToString(RPAREN) = "\")\""
          | tokenToString(SEMICOLON) = "\";\""
	  | tokenToString(STOP) = "\".\""
	  | tokenToString(TIMESOP) = "\"*\""
	  | tokenToString(TRUE) = "\"true\""
	  | tokenToString(UNDERSCORE) = "\"_\""
	  | tokenToString(VAR "") = "a variable"
	  | tokenToString(VAR x) = x

	fun tokenListToString([x]) = tokenToString(x)
	  | tokenListToString([x,y]) = tokenToString(x)^" or "^tokenToString(y)
	  | tokenListToString(a::b) = tokenToString(a)^", "
				     ^tokenListToString(b)
	  | tokenListToString([]) = ""


        fun errorFns(condition) = 
	  fn (expectedList,found) =>
	   let val f = ref found
	    in
	      (print ("line "^
			      (makeString (!lineNumber))^", EXPECTED "^
			      (tokenListToString(expectedList))^
			      "; FOUND "^(tokenToString found));
	       while not(condition(!f)) do f:=nextToken();
	       cleanParse:=false;
	       print("\tSkipping to "^
			      (tokenToString(!f))^".\n\n");
	       raise ParseError(!f)
	      )
	   end

     in
	
      (* Before the value polymorphism rule introduced in SML '96, I
       * could get away with   val error = errorFns(fn x=> x=EOF orelse x=STOP)
       * which was required to have type token list * token -> 'a.
       * however, now this 'a gets instantiated at its first instance,
       * so now I need the unit argument to stop this happening.
       * it's not so pleasant, but at least its better than having one
       * case for each type (there are eleven different types 'a has to
       * be matched against).
       *)


       fun error () = errorFns(fn x=> x=EOF orelse x=STOP)


     end









	(* PART TWO: variable numbering functions ----------------------*)
	(*  (hacky in extremes)						*)
	(*   used to number every variable in a clause.			*)

	val clauseVars = ref []:string list ref
	val numVars = ref ~1

	fun getVarNum(v) =
	    let
		fun gvn(v,n,[])   = (clauseVars:=(!clauseVars)@[v];
				     numVars:=n;   n)
		  | gvn(v,n,a::b) = if v=a then n else gvn(v,n+1,b)
	     in
		gvn(v,0,!clauseVars)
	    end





	     (* BRACKETING and Maths: tricky --- requires a stack. *)

        local
		val stack = ref [] : token list ref
           in
		fun wipeStack() = stack:=[]
		fun stackToList() = !stack
		fun listToStack(l) = stack:=l

 	        fun stackTop() = 
		    let 
			fun s(nil) = EOF
			  | s(a::b) = a
	     	     in
			s(!stack)
		    end

	        fun push(s) = stack:=(s::(!stack))

	        fun pop() =
		       let
			  fun p(nil) = nil
			    | p(a::b) = b
			in
			  stack:=p(!stack)
		       end

     		   fun noBracketsAtDepth() = 
		       let
			      fun noB(nil) = true
				| noB(ARROW::_) = true
				| noB _ = false
		        in
			    noB(!stack)
	   	       end


		   fun noBrackets() =
		       let
				fun noB(nil) = true
				  | noB(x::y) = x=ARROW andalso noB(y)
	  	        in
				noB(!stack)
	  	       end

           end



	fun openBrackets() =
	    case nextToken() of
		LPAREN => (push(LPAREN);
		          openBrackets())
	      | X => putToken(X)


	fun newDepth() = push(ARROW)
	fun oldDepth() = let val a = stackTop()
			  in if a = ARROW then pop()
					     else raise ParseError(RPAREN)
			 end



	fun closeBrackets(expected) =
	    case stackTop() of
	        LPAREN => 
			(pop();
		         case nextToken() of
		             RPAREN => closeBrackets(expected)
	        	   | X => X
			)
	     | ARROW => RPAREN
	     | X => error()(expected,RPAREN)
				
                     (* the RPAREN is required to return a type of Token.
                      * since value polymorphism is introduced we can't
                      * have error functions with 'a value type.... hence
                      * the need for dummy elements of appropriate type
                      * which are never reached.*)





	(* PART THREE: procedure name renumbering.		*)
	(* renames procedures with a suffix declaring how many  *)
	(* parameters it has.   e.g. run(lemon) -> run/1(lemon) *)


	fun storedName(name,args) =
            let
		fun count(nil) = 0
		  | count(a::b) = 1+count(b)
	     in
		name^"/"^(makeString (count args))
	    end









	(* PART FOUR:  the recursive descent parser proper.	*)
	(********************************************************)



     fun get(VAR _) = (case nextToken() of
                           (VAR x) => x
                         | UNDERSCORE => ""  
                         | X => error()([VAR "",UNDERSCORE],X))
       | get(ATOM _) = (case nextToken() of
			   (ATOM x) => x
			 | X => error()([ATOM ""],X))
       | get(t:token) =
	 (let val t' = nextToken() in
            if t'=t then "" else error()([t],t')
	  end)






     (*----------------------------------------------------------------*)
     (* parse VARlist(): accepts things of form :
                   VAR COMMA VAR COMMA ... COMMA VAR RPAREN
        and returns next token.
      -----------------------------------------------------------------*)

     fun parseVARlist() =
      (let val v = get(VAR "")
	in VARIABLE(v,getVarNum(v))
       end::
       (case nextToken() of
           COMMA => parseVARlist()
	 | RPAREN => nil
	 | X => error()([COMMA,RPAREN],X)
       )
      )





(***************** Parse function  for trees ******************************)

      fun parseTreeEND(parameters) = 
	  case (nextToken(),nextToken()) of
   	      ((VAR x),GT) => if parameters then PARAMETER(x,getVarNum(x))
					    else VARIABLE(x,getVarNum(x))
	    | (UNDERSCORE,GT) => WILDCARD
	    | (X,GT) => error()([VAR "",UNDERSCORE],X)
	    | (X,Y) => error()([GT],Y)




     and parseTreeChildren(parameters) =
         let
	    val (obj,Y) = parseObject(parameters,[GT,COMMA,BACKSLASH])
	  in
	      case Y of
	          GT => (putToken(GT);[obj])
	        | BACKSLASH  => (putToken(BACKSLASH);[obj])
                | COMMA => obj::parseTreeChildren(parameters)
                | X => error()([COMMA,BACKSLASH,GT],X)
          end



     and parseTreeRest(label,parameters) =
         let val kids = parseTreeChildren(parameters)
	  in case nextToken() of
	       GT => (HERBRAND(label,kids,VOID),nextToken())
	     | BACKSLASH => (HERBRAND(label,kids,parseTreeEND(parameters)),
			     nextToken())
	     | X => error()([BACKSLASH,GT],X)
         end     



  and parseTree(parameters) = 
	case (nextToken(),nextToken()) of
	  ((ATOM x),LT) => parseTreeRest(ATOMIC x,parameters)
	| ((VAR x), LT) => parseTreeRest(if parameters 

					    then PARAMETER(x,getVarNum(x))
					    else VARIABLE(x,getVarNum(x)),
					    parameters)
	| (UNDERSCORE,LT) => parseTreeRest(WILDCARD,parameters)
	| (X,LT) => error()([ATOM "",VAR "",UNDERSCORE],X)
	| (X,Y) => error()([LT],Y)







(****************** Parse function for arith expressions ******************)
		(*NB, no need to worry about parameters, since *)
		(* arithmetic constraints never in head.       *)

		(* define a literal to be either a number or a *)
		(* variable.				       *)

   and parseLiteral(VAR x) = VARIABLE(x,getVarNum(x))

     | parseLiteral(NUMERIC(whole,frac)) =
	let
	   fun digToNum("0") = 0.0
	     | digToNum("1") = 1.0
	     | digToNum("2") = 2.0
	     | digToNum("3") = 3.0
	     | digToNum("4") = 4.0
	     | digToNum("5") = 5.0
	     | digToNum("6") = 6.0
	     | digToNum("7") = 7.0
	     | digToNum("8") = 8.0
	     | digToNum("9") = 9.0
	     | digToNum(X) = raise ParseError(NUMERIC(X,""))

	   fun makeInt(v,[]) = v
	     | makeInt(v,a::b) = makeInt(v*10.0+(digToNum(a)),b)

	   fun fracSize([]) = 1.0
	     | fracSize(a::b) = fracSize(b)*10.0
	
	   val wholeInt = makeInt(0.0,map str (explode whole))
	   val fracInt = makeInt(0.0,map str (explode frac))
	 in
	        NUMBER(wholeInt+(fracInt/(fracSize(explode(frac)))))
	end

     | parseLiteral(X) = error()([VAR "",NUMERIC("","")],X)





		(* ParseExp: parse arithmetic expression.  Tricky, *)
		(* 'cos it requires a stack.  Made more complex    *)
		(* because leading brackets have all been stripped *)
		(* off.						   *)


   and parseExp(expected) = 
        let 
	    fun isArithToken(LPAREN) = true	(* *could* the token be part*)
	      | isArithToken(RPAREN) = true	(* of an arithmetic expr?   *)
	      | isArithToken(PLUSOP) = true
	      | isArithToken(MINUSOP) = true
	      | isArithToken(TIMESOP) = true
	      | isArithToken(DIVOP) = true
	      | isArithToken(NUMERIC _) = true
  	      | isArithToken(VAR _) = true
	      | isArithToken(_) = false


            fun inputPrecedence(PLUSOP) = 1
	      | inputPrecedence(MINUSOP) = 1
	      | inputPrecedence(TIMESOP) = 3
	      | inputPrecedence(DIVOP) = 3
	      | inputPrecedence(VAR _) = 7
	      | inputPrecedence(NUMERIC _) = 7
	      | inputPrecedence(LPAREN) = 9
	      | inputPrecedence(RPAREN) = 0
	      | inputPrecedence(_) = ~1


	    fun stackPrecedence(RPAREN) = 0
	      | stackPrecedence(X) = (inputPrecedence(X)+1) mod 10



		(* reverse polish algorithm taken from  *)
		(* "the theory and practice of compiler *)
		(* writing", Tremblay & Sorenson,       *)
		(* McGraw Hill.  pp281-2.		*)

            fun reversePolish() =
	        let
		   val tok = ref(nextToken())
		   val rightParen = ref false
		   val endOfExpression = ref false
		   val temp = ref EOF
		   val result = ref []: token list ref
		in
		(while isArithToken(!tok) andalso not(!endOfExpression) do
		 (
		  while ((inputPrecedence(!tok)<=stackPrecedence(stackTop()))
			 andalso (not(!rightParen)))
                      do (
			  temp:=stackTop();
			  pop();
			  if    !tok<>RPAREN
			  then result:=(!temp)::(!result)
			  else (rightParen:=true;
				if !temp=LPAREN then ()
				else (push(!temp);
				      putToken(RPAREN);
				      endOfExpression:=true))
			 );
		  if !rightParen then () else push(!tok);
		  tok:=nextToken();
		  rightParen:=false
		 );
		putToken(!tok);
		(rev(!result))@stackToList()
		)
		end


	    fun TOKtoOP(PLUSOP) = PLUS
	      | TOKtoOP(MINUSOP) = MINUS
	      | TOKtoOP(TIMESOP) = TIMES
	      | TOKtoOP(DIVOP) = DIVIDES
	      | TOKtoOP(X) = error()([PLUSOP,MINUSOP,TIMESOP,DIVOP],X)




	    local
		(* FIRST, define a stack for intermediate generation*)
		(* of values.	=ArithStack (not Bracketing stack)  *)

		val stack = ref []: object list ref
	        exception stackErr
		fun stackEmpty() = isNil(!stack)
	        fun push(a) = stack:=a::(!stack)
		fun pop() = case !stack of nil  => raise stackErr
					 | a::b => (stack:=b; a)

	    in	    

 	        fun genCode(a::b) =
		    ((case a of
		        VAR _ => (push(parseLiteral(a));genCode(b))
		      | NUMERIC _ => (push(parseLiteral(a));genCode(b))
		      | LPAREN => let val result = pop()
				  in if stackEmpty() then (result,a::b)
				     else 
                                       error()
                                         ([PLUSOP,MINUSOP,TIMESOP,DIVOP],
						 nextToken())
				  end
		      | ARROW => let val result = pop()
				  in if stackEmpty() then (result,a::b)
				     else error()
                                       ([PLUSOP,MINUSOP,TIMESOP,DIVOP],
						 nextToken())
				  end
		      | X => let
			  	val e2 = pop()
			  	val e1 = pop()
			     in
			        (push(TOKtoOP(X)(e1,e2));genCode(b))
			     end
 	              )

                        handle stackErr => 
                          error()
                          ([VAR "",NUMERIC("",""),LPAREN,RPAREN,
                                  TIMESOP,DIVOP,PLUSOP,MINUSOP],nextToken())
                          )
                        
                  | genCode(nil) = 
                    let val result = pop()
                    in if stackEmpty() then (result,nil)
                       else error()
                             ([PLUSOP,MINUSOP,TIMESOP,DIVOP],nextToken())
                    end
                  
                  handle stackErr => 
                    error()([VAR "",NUMERIC("",""),LPAREN,RPAREN,
                            TIMESOP,DIVOP,PLUSOP,MINUSOP],nextToken())
                         
            end




	in
	  let val (code,rem) =  genCode(reversePolish())
	   in 
	      (wipeStack();   		(*bracketing stack NOT arithstack *)
	       listToStack(rem);	(*reload stack.			  *)
	       (code,nextToken())	(* return arith code.		  *)
	      )
	  end
	end





(****************** Parse function for objects ************************)

		(* TreeORNum: choose between VAR<A,B,C... and *)
		(* VAR < X  (arithmetic)		      *)

	(* we have a tree if a ",", "\", ">", "_" or atom preceeds *)
	(* a constraint separator -> & | . etc.			   *)


  and TreeORNum(VAR x,LT,parameters) =	
	let
	  datatype answer = yes | no | undecided

	  fun disambiguate() =
	      let val t = nextToken()
		  val isTree = 
		  case t of  COMMA => yes      | UNDERSCORE => yes
		           | ATOM _ => yes     | BACKSLASH => yes
			   | GT => yes         | AMPERSAND => no
                           | ARROW => no       | QUERY => no
			   | BAR => no
			   | STOP => no	       | EOF => no
			   | _ => undecided
				
	      in  if isTree=yes then (putToken(t); true) else
		  if isTree=no then (putToken(t); false) else
		  let 
		      val descision = disambiguate()
		   in
		      (putToken(t);descision)
		  end
	     end

         in
	    if disambiguate() then (putTokenList([LT,VAR x]);
				    parseTree(parameters))
			     else (if parameters then PARAMETER(x,getVarNum(x))
				                 else VARIABLE(x,getVarNum(x)),
				   LT)
        end		


   | TreeORNum(X,LT,parameters) =(putTokenList([LT,X]);parseTree(parameters))
   | TreeORNum(_,_,_) = raise Fail "Impossible branch"




  and parseObject(parameters:bool,expected) =
     (openBrackets();
      case (nextToken(),nextToken()) of
         (NIL,X)        => (VOID,X)
       | (NUMERIC (a,b),X)=>(putTokenList([X,NUMERIC(a,b)]);parseExp(expected))
       | (X,LT)		=> (TreeORNum(X,LT,parameters))
       | (VAR x,PLUSOP) => (putTokenList([PLUSOP,VAR x]); parseExp(expected))
       | (VAR x,MINUSOP)=> (putTokenList([MINUSOP,VAR x]); parseExp(expected))
       | (VAR x,TIMESOP)=> (putTokenList([TIMESOP,VAR x]); parseExp(expected))
       | (VAR x,DIVOP)  => (putTokenList([DIVOP,VAR x]); parseExp(expected))
       | (VAR x,Y)      =>  (if parameters then PARAMETER(x,getVarNum(x))
					   else VARIABLE(x,getVarNum(x)),Y)
       | (UNDERSCORE,Y) => (WILDCARD,Y)
       | (ATOM x,Y)     => (ATOMIC x,Y)
       | (X,Y) => error()
           ([NIL,VAR "",UNDERSCORE,ATOM "",NUMERIC("","")],X)
     )




   fun parseObjectList(parameters:bool) =
	case parseObject(parameters,[COMMA,BACKSLASH,GT]) of
	    (obj,COMMA) => obj::parseObjectList(parameters)
	  | (obj,RPAREN) => [obj]
	  | (_,X) => error()([COMMA,RPAREN],X)







(*************** Parse functions for program structures *******************)


    fun isProc() =		(* called in context of looking for agent *)
        let val x = nextToken()
	 in case x of
	    (ATOM _) =>
	       (case nextToken() of
		 AMPERSAND => (putToken(AMPERSAND);putToken(x);true)
		 | BAR     => (putToken(BAR);      putToken(x);true)
 	         | STOP    => (putToken(STOP);     putToken(x);true)
		 | LPAREN  => (putToken(LPAREN);   putToken(x);true)
                 | Z => (putToken(Z);putToken(x);false)
       	      )
	    | _ =>  (putToken(x);false)
        end




    fun parseGoal() =
        (let val name = get(ATOM "")
	  in
            case nextToken() of
               STOP =>      (call(storedName(name,[]),[]),STOP)
	     | AMPERSAND => (call(storedName(name,[]),[]),AMPERSAND)
	     | BAR    =>    (call(storedName(name,[]),[]),BAR)
  	     | LPAREN =>    let
				val arglist = parseObjectList(false)
			     in
			        (call(storedName(name,arglist),arglist),
				 nextToken())
			    end
             | X => error()([STOP, AMPERSAND, BAR, LPAREN],X)
	 end
        )






     (*----------------------------------------------------------------*)
     (* items of form 			o OP o			       *)

    fun parseEQConstraint() =
        case parseObject(false,[EQ,LT,LTE,GT,GTE]) of
          (o1,EQ) => let val (o2,X) = parseObject(false,
					[AMPERSAND,BAR,ARROW,STOP]) 
		     in (eq(o1,o2),X)
		    end
          |(o1,LT) => let val (o2,X) = parseObject(false,
					[AMPERSAND,BAR,ARROW,STOP]) 
		     in (less(false,o1,o2),X)
		    end
          |(o1,LTE) => let val (o2,X) = parseObject(false,
					[AMPERSAND,BAR,ARROW,STOP]) 
		     in (less(true,o1,o2),X)
		    end
          |(o1,GT) => let val (o2,X) = parseObject(false,
					[AMPERSAND,BAR,ARROW,STOP]) 
		     in (greater(false,o1,o2),X)
		    end
          |(o1,GTE) => let val (o2,X) = parseObject(false,
					[AMPERSAND,BAR,ARROW,STOP]) 
		     in (greater(true,o1,o2),X)
		    end
	 | (_,X) => error()([EQ,LT,LTE,GT,GTE],X)





     (*----------------------------------------------------------------*)
     (* items of form    OP c.					       *)

    fun parseOPConstraint(CONSTRUCTOR) =
        (newDepth();
	 openBrackets();
	 let 
	    val (c,n) = parseConstraint()
	    val n' = case n of
			 RPAREN =>closeBrackets([ARROW,STOP,AMPERSAND,BAR])
			    | _ =>if noBracketsAtDepth() then n
                                  else error()([RPAREN],n)
          in (
	      oldDepth();
	      (CONSTRUCTOR(c),n')
             )
	  end)





    (*---------------------------------------------------------------*)

    and parseConstraint() =			
        case nextToken() of
	    KNOWN => (  (ignore(get(LPAREN)); 
		          (let val x = get(VAR "")
		            in known(VARIABLE(x,getVarNum(x)))
		           end)
                        ),
	  	        (ignore(get(RPAREN));nextToken())
                     )
	  | FIXED => (  (ignore(get(LPAREN)); 
		         (let val x = get(VAR "")
		           in fixed(VARIABLE(x,getVarNum(x)))
		          end)
                        ),
	 	        (ignore(get(RPAREN));nextToken())
		     )
          | TRUE       => (tt,nextToken())
	  | FALSE      => (ff,nextToken())
	  | NOT        => parseOPConstraint(neg)
          | CONSISTENT => parseOPConstraint(consistent)
	  | x => (putToken(x); parseEQConstraint())





     (*----------------------------------------------------------------*)

    fun parseAgent() =
        if isProc() then parseGoal()
	else 
	  let val (c,X) = parseConstraint()
	      val X = if X=RPAREN 
		      then closeBrackets([AMPERSAND,BAR,STOP,ARROW])
		      else X
	  in case X of
 	       STOP => (tell(c),STOP)
	     | RPAREN => (tell(c),RPAREN)
	     | AMPERSAND => (tell(c),AMPERSAND)
	     | BAR =>       (tell(c),BAR)  
	     | QUERY => (newDepth();
			 let val (a,X) = parseAgents()
		          in (oldDepth();(select(c,a),X))
			 end)
	     | ARROW => (newDepth();
			 let val (a,X) = parseAgents()
		          in (oldDepth();(guard(c,a),X))
			 end)
	     | Y => error()([STOP,AMPERSAND,BAR,ARROW,QUERY],Y)
         end



     and parseAgents() =
	 (openBrackets();
	  let val (a,X) = parseAgent()
	      val X= if X=RPAREN then closeBrackets([AMPERSAND,BAR,STOP])
				 else X
	   in
	     case X of
	         AMPERSAND => let val (b,X) = parseAgents()
		  	       in (parAgents(a,b),X)
			      end
	       | BAR       => let val (b,X) = parseAgents()
			       in (altAgents(a,b),X)
			      end
	       | STOP => if noBrackets() then (a,STOP)
                         else  error()([AMPERSAND,BAR,RPAREN],STOP)
	       | RPAREN => (a,RPAREN)
	       | X => error()([AMPERSAND,BAR,STOP,RPAREN],X)
	  end
         )



 
     (*----------------------------------------------------------------*)
(*     fun parseBody((name,args)) =
        case parseConstraint() of
           (c,STOP) => (clause(storedName(name,args),args,!numVars,c,success),
			STOP)
         | (c,ARROW) => let val (d,Y) = parseAgents()
		         in (clause(storedName(name,args),args,
				    !numVars,c,d),Y)
			end
         | (c,QUERY) => let val (d,Y) = parseAgents()
		         in (clause(storedName(name,args),args,
				    !numVars,c,d),Y)
			end
	 | (_,X) => error()([STOP,ARROW,QUERY],X)
*)



     (*----------------------------------------------------------------*)
     fun parseHead() =
        case nextToken() of
            EOF => (("",nil),EOF)
	  | STOP => (("",nil),STOP)
	  | ATOM n =>
	         (case nextToken() of
	             STOP => ((n,nil),STOP)
		   | LPAREN => ((n,parseObjectList(true)),nextToken())
	  	   | X => error()([STOP,LPAREN],X)
	         )
          | X => error()([ATOM "",EOF],X)





     (*----------------------------------------------------------------*)
     fun parseClause() =
        (case parseHead() of
            ((name,args),STOP) => (clause(storedName(name,args),args,
					  !numVars,none,success),
				   STOP)
  	  | (x,EOF) => (clause("",[],0,none,failure),EOF)
	  | ((n,a),IS) => let val (b,Y) = parseAgents()
	                  in 
			   (clause(storedName(n,a),a,(!numVars)+1,none,b),Y)
			 end
	  | (x,Y) =>error()([IS,STOP,EOF],Y)
	)

	handle ParseError(endPANICtoken) =>
	      (clause("",[],0,none,failure),endPANICtoken)
		





     (*----------------------------------------------------------------*)
     fun parseJO(onlyOne) =
	 (cleanParse:=true;
	  clauseVars:=[];
	  numVars:= ~1;
	  wipeStack();
          case parseClause() of
             (c as clause(name,_,_,_,_),STOP) 
                   => (if (!cleanParse) then (print (name^"\n");store(c))
                       else (); 
                       onlyOne orelse parseJO(onlyOne))
           | (_,EOF) => true
  	   | (_,X) => false
	 )



   in (* ---------------------------------------------------------------- *)


      fun parse (file,buffsize,prompt1,prompt2,anyInput,onlyOne) = 
		(openFile(file,buffsize,prompt1,prompt2,anyInput);
                 parseJO(onlyOne))

      fun parseCLI() = 
          (cleanParse:=true;
	   clauseVars:=[];
	   numVars:= ~1;
	   wipeStack();
	   let val (agent,_) = parseAgents()
	    in
	        if !cleanParse then ((!numVars)+1,agent,!clauseVars) 
				else (0,failure,nil)
	   end)
  end 

end

