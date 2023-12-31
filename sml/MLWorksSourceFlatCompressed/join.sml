require "base";
functor Join(structure Lex : LEXER
structure ParserData: PARSER_DATA
structure LrParser : LR_PARSER
sharing ParserData.LrTable = LrParser.LrTable
sharing ParserData.Token = LrParser.Token
sharing type Lex.UserDeclarations.svalue = ParserData.svalue
sharing type Lex.UserDeclarations.pos = ParserData.pos
sharing type Lex.UserDeclarations.token = ParserData.Token.token)
: PARSER =
struct
structure Token = ParserData.Token
structure Stream = LrParser.Stream
exception ParseError = LrParser.ParseError
type arg = ParserData.arg
type pos = ParserData.pos
type result = ParserData.result
type svalue = ParserData.svalue
val makeLexer = LrParser.Stream.streamify o Lex.makeLexer
val parse = fn (lookahead,lexer,error,arg) =>
(fn (a,b) => (ParserData.Actions.extract a,b))
(LrParser.parse {table = ParserData.table,
lexer=lexer,
lookahead=lookahead,
saction = ParserData.Actions.actions,
arg=arg,
void= ParserData.Actions.void,
ec = {is_keyword = ParserData.EC.is_keyword,
noShift = ParserData.EC.noShift,
preferred_change = ParserData.EC.preferred_change,
errtermvalue = ParserData.EC.errtermvalue,
error=error,
showTerminal = ParserData.EC.showTerminal,
terms = ParserData.EC.terms}}
)
val sameToken = Token.sameToken
end
functor JoinWithArg(structure Lex : ARG_LEXER
structure ParserData: PARSER_DATA
structure LrParser : LR_PARSER
sharing ParserData.LrTable = LrParser.LrTable
sharing ParserData.Token = LrParser.Token
sharing type Lex.UserDeclarations.svalue = ParserData.svalue
sharing type Lex.UserDeclarations.pos = ParserData.pos
sharing type Lex.UserDeclarations.token = ParserData.Token.token)
: ARG_PARSER =
struct
structure Token = ParserData.Token
structure Stream = LrParser.Stream
exception ParseError = LrParser.ParseError
type arg = ParserData.arg
type lexarg = Lex.UserDeclarations.arg
type pos = ParserData.pos
type result = ParserData.result
type svalue = ParserData.svalue
val makeLexer = fn s => fn arg =>
LrParser.Stream.streamify (Lex.makeLexer s arg)
val parse = fn (lookahead,lexer,error,arg) =>
(fn (a,b) => (ParserData.Actions.extract a,b))
(LrParser.parse {table = ParserData.table,
lexer=lexer,
lookahead=lookahead,
saction = ParserData.Actions.actions,
arg=arg,
void= ParserData.Actions.void,
ec = {is_keyword = ParserData.EC.is_keyword,
noShift = ParserData.EC.noShift,
preferred_change = ParserData.EC.preferred_change,
errtermvalue = ParserData.EC.errtermvalue,
error=error,
showTerminal = ParserData.EC.showTerminal,
terms = ParserData.EC.terms}}
)
val sameToken = Token.sameToken
end;
