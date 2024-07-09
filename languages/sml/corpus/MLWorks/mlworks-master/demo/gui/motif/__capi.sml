(* === CAPI example for Motif ===
 * 
 * Copyright 2013 Ravenbrook Limited <http://www.ravenbrook.com/>.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * $Log: __capi.sml,v $
 * Revision 1.2  1998/08/05 16:59:23  johnh
 * [Bug #30463]
 * Add make_form for use by guess demo.
 *
# Revision 1.1  1998/07/21  09:53:16  johnh
# new unit
# [Bug #30441]
# Part of an example of CAPI and projects.
#
 *)

require "capi";
require "__xm";

structure Capi : CAPI = 
struct

  type Widget = Xm.widget

  fun initialize_application (name, title) =
    Xm.initialize ("MLWorks", "mlworks", [(Xm.TITLE, Xm.STRING title),
				 (Xm.ICON_NAME, Xm.STRING title)])

  datatype WidgetAttribute = 
      PanedMargin of bool
    | Position of    int * int
    | Size of        int * int
    | ReadOnly of    bool

  fun convert_widget_attributes (PanedMargin true) =
      [(Xm.MARGIN_WIDTH, Xm.INT 10)]
    | convert_widget_attributes (PanedMargin false) =
      [(Xm.MARGIN_WIDTH, Xm.INT 0)]
    | convert_widget_attributes (Position (x,y)) = 
      [(Xm.X, Xm.INT x), (Xm.Y, Xm.INT y)]
    | convert_widget_attributes (Size (w,h)) = 
      [(Xm.WIDTH, Xm.INT w), (Xm.HEIGHT, Xm.INT h)]
    | convert_widget_attributes (ReadOnly tf) = 
      [(Xm.EDITABLE, Xm.BOOL (not tf))]

  fun setAttribute (widg, attrib) = 
    Xm.Widget.valuesSet (widg, convert_widget_attributes attrib)

  val destroy = Xm.Widget.destroy
  val reveal = Xm.Widget.manage
  val hide = Xm.Widget.unmanageChild
  val to_front = Xm.Widget.toFront
  val parent = Xm.Widget.parent

  fun quit_loop shell = Xm.Widget.destroy shell

  fun initialize_toplevel shell= 
    (Xm.Widget.realize shell;
     Xm.Widget.map shell)

  fun initialize_application_shell shell =
    Xm.Widget.realize shell

  (* set the label string of a label widget *)  
  fun set_label_string (label,s) =
    let
      val cstring = Xm.CompoundString.createSimple s
    in
      Xm.Widget.valuesSet (label, 
                           [(Xm.LABEL_STRING, Xm.COMPOUND_STRING cstring)])
    end
  
  fun widget_size widget =
    case Xm.Widget.valuesGet (widget,[Xm.WIDTH,Xm.HEIGHT]) of
      [Xm.INT width,Xm.INT height] => (width,height) 
    | _ => (50,50)

  fun widget_pos widget =
    case Xm.Widget.valuesGet (widget,[Xm.X,Xm.Y]) of
      [Xm.INT horz,Xm.INT vert] => (horz,vert) 
    | _ => (50,50)

  fun main_loop () = Xm.mainLoop () 

  fun send_message (parent,message) =
    let
      val dialog =
        Xm.Widget.createPopupShell ("messageDialog",
                                    Xm.Widget.DIALOG_SHELL,
                                    parent, [])
            
      val widget =
        Xm.Widget.create
          ("message", Xm.Widget.MESSAGE_BOX, dialog,
           [(Xm.MESSAGE_STRING, Xm.COMPOUND_STRING (Xm.CompoundString.createSimple message))])

      val _ =
        map 
           (fn c =>
             Xm.Widget.unmanageChild (Xm.MessageBox.getChild(widget,c)))
           [Xm.Child.CANCEL_BUTTON,
            Xm.Child.HELP_BUTTON]

      fun exit _ = Xm.Widget.destroy dialog
    in
      Xm.Callback.add (widget, Xm.Callback.OK, exit);
      Xm.Widget.manage widget
    end

  datatype Callback =
	Activate
      | Destroy
      | Unmap
      | Resize
      | ValueChange

  fun add_callback (w,t,f) =
    let
      val xt =
        case t of
          Activate => Xm.Callback.ACTIVATE
        | Destroy => Xm.Callback.DESTROY
        | Unmap => Xm.Callback.UNMAP
	| Resize => Xm.Callback.RESIZE
	| ValueChange => Xm.Callback.VALUE_CHANGED
    in
      Xm.Callback.add (w,xt,fn _ => f ())
    end

  fun move_window (widget, x, y) = ()
  fun size_window (widget, w, h) = 
    Xm.Widget.valuesSet (widget, [(Xm.WIDTH, Xm.INT w),
				  (Xm.HEIGHT, Xm.INT h)])

  val get_text_string = Xm.Text.getString
  val set_text_string = Xm.Text.setString

  fun make_window (name, parent, attributes) =
    let
      val shell =
        Xm.Widget.create
	  (name,
           Xm.Widget.TOP_LEVEL_SHELL,
           parent,
           [(Xm.TITLE, Xm.STRING name),
            (Xm.ICON_NAME, Xm.STRING name)])

      val mainWindow = Xm.Widget.create ("main", Xm.Widget.FORM, shell, [])
    in
      Xm.Widget.manage mainWindow;
      (shell,mainWindow)
    end

  fun make_widget (name, class, parent, attributes) =
    let
      val parameter_attributes = 
	foldl (op @) [] (map convert_widget_attributes attributes)
    in
      Xm.Widget.create
	(name, class, parent, parameter_attributes)
    end

  fun make_subwindow (name, parent, attributes) = 
    make_widget (name, Xm.Widget.FORM, parent, attributes)

  fun make_label (name, parent, attributes) = 
    make_widget (name, Xm.Widget.LABEL_GADGET, parent, attributes)

  fun make_text (name, parent, attributes) = 
    make_widget (name, Xm.Widget.TEXT, parent, attributes)

  fun make_button {name, parent, attributes, sensitive, action} = 
    let
      val button = 
	make_widget (name, Xm.Widget.PUSH_BUTTON, parent, attributes)
      fun sens_fn () =
        Xm.Widget.valuesSet (button, [(Xm.SENSITIVE, Xm.BOOL (sensitive()))])
    in
      Xm.Callback.add (button, Xm.Callback.ACTIVATE, fn _ => action());
      (button, sens_fn)
    end

end


