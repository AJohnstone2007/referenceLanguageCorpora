(* ***********************************************************************

   Project: sml/Tk: an Tk Toolkit for sml
   Author: Stefan Westmeier, University of Bremen
  $Date: 1999/06/16 09:58:14 $
  $Revision: 1.1 $
   Purpose of this file: basic process control and communication routines

   *********************************************************************** *)

require "__text_io";

require "basic_types";

signature COM =
    sig
	val addApp    : BasicTypes.AppId * BasicTypes.program * 
	                BasicTypes.protocolName * BasicTypes.CallBack * 
			BasicTypes.QuitAction -> unit
	val addAppI   : BasicTypes.App -> unit
	val removeApp : BasicTypes.AppId -> unit

	val getApp    : BasicTypes.AppId -> BasicTypes.App

	val selAppId         : BasicTypes.App -> BasicTypes.AppId
	val selAppProt       : BasicTypes.App -> TextIO.outstream
	val selAppIn         : BasicTypes.App -> TextIO.outstream
	val selAppOut        : BasicTypes.App -> TextIO.instream
	val selAppCallBack   : BasicTypes.App -> BasicTypes.CallBack
	val selAppQuitAction : BasicTypes.App -> BasicTypes.QuitAction

(*
	val getProt    : unit -> outstream
	val getIn      : unit -> outstream
	val getOut     : unit -> instream
	val getAppProt : AppId -> outstream
	val getAppIn   : AppId -> outstream
	val getAppOut  : AppId -> instream
*)
	val getAppCallBack   : BasicTypes.AppId -> BasicTypes.CallBack
	val getAppQuitAction : BasicTypes.AppId -> BasicTypes.QuitAction


	val getLine   : unit -> string
	val getLineM  : unit -> string
	val putLine   : string -> unit
	val getLineApp  : BasicTypes.AppId -> string
	val getLineMApp : BasicTypes.AppId -> string
	val putLineApp  : BasicTypes.AppId -> string -> unit

	val putTclCmd  : string -> unit
	val readTclVal : string -> string

	val commToTcl  : string
	val writeToTcl : string
	val writeMToTcl: string

	val initTcl  : BasicTypes.CallBack -> bool
	val runTcl   : unit -> unit
	val exitTcl  : unit -> unit
	val resetTcl : unit -> unit
    end;
