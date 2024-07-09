(*
 *
 * $Log: pi_grm.sig,v $
 * Revision 1.2  1998/06/11 13:09:36  jont
 * Automatic checkin:
 * changed attribute _comment to ' * '
 *
 *
 *)
signature PI_TOKENS =
sig
type ('a,'b) token
type svalue
val NU: (string) *  'a * 'a -> (svalue,'a) token
val MU: (string) *  'a * 'a -> (svalue,'a) token
val SIGMA: (string) *  'a * 'a -> (svalue,'a) token
val BSIGMA: (string) *  'a * 'a -> (svalue,'a) token
val PI: (string) *  'a * 'a -> (svalue,'a) token
val EXISTS: (string) *  'a * 'a -> (svalue,'a) token
val NOT: (string) *  'a * 'a -> (svalue,'a) token
val FF: (string) *  'a * 'a -> (svalue,'a) token
val TT: (string) *  'a * 'a -> (svalue,'a) token
val SHOW: (string) *  'a * 'a -> (svalue,'a) token
val SET: (string) *  'a * 'a -> (svalue,'a) token
val VERSION: (string) *  'a * 'a -> (svalue,'a) token
val FALSE: (string) *  'a * 'a -> (svalue,'a) token
val TRUE: (string) *  'a * 'a -> (svalue,'a) token
val OFF: (string) *  'a * 'a -> (svalue,'a) token
val ON: (string) *  'a * 'a -> (svalue,'a) token
val REMEMBER: (string) *  'a * 'a -> (svalue,'a) token
val REWRITE: (string) *  'a * 'a -> (svalue,'a) token
val QUIT: (string) *  'a * 'a -> (svalue,'a) token
val HELP: (string) *  'a * 'a -> (svalue,'a) token
val WEQD: (string) *  'a * 'a -> (svalue,'a) token
val WEQ: (string) *  'a * 'a -> (svalue,'a) token
val WTRANS: (string) *  'a * 'a -> (svalue,'a) token
val TRANS: (string) *  'a * 'a -> (svalue,'a) token
val TABLES: (string) *  'a * 'a -> (svalue,'a) token
val TRACES: (string) *  'a * 'a -> (svalue,'a) token
val TIMEr: (string) *  'a * 'a -> (svalue,'a) token
val THRESHOLD: (string) *  'a * 'a -> (svalue,'a) token
val SIZE: (string) *  'a * 'a -> (svalue,'a) token
val ZTEP: (string) *  'a * 'a -> (svalue,'a) token
val STEP: (string) *  'a * 'a -> (svalue,'a) token
val INPUT: (string) *  'a * 'a -> (svalue,'a) token
val EQD: (string) *  'a * 'a -> (svalue,'a) token
val EQ: (string) *  'a * 'a -> (svalue,'a) token
val ENVIRONMENT: (string) *  'a * 'a -> (svalue,'a) token
val DEBUG: (string) *  'a * 'a -> (svalue,'a) token
val DEAD: (string) *  'a * 'a -> (svalue,'a) token
val CLEAR: (string) *  'a * 'a -> (svalue,'a) token
val CHECK: (string) *  'a * 'a -> (svalue,'a) token
val AGENT: (string) *  'a * 'a -> (svalue,'a) token
val ALL: (string) *  'a * 'a -> (svalue,'a) token
val DummyFORMULA:  'a * 'a -> (svalue,'a) token
val DummyAGENT:  'a * 'a -> (svalue,'a) token
val DummyCMD:  'a * 'a -> (svalue,'a) token
val EOL:  'a * 'a -> (svalue,'a) token
val EOF:  'a * 'a -> (svalue,'a) token
val SEMICOLON:  'a * 'a -> (svalue,'a) token
val COMMA:  'a * 'a -> (svalue,'a) token
val QUERY:  'a * 'a -> (svalue,'a) token
val BANG:  'a * 'a -> (svalue,'a) token
val AMPERSAND:  'a * 'a -> (svalue,'a) token
val SHARP:  'a * 'a -> (svalue,'a) token
val QUOTE:  'a * 'a -> (svalue,'a) token
val HAT:  'a * 'a -> (svalue,'a) token
val EQUALS:  'a * 'a -> (svalue,'a) token
val SLASH:  'a * 'a -> (svalue,'a) token
val BACKSLASH:  'a * 'a -> (svalue,'a) token
val DOT:  'a * 'a -> (svalue,'a) token
val isGREATER:  'a * 'a -> (svalue,'a) token
val isLESS:  'a * 'a -> (svalue,'a) token
val RBRACE:  'a * 'a -> (svalue,'a) token
val LBRACE:  'a * 'a -> (svalue,'a) token
val RBRACK:  'a * 'a -> (svalue,'a) token
val LBRACK:  'a * 'a -> (svalue,'a) token
val RPAR:  'a * 'a -> (svalue,'a) token
val LPAR:  'a * 'a -> (svalue,'a) token
val NIL:  'a * 'a -> (svalue,'a) token
val PLUS:  'a * 'a -> (svalue,'a) token
val PAR:  'a * 'a -> (svalue,'a) token
val STRING: (string) *  'a * 'a -> (svalue,'a) token
val TAU: (string) *  'a * 'a -> (svalue,'a) token
val NUM: (int) *  'a * 'a -> (svalue,'a) token
val ACT: (string) *  'a * 'a -> (svalue,'a) token
val ID: (string) *  'a * 'a -> (svalue,'a) token
end
signature PI_LRVALS=
sig
structure Tokens : PI_TOKENS
structure ParserData:PARSER_DATA
sharing type ParserData.Token.token = Tokens.token
sharing type ParserData.svalue = Tokens.svalue
end
