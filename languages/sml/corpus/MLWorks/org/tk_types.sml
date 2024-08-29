(* ***************************************************************************
 
   $Source: /Users/nb/info.ravenbrook.com/project/mlworks/import/2013-04-25/xanalys-tarball/MLW/smltk/src/RCS/tk_types.sml,v $
 
   sml_tk Export Signature.  ``All you ever wanted to know about sml_tk''
  
   Part I: Types, type constructors, selectors etc. 

   $Date: 1999/06/16 10:06:36 $
   $Revision: 1.1 $
   Author: cxl (Last modification by $Author: johnh $)

   (C) 1996, Bremen Institute for Safe Systems, Universitaet Bremen
 
  ************************************************************************** *)

require "__text_io";

require "fonts";
require "basic_types";
require "com";
require "config";
require "tk_event";
require "c_item";
require "ann_texts";
require "annotation";

signature TK_TYPES =
  sig

    (* type 'a option; *)
    (* datatype 'a option = NONE | SOME of 'a *)
    (* This type is here because Isabelle has another type called option
     * with constructors Some and None. *)

    (*
     * Exceptions 
     *)
    exception CITEM of string
    exception WIDGET of string    
    exception TCL_ERROR of string
    exception CONFIG of string
    exception WINDOWS of string


    type AnnId 
    type Title
    type WidPath

    type BitmapName 
    type BitmapFile 
    type ImageFile
(*  type PixmapFile *)
    type CursorName
    type CursorFile

    (* Identifiers for sml_tk's entities: windows, CItems, Images, Widgets *)
    type WinId
    type CItemId
    type ImageId
    type WidId

    type Coord 

    datatype TkEvent =
      TkEvent of int                       (* %b  button number     *)
	      *  string                    (* %s  state field       *)
              *  int                       (* %x  x field           *)
              *  int                       (* %y  y field           *)
              *  int                       (* %X  x_root field      *)
              *  int                       (* %Y  y_root field      *)       

    (* -- selectors *)
    val selButton   : TkEvent -> int
    val selState    : TkEvent -> string
    val selXPos     : TkEvent -> int
    val selXRootPos : TkEvent -> int
    val selYPos     : TkEvent -> int
    val selYRootPos : TkEvent -> int
	
    type SimpleAction 
    type Action

    datatype Event = 
	(* Key press/release events *)
	KeyPress   of string
      | KeyRelease of string
	(* Button press/release events, NONE means any old button *)
      | ButtonPress   of int option
      | ButtonRelease of int option
	(* Cursor events *)
      | Enter  | Leave  | Motion      
	(* user-defined events, or explicitly given events *)
      | UserEv of string
	(* event modifiers  *)
      | Shift of Event  | Ctrl of Event | Lock of Event   | Any of Event 
      | Double of Event | Triple of Event
      | ModButton of int* Event
      | Alt of Event    | Meta of Event 
      | Mod3 of Event   | Mod4 of Event | Mod5 of Event 
	(* Not all combinations make sense, eg.
	 * modifiying a button event with a different button will cast
	 * doubt on either your sanity or understanding of these events *)


    datatype Binding = BindEv of Event * Action


    datatype RelKind =  
	Flat | Groove | Raised | Ridge | Sunken

    datatype Color	= 
	NoColor | Black | White | Grey | Blue | Green | Red | Brown | Yellow

    datatype ArrowPos   = 
	NoneAP | FirstAP | LastAP | BothAP

    datatype CapstyleKind = 
	Butt | Projecting | Round
	
    datatype JoinstyleKind = 
	Bevel | Miter | RoundJoin

    datatype AnchorKind =
	North | NorthEast | 
	East  | SouthEast | 
	South | SouthWest | 
	West  | NorthWest |
	Center

    datatype IconKind =
        NoIcon
      |	TkBitmap    of BitmapName            (* -bitmap <tk bitmap>     *)
      | FileBitmap  of BitmapFile            (* -bitmap @<filename>     *)
(*    | FilePixmap  of PixmapFile * ImageId                             *)
      | FileImage   of ImageFile  * ImageId
      

    datatype CursorKind =
	NoCursor
      |	XCursor     of CursorName * ((Color * (Color option )) option ) 
      | FileCursor  of CursorFile * Color * ((CursorFile * Color) option )
      

    datatype FontConfig =
	Bold | Italic | 
	Tiny | Small | NormalSize | Large | Huge |
	Scale of real 
 
	
    datatype Font = 
	XFont of string  
      | Normalfont of FontConfig list      
      | Typewriter of FontConfig list 
      | SansSerif of  FontConfig list
      | Symbol of     FontConfig list

    datatype Configure =
	Width of int
      | Height of int
      | Borderwidth of int
      | Relief of RelKind
      | Foreground of Color
      | Background of Color
      | Text of string			(* -label "bla" *)
      | Font of Font			(* -font "bla" *)
      | Variable of string		(* -variable "bla" *)
      | Value of string			(* -value "bla" *)
      | Icon of IconKind                (* -bitmap or -image ... *)
      | Cursor of CursorKind            (* -cursor ... *)
      | Command of SimpleAction

      | Anchor of AnchorKind

      | TextWidReadOnly of bool


      | FillColor    of Color
      | Outline      of Color
      | OutlineWidth of int
      | Stipple

      | Smooth    of bool
      | Arrow     of ArrowPos
      | Capstyle  of CapstyleKind
      | Joinstyle of JoinstyleKind
      
    datatype UserKind =
	User
      | Program

    datatype WinConfigure =
	WinAspect       of int * int * int *int                   (* xthin/ythin xfat/yfat *)
      |	WinGeometry     of ((int * int) option)            (* width x height *)
	                 * ((int * int) option)            (* xpos  x ypos   *)
(*
      | WinIcon         of IconKind
      | WinIconMask     of IconKind
      | WinIconName     of string
 *)
      | WinMaxSize      of int * int       (* width * height *)
      | WinMinSize      of int * int
      | WinPositionFrom of UserKind
      | WinSizeFrom     of UserKind
      | WinTitle        of string
      | WinGroup        of WinId                                  (* window / leader *)
      | WinTransient    of WinId option
      | WinOverride     of bool
      

    datatype Edge	= Top | Bottom | Left | Right
    datatype Style	= X | Y | Both
    datatype ScrollType	= NoneScb | LeftScb | RightScb

    datatype Pack	= 
	Expand of bool
      | Fill of Style
      | PadX of int
      | PadY of int
      | Side of Edge

    datatype Mark	= 
	Mark      of int * int 
      | MarkToEnd of int 
      | MarkEnd


    (* main datatypes: widgets, text annotations, canvas items, menu items *)

    datatype Widget	= 
	Frame   of WidId * Widget list * 
	           Pack list * Configure list * Binding list
      | Message of WidId * 
		   Pack list * Configure list * Binding list
      | Label   of WidId * 
		   Pack list * Configure list * Binding list
      | Listbox of WidId * ScrollType * 
		   Pack list * Configure list * Binding list
      | Button  of WidId * 
		   Pack list * Configure list * Binding list
      | Radiobutton of WidId * 
		   Pack list * Configure list * Binding list 
      | Checkbutton of WidId * 
		   Pack list * Configure list * Binding list 
      | Menubutton of WidId * bool * MItem list * 
		   Pack list * Configure list * Binding list 
      | Entry   of WidId * 
		   Pack list * Configure list * Binding list
      | TextWid of WidId * ScrollType * AnnoText *
		   Pack list * Configure list * Binding list
      | Canvas  of WidId * ScrollType * CItem list * 
		   Pack list * Configure list * Binding list
      | Popup   of WidId * bool * MItem list

    and AnnoText = 
	AnnoText of (int* int) option* string* Annotation list

    and Annotation = 
	TATag    of AnnId * (Mark * Mark) list * 
                    Configure list * Binding list
      | TAWidget of AnnId * Mark * WidId * Widget list * Configure list *
                    Configure list * Binding list

    and CItem = 
	CRectangle of CItemId * 
	              Coord * Coord *
		      Configure list * Binding list
      | COval      of CItemId * 
		      Coord * Coord *
		      Configure list * Binding list
      | CLine      of CItemId * 
		      Coord list *
		      Configure list * Binding list
      | CPoly      of CItemId * 
		      Coord list *
		      Configure list * Binding list
      | CIcon      of CItemId * 
		      Coord * IconKind *
		      Configure list * Binding list
      | CWidget    of CItemId * 
		      Coord * WidId * Widget list * Configure list *
		      Configure list * Binding list
      | CTag       of CItemId *
		      CItemId list
    and MItem	= 
	MCheckbutton of (Configure) list 
      | MRadiobutton of (Configure) list 
      | MCascade of MItem list * Configure list
      | MSeparator
      | MCommand of (Configure) list

      (* -- selectors for all widgets *)
      val selWidgetId      : Widget -> WidId
      val selWidgetBind    : Widget -> Binding list
      val selWidgetConf    : Widget -> Configure list

      (* -- update functions for all widgets *)
      val updWidgetBind    : Widget -> Binding list -> Widget
      val updWidgetConf    : Widget -> Configure list -> Widget

      (* -- selectors for Canvas widgets *)
      val selCanvasItems   : Widget -> CItem list
      val selCanvasScrollType : Widget -> ScrollType

      (* -- update functions for Canvas Widgets *)
      val updCanvasItems      : Widget -> CItem list -> Widget
      val updCanvasScrollType : Widget -> ScrollType -> Widget

      (* -- selectors for Text widgets *)
      val selTextWidScrollType  : Widget -> ScrollType
      val selTextWidAnnoText    : Widget -> AnnoText
      val selTextWidText        : Widget -> string
      val selTextWidAnnotations : Widget -> Annotation list

      val updTextWidScrollType  : Widget -> ScrollType      -> Widget
      val updTextWidAnnotations : Widget -> Annotation list -> Widget


      (* -- selectors for CItem *)
      val selItemId         : CItem -> CItemId
      val selItemCoords     : CItem -> Coord list
      val selItemConf       : CItem -> Configure list
      val selItemBind       : CItem -> Binding list

      val selItemIcon       : CItem -> IconKind
      val selItemItems      : CItem -> CItemId list
      val selItemWidId      : CItem -> WidId
      val selItemWidgetConf : CItem -> Configure list
      val selItemWidgets    : CItem -> Widget list

      (* -- update functions for CItem *)
      val updItemCoords     : CItem -> Coord list -> CItem
      val updItemConf       : CItem -> Configure list -> CItem
      val updItemBind       : CItem -> Binding list -> CItem

      val updItemIcon       : CItem -> IconKind -> CItem
      val updItemItems      : CItem -> CItemId list -> CItem
      val updItemWidgetConf : CItem -> Configure list -> CItem
      val updItemWidgets    : CItem -> Widget list -> CItem

      (* -- selectors and update function for AnnoText   *)
      val selText   : AnnoText -> string
      val selAnno   : AnnoText -> Annotation list
      val updAnno   : AnnoText -> Annotation list -> AnnoText

      (* -- selectors for Annotation *)
      val selAnnotationId         : Annotation -> AnnId
      val selAnnotationConf       : Annotation -> Configure list
      val selAnnotationBind       : Annotation -> Binding list
      val selAnnotationMarks      : Annotation -> (Mark * Mark) list
      val selAnnotationWidId      : Annotation -> WidId
      val selAnnotationWidgets    : Annotation -> Widget list
      val selAnnotationWidgetConf : Annotation -> Configure list
      (* -- update functions for Annotation *)
      val updAnnotationConf       : Annotation -> Configure list -> Annotation
      val updAnnotationBind       : Annotation -> Binding list   -> Annotation
      val updAnnotationWidgets    : Annotation -> Widget list    -> Annotation

      (* -- selectors for MItem *)
      val selMCommand        : MItem -> SimpleAction
      val selMRelief         : MItem -> RelKind
      val selMText           : MItem -> string
      val selMWidth          : MItem -> int
      val selMItemConfigure  : MItem -> Configure list
  
      type Window

      (* -- selectors *)
      val selWindowAction     : Window -> SimpleAction
      val selWindowConfigures : Window -> WinConfigure list
      val selWindowWidgets    : Window -> Widget list
      val selWindowWinId      : Window -> WinId


      (* application stuff. not clear what needs to be exported. *)

      type AppId	      
      type CallBack     
      type QuitAction   
      type programName  
      type programParms 
      type program      
      type protocolName 
      type App	      

      (* -- selectors for App *)
      val selAppId         : App -> AppId
      val selAppProt       : App -> TextIO.outstream
      val selAppIn         : App -> TextIO.outstream
      val selAppOut        : App -> TextIO.instream
      val selAppCallBack   : App -> CallBack
      val selAppQuitAction : App -> QuitAction

end



structure TkTypes : TK_TYPES =
  struct

    open Fonts
    open BasicTypes
    open Config
    open CItem
    open Annotation
    open AnnotatedText
    open TkEvent
    open Com

(*  type 'a option = 'a SysDep.option *)

    type EventName     = string
    type AnnId         = string
    type Title         = string
    type WidPath       = string

    type BitmapName    = string
    type BitmapFile    = string
    type ImageFile     = string
    type PixmapFile    = string
    type CursorName    = string
    type CursorFile    = string

    type EventName = string

    type Coord = int * int

    (* CItem *)
    val selItemConf       = selItemConfigure
    val selItemBind       = selItemBinding
    val selItemWidgetConf = selItemWidgetConfigure
    val updItemConf       = updItemConfigure
    val updItemBind       = updItemBinding
    val updItemWidgetConf = updItemWidgetConfigure 

    (* Annotation *)
    val selAnnotationConf       = selAnnotationConfigure
    val selAnnotationBind       = selAnnotationBinding
    val selAnnotationWidgetConf = selAnnotationWidgetConfigure
    val updAnnotationConf       = updAnnotationConfigure
    val updAnnotationBind       = updAnnotationBinding
	
    (* Widget *) 
    val selWidgetId   = selWidgetWidId
    val selWidgetConf = selWidgetConfigure
    val selWidgetBind = selWidgetBinding
    val selWidgetType = selWidgetWidgetType
    val updWidgetConf = updWidgetConfigure
    val updWidgetBind = updWidgetBinding

    type Window = WinId * WinConfigure list * Widget list * SimpleAction

    type AppId	      = string
    type CallBack     = string -> unit
    type QuitAction   = unit -> unit
    type programName  = string
    type programParms = string list
    type program      = (programName * programParms)
    type protocolName = string
    type App	      = (AppId* TextIO.instream* TextIO.outstream* 
			 TextIO.outstream* CallBack * QuitAction) 

end





