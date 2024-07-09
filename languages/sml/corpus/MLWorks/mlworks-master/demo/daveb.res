! Dave's .Xresources file.

*Font:          -*-times-medium-r-*-*-14-*-*-*-*-*-*-1
*Background:    White
*Foreground:    Black
*Text.Translations:			#override \
                        		Button1 <Btn2Down>:	extend-end(CLIPBOARD)
*BlinkRate:	0

visual*geometry:			80x50

XTerm*utmpInhibit:			true
xterm-console.icongeometry:		+5+5
XTerm.geometry:				80x25
XTerm*SimpleMenu*background:		#E0EFFF
XTerm*fontMenu.Label:			VT Fonts
XTerm*fontMenu*fontdefault*Label:	Default
XTerm*fontMenu*font1*Label:		Unreadable
XTerm*VT100*font:			-adobe-courier-medium-r-*-*-14-*-*-*-*-*-*-1
XTerm*VT100*font1:			nil2
XTerm*fontMenu*font2*Label:		Tiny
XTerm*VT100*font2:			-adobe-courier-medium-r-*-*-8-*-*-*-*-*-*-1
XTerm*fontMenu*font3*Label:		Small
XTerm*VT100*font3:			-adobe-courier-medium-r-*-*-10-*-*-*-*-*-*-1
XTerm*fontMenu*font4*Label:		Medium
XTerm*VT100*font4:			-adobe-courier-medium-r-*-*-12-*-*-*-*-*-*-1
XTerm*fontMenu*font5*Label:		Large
XTerm*VT100*font5:			-adobe-courier-medium-r-*-*-14-*-*-*-*-*-*-1
XTerm*fontMenu*font6*Label:		Huge
XTerm*VT100*font6:			-adobe-courier-medium-r-*-*-18-*-*-*-*-*-*-1
XTerm*thickness:			8
XTerm*VT100.scrollTtyOutput:		false
XTerm*VT100.scrollKey:			true
XTerm*VT100.saveLines:			4000
XTerm*VT100.reverseWrap:		true
XTerm*VT100.Translations:    		#override \
                        		Button1 <Btn2Down>:	select-end(CLIPBOARD)\n\
                        		Button1 <Btn2Up>:	ignore()\n\
                                        Ctrl Shift ~Button2 ~Button3 <Btn1Down>: set-vt-font(1) \n\
                                        Ctrl Shift ~Button2 ~Button3 <Btn2Down>: set-vt-font(2) \n\
                                        Ctrl Shift ~Button1 ~Button2 <Btn3Down>: set-vt-font(4)
shell*VT100.scrollBar:			true
shell*VT100.geometry:			80x50
shell*Title:				Shell
shell*IconName:				Shell
remoteShell*VT100.scrollBar:		true
remoteShell*VT100.geometry:		80x25
remoteShell*Title:			Remote Shell
remoteShell*IconName:			Remote Shell
processStatus*VT100.font:		-adobe-courier-medium-r-*-*-8-*-*-*-*-*-*-1
processStatus*VT100.geometry:		64x11
processStatus*Title:			Process Status
processStatus*IconName:			PS
monitor*VT100.font:			-adobe-courier-medium-r-*-*-8-*-*-*-*-*-*-1
monitor*VT100.geometry:			64x11
monitor*Title:				Process Status
monitor*IconName:			Monitor

Xman*manualBrowser.title:		Manual
Xman*manualBrowser.iconName:		Manual
Xman*pleaseStandBy*Label:		Formatting...
Xman*manualBrowser.geometry:		600x648
Xman*directoryHeight:			128
Xman*manualFontNormal:			-adobe-courier-medium-r-*-*-12-*-*-*-*-*-*-1
Xman*manualFontBold:			-adobe-courier-bold-r-*-*-12-*-*-*-*-*-*-1
Xman*manualFontItalic:			-adobe-courier-medium-o-*-*-12-*-*-*-*-*-*-1
Xman*SimpleMenu.font:			-*-times-medium-r-*-*-14-*-*-*-*-*-*-1
Xman*bothShown:				false
Xman*topBox:				false

XLoad*geometry:				65x65
XClock*geometry:			65x65
XFontSel*sampleText*Label: \
 !"#$%&'()*+,-./\n\
0123456789:;<=>?\n\
@ABCDEFGHIJKLMNO\n\
PQRSTUVWXYZ[\\]^_\n\
`abcdefghijklmno\n\
pqrstuvwxyz{|}~
XFontSel*sampleText*Height: 60

Emacs*Font:				-adobe-courier-medium-r-*-*-14-*-*-*-*-*-*-1
emacs*Font:				-adobe-courier-medium-r-*-*-14-*-*-*-*-*-*-1
xemacs*Font:				-adobe-courier-medium-r-*-*-14-*-*-*-*-*-*-1
epoch.screen.class:     		Epoch
epoch.minibuf.class:    		Epoch

XClipboard*title:			Clipboard
XClipboard*iconName:			Clipboard
XClipboard*Font:			-*-times-medium-r-*-*-14-*-*-*-*-*-*-1
XClipboard*Text*Font:			-adobe-courier-medium-r-*-*-14-*-*-*-*-*-*-1
XClipboard*wordWrap:			false

XFontSel*title:				Font Selector
XFontSel*iconName:			Font

XCutsel*title:				Cut Selector
XCutsel*iconName:			Cut

Mwm*buttonBindings:		globalButtons
Mwm*bitmapDirectory:		HOME/lib/X11/bitmaps
Mwm*clientAutoPlace:		false
Mwm*doubleClickTime:            3000
Mwm*enableWarp:			false
Mwm*iconAutoPlace:		false
Mwm*interactivePlacement:	true
Mwm*lowerOnIconify:		false
Mwm*transientDecoration:	all
Mwm*XClock.clientDecoration:	border
Mwm*XLoad.clientDecoration:	border
Mwm*XBiff.clientDecoration:	border
Mwm*processStatus.clientDecoration:	border
Mwm*monitor.clientDecoration:	border
Mwm*showFeedback:		placement resize behavior quit restart kill
Mwm*fontList:			-*-times-medium-r-*-*-14-*-*-*-*-*-*-1
Mwm*background:			#B0D8E6
Mwm*foreground:			Black
Mwm*topShadowColor:		#D0F8FF
Mwm*bottomShadowColor:		#90B8C6
Mwm*activeBackground:		#E0EFFF
Mwm*activeForeground:		Black
Mwm*activeTopShadowColor:	#FFFFFF
Mwm*activeBottomShadowColor:	#C0D0D0
Mwm*menu*background:		#EFCFAF
Mwm*menu*foreground:		Black
Mwm*menu*topShadowColor:	#FFEFAF
Mwm*menu*bottomShadowColor:	#D0C05F
Mwm*iconImageBackground:	White
Mwm*iconImageForeground:	Black
Mwm*iconDecoration:		activelabel label image
Mwm*resizeBorderWidth:		5
Mwm*keyboardFocusPolicy:	pointer
Mwm*moveOpaque:			False
Mwm*focusAutoRaise:		False
Mwm*iconPlacement:		top left
Mwm*startupKeyFocus:		True
Mwm*iconImageMinimum:		16x16
Mwm*iconImageMaximum:		32x32
Mwm*shell*iconImage:		scallop.xbm
Mwm*smallShell*iconImage:	scallop.xbm
Mwm*remoteShell*iconImage:	remote-scallop.xbm
Mwm*Emacs*iconImage:		emacs.xbm
Mwm*Xman*iconImage:		manual.xbm
Mwm*dxterm*iconImage:		crap.xbm
Mwm*sm*iconImage:		crap.xbm
Mwm*XClipboard*iconImage:	clipboard.xbm
Mwm*XFontSel*iconImage:		font.xbm
Mwm*XConsole*iconImage:		console.xbm
Mwm*XCutsel*iconImage:		scissors.xbm
Mwm*Bitmap*iconImage:		bitmap.xbm
Mwm*windowMenu:			windowToolMenu
!Mwm*useIconBox:			true
!Mwm*iconBoxGeometry:		6x2+0+80
!Mwm*iconBoxSBDisplayPolicy:	vertical
!Mwm*iconbox.clientDecoration:	border
!Mwm*iconbox.matteWidth:		0

notes*multiClickTime:		500

