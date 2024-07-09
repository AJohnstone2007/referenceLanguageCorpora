(*  ==== INITIAL BASIS : CHARACTERS ====
 *
 *  Copyright 2013 Ravenbrook Limited <http://www.ravenbrook.com/>.
 *  All rights reserved.
 *  
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 *  
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 *  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 *  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  Description
 *  -----------
 *  This is part of the extended Initial Basis.
 *
 *  Revision Log
 *  ------------
 *  $Log: char.sml,v $
 *  Revision 1.6  1996/10/03 15:20:04  io
 *  [Bug #1614]
 *  remove redundant requires
 *
 *  Revision 1.5  1996/10/01  13:13:02  io
 *  [Bug #1626]
 *  remove option type in toCString
 *
 *  Revision 1.4  1996/06/04  15:23:23  io
 *  stringcvt -> string_cvt
 *
 *  Revision 1.3  1996/05/22  09:44:32  io
 *  fix bug in isPrint & isGraph
 *
 *  Revision 1.2  1996/05/17  15:55:44  io
 *  fromCString valid
 *
 *  Revision 1.1  1996/05/14  14:12:01  jont
 *  new unit
 *
 * Revision 1.3  1996/05/14  14:12:01  io
 * remove exception Chr
 *
 * Revision 1.2  1996/05/07  21:05:52  io
 * revising...
 *
 * Revision 1.1  1996/04/18  11:41:00  jont
 * new unit
 *
 *  Revision 1.1  1995/03/08  16:22:37  brianm
 *  new unit
 *  No reason given
 *
 *
 *)
require "__string_cvt";
signature CHAR =
  sig

    eqtype char
    eqtype string

    val maxOrd : int
    val minChar : char
    val maxChar : char

    val chr : int -> char (* raise Chr *)
    val ord : char -> int

    val succ : char -> char (* raise Chr *)
    val pred : char -> char (* raise Chr *)

    val <  : (char * char) -> bool
    val <= : (char * char) -> bool
    val >  : (char * char) -> bool
    val >= : (char * char) -> bool

    val compare : (char * char) -> order
    val contains : string -> char -> bool
    val notContains : string -> char -> bool
    val isLower : char -> bool
    val isUpper : char -> bool
    val isDigit : char -> bool
    val isAlpha : char -> bool
    val isAlphaNum : char -> bool
    val isAscii : char -> bool
    val isSpace : char -> bool
    val toLower : char -> char
    val toUpper : char -> char
    val isCntrl : char -> bool
    val isGraph : char -> bool
    val isHexDigit : char -> bool
    val isPrint: char -> bool

    val isPunct : char -> bool
    val fromString : string -> char option
    val toString : char -> string
    val scan : (char, 'a) StringCvt.reader -> 'a -> (char * 'a) option

    val fromCString : string -> char option
    val toCString : char -> string


  end; (* CHAR *)
