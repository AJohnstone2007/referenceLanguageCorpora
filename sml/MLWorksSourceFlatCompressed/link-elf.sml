structure Basic : BASIC = Basic ();
structure Term : TERM = Term (val fixity_min = 0
val fixity_max = 10000);
structure Skeleton : SKELETON = Skeleton (structure Term = Term) ;
structure Naming : NAMING =
Naming (structure Basic = Basic
structure Term = Term);
structure Sb : SB =
Sb (structure Basic = Basic
structure Term = Term
structure Naming = Naming);
structure Symtab : SYMTAB =
Symtab (type entry = Term.sign_entry
structure Hash = Hash
structure Hasher = Hasher);
structure Symbols_Mono : SYMBOLS =
Symbols_Mono (structure F = Formatter);
structure PrintVar : PRINT_VAR =
PrintVar (structure Basic = Basic
structure Term = Term
structure Naming = Naming);
structure PrintTerm : PRINT_TERM =
PrintTerm (structure Basic = Basic
structure Term = Term
structure Sb = Sb
structure Symtab = Symtab
structure Naming = Naming
structure PrintVar = PrintVar
structure F = Formatter
structure S = Symbols_Mono
val use_fixity = false);
structure IPrint : PRINT =
PrintExtend (structure Basic = Basic
structure Term = Term
structure Sb = Sb
structure Symtab = Symtab
structure PrintTerm = PrintTerm);
structure Reduce : REDUCE =
Reduce (structure Term = Term
structure Print = IPrint
structure Sb = Sb);
structure PrintNorm : PRINT_TERM =
PrintNorm (structure Term = Term
structure PrintTerm = PrintTerm
structure Reduce = Reduce);
structure Print : PRINT =
PrintExtend (structure Basic = Basic
structure Term = Term
structure Sb = Sb
structure Symtab = Symtab
structure PrintTerm = PrintNorm);
structure PrintTermFixity : PRINT_TERM =
PrintTerm (structure Basic = Basic
structure Term = Term
structure Sb = Sb
structure Symtab = Symtab
structure Naming = Naming
structure PrintVar = PrintVar
structure F = Formatter
structure S = Symbols_Mono
val use_fixity = true);
structure PrintNormFixity : PRINT_TERM =
PrintNorm (structure Term = Term
structure PrintTerm = PrintTermFixity
structure Reduce = Reduce);
structure PrintEllide : PRINT_TERM =
PrintEllide (structure Basic = Basic
structure Term = Term
structure Reduce = Reduce
structure Symtab = Symtab
structure PrintTerm = PrintNormFixity);
structure ElfPrint : PRINT =
PrintExtend (structure Basic = Basic
structure Term = Term
structure Sb = Sb
structure Symtab = Symtab
structure PrintTerm = PrintEllide);
structure PrintVarVerbose : PRINT_VAR =
PrintVarVerbose (structure Basic = Basic
structure Term = Term
structure Print = ElfPrint);
structure Interface : INTERFACE = Interface ();
structure Absyn : ABSYN =
Absyn (structure Basic = Basic
structure Term = Term
structure Naming = Naming
structure Symtab = Symtab);
structure ElfAbsyn : ELF_ABSYN =
ElfAbsyn (structure Term = Term);
structure ElfLrVals : Elf_LRVALS =
ElfLrValsFun (structure Token = LrParser.Token
structure Term = Term
structure Absyn = Absyn
structure ElfAbsyn = ElfAbsyn);
structure ElfLex : LEXER =
ElfLexFun (structure Tokens = ElfLrVals.Tokens
structure Interface = Interface);
structure ElfParser : PARSER =
Join (structure ParserData = ElfLrVals.ParserData
structure Lex = ElfLex
structure LrParser = LrParser);
structure ElfParseCore : PARSE =
ParseCore (structure Interface = Interface
structure Parser = ElfParser
val EOF_token_name = ElfLrVals.Tokens.EOF
val QUERY_token_name = ElfLrVals.Tokens.QUERY
val SIGENTRY_token_name = ElfLrVals.Tokens.SIGENTRY);
structure ElfParse : ELF_PARSE =
ElfParse (structure ElfAbsyn = ElfAbsyn
structure Parse = ElfParseCore
structure Tokens = ElfLrVals.Tokens);
structure Trail : TRAIL =
Trail (structure Basic = Basic
structure Term = Term);
structure ConstraintsDataTypes : CONSTRAINTS_DATATYPES =
ConstraintsDataTypes (structure Term = Term);
structure Constraints : CONSTRAINTS =
Constraints (structure Term = Term
structure ConstraintsDataTypes = ConstraintsDataTypes
structure Print = Print
structure PrintVarVerbose = PrintVarVerbose
structure Sb = Sb
structure Reduce = Reduce);
structure ElfUUtils : UUTILS =
UUtils (structure Term = Term
structure Print = Print
structure Sb = Sb
structure Trail = Trail
structure Reduce = Reduce);
structure ElfEqual : EQUAL =
Equal (structure Term = Term
structure Sb = Sb
structure Reduce = Reduce
structure UUtils = ElfUUtils);
structure ElfUnify : UNIFY =
UnifyLlambda (structure Basic = Basic
structure Term = Term
structure Sb = Sb
structure Reduce = Reduce
structure Print = Print
structure Trail = Trail
structure UUtils = ElfUUtils
structure Constraints = Constraints
val enable_tracing = true
val allow_definitions = false);
structure ElfSimplifyEquals : UNIFY =
SimplifyEquals (structure Basic = Basic
structure Term = Term
structure Sb = Sb
structure UUtils = ElfUUtils
structure Equal = ElfEqual
structure Constraints = Constraints
structure Unify = ElfUnify);
structure ElfDepend : TYPE_DEPEND =
ElfDepend (structure Term = Term);
structure ElfTypeRecon : TYPE_RECON =
TypeRecon (structure Basic = Basic
structure Term = Term
structure IPrint = Print
structure Print = ElfPrint
structure Sb = Sb
structure Reduce = Reduce
structure Constraints = Constraints
structure UUtils = ElfUUtils
structure Unify = ElfUnify
structure Equal = ElfEqual
structure Simplify = ElfSimplifyEquals
structure TypeDepend = ElfDepend
structure Naming = Naming);
structure Sign : SIGN =
Sign (structure Basic = Basic
structure Term = Term
structure IPrint = Print
structure Print = ElfPrint);
structure Redundancy : REDUNDANCY =
Redundancy (structure Basic = Basic
structure Term = Term
structure Print = Print
structure Sb = Sb
structure Reduce = Reduce);
structure ElfFrontEnd : ELF_FRONT_END =
ElfFrontEnd (structure Basic = Basic
structure Term = Term
structure Sb = Sb
structure Reduce = Reduce
structure Print = Print
structure Sign = Sign
structure Trail = Trail
structure Constraints = Constraints
structure TypeRecon = ElfTypeRecon
structure Interface = Interface
structure Absyn = Absyn
structure ElfParse = ElfParse
structure Symtab = Symtab
structure Naming = Naming
structure Redundancy = Redundancy);
structure Symtab : SYMTAB =
SymtabInit (structure Term = Term
structure Sign = Sign
structure EmptySymtab = Symtab
val sig_file_read = ElfFrontEnd.file_read
val init_file = Location.lam_home ^ "elf/lib/init.elf");
structure Absyn : ABSYN =
Absyn (structure Basic = Basic
structure Term = Term
structure Naming = Naming
structure Symtab = Symtab);
structure ElfLrVals : Elf_LRVALS =
ElfLrValsFun (structure Token = LrParser.Token
structure Term = Term
structure Absyn = Absyn
structure ElfAbsyn = ElfAbsyn);
structure ElfLex : LEXER =
ElfLexFun (structure Tokens = ElfLrVals.Tokens
structure Interface = Interface);
structure ElfParser : PARSER =
Join (structure ParserData = ElfLrVals.ParserData
structure Lex = ElfLex
structure LrParser = LrParser);
structure ElfParseCore : PARSE =
ParseCore (structure Interface = Interface
structure Parser = ElfParser
val EOF_token_name = ElfLrVals.Tokens.EOF
val QUERY_token_name = ElfLrVals.Tokens.QUERY
val SIGENTRY_token_name = ElfLrVals.Tokens.SIGENTRY);
structure ElfParse : ELF_PARSE =
ElfParse (structure ElfAbsyn = ElfAbsyn
structure Parse = ElfParseCore
structure Tokens = ElfLrVals.Tokens);
structure ElfFrontEnd : ELF_FRONT_END =
ElfFrontEnd (structure Basic = Basic
structure Term = Term
structure Sb = Sb
structure Reduce = Reduce
structure Print = Print
structure Sign = Sign
structure Trail = Trail
structure Constraints = Constraints
structure TypeRecon = ElfTypeRecon
structure Interface = Interface
structure Absyn = Absyn
structure ElfParse = ElfParse
structure Symtab = Symtab
structure Naming = Naming
structure Redundancy = Redundancy);
structure Specials : SPECIALS =
Specials (structure Term = Term
structure Symtab = Symtab);
structure Progtab : PROGTAB =
Progtab (structure Basic = Basic
structure Term = Term
structure Sb = Sb
structure Sign = Sign
structure Print = ElfPrint
structure Reduce = Reduce
structure Skeleton = Skeleton);
structure UnifySkeleton =
UnifySkeleton (structure Basic = Basic
structure Term = Term
structure Sb = Sb
structure Reduce = Reduce
structure Print = Print
structure Trail = Trail
structure UUtils = ElfUUtils
structure Constraints = Constraints
structure Unify = ElfUnify
structure Skeleton = Skeleton);
structure SolverStats : SOLVER_STATS = SolverStats ();
structure Solver : SOLVER =
Solver (structure Basic = Basic
structure Term = Term
structure Skeleton = Skeleton
structure Sb = Sb
structure Sign = Sign
structure Constraints = Constraints
structure Reduce = Reduce
structure Trail = Trail
structure Unify = ElfUnify
structure UnifySkeleton = UnifySkeleton
structure IPrint = Print
structure Print = ElfPrint
structure Specials = Specials
structure Progtab = Progtab
val enable_stats = false
structure SolverStats = SolverStats);
structure Store : STORE =
Store(structure Basic = Basic
structure Term = Term
structure Sb = Sb
structure Sign = Sign
structure Progtab = Progtab
structure Solver = Solver
structure Trail = Trail
structure Constraints = Constraints
structure TypeRecon = ElfTypeRecon
structure ElfFrontEnd = ElfFrontEnd
structure Reduce = Reduce
structure Redundancy = Redundancy
structure Symtab = Symtab);
structure Elf : ELF =
Elf (structure Basic = Basic
structure Term = Term
structure Sb = Sb
structure Reduce = Reduce
structure Sign = Sign
structure Constraints = Constraints
structure Unify = ElfUnify
structure Print = ElfPrint
structure Specials = Specials
structure Progtab = Progtab
structure Simplify = ElfSimplifyEquals
structure TypeRecon = ElfTypeRecon
structure ElfFrontEnd = ElfFrontEnd
structure Solver = Solver
structure Sys = Sys
structure Time = Time
structure Store = Store);
