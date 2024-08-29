(* net-db.sml
 *
 * This file includes parts which are Copyright (c) 1995 AT&T Bell
 * Laboratories. All rights reserved.  
 *
 * $Log: __net_db.sml,v $
 * Revision 1.2  1999/02/16 09:31:27  mitchell
 * [Bug #190508]
 * Improve layout
 *
 *  Revision 1.1  1999/02/15  14:07:54  mitchell
 *  new unit
 *  [Bug #190508]
 *  Add socket support to the basis library
 *
 *)

require "net_db.sml";
require "__sys_word";
require "__pre_sock";
require "__string_cvt";
require "__word8";

structure NetDB : NET_DB =
  struct

    structure SysW = SysWord

    val netdbFun = MLWorks.Internal.Runtime.environment

    datatype net_addr = NETADDR of SysW.word

    type addr_family = PreSock.addr_family

    datatype entry = NETENT of {
        name : string,
        aliases : string list,
        addrType : addr_family,
        addr : net_addr
      }

    local
      fun conc field (NETENT a) = field a
    in
      val name = conc #name
      val aliases = conc #aliases
      val addrType = conc #addrType
      val addr = conc #addr
    end (* local *)

    (* Network DB query functions *)
    local
      type netent
        = (string * string list * PreSock.af * SysWord.word)
      fun getNetEnt NONE = NONE
        | getNetEnt (SOME(name, aliases, addrType, addr)) = SOME(NETENT{
              name = name, aliases = aliases,
              addrType = PreSock.AF addrType, addr = NETADDR addr
            })
      val getNetByName' : string -> netent option
            = netdbFun "system os getNetByName";

      val getNetByAddr' : (SysWord.word * PreSock.af) -> netent option
            = netdbFun "system os getNetByAddr"
    in
      val getByName = getNetEnt o getNetByName'
      fun getByAddr (NETADDR addr, PreSock.AF af) =
            getNetEnt(getNetByAddr'(addr, af))
    end (* local *)

    fun scan getc strm = 
        let
          val (op +) = SysW.+
        in
          case (PreSock.toWords getc strm) of
            SOME([a, b, c, d], strm) =>
              SOME(
                NETADDR(SysW.<<(a, 0w24)+SysW.<<(b, 0w16)+SysW.<<(c, 0w8)+d),
                strm)
          | SOME([a, b, c], strm) =>
              SOME(NETADDR(SysW.<<(a, 0w24)+SysW.<<(b, 0w16)+c), strm)
          | SOME([a, b], strm) =>
              SOME(NETADDR(SysW.<<(a, 0w24)+b), strm)
          | SOME([a], strm) => SOME(NETADDR a, strm)
          | _ => NONE
        end

    val fromString = StringCvt.scanString scan

    fun toString (NETADDR addr) = 
        let fun get n = Word8.fromLargeWord(SysW.toLargeWord((SysW.>>(addr, n))))
         in PreSock.fromBytes (get 0w24, get 0w16, get 0w8, get 0w0)
        end
  end




